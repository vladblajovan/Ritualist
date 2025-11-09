//
//  DefaultFeatureGatingBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 15.08.2025.
//

import Foundation

// MARK: - Default Feature Gating Business Service

public final class DefaultFeatureGatingBusinessService: FeatureGatingBusinessService {
    private let userService: UserService
    private let errorHandler: ErrorHandler?
    
    // Free tier limits (using centralized BusinessConstants)
    private static let freeMaxHabits = BusinessConstants.freeMaxHabits
    
    public init(userService: UserService, errorHandler: ErrorHandler? = nil) {
        self.userService = userService
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
    
    public var hasPremiumThemes: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasPrioritySupport: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        switch feature {
        case .unlimitedHabits:
            return "You've reached the limit of \(Self.freeMaxHabits) habits on the free plan. Upgrade to Pro to track unlimited habits."
        case .advancedAnalytics:
            return "Advanced analytics are available with Ritualist Pro. Get detailed insights into your habit patterns."
        case .customReminders:
            return "Custom reminder times are a Pro feature. Upgrade to set personalized notification schedules."
        case .dataExport:
            return "Export your habit data with Ritualist Pro. Download your progress as CSV files."
        case .premiumThemes:
            return "Premium themes and customization options are available with Pro."
        case .prioritySupport:
            return "Get faster support response times with Ritualist Pro."
        }
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
        case .premiumThemes:
            return await hasPremiumThemes
        case .prioritySupport:
            return await hasPrioritySupport
        }
    }
    
    private var isPremiumUser: Bool {
        get async {
            return userService.isPremiumUser
        }
    }
}
