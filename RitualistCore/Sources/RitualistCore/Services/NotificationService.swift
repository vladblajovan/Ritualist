//
//  NotificationService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation
@preconcurrency import UserNotifications
#if canImport(UIKit)
import UIKit
#endif

public enum NotificationAuthorizationStatus {
    case notDetermined
    case denied 
    case authorized
    case provisional
    case ephemeral
}

public protocol NotificationService: Sendable {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func checkAuthorizationStatus() async -> Bool
    func schedule(for habitID: UUID, times: [ReminderTime]) async throws
    func scheduleWithActions(for habitID: UUID, habitName: String, habitKind: HabitKind, times: [ReminderTime]) async throws
    func scheduleSingleNotification(for habitID: UUID, habitName: String, habitKind: HabitKind, time: ReminderTime) async throws
    func scheduleRichReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, times: [ReminderTime]) async throws
    func schedulePersonalityTailoredReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, personalityProfile: PersonalityProfile, times: [ReminderTime]) async throws
    func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws
    func cancel(for habitID: UUID) async
    func sendImmediate(title: String, body: String, habitId: UUID?) async throws
    func setupNotificationCategories() async

    // Personality Analysis Scheduler methods
    func schedulePersonalityAnalysis(userId: UUID, at date: Date, frequency: AnalysisFrequency) async throws
    func sendPersonalityAnalysisCompleted(userId: UUID, profile: PersonalityProfile) async throws
    func cancelPersonalityAnalysis(userId: UUID) async
    func getNotificationSettings() async -> NotificationAuthorizationStatus

    // Location-based notification methods
    func sendLocationTriggeredNotification(for habitID: UUID, habitName: String, event: GeofenceEvent) async throws

    // Pending notification management (for daily rescheduling)
    func getPendingHabitNotificationIds() async -> [String]
    func clearHabitNotifications(ids: [String]) async

    // Badge management
    func updateBadgeCount() async
    func decrementBadge() async

    /// Clears personality analysis notifications from delivered list and updates badge count
    /// Call this when user views personality insights to clear those specific notifications
    func clearPersonalityNotifications() async

    // Fired notification tracking (prevents duplicates on app restart)
    func syncFiredNotificationsFromDelivered() async
}

public final class LocalNotificationService: NSObject, NotificationService, @unchecked Sendable {
    private static let habitReminderCategory = "HABIT_REMINDER"
    private static let binaryHabitReminderCategory = "BINARY_HABIT_REMINDER"
    private static let numericHabitReminderCategory = "NUMERIC_HABIT_REMINDER"
    private static let habitStreakMilestoneCategory = "HABIT_STREAK_MILESTONE"

    /// Generates a second offset (0-58) based on habitID to prevent notifications
    /// from different habits firing at the exact same moment when they share the same time.
    /// This avoids iOS coalescing multiple notifications into a single banner.
    private static func secondOffset(for habitID: UUID) -> Int {
        Int(habitID.uuidString.utf8.reduce(0) { $0 &+ Int($1) }) % 59
    }
    
    // Personality Analysis Categories
    private static let personalityAnalysisCategories = [
        "PERSONALITY_ANALYSIS_OPENNESS",
        "PERSONALITY_ANALYSIS_CONSCIENTIOUSNESS", 
        "PERSONALITY_ANALYSIS_EXTRAVERSION",
        "PERSONALITY_ANALYSIS_AGREEABLENESS",
        "PERSONALITY_ANALYSIS_NEUROTICISM",
        "PERSONALITY_ANALYSIS_INSUFFICIENT_DATA"
    ]
    
    // Delegate handler for notification actions
    public var actionHandler: ((NotificationAction, UUID, String?, HabitKind, ReminderTime?) async throws -> Void)?
    public var trackingService: UserActionTrackerService?
    public var personalityDeepLinkCoordinator: PersonalityDeepLinkCoordinator?
    private let errorHandler: ErrorHandler?
    private let habitCompletionCheckService: HabitCompletionCheckService
    private let userDefaultsService: UserDefaultsService
    private let timezoneService: TimezoneService
    private let logger: DebugLogger

    // Badge count cache to avoid frequent deliveredNotifications() API calls
    // Cache is simple (not thread-safe) - worst case is an extra API call, which is acceptable
    private var cachedDeliveredNotifications: [UNNotification]?
    private var cacheTimestamp: Date?
    private static let cacheValidityDuration: TimeInterval = 5.0

    /// Get delivered notifications with caching to reduce API calls
    /// Cache is invalidated after 5 seconds or when explicitly cleared
    private func getDeliveredNotificationsCached(bypassCache: Bool = false) async -> [UNNotification] {
        let center = UNUserNotificationCenter.current()

        // Check if cache is valid
        if !bypassCache,
           let cached = cachedDeliveredNotifications,
           let timestamp = cacheTimestamp,
           Date().timeIntervalSince(timestamp) < Self.cacheValidityDuration {
            return cached
        }

        // Fetch fresh data and update cache
        let delivered = await center.deliveredNotifications()
        cachedDeliveredNotifications = delivered
        cacheTimestamp = Date()
        return delivered
    }

    /// Invalidate the delivered notifications cache
    /// Call after removing notifications to ensure fresh data on next read
    private func invalidateDeliveredNotificationsCache() {
        cachedDeliveredNotifications = nil
        cacheTimestamp = nil
    }

    // Track catch-up notifications to prevent duplicate delivery on repeated foreground events
    // Persisted to UserDefaults to survive app termination/relaunch
    // Keys defined in UserDefaultsKeys for centralized management

    /// Check if a catch-up was already delivered today for a habit (using display timezone)
    private func wasCatchUpDeliveredToday(habitId: UUID) async -> Bool {
        // Get display timezone for consistent "today" check across app
        let timezone: TimeZone
        do {
            timezone = try await timezoneService.getDisplayTimezone()
        } catch {
            timezone = TimeZone.current
        }

        guard let storedDate = userDefaultsService.date(forKey: UserDefaultsKeys.catchUpDeliveryDate),
              CalendarUtils.isTodayLocal(storedDate, timezone: timezone) else {
            return false
        }
        guard let storedIds = userDefaultsService.stringArray(forKey: UserDefaultsKeys.catchUpDeliveredHabitIds) else {
            return false
        }
        let deliveredIds = Set(storedIds.compactMap { UUID(uuidString: $0) })
        return deliveredIds.contains(habitId)
    }

