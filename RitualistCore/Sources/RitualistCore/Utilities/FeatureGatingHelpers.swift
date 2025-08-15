//
//  FeatureGatingHelpers.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 15.08.2025.
//

import Foundation

// MARK: - Feature Gating Helper

public struct FeatureGating {
    /// Standard messaging for when users hit the habit limit
    public static func habitLimitReachedMessage(current: Int, limit: Int) -> String {
        "You've created \(current) of \(limit) habits available on the free plan. Upgrade to Ritualist Pro for unlimited habits and more features."
    }
    
    /// Check if we should show paywall based on habit count and build configuration
    public static func shouldShowPaywallForHabits(currentCount: Int, maxAllowed: Int) -> Bool {
        // Don't show paywall if all features are enabled at build time
        guard BuildConfig.shouldShowPaywalls else { return false }
        return currentCount >= maxAllowed
    }
    
    /// Check if we should show any paywall UI based on build configuration
    public static func shouldShowPaywallUI() -> Bool {
        BuildConfig.shouldShowPaywalls
    }
    
    /// Features included in premium subscription
    public static let premiumFeatures: [String] = [
        "Unlimited habits",
        "Advanced analytics and insights",
        "Custom reminder schedules",
        "Data export to CSV",
        "Premium themes and customization",
        "Priority customer support",
        "Future Pro features included"
    ]
}