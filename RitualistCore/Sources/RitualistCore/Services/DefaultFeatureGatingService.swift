//
//  DefaultFeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation
import Observation

@available(iOS 17.0, macOS 14.0, *)
public final class DefaultFeatureGatingService: FeatureGatingService, Sendable {
    private let subscriptionService: SecureSubscriptionService
    private let errorHandler: ErrorHandler?

    // Free tier limits (using centralized BusinessConstants)
    private static let freeMaxHabits = BusinessConstants.freeMaxHabits

    public init(subscriptionService: SecureSubscriptionService, errorHandler: ErrorHandler? = nil) {
        self.subscriptionService = subscriptionService
        self.errorHandler = errorHandler
    }

    public func maxHabitsAllowed() async -> Int {
        await isPremiumUser() ? Int.max : Self.freeMaxHabits
    }

    public func canCreateMoreHabits(currentCount: Int) async -> Bool {
        await isPremiumUser() || currentCount < Self.freeMaxHabits
    }

    public func hasAdvancedAnalytics() async -> Bool {
        await isPremiumUser()
    }

    public func hasCustomReminders() async -> Bool {
        await isPremiumUser()
    }

    public func hasDataExport() async -> Bool {
        await isPremiumUser()
    }

    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        switch feature {
        case .unlimitedHabits:
            return "You've reached the limit of \(BusinessConstants.freeMaxHabits) habits on the free plan. Upgrade to Pro to track unlimited habits."
        case .advancedAnalytics:
            return "Advanced analytics are available with Ritualist Pro. Get detailed insights into your habit patterns."
        case .customReminders:
            return "Custom reminder times are a Pro feature. Upgrade to set personalized notification schedules."
        case .dataExport:
            return "Export your habit data with Ritualist Pro. Download your progress as CSV files."
        }
    }

    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        switch feature {
        case .unlimitedHabits:
            return await isPremiumUser()
        case .advancedAnalytics:
            return await hasAdvancedAnalytics()
        case .customReminders:
            return await hasCustomReminders()
        case .dataExport:
            return await hasDataExport()
        }
    }

    public func isOverActiveHabitLimit(activeCount: Int) async -> Bool {
        // Premium users are never over the limit
        if await isPremiumUser() {
            return false
        }
        // Free users are over limit if they have more than freeMaxHabits
        return activeCount > Self.freeMaxHabits
    }

    private func isPremiumUser() async -> Bool {
        await subscriptionService.isPremiumUser()
    }
}