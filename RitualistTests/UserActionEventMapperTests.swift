//
//  UserActionEventMapperTests.swift
//  RitualistTests
//
//  Created by Claude on 04.08.2025.
//

import Testing
import Foundation
@testable import Ritualist

struct UserActionEventMapperTests {
    
    let mapper = UserActionEventMapper()
    
    // Test data
    static let testDate = Date(timeIntervalSince1970: 1691174400) // Fixed test date
    static let testHabitId = "test-habit-123"
    static let testHabitName = "Test Habit"
    
    // MARK: - Onboarding Event Tests
    
    @Test("Onboarding started event returns correct name")
    func onboardingStartedEventName() {
        let result = mapper.eventName(for: .onboardingStarted)
        #expect(result == "onboarding_started")
    }
    
    @Test("Onboarding completed event returns correct name")
    func onboardingCompletedEventName() {
        let result = mapper.eventName(for: .onboardingCompleted)
        #expect(result == "onboarding_completed")
    }
    
    @Test("Onboarding skipped event returns correct name")
    func onboardingSkippedEventName() {
        let result = mapper.eventName(for: .onboardingSkipped)
        #expect(result == "onboarding_skipped")
    }
    
    @Test("Onboarding page viewed event returns correct name")
    func onboardingPageViewedEventName() {
        let result = mapper.eventName(for: .onboardingPageViewed(page: 1))
        #expect(result == "onboarding_page_viewed")
    }
    
    @Test("Onboarding page viewed event returns correct properties")
    func onboardingPageViewedProperties() {
        let result = mapper.eventProperties(for: .onboardingPageViewed(page: 3))
        #expect(result["page"] as? Int == 3)
    }
    
    @Test("Onboarding events without parameters return empty properties")
    func onboardingEventsEmptyProperties() {
        let events: [UserActionEvent] = [.onboardingStarted, .onboardingCompleted, .onboardingSkipped]
        
        for event in events {
            let result = mapper.eventProperties(for: event)
            #expect(result.isEmpty)
        }
    }
    
    // MARK: - Habits Assistant Event Tests
    
    @Test("Habits assistant opened event returns correct name")
    func habitsAssistantOpenedEventName() {
        let result = mapper.eventName(for: .habitsAssistantOpened(source: .habitsPage))
        #expect(result == "habits_assistant_opened")
    }
    
    @Test("Habits assistant opened event returns correct properties")
    func habitsAssistantOpenedProperties() {
        let result = mapper.eventProperties(for: .habitsAssistantOpened(source: .emptyState))
        #expect(result["source"] as? String == "empty_state")
    }
    
    @Test("Habits assistant closed event returns correct name")
    func habitsAssistantClosedEventName() {
        let result = mapper.eventName(for: .habitsAssistantClosed)
        #expect(result == "habits_assistant_closed")
    }
    
    @Test("Habits assistant category selected event returns correct name and properties")
    func habitsAssistantCategorySelectedEvent() {
        let event = UserActionEvent.habitsAssistantCategorySelected(category: "health")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habits_assistant_category_selected")
        #expect(properties["category"] as? String == "health")
    }
    
    @Test("Habits assistant habit suggestion viewed event returns correct properties")
    func habitsAssistantHabitSuggestionViewedProperties() {
        let event = UserActionEvent.habitsAssistantHabitSuggestionViewed(habitId: Self.testHabitId, category: "fitness")
        let result = mapper.eventProperties(for: event)
        
        #expect(result["habit_id"] as? String == Self.testHabitId)
        #expect(result["category"] as? String == "fitness")
    }
    
    @Test("Habits assistant habit added event returns correct properties")
    func habitsAssistantHabitAddedProperties() {
        let event = UserActionEvent.habitsAssistantHabitAdded(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            category: "wellness"
        )
        let result = mapper.eventProperties(for: event)
        
        #expect(result["habit_id"] as? String == Self.testHabitId)
        #expect(result["habit_name"] as? String == Self.testHabitName)
        #expect(result["category"] as? String == "wellness")
    }
    
    @Test("Habits assistant habit add failed event returns correct properties")
    func habitsAssistantHabitAddFailedProperties() {
        let event = UserActionEvent.habitsAssistantHabitAddFailed(habitId: Self.testHabitId, error: "validation_error")
        let result = mapper.eventProperties(for: event)
        
        #expect(result["habit_id"] as? String == Self.testHabitId)
        #expect(result["error"] as? String == "validation_error")
    }
    
    // MARK: - Habit Management Event Tests
    
