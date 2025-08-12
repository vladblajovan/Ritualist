import Foundation
import RitualistCore

/// Maps UserActionEvent cases to event names and properties for tracking
public final class UserActionEventMapper {
    
    public init() {}
    
    /// Get event name for tracking
    public func eventName(for event: UserActionEvent) -> String {
        switch event {
        case .onboardingStarted, .onboardingCompleted, .onboardingSkipped, .onboardingPageViewed, 
             .onboardingPageNext, .onboardingPageBack, .onboardingUserNameEntered,
             .onboardingNotificationPermissionRequested, .onboardingNotificationPermissionGranted,
             .onboardingNotificationPermissionDenied:
            return onboardingEventName(for: event)
        case .habitsAssistantOpened, .habitsAssistantClosed, .habitsAssistantCategorySelected,
             .habitsAssistantHabitSuggestionViewed, .habitsAssistantHabitAdded, .habitsAssistantHabitAddFailed,
             .habitsAssistantHabitRemoved, .habitsAssistantHabitRemoveFailed:
            return assistantEventName(for: event)
        case .habitCreated, .habitUpdated, .habitDeleted, .habitArchived, .habitRestored,
             .habitLogged, .habitLogDeleted, .habitLogUpdated, .habitStreakAchieved:
            return habitEventName(for: event)
        case .screenViewed, .tabSwitched:
            return navigationEventName(for: event)
        case .notificationPermissionRequested, .notificationPermissionGranted, .notificationPermissionDenied,
             .notificationReceived, .notificationActionTapped, .notificationScheduled, .notificationCancelled:
            return notificationEventName(for: event)
        case .categoryCreated, .categoryUpdated, .categoryDeleted, .categoryReordered, .categoryManagementOpened:
            return categoryEventName(for: event)
        case .paywallShown, .paywallDismissed, .productSelected, .purchaseAttempted, .purchaseCompleted,
             .purchaseFailed, .purchaseRestoreAttempted, .purchaseRestoreCompleted, .purchaseRestoreFailed:
            return paywallEventName(for: event)
        case .tipsCarouselViewed, .tipViewed, .tipDetailOpened, .tipDetailClosed,
             .tipsBottomSheetOpened, .tipsBottomSheetClosed, .tipsCategoryFilterApplied:
            return tipsEventName(for: event)
        case .settingsOpened, .profileUpdated, .notificationSettingsChanged, .appearanceChanged:
            return settingsEventName(for: event)
        case .errorOccurred, .crashReported, .performanceMetric:
            return systemEventName(for: event)
        case .custom(let event, _):
            return event
        }
    }
    
    /// Get event properties for tracking
    public func eventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .onboardingStarted, .onboardingCompleted, .onboardingSkipped, .onboardingPageViewed, 
             .onboardingPageNext, .onboardingPageBack, .onboardingUserNameEntered,
             .onboardingNotificationPermissionRequested, .onboardingNotificationPermissionGranted,
             .onboardingNotificationPermissionDenied:
            return onboardingEventProperties(for: event)
        case .habitsAssistantOpened, .habitsAssistantClosed, .habitsAssistantCategorySelected,
             .habitsAssistantHabitSuggestionViewed, .habitsAssistantHabitAdded, .habitsAssistantHabitAddFailed,
             .habitsAssistantHabitRemoved, .habitsAssistantHabitRemoveFailed:
            return assistantEventProperties(for: event)
        case .habitCreated, .habitUpdated, .habitDeleted, .habitArchived, .habitRestored,
             .habitLogged, .habitLogDeleted, .habitLogUpdated, .habitStreakAchieved:
            return habitEventProperties(for: event)
        case .screenViewed, .tabSwitched:
            return navigationEventProperties(for: event)
        case .notificationPermissionRequested, .notificationPermissionGranted, .notificationPermissionDenied,
             .notificationReceived, .notificationActionTapped, .notificationScheduled, .notificationCancelled:
            return notificationEventProperties(for: event)
        case .categoryCreated, .categoryUpdated, .categoryDeleted, .categoryReordered, .categoryManagementOpened:
            return categoryEventProperties(for: event)
        case .paywallShown, .paywallDismissed, .productSelected, .purchaseAttempted, .purchaseCompleted,
             .purchaseFailed, .purchaseRestoreAttempted, .purchaseRestoreCompleted, .purchaseRestoreFailed:
            return paywallEventProperties(for: event)
        case .tipsCarouselViewed, .tipViewed, .tipDetailOpened, .tipDetailClosed,
             .tipsBottomSheetOpened, .tipsBottomSheetClosed, .tipsCategoryFilterApplied:
            return tipsEventProperties(for: event)
        case .settingsOpened, .profileUpdated, .notificationSettingsChanged, .appearanceChanged:
            return settingsEventProperties(for: event)
        case .errorOccurred, .crashReported, .performanceMetric:
            return systemEventProperties(for: event)
        case .custom(_, let parameters):
            return parameters
        }
    }
}

