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
    @Injected(\.urlValidationService) private var urlValidationService
    @Injected(\.navigationService) private var navigationService
    
    var body: some Scene {
        WindowGroup {
            RootAppView()
                .modelContainer(persistenceContainer?.container ?? createFallbackContainer())
                .task {
                    await setupNotifications()
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
    // Fallback container if dependency injection fails
    private func createFallbackContainer() -> ModelContainer {
        do {
            // Use app group shared container for consistency
            guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladblajovan.Ritualist") else {
                fatalError("Failed to get shared container URL for app group")
            }
            
            let configuration = ModelConfiguration(
                url: sharedContainerURL.appendingPathComponent("Ritualist.sqlite")
            )
            
            return try ModelContainer(
                for: HabitModel.self, HabitLogModel.self, UserProfileModel.self, 
                    HabitCategoryModel.self, OnboardingStateModel.self, PersonalityAnalysisModel.self,
                configurations: configuration
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
    
    /// Handle deep links from widget taps
    /// Navigates to appropriate habit or overview section with enhanced validation
    private func handleDeepLink(_ url: URL) {
        // Validate the URL first using centralized service
        let validationResult = urlValidationService.validateDeepLinkURL(url)
        
        guard validationResult.isValid else {
            print("[DEEP-LINK] URL validation failed: \(validationResult.description)")
            // Fallback to overview for invalid URLs
            handleOverviewDeepLink()
            return
        }
        
        switch url.host {
        case "habit":
            handleHabitDeepLink(url)
        case "overview":
            handleOverviewDeepLink()
        default:
            // Unknown deep link - navigate to overview as fallback
            handleOverviewDeepLink()
        }
    }
    
    /// Handle habit-specific deep links from widget
    /// Formats: 
    /// - Legacy: ritualist://habit/{habitId}
    /// - Enhanced: ritualist://habit/{habitId}?date={ISO8601}&action={action}
    private func handleHabitDeepLink(_ url: URL) {
        // Use centralized validation service to extract habit ID
        guard let habitId = urlValidationService.extractHabitId(from: url) else {
            // Invalid habit ID - fallback to overview
            print("[DEEP-LINK] Failed to extract valid habit ID from URL: \(url)")
            handleOverviewDeepLink()
            return
        }
        
        // Extract date and action parameters using validation service
        let targetDate = urlValidationService.extractDate(from: url)
        let action = urlValidationService.extractAction(from: url)
        
        Task { @MainActor in            
            // For enhanced deep links with date and action parameters
            if let targetDate = targetDate {
                
                // Navigate to Overview tab with date context
                navigationService.navigateToOverview(shouldRefresh: true)
                
                // Handle specific actions using type-safe enum
                switch action {
                case .progress:
                    // For numeric habits: Navigate and show progress sheet
                    await handleProgressDeepLinkAction(habitId: habitId, targetDate: targetDate)
                    
                case .view:
                    // For completed binary habits: Just navigate to view the date
                    print("[DEEP-LINK] View action requested for habit \(habitId) on date \(targetDate)")
                    
                    // Navigate to the specific date in overview
                    // The overview will show the habit status for that date
                    await navigateToDateInOverview(targetDate)
                }
                
            } else {
                // Legacy deep link: Navigate to Overview tab and trigger habit completion flow
                navigationService.navigateToOverview(shouldRefresh: true)
                print("[DEEP-LINK] Legacy deep link for habit \(habitId) - navigated to overview")
            }
        }
    }
    
    /// Handle progress deep link action for numeric habits
    /// Opens the progress sheet for the specified habit and date
    @MainActor
    private func handleProgressDeepLinkAction(habitId: UUID, targetDate: Date) async {
        print("[DEEP-LINK] Progress action requested for habit \(habitId) on date \(targetDate)")
        
        do {
            // Fetch the habit to verify it exists and is numeric
            let habitRepository = Container.shared.habitRepository()
            let habits = try await habitRepository.fetchAllHabits()
            
            guard let habit = habits.first(where: { $0.id == habitId }),
                  habit.kind == .numeric else {
                print("[DEEP-LINK] Error: Habit \(habitId) not found or not numeric")
                return
            }
            
            // Navigate to Overview tab first - regardless of current tab
            let navigationService = Container.shared.navigationService()
            navigationService.navigateToOverview(shouldRefresh: true)
            
            let overviewViewModel = Container.shared.overviewViewModel()
            
            // Navigate to the specific date first and wait for completion
            print("[DEEP-LINK-TRACE] About to navigate to date and load data for habit \(habit.name)...")
            await navigateToDateInOverview(targetDate)
            print("[DEEP-LINK-TRACE] Navigation and data loading completed - now setting pending habit")
            
            // Set the habit as pending for progress sheet auto-opening
            // The sheet will open when OverviewView appears and calls processPendingNumericHabit()
            print("[DEEP-LINK-TRACE] About to set pending numeric habit \(habit.name) (ID: \(habit.id))")
            overviewViewModel.setPendingNumericHabit(habit)
            
            print("[DEEP-LINK-TRACE] Progress sheet configured for habit \(habit.name) on \(targetDate) - will open when view appears")
            print("[DEEP-LINK-TRACE] handleProgressDeepLinkAction completed successfully")
            
        } catch {
            print("[DEEP-LINK] Error fetching habit for progress action: \(error)")
        }
    }
    
    /// Navigate to a specific date in the Overview
    /// Sets the overview to display the specific date and refreshes data
    @MainActor
    private func navigateToDateInOverview(_ targetDate: Date) async {
        print("[DEEP-LINK-TRACE] navigateToDateInOverview started for date \(targetDate)")
        
        let overviewViewModel = Container.shared.overviewViewModel()
        
        // Set the date first
        print("[DEEP-LINK-TRACE] Setting viewingDate to \(targetDate)")
        overviewViewModel.viewingDate = targetDate
        
        // Wait for data loading to complete before proceeding
        print("[DEEP-LINK-TRACE] About to await loadData()")
        await overviewViewModel.loadData()
        print("[DEEP-LINK-TRACE] loadData() completed successfully")
        
        print("[DEEP-LINK-TRACE] navigateToDateInOverview completed for date \(targetDate)")
    }
    
    /// Handle overview deep links from widget
    /// Simply navigates to the Overview tab
    private func handleOverviewDeepLink() {
        Task { @MainActor in
            navigationService.navigateToOverview(shouldRefresh: true)
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
