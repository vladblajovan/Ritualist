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
        FeatureGatingConstants.getFeatureBlockedMessage(for: feature)
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

    private func isPremiumUser() async -> Bool {
        await subscriptionService.isPremiumUser()
    }
}