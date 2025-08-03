import Foundation

/// Maps UserActionEvent cases to event names and properties for tracking
public final class UserActionEventMapper {
    
    public init() {}
    
    /// Get event name for tracking
    public func eventName(for event: UserActionEvent) -> String {
        switch event {
        case .onboardingStarted, .onboardingCompleted, .onboardingSkipped, .onboardingPageViewed:
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
        case .onboardingPageViewed, .onboardingStarted, .onboardingCompleted, .onboardingSkipped:
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
        case .settingsOpened, .profileUpdated, .notificationSettingsChanged, .appearanceChanged:
            return settingsEventProperties(for: event)
        case .errorOccurred, .crashReported, .performanceMetric:
            return systemEventProperties(for: event)
        case .custom(_, let parameters):
            return parameters
        }
    }
}

// MARK: - Private Event Name Mapping

private extension UserActionEventMapper {
    
    func onboardingEventName(for event: UserActionEvent) -> String {
        switch event {
        case .onboardingStarted: return "onboarding_started"
        case .onboardingCompleted: return "onboarding_completed"
        case .onboardingSkipped: return "onboarding_skipped"
        case .onboardingPageViewed: return "onboarding_page_viewed"
        default: return ""
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
        default: return ""
        }
    }
    
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
        default: return ""
        }
    }
    
    func navigationEventName(for event: UserActionEvent) -> String {
        switch event {
        case .screenViewed: return "screen_viewed"
        case .tabSwitched: return "tab_switched"
        default: return ""
        }
    }
    
    func settingsEventName(for event: UserActionEvent) -> String {
        switch event {
        case .settingsOpened: return "settings_opened"
        case .profileUpdated: return "profile_updated"
        case .notificationSettingsChanged: return "notification_settings_changed"
        case .appearanceChanged: return "appearance_changed"
        default: return ""
        }
    }
    
    func systemEventName(for event: UserActionEvent) -> String {
        switch event {
        case .errorOccurred: return "error_occurred"
        case .crashReported: return "crash_reported"
        case .performanceMetric: return "performance_metric"
        default: return ""
        }
    }
}

// MARK: - Private Event Properties Mapping

private extension UserActionEventMapper {
    
    func onboardingEventProperties(for event: UserActionEvent) -> [String: Any] {
        switch event {
        case .onboardingPageViewed(let page):
            return ["page": page]
        default:
            return [:]
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
            return habitLoggedProperties(habitId: habitId, habitName: habitName, date: date, logType: logType, value: value)
        case .habitLogDeleted(let habitId, let habitName, let date):
            return habitLogDeletedProperties(habitId: habitId, habitName: habitName, date: date)
        case .habitLogUpdated(let habitId, let habitName, let date, let oldValue, let newValue):
            return habitLogUpdatedProperties(habitId: habitId, habitName: habitName, date: date, oldValue: oldValue, newValue: newValue)
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
    
    // MARK: - Complex Property Helpers
    
    func habitLoggedProperties(habitId: String, habitName: String, date: Date, logType: String, value: Double?) -> [String: Any] {
        var props: [String: Any] = [
            "habit_id": habitId,
            "habit_name": habitName,
            "date": ISO8601DateFormatter().string(from: date),
            "log_type": logType
        ]
        if let value = value {
            props["value"] = value
        }
        return props
    }
    
    func habitLogDeletedProperties(habitId: String, habitName: String, date: Date) -> [String: Any] {
        [
            "habit_id": habitId,
            "habit_name": habitName,
            "date": ISO8601DateFormatter().string(from: date)
        ]
    }
    
    func habitLogUpdatedProperties(habitId: String, habitName: String, date: Date, oldValue: Double?, newValue: Double?) -> [String: Any] {
        var props: [String: Any] = [
            "habit_id": habitId,
            "habit_name": habitName,
            "date": ISO8601DateFormatter().string(from: date)
        ]
        if let oldValue = oldValue {
            props["old_value"] = oldValue
        }
        if let newValue = newValue {
            props["new_value"] = newValue
        }
        return props
    }
}