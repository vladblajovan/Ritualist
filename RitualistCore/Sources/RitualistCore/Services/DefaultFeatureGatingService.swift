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
    private let userService: UserService
    private let errorHandler: ErrorHandlingActor?
    
    // Free tier limits
    private static let freeMaxHabits = 5
    
    public init(userService: UserService, errorHandler: ErrorHandlingActor? = nil) {
        self.userService = userService
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
    
    public var hasPremiumThemes: Bool {
        isPremiumUser
    }
    
    public var hasPrioritySupport: Bool {
        isPremiumUser
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
        case .premiumThemes:
            return hasPremiumThemes
        case .prioritySupport:
            return hasPrioritySupport
        }
    }
    
    private var isPremiumUser: Bool {
        userService.isPremiumUser
    }
}