    /// Mark a catch-up as delivered today for a habit
    private func markCatchUpDelivered(habitId: UUID) {
        var currentIds = userDefaultsService.stringArray(forKey: UserDefaultsKeys.catchUpDeliveredHabitIds) ?? []

        // Reset if stored date is not today (using device timezone for simplicity in setter)
        if let storedDate = userDefaultsService.date(forKey: UserDefaultsKeys.catchUpDeliveryDate),
           !CalendarUtils.isTodayLocal(storedDate) {
            currentIds = []
        }

        currentIds.append(habitId.uuidString)
        userDefaultsService.set(currentIds as Any, forKey: UserDefaultsKeys.catchUpDeliveredHabitIds)
        userDefaultsService.set(Date(), forKey: UserDefaultsKeys.catchUpDeliveryDate)
    }

    // MARK: - Fired Notification Tracking
    // Tracks which notifications have already fired today to prevent duplicates on app restart

    /// Check if a notification has already fired today
    private func hasNotificationFiredToday(notificationId: String) async -> Bool {
        let timezone: TimeZone
        do {
            timezone = try await timezoneService.getDisplayTimezone()
        } catch {
            timezone = TimeZone.current
        }

        guard let storedDate = userDefaultsService.date(forKey: UserDefaultsKeys.firedNotificationDate),
              CalendarUtils.isTodayLocal(storedDate, timezone: timezone) else {
            return false
        }
        guard let storedIds = userDefaultsService.stringArray(forKey: UserDefaultsKeys.firedNotificationIds) else {
            return false
        }
        return storedIds.contains(notificationId)
    }

    /// Mark a notification as fired today
    private func markNotificationFired(notificationId: String) {
        var currentIds = userDefaultsService.stringArray(forKey: UserDefaultsKeys.firedNotificationIds) ?? []

        // Reset if stored date is not today
        if let storedDate = userDefaultsService.date(forKey: UserDefaultsKeys.firedNotificationDate),
           !CalendarUtils.isTodayLocal(storedDate) {
            currentIds = []
        }

        // Avoid duplicates
        if !currentIds.contains(notificationId) {
            currentIds.append(notificationId)
        }
        userDefaultsService.set(currentIds as Any, forKey: UserDefaultsKeys.firedNotificationIds)
        userDefaultsService.set(Date(), forKey: UserDefaultsKeys.firedNotificationDate)
    }

    /// Sync fired notification state from delivered notifications
    /// Call this on app launch to catch notifications that fired in background
    public func syncFiredNotificationsFromDelivered() async {
        // Bypass cache on app launch to ensure fresh data, but populate cache for subsequent calls
        let delivered = await getDeliveredNotificationsCached(bypassCache: true)

        for notification in delivered {
            let id = notification.request.identifier
            // Only track habit-related notifications
            if id.hasPrefix("today_") || id.hasPrefix("rich_") || id.hasPrefix("tailored_") {
                markNotificationFired(notificationId: id)
            }
        }

        let count = delivered.filter {
            $0.request.identifier.hasPrefix("today_") ||
            $0.request.identifier.hasPrefix("rich_") ||
            $0.request.identifier.hasPrefix("tailored_")
        }.count

        if count > 0 {
            logger.log(
                "🔄 Synced fired notifications from delivered",
                level: .debug,
                category: .notifications,
                metadata: ["count": count]
            )
        }
    }

    public init(
        habitCompletionCheckService: HabitCompletionCheckService,
        userDefaultsService: UserDefaultsService,
        timezoneService: TimezoneService,
        errorHandler: ErrorHandler? = nil,
        logger: DebugLogger
    ) {
        self.habitCompletionCheckService = habitCompletionCheckService
        self.userDefaultsService = userDefaultsService
        self.timezoneService = timezoneService
        self.errorHandler = errorHandler
        self.logger = logger
        super.init()

        // Set up the notification center delegate to handle foreground notifications
        logger.logNotification(event: "Setting up notification delegate")
        UNUserNotificationCenter.current().delegate = self
        logger.log(
            "🔧 Notification delegate configured",
            level: .debug,
            category: .notifications,
            metadata: ["delegate": String(describing: UNUserNotificationCenter.current().delegate)]
        )
        
        // Setup notification categories with actions
        Task {
            await setupNotificationCategories()
        }
    }
    
