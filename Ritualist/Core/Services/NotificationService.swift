import Foundation
import UserNotifications

public protocol NotificationService {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func checkAuthorizationStatus() async -> Bool
    func schedule(for habitID: UUID, times: [ReminderTime]) async throws
    func scheduleWithActions(for habitID: UUID, habitName: String, times: [ReminderTime]) async throws
    func cancel(for habitID: UUID) async
    func sendImmediate(title: String, body: String) async throws
    func setupNotificationCategories() async
}

public final class LocalNotificationService: NSObject, NotificationService {
    private static let habitReminderCategory = "HABIT_REMINDER"
    
    // Delegate handler for notification actions
    public var actionHandler: ((NotificationAction, UUID, String?, ReminderTime?) async throws -> Void)?
    public var trackingService: UserActionTrackerService?
    
    override public init() {
        super.init()
        // Set up the notification center delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = self
        
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
            content.title = Strings.Notification.title
            content.body = Strings.Notification.body
            var date = DateComponents()
            date.hour = time.hour; date.minute = time.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            let id = "\(habitID.uuidString)-\(index)"
            let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            try await center.add(req)
        }
    }
    
    public func scheduleWithActions(for habitID: UUID, habitName: String, times: [ReminderTime]) async throws {
        let center = UNUserNotificationCenter.current()
        
        for (index, time) in times.enumerated() {
            let content = UNMutableNotificationContent()
            content.title = "Time for \(habitName)"
            content.body = "It's \(String(format: "%02d:%02d", time.hour, time.minute)) - time to work on your \(habitName) habit!"
            content.sound = .default
            content.categoryIdentifier = Self.habitReminderCategory
            
            // Store habit information in userInfo for action handling
            content.userInfo = [
                "habitId": habitID.uuidString,
                "habitName": habitName,
                "reminderHour": time.hour,
                "reminderMinute": time.minute
            ]
            
            var date = DateComponents()
            date.hour = time.hour
            date.minute = time.minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
            
            let id = "\(habitID.uuidString)-\(time.hour)-\(time.minute)"
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            
            try await center.add(request)
        }
        
        // Track notification scheduling
        trackingService?.track(.notificationScheduled(
            habitId: habitID.uuidString,
            habitName: habitName,
            reminderCount: times.count
        ))
    }
    public func cancel(for habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let prefix = habitID.uuidString
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
        
        // Extract habit name from pending notifications for tracking
        let habitName = pending.first(where: { $0.identifier.hasPrefix(prefix) })?.content.userInfo["habitName"] as? String ?? "Unknown Habit"
        
        center.removePendingNotificationRequests(withIdentifiers: ids)
        
        // Track notification cancellation
        if !ids.isEmpty {
            trackingService?.track(.notificationCancelled(
                habitId: habitID.uuidString,
                habitName: habitName,
                reason: "manual_cancellation"
            ))
        }
    }
    
    public func sendImmediate(title: String, body: String) async throws {
        let center = UNUserNotificationCenter.current()
        
        // Request permission if needed
        let authorized = try await requestAuthorizationIfNeeded()
        guard authorized else { 
            print("Notification not authorized")
            return 
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // Trigger with 20 minutes delay for "remind me later" functionality
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 20.0 * 60.0, repeats: false)
        let id = "snooze-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        print("Scheduling snooze notification: \(title) - \(body)")
        try await center.add(request)
        print("Snooze notification scheduled successfully")
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension LocalNotificationService: UNUserNotificationCenterDelegate {
    // This method is called when a notification is received while the app is in the foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("Notification received in foreground: \(notification.request.content.title)")
        // Show the notification even when the app is in the foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // This method is called when the user taps on a notification
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle notification response on main thread
        DispatchQueue.main.async {
            Task {
                await self.handleNotificationResponse(response)
                completionHandler()
            }
        }
    }
    
    // MARK: - Notification Categories Setup
    
    public func setupNotificationCategories() async {
        let logAction = UNNotificationAction(
            identifier: NotificationAction.log.rawValue,
            title: NotificationAction.log.title,
            options: [.foreground]
        )
        
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
        
        let habitReminderCategory = UNNotificationCategory(
            identifier: Self.habitReminderCategory,
            actions: [logAction, remindLaterAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let center = UNUserNotificationCenter.current()
        await center.setNotificationCategories([habitReminderCategory])
        
        print("Notification categories setup complete")
    }
    
    // MARK: - Notification Response Handling
    
    private func handleNotificationResponse(_ response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString),
              let habitName = userInfo["habitName"] as? String,
              let reminderHour = userInfo["reminderHour"] as? Int,
              let reminderMinute = userInfo["reminderMinute"] as? Int else {
            print("Invalid notification userInfo: \(userInfo)")
            return
        }
        
        let reminderTime = ReminderTime(hour: reminderHour, minute: reminderMinute)
        
        guard let action = NotificationAction(rawValue: response.actionIdentifier) else {
            print("Unknown notification action: \(response.actionIdentifier)")
            return
        }
        
        print("Handling notification action: \(action) for habit: \(habitName)")
        
        // Track notification action
        trackingService?.track(.notificationActionTapped(
            action: action.rawValue,
            habitId: habitId.uuidString,
            habitName: habitName,
            source: "notification_action"
        ))
        
        // Call the injected action handler (we're already on main thread)
        do {
            try await actionHandler?(action, habitId, habitName, reminderTime)
        } catch {
            print("Error handling notification action: \(error)")
        }
    }
}