    @Test("Habit created event returns correct name and properties")
    func habitCreatedEvent() {
        let event = UserActionEvent.habitCreated(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            habitType: "binary"
        )
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_created")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["habit_type"] as? String == "binary")
    }
    
    @Test("Habit updated event returns correct name and properties")
    func habitUpdatedEvent() {
        let event = UserActionEvent.habitUpdated(habitId: Self.testHabitId, habitName: Self.testHabitName)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_updated")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
    }
    
    @Test("Habit deleted event returns correct name and properties")
    func habitDeletedEvent() {
        let event = UserActionEvent.habitDeleted(habitId: Self.testHabitId, habitName: Self.testHabitName)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_deleted")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
    }
    
    @Test("Habit archived event returns correct name and properties")
    func habitArchivedEvent() {
        let event = UserActionEvent.habitArchived(habitId: Self.testHabitId, habitName: Self.testHabitName)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_archived")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
    }
    
    @Test("Habit restored event returns correct name and properties")
    func habitRestoredEvent() {
        let event = UserActionEvent.habitRestored(habitId: Self.testHabitId, habitName: Self.testHabitName)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_restored")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
    }
    
    // MARK: - Habit Tracking Event Tests
    
    @Test("Habit logged event with value returns correct properties")
    func habitLoggedEventWithValue() {
        let event = UserActionEvent.habitLogged(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            date: Self.testDate,
            logType: "numeric",
            value: 5.0
        )
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_logged")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["log_type"] as? String == "numeric")
        #expect(properties["value"] as? Double == 5.0)
        
        // Check date formatting
        let dateString = properties["date"] as? String
        #expect(dateString != nil)
        #expect(!dateString!.isEmpty)
    }
    
