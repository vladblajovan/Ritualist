//
//  FeatureGatingBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

/// Thread-agnostic business logic for feature gating
public protocol FeatureGatingBusinessService {
    /// Maximum number of habits allowed for the current user
    var maxHabitsAllowed: Int { get async }
    
    /// Whether the user can create more habits
    func canCreateMoreHabits(currentCount: Int) async -> Bool
    
    /// Whether advanced analytics are available
    var hasAdvancedAnalytics: Bool { get async }
    
    /// Whether custom reminders are available
    var hasCustomReminders: Bool { get async }
    
    /// Whether data export is available
    var hasDataExport: Bool { get async }
    
    /// Whether premium themes are available
    var hasPremiumThemes: Bool { get async }
    
    /// Whether priority support is available
    var hasPrioritySupport: Bool { get async }
    
    /// Get a user-friendly message when a feature is blocked
    func getFeatureBlockedMessage(for feature: FeatureType) -> String
    
    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: FeatureType) async -> Bool
}