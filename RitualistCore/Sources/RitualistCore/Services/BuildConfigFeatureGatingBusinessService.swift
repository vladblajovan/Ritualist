//
//  BuildConfigFeatureGatingBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 15.08.2025.
//

import Foundation
import Observation

// MARK: - Build Config Feature Gating Business Service

/// Feature gating business service that respects build-time configuration
/// When all features are enabled at build time, this service grants access to everything
/// When subscription gating is enabled, it delegates to the standard feature gating logic
public final class BuildConfigFeatureGatingBusinessService: FeatureGatingBusinessService {
    private let buildConfigService: BuildConfigurationService
    private let standardFeatureGating: FeatureGatingBusinessService
    
    public init(
        buildConfigService: BuildConfigurationService,
        standardFeatureGating: FeatureGatingBusinessService
    ) {
        self.buildConfigService = buildConfigService
        self.standardFeatureGating = standardFeatureGating
    }
    
    public var maxHabitsAllowed: Int {
        get async {
            if buildConfigService.allFeaturesEnabled {
                return Int.max
            }
            return await standardFeatureGating.maxHabitsAllowed
        }
    }
    
    public func canCreateMoreHabits(currentCount: Int) async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return await standardFeatureGating.canCreateMoreHabits(currentCount: currentCount)
    }
    
    public var hasAdvancedAnalytics: Bool {
        get async {
            if buildConfigService.allFeaturesEnabled {
                return true
            }
            return await standardFeatureGating.hasAdvancedAnalytics
        }
    }
    
    public var hasCustomReminders: Bool {
        get async {
            if buildConfigService.allFeaturesEnabled {
                return true
            }
            return await standardFeatureGating.hasCustomReminders
        }
    }
    
    public var hasDataExport: Bool {
        get async {
            if buildConfigService.allFeaturesEnabled {
                return true
            }
            return await standardFeatureGating.hasDataExport
        }
    }
    
    public var hasPremiumThemes: Bool {
        get async {
            if buildConfigService.allFeaturesEnabled {
                return true
            }
            return await standardFeatureGating.hasPremiumThemes
        }
    }
    
    public var hasPrioritySupport: Bool {
        get async {
            if buildConfigService.allFeaturesEnabled {
                return true
            }
            return await standardFeatureGating.hasPrioritySupport
        }
    }
    
    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        if buildConfigService.allFeaturesEnabled {
            return "All features are enabled in this build configuration."
        }
        return standardFeatureGating.getFeatureBlockedMessage(for: feature)
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return await standardFeatureGating.isFeatureAvailable(feature)
    }
}

// MARK: - Legacy Factory



extension BuildConfigFeatureGatingBusinessService {
    /// Creates a build config aware feature gating business service with standard subscription logic as fallback
    public static func create(userService: UserService, errorHandler: ErrorHandlingActor? = nil) -> FeatureGatingBusinessService {
        let buildConfigService = DefaultBuildConfigurationService()
        let standardFeatureGating = DefaultFeatureGatingBusinessService(userService: userService, errorHandler: errorHandler)
        
        return BuildConfigFeatureGatingBusinessService(
            buildConfigService: buildConfigService,
            standardFeatureGating: standardFeatureGating
        )
    }
}
