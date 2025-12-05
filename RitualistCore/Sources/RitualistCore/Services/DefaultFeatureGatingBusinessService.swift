//
//  DefaultFeatureGatingBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 15.08.2025.
//

import Foundation

// MARK: - Default Feature Gating Business Service

public final class DefaultFeatureGatingBusinessService: FeatureGatingBusinessService {
    private let subscriptionService: SecureSubscriptionService
    private let errorHandler: ErrorHandler?

    // Free tier limits (using centralized BusinessConstants)
    private static let freeMaxHabits = BusinessConstants.freeMaxHabits

    public init(subscriptionService: SecureSubscriptionService, errorHandler: ErrorHandler? = nil) {
        self.subscriptionService = subscriptionService
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int {
        get async {
            return await isPremiumUser ? Int.max : Self.freeMaxHabits
        }
    }
    
    public func canCreateMoreHabits(currentCount: Int) async -> Bool {
        return await isPremiumUser || currentCount < Self.freeMaxHabits
    }
    
    public var hasAdvancedAnalytics: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasCustomReminders: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasDataExport: Bool {
        get async {
            return await isPremiumUser
        }
    }

    public var hasICloudSync: Bool {
        get async {
            return await isPremiumUser
        }
    }

    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        return FeatureGatingConstants.getFeatureBlockedMessage(for: feature)
    }

    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        switch feature {
        case .unlimitedHabits:
            return await isPremiumUser
        case .advancedAnalytics:
            return await hasAdvancedAnalytics
        case .customReminders:
            return await hasCustomReminders
        case .dataExport:
            return await hasDataExport
        case .iCloudSync:
            return await hasICloudSync
        }
    }
    
    private var isPremiumUser: Bool {
        get async {
            return await subscriptionService.isPremiumUser()
        }
    }
}
