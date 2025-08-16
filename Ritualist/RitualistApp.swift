//
//  RitualistApp.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 29.07.2025.
//

import SwiftUI
import SwiftData
import FactoryKit
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
        
        // Handle personality analysis notifications on main actor
        Task { @MainActor in
            personalityDeepLinkCoordinator.handleNotificationResponse(response)
        }
        
        completionHandler()
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
