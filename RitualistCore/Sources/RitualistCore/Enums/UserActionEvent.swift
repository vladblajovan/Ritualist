//
//  UserActionEvent.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public enum UserActionEvent {
    // Onboarding & Setup
    case onboardingStarted
    case onboardingCompleted
    case onboardingSkipped
    case onboardingPageViewed(page: Int, pageName: String)
    case onboardingPageNext(fromPage: Int, toPage: Int)
    case onboardingPageBack(fromPage: Int, toPage: Int)
    case onboardingUserNameEntered(hasName: Bool)
    case onboardingNotificationPermissionRequested
    case onboardingNotificationPermissionGranted
    case onboardingNotificationPermissionDenied
    
    // Habits Assistant
    case habitsAssistantOpened(source: HabitsAssistantSource)
    case habitsAssistantClosed
    case habitsAssistantCategorySelected(category: String)
    case habitsAssistantCategoryCleared
    case habitsAssistantHabitSuggestionViewed(habitId: String, category: String)
    case habitsAssistantHabitAdded(habitId: String, habitName: String, category: String)
    case habitsAssistantHabitAddFailed(habitId: String, error: String)
    case habitsAssistantHabitRemoved(habitId: String, habitName: String, category: String)
    case habitsAssistantHabitRemoveFailed(habitId: String, error: String)
    
    // Habit Management
    case habitCreated(habitId: String, habitName: String, habitType: String)
    case habitUpdated(habitId: String, habitName: String)
    case habitDeleted(habitId: String, habitName: String)
    case habitArchived(habitId: String, habitName: String)
    case habitRestored(habitId: String, habitName: String)
    
    // Habit Tracking
    case habitLogged(habitId: String, habitName: String, date: Date, logType: String, value: Double?)
    case habitLogDeleted(habitId: String, habitName: String, date: Date)
    case habitLogUpdated(habitId: String, habitName: String, date: Date, oldValue: Double?, newValue: Double?)
    case habitStreakAchieved(habitId: String, habitName: String, streakLength: Int)
    
    // Navigation
    case screenViewed(screen: String)
    case tabSwitched(from: String, to: String)
    
    // Notifications
    case notificationPermissionRequested
    case notificationPermissionGranted
    case notificationPermissionDenied
    case notificationReceived(habitId: String, habitName: String, source: String)
    case notificationActionTapped(action: String, habitId: String, habitName: String, source: String)
    case notificationScheduled(habitId: String, habitName: String, reminderCount: Int)
    case notificationCancelled(habitId: String, habitName: String, reason: String)
    
    // Category Management
    case categoryCreated(categoryId: String, categoryName: String, emoji: String)
    case categoryUpdated(categoryId: String, categoryName: String)
    case categoryDeleted(categoryId: String, categoryName: String, habitsCount: Int)
    case categoryReordered(categoryId: String, fromOrder: Int, toOrder: Int)
    case categoryManagementOpened
    
    // Paywall & Purchases
    case paywallShown(source: String, trigger: String)
    case paywallDismissed(source: String, duration: TimeInterval)
    case productSelected(productId: String, productName: String, price: String)
    case purchaseAttempted(productId: String, productName: String, price: String)
    case purchaseCompleted(productId: String, productName: String, price: String, duration: String)
    case purchaseFailed(productId: String, error: String)
    case purchaseRestoreAttempted
    case purchaseRestoreCompleted(productId: String?, productName: String?)
    case purchaseRestoreFailed(error: String)
    
    // Tips & Engagement
    case tipsCarouselViewed
    case tipViewed(tipId: String, tipTitle: String, category: String, source: String)
    case tipDetailOpened(tipId: String, tipTitle: String, category: String, isFeatured: Bool)
    case tipDetailClosed(tipId: String, tipTitle: String, timeSpent: TimeInterval)
    case tipsBottomSheetOpened(source: String)
    case tipsBottomSheetClosed(timeSpent: TimeInterval)
    case tipsCategoryFilterApplied(category: String)
    
    // Settings & Profile
    case settingsOpened
    case profileUpdated(field: String)
    case notificationSettingsChanged(enabled: Bool)
    case appearanceChanged(theme: String)
    
    // Errors & Performance
    case errorOccurred(error: String, context: String)
    case crashReported(error: String)
    case performanceMetric(metric: String, value: Double, unit: String)
    
    // Custom Events
    case custom(event: String, parameters: [String: Any])
}