// MARK: - Private Event Name Mappers
private extension UserActionEventMapper {
    
    func onboardingEventName(for event: UserActionEvent) -> String {
        switch event {
        case .onboardingStarted: return "onboarding_started"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingSkipped: return "onboarding_skipped"
        case .onboardingPageViewed: return "onboarding_page_viewed"
        case .onboardingPageNext: return "onboarding_page_next"
        case .onboardingPageBack: return "onboarding_page_back"
        case .onboardingUserNameEntered: return "onboarding_user_name_entered"
        case .onboardingNotificationPermissionRequested: return "onboarding_notification_permission_requested"
        case .onboardingNotificationPermissionGranted: return "onboarding_notification_permission_granted"
        case .onboardingNotificationPermissionDenied: return "onboarding_notification_permission_denied"
        default: return "unknown_onboarding_event"
        }
    }
    
    func assistantEventName(for event: UserActionEvent) -> String {
        switch event {
        case .habitsAssistantOpened: return "habits_assistant_opened"
        case .habitsAssistantClosed: return "habits_assistant_closed"
        case .habitsAssistantCategorySelected: return "habits_assistant_category_selected"
        case .habitsAssistantHabitSuggestionViewed: return "habits_assistant_habit_suggestion_viewed"
        case .habitsAssistantHabitAdded: return "habits_assistant_habit_added"
        case .habitsAssistantHabitAddFailed: return "habits_assistant_habit_add_failed"
        case .habitsAssistantHabitRemoved: return "habits_assistant_habit_removed"
        case .habitsAssistantHabitRemoveFailed: return "habits_assistant_habit_remove_failed"
        default: return "unknown_assistant_event"
        }
    }
    
    // Simplified implementations for other event types
    func habitEventName(for event: UserActionEvent) -> String {
        switch event {
        case .habitCreated: return "habit_created"
        case .habitUpdated: return "habit_updated" 
        case .habitDeleted: return "habit_deleted"
        case .habitLogged: return "habit_logged"
        default: return "unknown_habit_event"
        }
    }
    
    func navigationEventName(for event: UserActionEvent) -> String {
        switch event {
        case .screenViewed: return "screen_viewed"
        case .tabSwitched: return "tab_switched"
        default: return "unknown_navigation_event"
        }
    }
    
    func notificationEventName(for event: UserActionEvent) -> String {
        return "notification_event"
    }
    
    func categoryEventName(for event: UserActionEvent) -> String {
        return "category_event"
    }
    
    func paywallEventName(for event: UserActionEvent) -> String {
        return "paywall_event"
    }
    
    func tipsEventName(for event: UserActionEvent) -> String {
        return "tips_event"
    }
    
    func settingsEventName(for event: UserActionEvent) -> String {
        return "settings_event"
    }
    
    func systemEventName(for event: UserActionEvent) -> String {
        switch event {
        case .errorOccurred: return "error_occurred"
        default: return "system_event"
        }
    }
}

// MARK: - Private Event Properties Mappers  
private extension UserActionEventMapper {
    
    func onboardingEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .onboardingPageViewed(let page, let pageName):
            return ["page": page, "page_name": pageName]
        default: return [:]
        }
    }
    
    func assistantEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func habitEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func navigationEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func notificationEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func categoryEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func paywallEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func tipsEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func settingsEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
    
    func systemEventProperties(for event: UserActionEvent) -> [String: Any] {
        return [:]
    }
}