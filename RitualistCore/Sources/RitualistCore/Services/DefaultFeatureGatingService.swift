//
//  DefaultFeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation
import Observation

@available(iOS 17.0, macOS 14.0, *)
@available(*, deprecated, message: "Use FeatureGatingUIService instead")
@Observable
public final class DefaultFeatureGatingService: FeatureGatingService {
    private let subscriptionService: SecureSubscriptionService
    private let errorHandler: ErrorHandler?

    // Free tier limits (using centralized BusinessConstants)
    private static let freeMaxHabits = BusinessConstants.freeMaxHabits

    public init(subscriptionService: SecureSubscriptionService, errorHandler: ErrorHandler? = nil) {
        self.subscriptionService = subscriptionService
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int {
        isPremiumUser ? Int.max : Self.freeMaxHabits
    }
    
    public func canCreateMoreHabits(currentCount: Int) -> Bool {
        isPremiumUser || currentCount < Self.freeMaxHabits
    }
    
    public var hasAdvancedAnalytics: Bool {
        isPremiumUser
    }
    
    public var hasCustomReminders: Bool {
        isPremiumUser
    }
    
    public var hasDataExport: Bool {
        isPremiumUser
    }

    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        return FeatureGatingConstants.getFeatureBlockedMessage(for: feature)
    }

    public func isFeatureAvailable(_ feature: FeatureType) -> Bool {
        switch feature {
        case .unlimitedHabits:
            return isPremiumUser
        case .advancedAnalytics:
            return hasAdvancedAnalytics
        case .customReminders:
            return hasCustomReminders
        case .dataExport:
            return hasDataExport
        }
    }
    
    private var isPremiumUser: Bool {
        subscriptionService.isPremiumUser()
    }
}