    public func requestAuthorizationIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            trackingService?.track(.notificationPermissionRequested)
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                trackingService?.track(.notificationPermissionGranted)
            } else {
                trackingService?.track(.notificationPermissionDenied)
            }
            return granted
        }
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
    
    public func checkAuthorizationStatus() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional
    }
    public func schedule(for habitID: UUID, times: [ReminderTime]) async throws {
        let center = UNUserNotificationCenter.current()
        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Ritualist"
            content.body = "Time for your habit!"
            var date = DateComponents()
            date.hour = time.hour; date.minute = time.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let id = "\(habitID.uuidString)-\(index)"
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try await center.add(req)
        }
    }
    
    public func scheduleWithActions(for habitID: UUID, habitName: String, habitKind: HabitKind, times: [ReminderTime]) async throws {
        // Schedule without badge (used when not doing bulk scheduling with badge ordering)
        for time in times {
            try await scheduleSingleNotification(for: habitID, habitName: habitName, habitKind: habitKind, time: time)
        }

        // Track notification scheduling
        trackingService?.track(.notificationScheduled(
            habitId: habitID.uuidString,
            habitName: habitName,
            reminderCount: times.count
        ))
    }

    public func scheduleSingleNotification(for habitID: UUID, habitName: String, habitKind: HabitKind, time: ReminderTime) async throws {
        let center = UNUserNotificationCenter.current()
        // Notifications should use local timezone - users want reminders at "7 AM local time"
        let calendar = CalendarUtils.currentLocalCalendar
        let today = Date()

        // Check if this notification already fired today (prevents duplicates on app restart)
        let notificationId = "today_\(habitID.uuidString)-\(time.hour)-\(time.minute)"
        if await hasNotificationFiredToday(notificationId: notificationId) {
            logger.log(
                "⏭️ Skipping notification - already fired today",
                level: .debug,
                category: .notifications,
                metadata: ["habit": habitName, "time": "\(time.hour):\(String(format: "%02d", time.minute))"]
            )
            return
        }

        let secondOffset = Self.secondOffset(for: habitID)

        let content = UNMutableNotificationContent()

        // Customize title and body based on habit type
        switch habitKind {
        case .binary:
            content.title = "Time to complete: \(habitName) ✓"
            content.body = "Quick tap to mark as done!"
        case .numeric:
            content.title = "Log progress: \(habitName)"
            content.body = "Time to track your progress!"
        }

        content.sound = .default
        // Hybrid badge approach: set expected badge for background notifications
        // willPresent recalculates for foreground; updateBadgeCount corrects on app activation
        let expectedBadge = await calculateExpectedBadgeCount()
        content.badge = NSNumber(value: expectedBadge)

        // Use different category based on habit type
        content.categoryIdentifier = habitKind == .binary ?
            Self.binaryHabitReminderCategory : Self.numericHabitReminderCategory

        // Store habit information in userInfo for action handling
        content.userInfo = [
            "habitId": habitID.uuidString,
            "habitName": habitName,
            "habitKind": habitKind == .binary ? "binary" : "numeric",
            "reminderHour": time.hour,
            "reminderMinute": time.minute
        ]

        // Create notification time for today only (non-repeating)
        // Add second offset to prevent multiple habits at same time from coalescing
        var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
        dateComponents.hour = time.hour
        dateComponents.minute = time.minute
        dateComponents.second = secondOffset

        // Only schedule if the time hasn't passed today
        if let notificationDate = calendar.date(from: dateComponents),
           notificationDate > Date() {
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let id = "today_\(habitID.uuidString)-\(time.hour)-\(time.minute)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

            try await center.add(request)
            logger.log(
                "📅 Scheduled notification for today",
                level: .info,
                category: .notifications,
                metadata: [
                    "habit": habitName,
                    "time": "\(time.hour):\(String(format: "%02d", time.minute))",
                    "id": id
                ]
            )
        } else if let notificationDate = calendar.date(from: dateComponents) {
            // Time has passed - check how long ago
            let timeSinceScheduled = Date().timeIntervalSince(notificationDate)
            let minimumCatchUpDelay: TimeInterval = 2 * 60 * 60 // 2 hours

            // Skip catch-up if original notification was recent (user probably already saw it)
            guard timeSinceScheduled >= minimumCatchUpDelay else {
                logger.log(
                    "⏭️ Skipping catch-up - original notification was recent",
                    level: .debug,
                    category: .notifications,
                    metadata: [
                        "habit": habitName,
                        "minutesSinceScheduled": Int(timeSinceScheduled / 60)
                    ]
                )
                return
            }

            // Check if habit is incomplete
            let shouldNotify = await habitCompletionCheckService.shouldShowNotification(
                habitId: habitID,
                date: today
            )

            if shouldNotify {
                // Skip if we already delivered a catch-up for this habit today
                // Uses display timezone for consistent "today" check across app
                guard await !wasCatchUpDeliveredToday(habitId: habitID) else {
                    logger.log(
                        "⏭️ Skipping catch-up - already delivered today",
                        level: .debug,
                        category: .notifications,
                        metadata: ["habit": habitName, "habitId": habitID.uuidString]
                    )
                    return
                }

                // Send catch-up notification with short delay
                // Use unique ID per habit to avoid duplicate catch-ups
                let catchUpContent = UNMutableNotificationContent()
                catchUpContent.title = "Don't forget: \(habitName)"
                catchUpContent.body = habitKind == .binary
                    ? "You haven't completed this habit yet today. Tap to mark as done!"
                    : "You haven't logged progress yet today. Tap to update!"
                catchUpContent.sound = .default
                // Don't set badge for catch-up notifications - they fire when app is in foreground
                // and won't persist in notification center, so badge would be orphaned
                catchUpContent.categoryIdentifier = habitKind == .binary
                    ? Self.binaryHabitReminderCategory
                    : Self.numericHabitReminderCategory
                catchUpContent.userInfo = [
                    "habitId": habitID.uuidString,
                    "habitName": habitName,
                    "habitKind": habitKind == .binary ? "binary" : "numeric",
                    "reminderHour": time.hour,
                    "reminderMinute": time.minute,
                    "isCatchUp": true
                ]

                // 30 second base delay + 1 minute stagger per habit to give user time to read and interact
                // Each habit gets a different minute slot (0-9) based on its ID hash
                let minuteIndex = Self.secondOffset(for: habitID) % 10
                let staggerOffset = Double(minuteIndex * 60)
                let catchUpTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 30 + staggerOffset, repeats: false)
                let catchUpId = "catchup_\(habitID.uuidString)"

                // Remove any existing catch-up for this habit to avoid duplicates
                center.removePendingNotificationRequests(withIdentifiers: [catchUpId])

                let catchUpRequest = UNNotificationRequest(
                    identifier: catchUpId,
                    content: catchUpContent,
                    trigger: catchUpTrigger
                )

                try await center.add(catchUpRequest)

                // Track that we've delivered this catch-up today (persisted to UserDefaults)
                markCatchUpDelivered(habitId: habitID)

                let totalDelay = 30 + (minuteIndex * 60)
                logger.log(
                    "🔔 Scheduled catch-up notification",
                    level: .info,
                    category: .notifications,
                    metadata: [
                        "habit": habitName,
                        "originalTime": "\(time.hour):\(String(format: "%02d", time.minute))",
                        "delay": "\(totalDelay)s",
                        "id": catchUpId
                    ]
                )
            } else {
                logger.log(
                    "⏰ Skipping notification - time passed and habit already completed",
                    level: .debug,
                    category: .notifications,
                    metadata: [
                        "habit": habitName,
                        "time": "\(time.hour):\(String(format: "%02d", time.minute))"
                    ]
                )
            }
        }
    }
    
    public func scheduleRichReminders(
        for habitID: UUID,
        habitName: String,
        habitCategory: String?,
        currentStreak: Int,
        times: [ReminderTime]
    ) async throws {
        let center = UNUserNotificationCenter.current()

        // Check if it's weekend for contextual messaging (local timezone)
        let calendar = CalendarUtils.currentLocalCalendar
        let today = Date()
        let isWeekend = calendar.isDateInWeekend(today)

        let secondOffset = Self.secondOffset(for: habitID)

        // Calculate expected badge once for all notifications in this batch
        let expectedBadge = await calculateExpectedBadgeCount()

        for time in times {
            // Generate rich notification content
            let content = HabitReminderNotificationContentGenerator.generateContent(
                for: habitID,
                habitName: habitName,
                reminderTime: time,
                habitCategory: habitCategory,
                currentStreak: currentStreak,
                isWeekend: isWeekend
            )

            // Set badge for background notifications (willPresent recalculates for foreground)
            content.badge = NSNumber(value: expectedBadge)

            // Create notification time for today only (non-repeating)
            // This ensures notifications are cancelled when habit is completed
            // Add second offset to prevent multiple habits at same time from coalescing
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            dateComponents.second = secondOffset

            // Only schedule if the time hasn't passed today
            if let notificationDate = calendar.date(from: dateComponents),
               notificationDate > Date() {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let id = "rich_\(habitID.uuidString)-\(time.hour)-\(time.minute)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try await center.add(request)

                logger.log(
                    "📅 Scheduled rich notification for today",
                    level: .debug,
                    category: .notifications,
                    metadata: [
                        "habit": habitName,
                        "time": "\(time.hour):\(String(format: "%02d", time.minute))",
                        "id": id
                    ]
                )
            }
        }

        // Track rich notification scheduling
        trackingService?.track(.notificationScheduled(
            habitId: habitID.uuidString,
            habitName: habitName,
            reminderCount: times.count
        ))
    }
    
    public func schedulePersonalityTailoredReminders(
        for habitID: UUID,
        habitName: String,
        habitCategory: String?,
        currentStreak: Int,
        personalityProfile: PersonalityProfile,
        times: [ReminderTime]
    ) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Check if personality analysis is recent (within 30 days)
        guard PersonalityTailoredNotificationContentGenerator.hasRecentAnalysis(personalityProfile) else {
            // Fall back to rich reminders if personality analysis is outdated
            return try await scheduleRichReminders(
                for: habitID,
                habitName: habitName,
                habitCategory: habitCategory,
                currentStreak: currentStreak,
                times: times
            )
        }
        
        // Check if it's weekend for contextual messaging (local timezone)
        let calendar = CalendarUtils.currentLocalCalendar
        let today = Date()
        let isWeekend = calendar.isDateInWeekend(today)

        let secondOffset = Self.secondOffset(for: habitID)

        // Calculate expected badge once for all notifications in this batch
        let expectedBadge = await calculateExpectedBadgeCount()

        for time in times {
            // Generate personality-tailored notification content
            let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
                for: habitID,
                habitName: habitName,
                reminderTime: time,
                personalityProfile: personalityProfile,
                habitCategory: habitCategory,
                currentStreak: currentStreak,
                isWeekend: isWeekend
            )

            // Set badge for background notifications (willPresent recalculates for foreground)
            content.badge = NSNumber(value: expectedBadge)

            // Create notification time for today only (non-repeating)
            // This ensures notifications are cancelled when habit is completed
            // Add second offset to prevent multiple habits at same time from coalescing
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            dateComponents.second = secondOffset

            // Only schedule if the time hasn't passed today
            if let notificationDate = calendar.date(from: dateComponents),
               notificationDate > Date() {
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let id = "tailored_\(habitID.uuidString)-\(time.hour)-\(time.minute)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                try await center.add(request)

                logger.log(
                    "📅 Scheduled tailored notification for today",
                    level: .debug,
                    category: .notifications,
                    metadata: [
                        "habit": habitName,
                        "time": "\(time.hour):\(String(format: "%02d", time.minute))",
                        "id": id
                    ]
                )
            }
        }

        // Track personality-tailored notification scheduling
        trackingService?.track(.notificationScheduled(
            habitId: habitID.uuidString,
            habitName: habitName,
            reminderCount: times.count
        ))
    }
    
    public func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Generate streak milestone content
        let content = HabitReminderNotificationContentGenerator.generateStreakMilestoneContent(
            for: habitID,
            habitName: habitName,
            streakDays: streakDays
        )
        
        // Immediate delivery for celebrations
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let identifier = "streak_milestone_\(habitID.uuidString)_\(streakDays)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try await center.add(request)
    }
    public func cancel(for habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let prefix = habitID.uuidString
        let pending = await center.pendingNotificationRequests()

        logger.logNotification(
            event: "Starting cancellation",
            habitId: habitID.uuidString,
            metadata: ["pending_count": pending.count]
        )
        
        // Log all pending notifications for this habit to debug
        let habitNotifications = pending.filter { notification in
            let id = notification.identifier
            let matches = id.hasPrefix(prefix) ||
                         id.hasPrefix("rich_\(prefix)") ||
                         id.hasPrefix("tailored_\(prefix)") ||
                         id.hasPrefix("today_\(prefix)") ||
                         id.hasPrefix("streak_milestone_\(prefix)")
            return matches
        }

        // Cancel all notifications that match the habit ID (including rich_, tailored_, today_, and streak_ prefixed ones)
        let ids = pending.map { $0.identifier }.filter { id in
            id.hasPrefix(prefix) ||
            id.hasPrefix("rich_\(prefix)") ||
            id.hasPrefix("tailored_\(prefix)") ||
            id.hasPrefix("today_\(prefix)") ||
            id.hasPrefix("streak_milestone_\(prefix)")
        }

        logger.log(
            "🗑️ Cancelling notifications",
            level: .info,
            category: .notifications,
            metadata: [
                "habitId": habitID.uuidString,
                "count": ids.count,
                "ids": ids.joined(separator: ", ")
            ]
        )
        
        // Extract habit name from pending notifications for tracking
        let habitName = pending.first(where: { notification in
            let id = notification.identifier
            return id.hasPrefix(prefix) || 
                   id.hasPrefix("rich_\(prefix)") || 
                   id.hasPrefix("tailored_\(prefix)") || 
                   id.hasPrefix("today_\(prefix)")
        })?.content.userInfo["habitName"] as? String ?? "Unknown Habit"
        
        center.removePendingNotificationRequests(withIdentifiers: ids)

        // Verify cancellation by checking pending notifications again
        let pendingAfter = await center.pendingNotificationRequests()
        let remainingHabitNotifications = pendingAfter.filter { notification in
            let id = notification.identifier
            return id.hasPrefix(prefix) ||
                   id.hasPrefix("rich_\(prefix)") ||
                   id.hasPrefix("tailored_\(prefix)") ||
                   id.hasPrefix("today_\(prefix)") ||
                   id.hasPrefix("streak_milestone_\(prefix)")
        }

        if !remainingHabitNotifications.isEmpty {
            logger.log(
                "⚠️ Cancellation incomplete - some notifications still pending",
                level: .warning,
                category: .notifications,
                metadata: [
                    "habitId": habitID.uuidString,
                    "remaining": remainingHabitNotifications.count,
                    "stillPending": remainingHabitNotifications.map { $0.identifier }.joined(separator: ", ")
                ]
            )
        } else {
            logger.log(
                "✅ Cancellation complete",
                level: .info,
                category: .notifications,
                metadata: ["habitId": habitID.uuidString, "cancelled": ids.count]
            )
        }
        
        // Track notification cancellation
        if !ids.isEmpty {
            trackingService?.track(.notificationCancelled(
                habitId: habitID.uuidString,
                habitName: habitName,
                reason: "habit_completed"
            ))
        }
    }
    
    public func sendImmediate(title: String, body: String, habitId: UUID? = nil) async throws {
        let center = UNUserNotificationCenter.current()

        // Request permission if needed
        let authorized = try await requestAuthorizationIfNeeded()
        guard authorized else {
            logger.log(
                "❌ Notification not authorized",
                level: .warning,
                category: .notifications
            )
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Include habitId in userInfo so completion status can be checked when notification fires
        if let habitId = habitId {
            content.userInfo = ["habitId": habitId.uuidString]
        }

        // Trigger with 20 minutes delay for "remind me later" functionality
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20.0 * 60.0, repeats: false)
        let id = habitId != nil ? "snooze-\(habitId!.uuidString)" : "snooze-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try await center.add(request)
        logger.log(
            "⏰ Snooze notification scheduled",
            level: .info,
            category: .notifications,
            metadata: ["title": title, "body": body, "delay": "20min", "habitId": habitId?.uuidString ?? "none"]
        )
    }
    
    // MARK: - Personality Analysis Methods
    
    public func schedulePersonalityAnalysis(userId: UUID, at date: Date, frequency: AnalysisFrequency) async throws {
        let center = UNUserNotificationCenter.current()
        let identifier = "personality_analysis_\(userId.uuidString)"
        
        // Remove existing notification
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        
        // Create content
        let content = UNMutableNotificationContent()
        content.title = "🔍 Checking Your Habits..."
        content.body = "We're analyzing your recent habit patterns for personality insights."
        content.sound = .default
        
        // Add deep link for scheduled analysis
        content.userInfo = [
            "type": "personality_analysis",
            "action": "check_analysis", 
            "scheduled": true
        ]
        
        // Use local timezone for notification scheduling - users expect notifications at local time
        let components = CalendarUtils.currentLocalCalendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        try await center.add(request)
    }
    
    public func sendPersonalityAnalysisCompleted(userId: UUID, profile: PersonalityProfile) async throws {
        let center = UNUserNotificationCenter.current()
        let identifier = "personality_completed_\(userId.uuidString)"
        
        // Generate rich notification content based on the analysis results
        let content = PersonalityNotificationContentGenerator.generateContent(for: profile)
        
        // Minimal delay to ensure proper notification center persistence (iOS requirement)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try await center.add(request)
        logger.log(
            "🔔 Personality analysis completion notification sent",
            level: .info,
            category: .notifications,
            metadata: ["userId": userId.uuidString]
        )
    }
    
    public func cancelPersonalityAnalysis(userId: UUID) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "personality_analysis_\(userId.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    public func getNotificationSettings() async -> NotificationAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .notDetermined:
            return .notDetermined
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .provisional:
            return .provisional
        case .ephemeral:
            return .ephemeral
        @unknown default:
            return .denied
        }
    }

    // MARK: - Pending Notification Management

    /// Returns IDs of all pending habit-related notifications
    /// Identifies habit notifications by UUID prefix or known prefixes (today_, rich_, tailored_, catchup_)
    public func getPendingHabitNotificationIds() async -> [String] {
        let center = UNUserNotificationCenter.current()
        let pendingRequests = await center.pendingNotificationRequests()

        return pendingRequests.compactMap { request in
            let id = request.identifier
            // Identify habit notifications by:
            // 1. Known prefixes for different notification types
            // 2. UUID format at the start (habitID-based notifications)
            if id.hasPrefix("today_") ||
               id.hasPrefix("rich_") ||
               id.hasPrefix("tailored_") ||
               id.hasPrefix("catchup_") ||
               (id.contains("-") && UUID(uuidString: String(id.prefix(36))) != nil) {
                return id
            }
            return nil
        }
    }

    /// Clears pending notifications with the specified IDs
    public func clearHabitNotifications(ids: [String]) async {
        guard !ids.isEmpty else { return }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ids)

        logger.logNotification(
            event: "Cleared habit notifications",
            metadata: ["count": ids.count]
        )
    }

    // MARK: - Badge Management

    /// Calculates the expected badge count for a new notification being scheduled.
    /// Uses current delivered count + pending habit notifications scheduled before this time.
    /// This provides a reasonable estimate for background notifications where willPresent isn't called.
    private func calculateExpectedBadgeCount() async -> Int {
        let delivered = await getDeliveredNotificationsCached()
        let currentBadge = delivered.filter(isHabitNotificationForBadge).count
        return currentBadge + 1
    }

    /// Determines if a notification should be counted toward the app badge.
    /// Habit notifications ARE counted; catch-up and personality notifications are NOT.
    private func isHabitNotificationForBadge(_ notification: UNNotification) -> Bool {
        let id = notification.request.identifier
        let userInfo = notification.request.content.userInfo
        let isCatchUp = userInfo["isCatchUp"] as? Bool ?? id.hasPrefix("catchup_")

        // Catch-up notifications fire in foreground and may not be interacted with
        guard !isCatchUp else { return false }

        return id.hasPrefix("today_") ||
               id.hasPrefix("rich_") ||
               id.hasPrefix("tailored_") ||
               userInfo["habitId"] != nil
    }

    /// Updates the app badge to show the count of delivered (unread) habit notifications
    public func updateBadgeCount() async {
        let delivered = await getDeliveredNotificationsCached()
        let habitNotificationCount = delivered.filter(isHabitNotificationForBadge).count

        try? await UNUserNotificationCenter.current().setBadgeCount(habitNotificationCount)

        logger.log(
            "🔢 Badge updated",
            level: .debug,
            category: .notifications,
            metadata: ["count": habitNotificationCount]
        )
    }

    /// Decrements the badge count by 1 (minimum 0)
    public func decrementBadge() async {
        let delivered = await getDeliveredNotificationsCached()
        let habitNotificationCount = delivered.filter(isHabitNotificationForBadge).count

        // Badge should reflect delivered notifications minus 1 (the one being handled)
        let newCount = max(0, habitNotificationCount - 1)

        try? await UNUserNotificationCenter.current().setBadgeCount(newCount)

        // Invalidate cache since we're decrementing (notification was handled)
        invalidateDeliveredNotificationsCache()

        logger.log(
            "🔢 Badge decremented",
            level: .debug,
            category: .notifications,
            metadata: ["newCount": newCount]
        )
    }

    /// Clears personality-related notifications from delivered list and updates badge
    /// This ensures only personality badges are cleared, not habit reminder badges
    public func clearPersonalityNotifications() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await getDeliveredNotificationsCached()

        // Find personality analysis notification IDs
        // Personality notifications use identifiers like "personality_completed_<userId>"
        // and categories from personalityAnalysisCategories
        let personalityNotificationIds = delivered.compactMap { notification -> String? in
            let id = notification.request.identifier
            let category = notification.request.content.categoryIdentifier

            // Check if it's a personality notification by ID prefix or category
            if id.hasPrefix("personality_") || Self.personalityAnalysisCategories.contains(category) {
                return id
            }
            return nil
        }

        // Remove only personality notifications from delivered list
        if !personalityNotificationIds.isEmpty {
            center.removeDeliveredNotifications(withIdentifiers: personalityNotificationIds)

            // Invalidate cache since delivered notifications changed
            invalidateDeliveredNotificationsCache()

            logger.log(
                "🧠 Cleared personality notifications",
                level: .debug,
                category: .notifications,
                metadata: ["count": personalityNotificationIds.count, "ids": personalityNotificationIds.joined(separator: ", ")]
            )
        }

        // Update badge count based on remaining habit notifications
        // This recalculates from scratch rather than clearing everything
        await updateBadgeCount()
    }

    // MARK: - Private Helpers
    
    /// Executes an async operation with a timeout to prevent blocking the delegate
    private func withTimeout<T: Sendable>(seconds: TimeInterval, operation: @escaping @Sendable () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add the actual operation
            group.addTask {
                await operation()
            }
            
            // Add the timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }
            
            // Return the first result (either completion or timeout)
            guard let result = try await group.next() else {
                throw TimeoutError()
            }
            
            // Cancel remaining tasks
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Timeout Error
private struct TimeoutError: Error {
    let message = "Operation timed out"
}

// MARK: - UNUserNotificationCenterDelegate
extension LocalNotificationService: UNUserNotificationCenterDelegate {
    // This method is called when a notification is received while the app is in the foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        #if canImport(UIKit)
        let appState = UIApplication.shared.applicationState.rawValue
        #else
        let appState = -1
        #endif

        logger.log(
            "🔥 Notification will present",
            level: .debug,
            category: .notifications,
            metadata: [
                "id": notification.request.identifier,
                "title": notification.request.content.title,
                "body": notification.request.content.body,
                "appState": appState
            ]
        )
        
        // Extract habitId from notification userInfo for completion checking
        let userInfo = notification.request.content.userInfo
        logger.logNotification(event: "Checking notification userInfo", metadata: ["userInfo": userInfo])

        // Check if this is a catch-up notification - don't show badge for these
        // as they fire in foreground and user may not interact with them
        // Note: isCatchUp is stored as Int (1) in userInfo, not Bool
        let isCatchUp = (userInfo["isCatchUp"] as? Int == 1) || (userInfo["isCatchUp"] as? Bool == true)

        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString) else {
            logger.log(
                "⚠️ No habitId in notification - showing by default",
                level: .warning,
                category: .notifications
            )
            completionHandler([.banner, .sound])
            return
        }

        logger.logNotification(
            event: "Checking completion status",
            type: "habit_reminder",
            habitId: habitId.uuidString
        )

        // Obj-C completion handlers are thread-safe but not marked Sendable
        nonisolated(unsafe) let handler = completionHandler
        let checkService = self.habitCompletionCheckService
        let loggerRef = self.logger
        let habitIdStr = habitId.uuidString
        let notificationId = notification.request.identifier

        Task { @MainActor [weak self] in
            let shouldShow = await checkService.shouldShowNotification(habitId: habitId, date: Date())

            if shouldShow {
                // Mark notification as fired to prevent duplicates on app restart
                self?.markNotificationFired(notificationId: notificationId)

                // Calculate badge dynamically based on current delivered notifications + 1
                // This is more reliable than pre-setting badge at schedule time
                let center = UNUserNotificationCenter.current()
                let delivered = await center.deliveredNotifications()

                // Count only habit-related notifications (not personality analysis, catch-up, etc.)
                let habitNotificationCount = delivered.filter { notification in
                    let id = notification.request.identifier
                    let info = notification.request.content.userInfo
                    let notificationIsCatchUp = (info["isCatchUp"] as? Int == 1) || (info["isCatchUp"] as? Bool == true)
                    guard !notificationIsCatchUp else { return false }
                    return id.hasPrefix("today_") || id.hasPrefix("rich_") || id.hasPrefix("tailored_") || info["habitId"] != nil
                }.count

                // For catch-up notifications, don't update badge (they fire in foreground and may not be interacted with)
                // For regular notifications, set badge to delivered count + 1 (this notification)
                if !isCatchUp {
                    let newBadge = habitNotificationCount + 1
                    try? await center.setBadgeCount(newBadge)
                    loggerRef.log(
                        "✅ Showing notification - habit not completed",
                        level: .info,
                        category: .notifications,
                        metadata: ["habitId": habitIdStr, "badge": newBadge, "notificationId": notificationId]
                    )
                } else {
                    loggerRef.log(
                        "✅ Showing catch-up notification (no badge update)",
                        level: .info,
                        category: .notifications,
                        metadata: ["habitId": habitIdStr]
                    )
                }

                // Return [.banner, .sound] without .badge since we set badge manually
                // This prevents iOS from overriding our badge with the pre-set value
                handler([.banner, .sound])
            } else {
                loggerRef.log(
                    "🚫 Suppressing notification - habit already completed",
                    level: .info,
                    category: .notifications,
                    metadata: ["habitId": habitIdStr]
                )
                handler([])
            }
        }
    }

    // This method is called when the user taps on a notification
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        #if canImport(UIKit)
        let appState = UIApplication.shared.applicationState.rawValue
        #else
        let appState = -1
        #endif

        logger.log(
            "🔥 Notification response received",
            level: .debug,
            category: .notifications,
            metadata: [
                "action": response.actionIdentifier,
                "id": response.notification.request.identifier,
                "title": response.notification.request.content.title,
                "appState": appState
            ]
        )

        // Obj-C completion handlers are thread-safe but not marked Sendable
        nonisolated(unsafe) let handler = completionHandler
        Task { @MainActor in
            await self.handleNotificationResponse(response)
            handler()
        }
    }
    
    // MARK: - Notification Categories Setup
    
    public func setupNotificationCategories() async {
        // Actions for binary habits (background completion)
        let binaryLogAction = UNNotificationAction(
            identifier: NotificationAction.log.rawValue,
            title: NotificationAction.log.title(for: .binary),
            options: NotificationAction.log.options(for: .binary)
        )
        
        // Actions for numeric habits (foreground for UI)
        let numericLogAction = UNNotificationAction(
            identifier: NotificationAction.log.rawValue,
            title: NotificationAction.log.title(for: .numeric),
            options: NotificationAction.log.options(for: .numeric)
        )
        
        // Shared actions (both background)
        let remindLaterAction = UNNotificationAction(
            identifier: NotificationAction.remindLater.rawValue,
            title: NotificationAction.remindLater.title,
            options: []
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss.rawValue,
            title: NotificationAction.dismiss.title,
            options: []
        )
        
        // Binary habit category (background completion)
        let binaryHabitCategory = UNNotificationCategory(
            identifier: Self.binaryHabitReminderCategory,
            actions: [binaryLogAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Numeric habit category (foreground for UI)
        let numericHabitCategory = UNNotificationCategory(
            identifier: Self.numericHabitReminderCategory,
            actions: [numericLogAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )
        
        // Legacy category (for backwards compatibility)
        let legacyLogAction = UNNotificationAction(
            identifier: NotificationAction.log.rawValue,
            title: NotificationAction.log.title,
            options: [.foreground]
        )
        
        let habitReminderCategory = UNNotificationCategory(
            identifier: Self.habitReminderCategory,
            actions: [legacyLogAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction] // Enable persistence tracking
        )
        
        // Streak milestone category (no actions - just celebratory)
        let habitStreakMilestoneCategory = UNNotificationCategory(
            identifier: Self.habitStreakMilestoneCategory,
            actions: [],
            intentIdentifiers: [],
            options: [.customDismissAction] // Enable persistence tracking
        )
        
        // Create personality analysis categories with basic options for persistence
        var allCategories: Set<UNNotificationCategory> = [
            binaryHabitCategory, 
            numericHabitCategory, 
            habitReminderCategory, 
            habitStreakMilestoneCategory
        ]
        
        for categoryId in Self.personalityAnalysisCategories {
            let personalityCategory = UNNotificationCategory(
                identifier: categoryId,
                actions: [], // No actions for personality notifications - just informational
                intentIdentifiers: [],
                options: [.customDismissAction] // Allow custom dismiss tracking
            )
            allCategories.insert(personalityCategory)
        }
        
        let center = UNUserNotificationCenter.current()
        await center.setNotificationCategories(allCategories)
    }
    
    // MARK: - Notification Response Handling

    private func handleNotificationResponse(_ response: sending UNNotificationResponse) async {
        // Remove this notification from delivered list
        let center = UNUserNotificationCenter.current()
        let notificationId = response.notification.request.identifier
        center.removeDeliveredNotifications(withIdentifiers: [notificationId])

        // Small delay to allow the system to process the removal before querying delivered notifications
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        await updateBadgeCount()

        logger.log(
            "🔔 Notification removed and badge updated",
            level: .debug,
            category: .notifications,
            metadata: ["notificationId": notificationId, "action": response.actionIdentifier]
        )

        let userInfo = response.notification.request.content.userInfo

        // Check if this is a personality analysis notification
        if let type = userInfo["type"] as? String, type == "personality_analysis" {
            logger.logNotification(event: "Detected personality analysis notification", type: "personality_analysis")

            await handlePersonalityNotificationResponse(response)
            return
        }

        // Otherwise, handle as habit notification
        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString),
              let habitName = userInfo["habitName"] as? String,
              let reminderHour = userInfo["reminderHour"] as? Int,
              let reminderMinute = userInfo["reminderMinute"] as? Int else {
            logger.log(
                "⚠️ Invalid notification userInfo (not habit or personality)",
                level: .warning,
                category: .notifications,
                metadata: ["userInfo": String(describing: userInfo)]
            )
            return
        }
        
        // Extract habit kind (fallback to binary for backwards compatibility)
        let habitKindString = userInfo["habitKind"] as? String ?? "binary"
        let habitKind: HabitKind = habitKindString == "numeric" ? .numeric : .binary
        
        let reminderTime = ReminderTime(hour: reminderHour, minute: reminderMinute)

        // Handle swipe-to-dismiss - no further processing needed
        if response.actionIdentifier == UNNotificationDismissActionIdentifier {
            logger.log(
                "👋 Notification dismissed via swipe",
                level: .debug,
                category: .notifications,
                metadata: ["habit": habitName]
            )
            return
        }

        // Handle tap on notification (default action) - open app and show habit sheet
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            logger.log(
                "👆 Notification tapped - opening app",
                level: .info,
                category: .notifications,
                metadata: ["habit": habitName, "habitKind": habitKind == .binary ? "binary" : "numeric"]
            )

            // Use .openApp action to open the habit sheet (distinct from .log quick action)
            do {
                try await actionHandler?(.openApp, habitId, habitName, habitKind, reminderTime)
            } catch {
                await errorHandler?.logError(
                    error,
                    context: ErrorContext.userInterface + "_notification_tap",
                    additionalProperties: [
                        "operation": "handleNotificationTap",
                        "habit_id": habitId.uuidString,
                        "habit_name": habitName
                    ]
                )
            }
            return
        }

        guard let action = NotificationAction(rawValue: response.actionIdentifier) else {
            logger.log(
                "⚠️ Unknown notification action",
                level: .warning,
                category: .notifications,
                metadata: ["action": response.actionIdentifier]
            )
            return
        }

        logger.log(
            "🎯 Handling notification action",
            level: .info,
            category: .notifications,
            metadata: ["action": action.rawValue, "habit": habitName]
        )
        
        // For log actions, check if habit is already completed to provide better UX
        if action == .log {
            let today = Date()
            let shouldShow = await habitCompletionCheckService.shouldShowNotification(habitId: habitId, date: today)

            if !shouldShow {
                logger.log(
                    "🚫 Habit already completed - skipping action",
                    level: .info,
                    category: .notifications,
                    metadata: ["habit": habitName, "habitId": habitId.uuidString]
                )

                // Track as already completed interaction
                trackingService?.track(.notificationActionTapped(
                    action: "already_completed",
                    habitId: habitId.uuidString,
                    habitName: habitName,
                    source: "notification_action_skipped"
                ))
                return
            }
        }
        
        // Track notification action
        trackingService?.track(.notificationActionTapped(
            action: action.rawValue,
            habitId: habitId.uuidString,
            habitName: habitName,
            source: "notification_action"
        ))
        
        // Call the injected action handler (we're already on main thread)
        do {
            try await actionHandler?(action, habitId, habitName, habitKind, reminderTime)
        } catch {
            await errorHandler?.logError(
                error,
                context: ErrorContext.userInterface + "_notification_action",
                additionalProperties: [
                    "operation": "handleNotificationAction",
                    "action": action.rawValue,
                    "habit_id": habitId.uuidString,
                    "habit_name": habitName
                ]
            )
        }
    }

    // MARK: - Location-Based Notifications

    /// Send a notification triggered by a geofence event
    public func sendLocationTriggeredNotification(
        for habitID: UUID,
        habitName: String,
        event: GeofenceEvent
    ) async throws {
        // Check if habit is already completed - skip notification if so
        let shouldNotify = await habitCompletionCheckService.shouldShowNotification(
            habitId: habitID,
            date: Date()
        )

        guard shouldNotify else {
            logger.log(
                "⏭️ Skipping location notification - habit already completed",
                level: .info,
                category: .notifications,
                metadata: [
                    "habit": habitName,
                    "habitId": habitID.uuidString,
                    "eventType": event.eventType.rawValue
                ]
            )
            return
        }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()

        // Customize title and body based on event type
        let locationLabel = event.configuration?.locationLabel ?? "this location"
        switch event.eventType {
        case .entry:
            content.title = "📍 You're near \(locationLabel)"
            content.body = "Time for your \(habitName) habit!"
        case .exit:
            content.title = "👋 Leaving \(locationLabel)"
            content.body = "Don't forget: \(habitName)"
        }

        content.sound = .default
        content.categoryIdentifier = Self.habitReminderCategory

        // Store habit information in userInfo
        content.userInfo = [
            "habitId": habitID.uuidString,
            "habitName": habitName,
            "eventType": event.eventType.rawValue,
            "locationLabel": event.configuration?.locationLabel ?? "",
            "isLocationTriggered": true
        ]

        // Send immediate notification (no trigger)
        let identifier = "\(habitID.uuidString)-location-\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        try await center.add(request)
        logger.log(
            "✅ Location-triggered notification sent",
            level: .info,
            category: .notifications,
            metadata: [
                "habit": habitName,
                "habitId": habitID.uuidString,
                "eventType": event.eventType.rawValue,
                "location": event.configuration?.locationLabel ?? "unknown"
            ]
        )
    }

    // MARK: - Personality Notification Handling

    /// Handle personality analysis notification responses
    @MainActor
    private func handlePersonalityNotificationResponse(_ response: sending UNNotificationResponse) async {
        logger.log(
            "🧠 Handling personality notification response",
            level: .debug,
            category: .notifications
        )

        guard let coordinator = personalityDeepLinkCoordinator else {
            logger.log(
                "⚠️ PersonalityDeepLinkCoordinator not set",
                level: .warning,
                category: .notifications
            )
            return
        }

        logger.log(
            "🧠 Forwarding to PersonalityDeepLinkCoordinator",
            level: .debug,
            category: .notifications
        )

        coordinator.handleNotificationResponse(response)
    }
}
