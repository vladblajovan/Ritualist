//
//  RitualistApp.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import SwiftUI
import SwiftData
import FactoryKit
import RitualistCore
import UserNotifications

@main struct RitualistApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Injected(\.notificationService) private var notificationService
    @Injected(\.persistenceContainer) private var persistenceContainer
    
    var body: some Scene {
        WindowGroup {
            RootAppView()
                .modelContainer(persistenceContainer?.container ?? createFallbackContainer())
                .task {
                    await setupNotifications()
                }
        }
    }
    
    // Fallback container if dependency injection fails
    private func createFallbackContainer() -> ModelContainer {
        do {
            return try ModelContainer(
                for: HabitModel.self, HabitLogModel.self, UserProfileModel.self, 
                    HabitCategoryModel.self, OnboardingStateModel.self, PersonalityAnalysisModel.self
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    private func setupNotifications() async {
        // Setup notification categories on app launch
        await notificationService.setupNotificationCategories()
        
        // Set up notification delegate
        await MainActor.run {
            UNUserNotificationCenter.current().delegate = appDelegate
        }
    }
}

// MARK: - App Delegate for Notification Handling

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    
    // Handle notification tap when app is in background/closed
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        // Check if this is a habit notification
        let userInfo = response.notification.request.content.userInfo
        if let habitId = userInfo["habitId"] as? String {
            // This is a habit notification - handle it like a log action
            self.handleHabitNotification(response)
        } else {
            // Handle personality analysis notifications on main actor
            Task { @MainActor in
                personalityDeepLinkCoordinator.handleNotificationResponse(response)
            }
        }
        
        completionHandler()
    }
    
    private func handleHabitNotification(_ response: UNNotificationResponse) {
        let userInfo = response.notification.request.content.userInfo
        
        guard let habitIdString = userInfo["habitId"] as? String,
              let habitId = UUID(uuidString: habitIdString),
              let habitName = userInfo["habitName"] as? String,
              let reminderHour = userInfo["reminderHour"] as? Int,
              let reminderMinute = userInfo["reminderMinute"] as? Int else {
            print("Invalid habit notification userInfo: \(userInfo)")
            return
        }
        
        let habitKindString = userInfo["habitKind"] as? String ?? "binary"
        let habitKind: HabitKind = habitKindString == "numeric" ? .numeric : .binary
        let reminderTime = ReminderTime(hour: reminderHour, minute: reminderMinute)
        
        // Simulate the "Log" action by calling the notification service's action handler
        Task { @MainActor in
            do {
                // Access the notification service and trigger the action handler
                let notificationService = Container.shared.notificationService()
                if let actionHandler = (notificationService as? LocalNotificationService)?.actionHandler {
                    try await actionHandler(.log, habitId, habitName, habitKind, reminderTime)
                }
            } catch {
                print("Error handling habit notification: \(error)")
            }
        }
    }
    
    // Handle notification when app is in foreground (optional - shows banner)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        // Show notification banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}

// Separate view to properly observe AppearanceManager changes
struct RootAppView: View {
    var body: some View {
        RootTabView()
            // RootTabView now handles onboarding through Factory injection
    }
}
