import Foundation

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
        case .habitsAssistantOpened, .habitsAssistantClosed, .habitsAssistantCategorySelected, .habitsAssistantCategoryCleared,
             .habitsAssistantHabitSuggestionViewed, .habitsAssistantHabitAdded, .habitsAssistantHabitAddFailed,
             .habitsAssistantHabitRemoved, .habitsAssistantHabitRemoveFailed:
            return assistantEventName(for: event)
        case .habitCreated, .habitUpdated, .habitDeleted, .habitArchived, .habitRestored,
             .habitLogged, .habitLogDeleted, .habitLogUpdated, .habitStreakAchieved:
            return habitEventName(for: event)
        case .screenViewed, .tabSwitched:
            return navigationEventName(for: event)
        case .notificationPermissionRequested, .notificationPermissionGranted, .notificationPermissionDenied,
             .notificationReceived, .notificationActionTapped, .notificationScheduled, .notificationCancelled,
             .notificationSuppressed:
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
        case .habitsAssistantOpened, .habitsAssistantClosed, .habitsAssistantCategorySelected, .habitsAssistantCategoryCleared,
             .habitsAssistantHabitSuggestionViewed, .habitsAssistantHabitAdded, .habitsAssistantHabitAddFailed,
             .habitsAssistantHabitRemoved, .habitsAssistantHabitRemoveFailed:
            return assistantEventProperties(for: event)
        case .habitCreated, .habitUpdated, .habitDeleted, .habitArchived, .habitRestored,
             .habitLogged, .habitLogDeleted, .habitLogUpdated, .habitStreakAchieved:
            return habitEventProperties(for: event)
        case .screenViewed, .tabSwitched:
            return navigationEventProperties(for: event)
        case .notificationPermissionRequested, .notificationPermissionGranted, .notificationPermissionDenied,
             .notificationReceived, .notificationActionTapped, .notificationScheduled, .notificationCancelled,
             .notificationSuppressed:
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
        case .habitsAssistantCategoryCleared: return "habits_assistant_category_cleared"
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
        case .habitArchived: return "habit_archived"
        case .habitRestored: return "habit_restored"
        case .habitLogged: return "habit_logged"
        case .habitLogDeleted: return "habit_log_deleted"
        case .habitLogUpdated: return "habit_log_updated"
        case .habitStreakAchieved: return "habit_streak_achieved"
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
        switch event {
        case .notificationPermissionRequested: return "notification_permission_requested"
        case .notificationPermissionGranted: return "notification_permission_granted"
        case .notificationPermissionDenied: return "notification_permission_denied"
        case .notificationReceived: return "notification_received"
        case .notificationActionTapped: return "notification_action_tapped"
        case .notificationScheduled: return "notification_scheduled"
        case .notificationCancelled: return "notification_cancelled"
        case .notificationSuppressed: return "notification_suppressed"
        default: return "notification_event"
        }
    }
    
    func categoryEventName(for event: UserActionEvent) -> String {
        switch event {
        case .categoryCreated: return "category_created"
        case .categoryUpdated: return "category_updated"
        case .categoryDeleted: return "category_deleted"
        case .categoryReordered: return "category_reordered"
        case .categoryManagementOpened: return "category_management_opened"
        default: return "category_event"
        }
    }
    
    func paywallEventName(for event: UserActionEvent) -> String {
        switch event {
        case .paywallShown: return "paywall_shown"
        case .paywallDismissed: return "paywall_dismissed"
        case .productSelected: return "product_selected"
        case .purchaseAttempted: return "purchase_attempted"
        case .purchaseCompleted: return "purchase_completed"
        case .purchaseFailed: return "purchase_failed"
        case .purchaseRestoreAttempted: return "purchase_restore_attempted"
        case .purchaseRestoreCompleted: return "purchase_restore_completed"
        case .purchaseRestoreFailed: return "purchase_restore_failed"
        default: return "unknown_paywall_event"
        }
    }
    
    func tipsEventName(for event: UserActionEvent) -> String {
        switch event {
        case .tipsCarouselViewed: return "tips_carousel_viewed"
        case .tipViewed: return "tip_viewed"
        case .tipDetailOpened: return "tip_detail_opened"
        case .tipDetailClosed: return "tip_detail_closed"
        case .tipsBottomSheetOpened: return "tips_bottom_sheet_opened"
        case .tipsBottomSheetClosed: return "tips_bottom_sheet_closed"
        case .tipsCategoryFilterApplied: return "tips_category_filter_applied"
        default: return "tips_event"
        }
    }
    
    func settingsEventName(for event: UserActionEvent) -> String {
        switch event {
        case .settingsOpened: 
            return "settings_opened"
        case .profileUpdated: 
            return "profile_updated"
        case .notificationSettingsChanged: 
            return "notification_settings_changed"
        case .appearanceChanged: 
            return "appearance_changed"
        default: 
            return "settings_event"
        }
    }
    
    func systemEventName(for event: UserActionEvent) -> String {
        switch event {
        case .errorOccurred: return "error_occurred"
        case .crashReported: return "crash_reported"
        case .performanceMetric: return "performance_metric"
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
        case .onboardingPageNext(let fromPage, let toPage):
            return ["from_page": fromPage, "to_page": toPage]
        case .onboardingPageBack(let fromPage, let toPage):
            return ["from_page": fromPage, "to_page": toPage]
        case .onboardingUserNameEntered(let hasName):
            return ["has_name": hasName]
        default: return [:]
        }
    }
    
    func assistantEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .habitsAssistantOpened(let source):
            return ["source": source.rawValue]
        case .habitsAssistantCategorySelected(let category):
            return ["category": category]
        case .habitsAssistantHabitSuggestionViewed(let habitId, let category):
            return ["habit_id": habitId, "category": category]
        case .habitsAssistantHabitAdded(let habitId, let habitName, let category):
            return ["habit_id": habitId, "habit_name": habitName, "category": category]
        case .habitsAssistantHabitAddFailed(let habitId, let error):
            return ["habit_id": habitId, "error": error]
        case .habitsAssistantHabitRemoved(let habitId, let habitName, let category):
            return ["habit_id": habitId, "habit_name": habitName, "category": category]
        case .habitsAssistantHabitRemoveFailed(let habitId, let error):
            return ["habit_id": habitId, "error": error]
        default:
            return [:]
        }
    }
    
    func habitEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .habitCreated(let habitId, let habitName, let habitType):
            return ["habit_id": habitId, "habit_name": habitName, "habit_type": habitType]
        case .habitUpdated(let habitId, let habitName):
            return ["habit_id": habitId, "habit_name": habitName]
        case .habitDeleted(let habitId, let habitName):
            return ["habit_id": habitId, "habit_name": habitName]
        case .habitArchived(let habitId, let habitName):
            return ["habit_id": habitId, "habit_name": habitName]
        case .habitRestored(let habitId, let habitName):
            return ["habit_id": habitId, "habit_name": habitName]
        case .habitLogged(let habitId, let habitName, let date, let logType, let value):
            var properties: [String: Any] = [
                "habit_id": habitId,
                "habit_name": habitName,
                "date": ISO8601DateFormatter().string(from: date),
                "log_type": logType
            ]
            if let value = value {
                properties["value"] = value
            }
            return properties
        case .habitLogDeleted(let habitId, let habitName, let date):
            return [
                "habit_id": habitId,
                "habit_name": habitName,
                "date": ISO8601DateFormatter().string(from: date)
            ]
        case .habitLogUpdated(let habitId, let habitName, let date, let oldValue, let newValue):
            var properties: [String: Any] = [
                "habit_id": habitId,
                "habit_name": habitName,
                "date": ISO8601DateFormatter().string(from: date)
            ]
            if let oldValue = oldValue {
                properties["old_value"] = oldValue
            }
            if let newValue = newValue {
                properties["new_value"] = newValue
            }
            return properties
        case .habitStreakAchieved(let habitId, let habitName, let streakLength):
            return ["habit_id": habitId, "habit_name": habitName, "streak_length": streakLength]
        default:
            return [:]
        }
    }
    
    func navigationEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .screenViewed(let screen):
            return ["screen": screen]
        case .tabSwitched(let from, let to):
            return ["from": from, "to": to]
        default:
            return [:]
        }
    }
    
    func notificationEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .notificationReceived(let habitId, let habitName, let source):
            return ["habit_id": habitId, "habit_name": habitName, "source": source]
        case .notificationActionTapped(let action, let habitId, let habitName, let source):
            return ["action": action, "habit_id": habitId, "habit_name": habitName, "source": source]
        case .notificationScheduled(let habitId, let habitName, let reminderCount):
            return ["habit_id": habitId, "habit_name": habitName, "reminder_count": reminderCount]
        case .notificationCancelled(let habitId, let habitName, let reason):
            return ["habit_id": habitId, "habit_name": habitName, "reason": reason]
        case .notificationSuppressed(let habitId, let habitName, let reason):
            return ["habit_id": habitId, "habit_name": habitName, "reason": reason]
        default:
            return [:]
        }
    }
    
    func categoryEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .categoryCreated(let categoryId, let categoryName, let emoji):
            return ["category_id": categoryId, "category_name": categoryName, "emoji": emoji]
        case .categoryUpdated(let categoryId, let categoryName):
            return ["category_id": categoryId, "category_name": categoryName]
        case .categoryDeleted(let categoryId, let categoryName, let habitsCount):
            return ["category_id": categoryId, "category_name": categoryName, "habits_count": habitsCount]
        case .categoryReordered(let categoryId, let fromOrder, let toOrder):
            return ["category_id": categoryId, "from_order": fromOrder, "to_order": toOrder]
        default:
            return [:]
        }
    }
    
    func paywallEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .paywallShown(let source, let trigger):
            return ["source": source, "trigger": trigger]
        case .paywallDismissed(let source, let duration):
            return ["source": source, "duration": duration]
        case .productSelected(let productId, let productName, let price):
            return ["product_id": productId, "product_name": productName, "price": price]
        case .purchaseAttempted(let productId, let productName, let price):
            return ["product_id": productId, "product_name": productName, "price": price]
        case .purchaseCompleted(let productId, let productName, let price, let duration):
            return ["product_id": productId, "product_name": productName, "price": price, "duration": duration]
        case .purchaseFailed(let productId, let error):
            return ["product_id": productId, "error": error]
        case .purchaseRestoreAttempted:
            return [:]
        case .purchaseRestoreCompleted(let productId, let productName):
            var properties: [String: Any] = [:]
            if let productId = productId {
                properties["product_id"] = productId
            }
            if let productName = productName {
                properties["product_name"] = productName
            }
            return properties
        case .purchaseRestoreFailed(let error):
            return ["error": error]
        default:
            return [:]
        }
    }
    
    func tipsEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .tipViewed(let tipId, let tipTitle, let category, let source):
            return ["tip_id": tipId, "tip_title": tipTitle, "category": category, "source": source]
        case .tipDetailOpened(let tipId, let tipTitle, let category, let isFeatured):
            return ["tip_id": tipId, "tip_title": tipTitle, "category": category, "is_featured": isFeatured]
        case .tipDetailClosed(let tipId, let tipTitle, let timeSpent):
            return ["tip_id": tipId, "tip_title": tipTitle, "time_spent": timeSpent]
        case .tipsBottomSheetOpened(let source):
            return ["source": source]
        case .tipsBottomSheetClosed(let timeSpent):
            return ["time_spent": timeSpent]
        case .tipsCategoryFilterApplied(let category):
            return ["category": category]
        default:
            return [:]
        }
    }
    
    func settingsEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .profileUpdated(let field):
            return ["field": field]
        case .notificationSettingsChanged(let enabled):
            return ["enabled": enabled]
        case .appearanceChanged(let theme):
            return ["theme": theme]
        default:
            return [:]
        }
    }
    
    func systemEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .errorOccurred(let error, let context):
            return ["error": error, "context": context]
        case .crashReported(let error):
            return ["error": error]
        case .performanceMetric(let metric, let value, let unit):
            return ["metric": metric, "value": value, "unit": unit]
        default:
            return [:]
        }
    }
}