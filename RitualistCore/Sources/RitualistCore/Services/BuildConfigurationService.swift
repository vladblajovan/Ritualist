//
//  BuildConfigurationService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 15.08.2025.
//

import Foundation

// MARK: - Build Configuration Detection

/// Defines the build-time configuration for subscription features
public enum BuildConfiguration: Sendable {
    /// All features are enabled for all users (no subscription gating)
    case allFeaturesEnabled
    /// Subscription-based feature gating is active
    case subscriptionBased
    
    /// Current build configuration determined at compile time
    public static let current: BuildConfiguration = {
        #if ALL_FEATURES_ENABLED && SUBSCRIPTION_ENABLED
        #error("Cannot have both ALL_FEATURES_ENABLED and SUBSCRIPTION_ENABLED flags set. Choose exactly one.")
        #elseif ALL_FEATURES_ENABLED
        return .allFeaturesEnabled
        #elseif SUBSCRIPTION_ENABLED
        return .subscriptionBased
        #else
        // Default to subscription-based when building standalone (e.g., Swift Package Manager)
        // The main app should always set explicit flags
        return .subscriptionBased
        #endif
    }()
}

// MARK: - Build Configuration Service Protocol

/// Service for detecting and working with build-time configuration
public protocol BuildConfigurationService: Sendable {
    /// Current build configuration
    var buildConfiguration: BuildConfiguration { get }
    
    /// Whether all features should be enabled regardless of subscription status
    var allFeaturesEnabled: Bool { get }
    
    /// Whether subscription gating should be enforced
    var subscriptionGatingEnabled: Bool { get }
    
    /// Whether paywall UI should be shown
    var shouldShowPaywalls: Bool { get }
}

// MARK: - Default Implementation

public final class DefaultBuildConfigurationService: BuildConfigurationService, Sendable {
    
    public init() {}
    
    public var buildConfiguration: BuildConfiguration {
        BuildConfiguration.current
    }
    
    public var allFeaturesEnabled: Bool {
        buildConfiguration == .allFeaturesEnabled
    }
    
    public var subscriptionGatingEnabled: Bool {
        buildConfiguration == .subscriptionBased
    }
    
    public var shouldShowPaywalls: Bool {
        subscriptionGatingEnabled
    }
}

// MARK: - Build Configuration Helper

public struct BuildConfig {
    /// Quick access to current build configuration
    public static var current: BuildConfiguration {
        BuildConfiguration.current
    }
    
    /// Check if all features are enabled at build time
    public static var allFeaturesEnabled: Bool {
        BuildConfiguration.current == .allFeaturesEnabled
    }
    
    /// Check if subscription gating is enabled at build time
    public static var subscriptionGatingEnabled: Bool {
        BuildConfiguration.current == .subscriptionBased
    }
    
    /// Check if paywall UI should be shown
    public static var shouldShowPaywalls: Bool {
        subscriptionGatingEnabled
    }
    
    /// Debug information about current build configuration
    public static var debugInfo: String {
        switch current {
        case .allFeaturesEnabled:
            return "Build Config: All Features Enabled (no subscription gating)"
        case .subscriptionBased:
            return "Build Config: Subscription Based (paywall gating active)"
        }
    }
}