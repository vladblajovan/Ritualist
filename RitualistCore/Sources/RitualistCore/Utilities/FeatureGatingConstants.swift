//
//  FeatureGatingConstants.swift
//  RitualistCore
//
//  Created by Claude Code on 15/11/2025.
//  Phase 2, Week 4: Shared Utilities Extraction
//

import Foundation

/// Centralized constants for feature gating messages and configuration
///
/// This provides a single source of truth for premium feature messaging,
/// making it easier to maintain consistency and update copy across the app.
public enum FeatureGatingConstants {

    // MARK: - Feature Blocked Messages

    /// Get the user-facing message explaining why a feature is blocked
    /// - Parameter feature: The feature type that is blocked
    /// - Returns: A localized message explaining the feature and how to unlock it
    public static func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        switch feature {
        case .unlimitedHabits:
            return Messages.unlimitedHabits
        case .advancedAnalytics:
            return Messages.advancedAnalytics
        case .customReminders:
            return Messages.customReminders
        case .dataExport:
            return Messages.dataExport
        }
    }

    // MARK: - Messages

    /// Premium feature blocked messages
    private enum Messages {
        /// Message shown when user tries to create more than the free limit of habits
        static let unlimitedHabits = "You've reached the limit of \(BusinessConstants.freeMaxHabits) habits on the free plan. Upgrade to Pro to track unlimited habits."

        /// Message shown when user tries to access advanced analytics
        static let advancedAnalytics = "Advanced analytics are available with Ritualist Pro. Get detailed insights into your habit patterns."

        /// Message shown when user tries to set custom reminder times
        static let customReminders = "Custom reminder times are a Pro feature. Upgrade to set personalized notification schedules."

        /// Message shown when user tries to export their data
        static let dataExport = "Export your habit data with Ritualist Pro. Download your progress as CSV files."
    }
}
