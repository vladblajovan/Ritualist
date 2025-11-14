//
//  FeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

public protocol FeatureGatingService {
    /// Maximum number of habits allowed for the current user
    var maxHabitsAllowed: Int { get }
    
    /// Whether the user can create more habits
    func canCreateMoreHabits(currentCount: Int) -> Bool
    
    /// Whether advanced analytics are available
    var hasAdvancedAnalytics: Bool { get }
    
    /// Whether custom reminders are available
    var hasCustomReminders: Bool { get }
    
    /// Whether data export is available
    var hasDataExport: Bool { get }

    /// Get a user-friendly message when a feature is blocked
    func getFeatureBlockedMessage(for feature: FeatureType) -> String
    
    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: FeatureType) -> Bool
}
