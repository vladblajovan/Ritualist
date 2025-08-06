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
        let result = mapper.eventName(for: .onboardingPageViewed(page: 1, pageName: "welcome"))
        #expect(result == "onboarding_page_viewed")
    }
    
    @Test("Onboarding page viewed event returns correct properties")
    func onboardingPageViewedProperties() {
        let result = mapper.eventProperties(for: .onboardingPageViewed(page: 3, pageName: "permissions"))
        #expect(result["page"] as? Int == 3)
        #expect(result["page_name"] as? String == "permissions")
    }
    
    @Test("Onboarding page navigation events return correct properties")
    func onboardingPageNavigationProperties() {
        let nextEvent = UserActionEvent.onboardingPageNext(fromPage: 1, toPage: 2)
        let backEvent = UserActionEvent.onboardingPageBack(fromPage: 2, toPage: 1)
        
        let nextProps = mapper.eventProperties(for: nextEvent)
        let backProps = mapper.eventProperties(for: backEvent)
        
        #expect(nextProps["from_page"] as? Int == 1)
        #expect(nextProps["to_page"] as? Int == 2)
        #expect(backProps["from_page"] as? Int == 2)
        #expect(backProps["to_page"] as? Int == 1)
    }
    
    @Test("Onboarding user name entered event returns correct properties")
    func onboardingUserNameEnteredProperties() {
        let hasNameEvent = UserActionEvent.onboardingUserNameEntered(hasName: true)
        let noNameEvent = UserActionEvent.onboardingUserNameEntered(hasName: false)
        
        let hasNameProps = mapper.eventProperties(for: hasNameEvent)
        let noNameProps = mapper.eventProperties(for: noNameEvent)
        
        #expect(hasNameProps["has_name"] as? Bool == true)
        #expect(noNameProps["has_name"] as? Bool == false)
    }
    
    @Test("Onboarding notification permission events return correct names")
    func onboardingNotificationPermissionEvents() {
        let requestEvent = mapper.eventName(for: .onboardingNotificationPermissionRequested)
        let grantedEvent = mapper.eventName(for: .onboardingNotificationPermissionGranted)
        let deniedEvent = mapper.eventName(for: .onboardingNotificationPermissionDenied)
        
        #expect(requestEvent == "onboarding_notification_permission_requested")
        #expect(grantedEvent == "onboarding_notification_permission_granted")
        #expect(deniedEvent == "onboarding_notification_permission_denied")
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
    
    // MARK: - Notification Event Tests
    
    @Test("Notification permission events return correct names")
    func notificationPermissionEvents() {
        #expect(mapper.eventName(for: .notificationPermissionRequested) == "notification_permission_requested")
        #expect(mapper.eventName(for: .notificationPermissionGranted) == "notification_permission_granted")
        #expect(mapper.eventName(for: .notificationPermissionDenied) == "notification_permission_denied")
    }
    
    @Test("Notification received event returns correct properties")
    func notificationReceivedEvent() {
        let event = UserActionEvent.notificationReceived(habitId: Self.testHabitId, habitName: Self.testHabitName, source: "daily_reminder")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "notification_received")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["source"] as? String == "daily_reminder")
    }
    
    @Test("Notification action tapped event returns correct properties")
    func notificationActionTappedEvent() {
        let event = UserActionEvent.notificationActionTapped(action: "mark_complete", habitId: Self.testHabitId, habitName: Self.testHabitName, source: "notification_center")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "notification_action_tapped")
        #expect(properties["action"] as? String == "mark_complete")
        #expect(properties["habit_id"] as? String == Self.testHabitId)
        #expect(properties["habit_name"] as? String == Self.testHabitName)
        #expect(properties["source"] as? String == "notification_center")
    }
    
    @Test("Notification scheduled and cancelled events return correct properties")
    func notificationSchedulingEvents() {
        let scheduledEvent = UserActionEvent.notificationScheduled(habitId: Self.testHabitId, habitName: Self.testHabitName, reminderCount: 3)
        let cancelledEvent = UserActionEvent.notificationCancelled(habitId: Self.testHabitId, habitName: Self.testHabitName, reason: "habit_deleted")
        
        let scheduledProps = mapper.eventProperties(for: scheduledEvent)
        let cancelledProps = mapper.eventProperties(for: cancelledEvent)
        
        #expect(scheduledProps["habit_id"] as? String == Self.testHabitId)
        #expect(scheduledProps["reminder_count"] as? Int == 3)
        #expect(cancelledProps["habit_id"] as? String == Self.testHabitId)
        #expect(cancelledProps["reason"] as? String == "habit_deleted")
    }
    
    // MARK: - Category Management Event Tests
    
    @Test("Category created event returns correct properties")
    func categoryCreatedEvent() {
        let event = UserActionEvent.categoryCreated(categoryId: "cat-123", categoryName: "Fitness", emoji: "💪")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "category_created")
        #expect(properties["category_id"] as? String == "cat-123")
        #expect(properties["category_name"] as? String == "Fitness")
        #expect(properties["emoji"] as? String == "💪")
    }
    
    @Test("Category deleted event returns correct properties")
    func categoryDeletedEvent() {
        let event = UserActionEvent.categoryDeleted(categoryId: "cat-123", categoryName: "Fitness", habitsCount: 5)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "category_deleted")
        #expect(properties["category_id"] as? String == "cat-123")
        #expect(properties["category_name"] as? String == "Fitness")
        #expect(properties["habits_count"] as? Int == 5)
    }
    
    @Test("Category reordered event returns correct properties")
    func categoryReorderedEvent() {
        let event = UserActionEvent.categoryReordered(categoryId: "cat-123", fromOrder: 2, toOrder: 0)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "category_reordered")
        #expect(properties["category_id"] as? String == "cat-123")
        #expect(properties["from_order"] as? Int == 2)
        #expect(properties["to_order"] as? Int == 0)
    }
    
    @Test("Category management opened event returns correct name")
    func categoryManagementOpenedEvent() {
        let name = mapper.eventName(for: .categoryManagementOpened)
        #expect(name == "category_management_opened")
    }
    
    // MARK: - Paywall Event Tests
    
    @Test("Paywall shown event returns correct properties")
    func paywallShownEvent() {
        let event = UserActionEvent.paywallShown(source: "habits", trigger: "habit_limit")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "paywall_shown")
        #expect(properties["source"] as? String == "habits")
        #expect(properties["trigger"] as? String == "habit_limit")
    }
    
    @Test("Paywall dismissed event returns correct properties")
    func paywallDismissedEvent() {
        let event = UserActionEvent.paywallDismissed(source: "habits", duration: 15.5)
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "paywall_dismissed")
        #expect(properties["source"] as? String == "habits")
        #expect(properties["duration"] as? TimeInterval == 15.5)
    }
    
    @Test("Product selected event returns correct properties")
    func productSelectedEvent() {
        let event = UserActionEvent.productSelected(productId: "monthly_pro", productName: "Monthly Pro", price: "$4.99")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "product_selected")
        #expect(properties["product_id"] as? String == "monthly_pro")
        #expect(properties["product_name"] as? String == "Monthly Pro")
        #expect(properties["price"] as? String == "$4.99")
    }
    
    @Test("Purchase events return correct properties")
    func purchaseEvents() {
        let attemptedEvent = UserActionEvent.purchaseAttempted(productId: "annual_pro", productName: "Annual Pro", price: "$29.99")
        let completedEvent = UserActionEvent.purchaseCompleted(productId: "annual_pro", productName: "Annual Pro", price: "$29.99", duration: "annual")
        let failedEvent = UserActionEvent.purchaseFailed(productId: "annual_pro", error: "payment_declined")
        
        let attemptedProps = mapper.eventProperties(for: attemptedEvent)
        let completedProps = mapper.eventProperties(for: completedEvent)
        let failedProps = mapper.eventProperties(for: failedEvent)
        
        #expect(mapper.eventName(for: attemptedEvent) == "purchase_attempted")
        #expect(mapper.eventName(for: completedEvent) == "purchase_completed")
        #expect(mapper.eventName(for: failedEvent) == "purchase_failed")
        
        #expect(attemptedProps["product_id"] as? String == "annual_pro")
        #expect(completedProps["duration"] as? String == "annual")
        #expect(failedProps["error"] as? String == "payment_declined")
    }
    
    @Test("Purchase restore events return correct properties")
    func purchaseRestoreEvents() {
        let attemptedEvent = UserActionEvent.purchaseRestoreAttempted
        let completedWithProductEvent = UserActionEvent.purchaseRestoreCompleted(productId: "annual_pro", productName: "Annual Pro")
        let completedWithoutProductEvent = UserActionEvent.purchaseRestoreCompleted(productId: nil, productName: nil)
        let failedEvent = UserActionEvent.purchaseRestoreFailed(error: "no_purchases_found")
        
        #expect(mapper.eventName(for: attemptedEvent) == "purchase_restore_attempted")
        #expect(mapper.eventProperties(for: attemptedEvent).isEmpty)
        
        let completedWithProps = mapper.eventProperties(for: completedWithProductEvent)
        let completedWithoutProps = mapper.eventProperties(for: completedWithoutProductEvent)
        let failedProps = mapper.eventProperties(for: failedEvent)
        
        #expect(completedWithProps["product_id"] as? String == "annual_pro")
        #expect(completedWithProps["product_name"] as? String == "Annual Pro")
        #expect(completedWithoutProps.isEmpty)
        #expect(failedProps["error"] as? String == "no_purchases_found")
    }
    
    // MARK: - Tips Event Tests
    
    @Test("Tips carousel viewed event returns correct name")
    func tipsCarouselViewedEvent() {
        let name = mapper.eventName(for: .tipsCarouselViewed)
        #expect(name == "tips_carousel_viewed")
    }
    
    @Test("Tip viewed event returns correct properties")
    func tipViewedEvent() {
        let event = UserActionEvent.tipViewed(tipId: "tip-123", tipTitle: "Start Small", category: "gettingStarted", source: "carousel")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "tip_viewed")
        #expect(properties["tip_id"] as? String == "tip-123")
        #expect(properties["tip_title"] as? String == "Start Small")
        #expect(properties["category"] as? String == "gettingStarted")
        #expect(properties["source"] as? String == "carousel")
    }
    
    @Test("Tip detail events return correct properties")
    func tipDetailEvents() {
        let openedEvent = UserActionEvent.tipDetailOpened(tipId: "tip-123", tipTitle: "Start Small", category: "gettingStarted", isFeatured: true)
        let closedEvent = UserActionEvent.tipDetailClosed(tipId: "tip-123", tipTitle: "Start Small", timeSpent: 45.2)
        
        let openedProps = mapper.eventProperties(for: openedEvent)
        let closedProps = mapper.eventProperties(for: closedEvent)
        
        #expect(mapper.eventName(for: openedEvent) == "tip_detail_opened")
        #expect(mapper.eventName(for: closedEvent) == "tip_detail_closed")
        
        #expect(openedProps["tip_id"] as? String == "tip-123")
        #expect(openedProps["is_featured"] as? Bool == true)
        #expect(closedProps["time_spent"] as? TimeInterval == 45.2)
    }
    
    @Test("Tips bottom sheet events return correct properties")
    func tipsBottomSheetEvents() {
        let openedEvent = UserActionEvent.tipsBottomSheetOpened(source: "tips_carousel")
        let closedEvent = UserActionEvent.tipsBottomSheetClosed(timeSpent: 120.5)
        
        let openedProps = mapper.eventProperties(for: openedEvent)
        let closedProps = mapper.eventProperties(for: closedEvent)
        
        #expect(mapper.eventName(for: openedEvent) == "tips_bottom_sheet_opened")
        #expect(mapper.eventName(for: closedEvent) == "tips_bottom_sheet_closed")
        
        #expect(openedProps["source"] as? String == "tips_carousel")
        #expect(closedProps["time_spent"] as? TimeInterval == 120.5)
    }
    
    @Test("Tips category filter applied event returns correct properties")
    func tipsCategoryFilterAppliedEvent() {
        let event = UserActionEvent.tipsCategoryFilterApplied(category: "motivation")
        
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)
        
        #expect(name == "tips_category_filter_applied")
        #expect(properties["category"] as? String == "motivation")
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