    @Test("Habit logged event without value returns correct properties")
    func habitLoggedEventWithoutValue() {
        let event = UserActionEvent.habitLogged(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            date: Self.testDate,
            logType: "binary",
            value: nil
        )
        
        let properties = mapper.eventProperties(for: event)
        
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["log_type"] as? String == "binary")
        #expect(properties["value"] == nil)
    }
    
    @Test("Habit log deleted event returns correct properties")
    func habitLogDeletedEvent() {
        let event = UserActionEvent.habitLogDeleted(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            date: Self.testDate
        )
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_log_deleted")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        
        // Check date formatting
        let dateString = properties["date"] as? String
        #expect(dateString != nil)
        #expect(!dateString!.isEmpty)
    }
    
    @Test("Habit log updated event returns correct properties")
    func habitLogUpdatedEvent() {
        let event = UserActionEvent.habitLogUpdated(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            date: Self.testDate,
            oldValue: 3.0,
            newValue: 5.0
        )
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_log_updated")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["old_value"] as? Double == 3.0)
        #expect(properties["new_value"] as? Double == 5.0)
    }
    
    @Test("Habit log updated event with nil values returns correct properties")
    func habitLogUpdatedEventWithNilValues() {
        let event = UserActionEvent.habitLogUpdated(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            date: Self.testDate,
            oldValue: nil,
            newValue: nil
        )
        
        let properties = mapper.eventProperties(for: event)
        
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["old_value"] == nil)
        #expect(properties["new_value"] == nil)
    }
    
    @Test("Habit streak achieved event returns correct properties")
    func habitStreakAchievedEvent() {
        let event = UserActionEvent.habitStreakAchieved(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            streakLength: 7
        )
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "habit_streak_achieved")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["streak_length"] as? Int == 7)
    }
    
    // MARK: - Navigation Event Tests
    
    @Test("Screen viewed event returns correct properties")
    func screenViewedEvent() {
        let event = UserActionEvent.screenViewed(screen: "habits")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "screen_viewed")
        #expect(properties["screen"] as? String == "habits")
    }
    
    @Test("Tab switched event returns correct properties")
    func tabSwitchedEvent() {
        let event = UserActionEvent.tabSwitched(from: "overview", to: "habits")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "tab_switched")
        #expect(properties["from"] as? String == "overview")
        #expect(properties["to"] as? String == "habits")
    }
    
    // MARK: - Settings Event Tests
    
    @Test("Settings opened event returns correct name")
    func settingsOpenedEvent() {
        let result = mapper.eventName(for: .settingsOpened)
        #expect(result == "settings_opened")
    }
    
    @Test("Profile updated event returns correct properties")
    func profileUpdatedEvent() {
        let event = UserActionEvent.profileUpdated(field: "name")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "profile_updated")
        #expect(properties["field"] as? String == "name")
    }
    
    @Test("Notification settings changed event returns correct properties")
    func notificationSettingsChangedEvent() {
        let event = UserActionEvent.notificationSettingsChanged(enabled: true)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "notification_settings_changed")
        #expect(properties["enabled"] as? Bool == true)
    }
    
    @Test("Appearance changed event returns correct properties")
    func appearanceChangedEvent() {
        let event = UserActionEvent.appearanceChanged(theme: "dark")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "appearance_changed")
        #expect(properties["theme"] as? String == "dark")
    }
    
    // MARK: - System Event Tests
    
    @Test("Error occurred event returns correct properties")
    func errorOccurredEvent() {
        let event = UserActionEvent.errorOccurred(error: "network_error", context: "sync")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "error_occurred")
        #expect(properties["error"] as? String == "network_error")
        #expect(properties["context"] as? String == "sync")
    }
    
    @Test("Crash reported event returns correct properties")
    func crashReportedEvent() {
        let event = UserActionEvent.crashReported(error: "nil_pointer_exception")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "crash_reported")
        #expect(properties["error"] as? String == "nil_pointer_exception")
    }
    
    @Test("Performance metric event returns correct properties")
    func performanceMetricEvent() {
        let event = UserActionEvent.performanceMetric(metric: "app_startup_time", value: 1.234, unit: "seconds")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "performance_metric")
        #expect(properties["metric"] as? String == "app_startup_time")
        #expect(properties["value"] as? Double == 1.234)
        #expect(properties["unit"] as? String == "seconds")
    }
    
    // MARK: - Custom Event Tests
    
    @Test("Custom event returns custom name and properties")
    func customEvent() {
        let customProperties: [String: Any] = [
            "feature": "test_feature",
            "version": 1,
            "enabled": true
        ]
        let event = UserActionEvent.custom(event: "custom_test_event", parameters: customProperties)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "custom_test_event")
        #expect(properties["feature"] as? String == "test_feature")
        #expect(properties["version"] as? Int == 1)
        #expect(properties["enabled"] as? Bool == true)
    }
    
    @Test("Custom event with empty parameters returns empty properties")
    func customEventEmptyParameters() {
        let event = UserActionEvent.custom(event: "custom_empty_event", parameters: [:])
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "custom_empty_event")
        #expect(properties.isEmpty)
    }
    
    // MARK: - Edge Cases and Error Handling
    
    @Test("Event names are consistent snake_case format")
    func eventNamesSnakeCaseFormat() {
        let events: [UserActionEvent] = [
            .onboardingStarted,
            .habitsAssistantOpened(source: .habitsPage),
            .habitCreated(habitId: "test", habitName: "test", habitType: "test"),
            .screenViewed(screen: "test"),
            .settingsOpened,
            .errorOccurred(error: "test", context: "test")
        ]
        
        for event in events {
            let name = mapper.eventName(for: event)
            #expect(!name.isEmpty)
            #expect(!name.contains(" ")) // No spaces
            #expect(!name.contains("-")) // No hyphens
            #expect(name.lowercased() == name) // All lowercase
            #expect(name.contains("_")) // Contains underscores
        }
    }
    
    @Test("Properties contain expected data types")
    func propertiesDataTypes() {
        let event = UserActionEvent.habitLogged(
            habitId: Self.testHabitId,
            habitName: Self.testHabitName,
            date: Self.testDate,
            logType: "numeric",
            value: 5.0
        )
        
        let properties = mapper.eventProperties(for: event)
        
        #expect(properties["habit_id"] is String)
        #expect(properties["habit_name"] is String)
        #expect(properties["date"] is String)
        #expect(properties["log_type"] is String)
        #expect(properties["value"] is Double)
    }
    
    @Test("ISO8601 date formatting is consistent")
    func dateFormattingConsistency() {
        let event1 = UserActionEvent.habitLogged(
            habitId: "test1",
            habitName: "Test 1",
            date: Self.testDate,
            logType: "binary",
            value: nil
        )
        
        let properties1 = mapper.eventProperties(for: event1)
        let dateString1 = properties1["date"] as? String
        
        #expect(dateString1?.contains("T") == true) // ISO8601 format includes T separator
        #expect(dateString1 != nil)
    }
    
    @Test("HabitsAssistantSource enum values map correctly")
    func habitsAssistantSourceMapping() {
        let sources: [HabitsAssistantSource] = [.onboarding, .habitsPage, .emptyState]
        
        for source in sources {
            let event = UserActionEvent.habitsAssistantOpened(source: source)
            let properties = mapper.eventProperties(for: event)
            let sourceValue = properties["source"] as? String
            
            #expect(sourceValue == source.rawValue)
        }
    }
}