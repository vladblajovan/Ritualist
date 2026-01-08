//
//  FeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

public protocol FeatureGatingService: Sendable {
    /// Maximum number of habits allowed for the current user
    func maxHabitsAllowed() async -> Int

    /// Whether the user can create more habits
    func canCreateMoreHabits(currentCount: Int) async -> Bool

    /// Whether advanced analytics are available
    func hasAdvancedAnalytics() async -> Bool

    /// Whether custom reminders are available
    func hasCustomReminders() async -> Bool

    /// Whether data export is available
    func hasDataExport() async -> Bool

    /// Get a user-friendly message when a feature is blocked
    func getFeatureBlockedMessage(for feature: FeatureType) -> String

    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: FeatureType) async -> Bool

    /// Check if user has exceeded the active habit limit for free tier
    /// Returns true if user is non-premium AND has more than freeMaxHabits active habits
    func isOverActiveHabitLimit(activeCount: Int) async -> Bool
}
