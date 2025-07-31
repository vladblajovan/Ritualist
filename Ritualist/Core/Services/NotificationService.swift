import Foundation
import UserNotifications

public protocol NotificationService {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func checkAuthorizationStatus() async -> Bool
    func schedule(for habitID: UUID, times: [ReminderTime]) async throws
    func cancel(for habitID: UUID) async
    func sendImmediate(title: String, body: String) async throws
}

public final class LocalNotificationService: NSObject, NotificationService {
    override public init() {
        super.init()
        // Set up the notification center delegate to handle foreground notifications
        UNUserNotificationCenter.current().delegate = self
    }
    
    public func requestAuthorizationIfNeeded() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
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
    public func cancel(for habitID: UUID) async {
        let center = UNUserNotificationCenter.current()
        let prefix = habitID.uuidString
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map { $0.identifier }.filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)
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
        
        // Trigger with 1 second delay to ensure it shows (0.1 might be too fast)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let id = "immediate-\(UUID().uuidString)"
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        
        print("Scheduling notification: \(title) - \(body)")
        try await center.add(request)
        print("Notification scheduled successfully")
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
        // Handle notification tap if needed
        completionHandler()
    }
}
