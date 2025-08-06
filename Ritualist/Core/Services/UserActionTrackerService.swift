//
//  UserActionTracker.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 30.07.2025.
//

import Foundation

// MARK: - User Action Events

public enum UserActionEvent {
    // Onboarding & Setup
    case onboardingStarted
    case onboardingCompleted
    case onboardingSkipped
    case onboardingPageViewed(page: Int)
    
    // Habits Assistant
    case habitsAssistantOpened(source: HabitsAssistantSource)
    case habitsAssistantClosed
    case habitsAssistantCategorySelected(category: String)
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

public enum HabitsAssistantSource: String, CaseIterable {
    case onboarding
    case habitsPage = "habits_page"
    case emptyState = "empty_state"
}

// MARK: - User Action Tracker Protocol

public protocol UserActionTrackerService {
    /// Track a user action event
    func track(_ event: UserActionEvent)
    
    /// Track a user action event with additional context
    func track(_ event: UserActionEvent, context: [String: Any])
    
    /// Set user properties (for analytics segmentation)
    func setUserProperty(key: String, value: Any)
    
    /// Identify the user (when user creates account or logs in)
    func identifyUser(userId: String, properties: [String: Any]?)
    
    /// Reset user identity (on logout)
    func resetUser()
    
    /// Enable/disable tracking (for privacy compliance)
    func setTrackingEnabled(_ enabled: Bool)
    
    /// Flush any pending events (useful before app backgrounding)
    func flush()
}

// MARK: - Default Implementation (No-op)

public final class NoOpUserActionTrackerService: UserActionTrackerService {
    public init() {}
    
    public func track(_ event: UserActionEvent) {
        // No-op implementation for when no tracking provider is configured
    }
    
    public func track(_ event: UserActionEvent, context: [String: Any]) {
        // No-op implementation
    }
    
    public func setUserProperty(key: String, value: Any) {
        // No-op implementation
    }
    
    public func identifyUser(userId: String, properties: [String: Any]?) {
        // No-op implementation
    }
    
    public func resetUser() {
        // No-op implementation
    }
    
    public func setTrackingEnabled(_ enabled: Bool) {
        // No-op implementation
    }
    
    public func flush() {
        // No-op implementation
    }
}

// MARK: - Debug Implementation (Console Logging)

public final class DebugUserActionTrackerService: UserActionTrackerService {
    private var isTrackingEnabled = true
    private var userProperties: [String: Any] = [:]
    private var currentUserId: String?
    
    private let eventMapper = UserActionEventMapper()
    private let logger = DebugLogger()
    
    public init() {}
    
    public func track(_ event: UserActionEvent) {
        track(event, context: [:])
    }
    
    public func track(_ event: UserActionEvent, context: [String: Any]) {
        guard isTrackingEnabled else { return }
        
        let eventName = eventMapper.eventName(for: event)
        var eventProperties = eventMapper.eventProperties(for: event)
        
        // Merge context into properties
        for (key, value) in context {
            eventProperties[key] = value
        }
        
        logger.logEvent(
            name: eventName,
            properties: eventProperties,
            userId: currentUserId,
            userProperties: userProperties
        )
    }
    
    public func setUserProperty(key: String, value: Any) {
        guard isTrackingEnabled else { return }
        userProperties[key] = value
        logger.logUserProperty(key: key, value: value)
    }
    
    public func identifyUser(userId: String, properties: [String: Any]?) {
        guard isTrackingEnabled else { return }
        currentUserId = userId
        if let properties = properties {
            for (key, value) in properties {
                userProperties[key] = value
            }
        }
        logger.logUserIdentified(userId: userId, properties: properties)
    }
    
    public func resetUser() {
        guard isTrackingEnabled else { return }
        currentUserId = nil
        userProperties.removeAll()
        logger.logUserReset()
    }
    
    public func setTrackingEnabled(_ enabled: Bool) {
        isTrackingEnabled = enabled
        logger.logTrackingStateChanged(enabled: enabled)
    }
    
    public func flush() {
        guard isTrackingEnabled else { return }
        logger.logFlushRequested()
    }
}
