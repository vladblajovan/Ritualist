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
}

public final class LocalNotificationService: NSObject, NotificationService, @unchecked Sendable {
    private static let habitReminderCategory = "HABIT_REMINDER"
    private static let binaryHabitReminderCategory = "BINARY_HABIT_REMINDER"
    private static let numericHabitReminderCategory = "NUMERIC_HABIT_REMINDER"
    private static let habitStreakMilestoneCategory = "HABIT_STREAK_MILESTONE"
    
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
    private let logger: DebugLogger

    public init(
        habitCompletionCheckService: HabitCompletionCheckService,
        errorHandler: ErrorHandler? = nil,
        logger: DebugLogger
    ) {
        self.habitCompletionCheckService = habitCompletionCheckService
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
        let center = UNUserNotificationCenter.current()
        // Notifications should use local timezone - users want reminders at "7 AM local time"
        let calendar = CalendarUtils.currentLocalCalendar
        let today = Date()
        
        for time in times {
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
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute
            
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
            } else {
                // Time has passed - check if habit is incomplete and send catch-up notification
                let shouldNotify = await habitCompletionCheckService.shouldShowNotification(
                    habitId: habitID,
                    date: today
                )

                if shouldNotify {
                    // Send catch-up notification with short delay (10 seconds)
                    // Use unique ID per habit to avoid duplicate catch-ups
                    let catchUpContent = UNMutableNotificationContent()
                    catchUpContent.title = "Don't forget: \(habitName)"
                    catchUpContent.body = habitKind == .binary
                        ? "You haven't completed this habit yet today. Tap to mark as done!"
                        : "You haven't logged progress yet today. Tap to update!"
                    catchUpContent.sound = .default
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

                    // 10 second delay so it doesn't feel jarring when opening the app
                    let catchUpTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                    let catchUpId = "catchup_\(habitID.uuidString)"

                    // Remove any existing catch-up for this habit to avoid duplicates
                    center.removePendingNotificationRequests(withIdentifiers: [catchUpId])

                    let catchUpRequest = UNNotificationRequest(
                        identifier: catchUpId,
                        content: catchUpContent,
                        trigger: catchUpTrigger
                    )

                    try await center.add(catchUpRequest)
                    logger.log(
                        "🔔 Scheduled catch-up notification",
                        level: .info,
                        category: .notifications,
                        metadata: [
                            "habit": habitName,
                            "originalTime": "\(time.hour):\(String(format: "%02d", time.minute))",
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
        
        // Track notification scheduling
        trackingService?.track(.notificationScheduled(
            habitId: habitID.uuidString,
            habitName: habitName,
            reminderCount: times.count
        ))
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

            // Create notification time for today only (non-repeating)
            // This ensures notifications are cancelled when habit is completed
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute

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

            // Create notification time for today only (non-repeating)
            // This ensures notifications are cancelled when habit is completed
            var dateComponents = calendar.dateComponents([.year, .month, .day], from: today)
            dateComponents.hour = time.hour
            dateComponents.minute = time.minute

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

        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString) else {
            logger.log(
                "⚠️ No habitId in notification - showing by default",
                level: .warning,
                category: .notifications
            )
            completionHandler([.banner, .sound, .badge])
            return
        }

        logger.logNotification(
            event: "Checking completion status",
            type: "habit_reminder",
            habitId: habitId.uuidString
        )

        // Use async completion checking with timeout to avoid blocking the delegate
        // Capture service to avoid capturing self in @Sendable closure
        let completionCheckService = self.habitCompletionCheckService
        // Use nonisolated(unsafe) for the completion handler since it comes from Objective-C
        // and we know it's safe to call from any context
        nonisolated(unsafe) let unsafeCompletionHandler = completionHandler
        let loggerRef = self.logger
        let habitIdStr = habitId.uuidString

        Task { @MainActor @Sendable in
            do {
                let shouldShow = try await withTimeout(seconds: 0.5) {
                    await completionCheckService.shouldShowNotification(habitId: habitId, date: Date())
                }

                if shouldShow {
                    loggerRef.log(
                        "✅ Showing notification - habit not completed",
                        level: .info,
                        category: .notifications,
                        metadata: ["habitId": habitIdStr]
                    )
                    unsafeCompletionHandler([.banner, .sound, .badge])
                } else {
                    loggerRef.log(
                        "🚫 Suppressing notification - habit already completed",
                        level: .info,
                        category: .notifications,
                        metadata: ["habitId": habitIdStr]
                    )
                    unsafeCompletionHandler([]) // Suppress notification
                }
            } catch {
                loggerRef.log(
                    "⚠️ Error checking completion - showing notification as fallback",
                    level: .warning,
                    category: .notifications,
                    metadata: ["error": String(describing: error), "habitId": habitIdStr]
                )
                // Fail-safe: show notification on any error
                unsafeCompletionHandler([.banner, .sound, .badge])
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
        
        // Handle notification response on main thread
        // Use nonisolated(unsafe) for Objective-C delegate parameters that are safe to use across isolation boundaries
        nonisolated(unsafe) let unsafeResponse = response
        nonisolated(unsafe) let unsafeCompletionHandler = completionHandler

        #if canImport(UIKit)
        DispatchQueue.main.async {
            Task {
                await self.handleNotificationResponse(unsafeResponse)
                unsafeCompletionHandler()
            }
        }
        #else
        Task {
            await self.handleNotificationResponse(unsafeResponse)
            unsafeCompletionHandler()
        }
        #endif
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
        // Clear app badge when any notification is tapped
        await MainActor.run {
            UNUserNotificationCenter.current().setBadgeCount(0)
        }

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
