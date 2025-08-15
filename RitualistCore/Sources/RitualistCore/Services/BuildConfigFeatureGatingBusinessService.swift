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

// MARK: - Convenience Factory

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

// MARK: - Legacy Build Config Feature Gating Service

/// Legacy Feature gating service that respects build-time configuration
/// When all features are enabled at build time, this service grants access to everything
/// When subscription gating is enabled, it delegates to the standard feature gating logic
@available(iOS 17.0, macOS 14.0, *)
@available(*, deprecated, message: "Use FeatureGatingUIService with BuildConfigFeatureGatingBusinessService instead")
@Observable
public final class BuildConfigFeatureGatingService: FeatureGatingService {
    private let buildConfigService: BuildConfigurationService
    private let standardFeatureGating: FeatureGatingService
    
    public init(
        buildConfigService: BuildConfigurationService,
        standardFeatureGating: FeatureGatingService
    ) {
        self.buildConfigService = buildConfigService
        self.standardFeatureGating = standardFeatureGating
    }
    
    // MARK: - FeatureGatingService Implementation
    
    public var maxHabitsAllowed: Int {
        if buildConfigService.allFeaturesEnabled {
            return Int.max
        }
        return standardFeatureGating.maxHabitsAllowed
    }
    
    public func canCreateMoreHabits(currentCount: Int) -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.canCreateMoreHabits(currentCount: currentCount)
    }
    
    public var hasAdvancedAnalytics: Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.hasAdvancedAnalytics
    }
    
    public var hasCustomReminders: Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.hasCustomReminders
    }
    
    public var hasDataExport: Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.hasDataExport
    }
    
    public var hasPremiumThemes: Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.hasPremiumThemes
    }
    
    public var hasPrioritySupport: Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.hasPrioritySupport
    }
    
    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        if buildConfigService.allFeaturesEnabled {
            return "All features are enabled in this build configuration."
        }
        return standardFeatureGating.getFeatureBlockedMessage(for: feature)
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return standardFeatureGating.isFeatureAvailable(feature)
    }
}

// MARK: - Legacy Factory

extension BuildConfigFeatureGatingService {
    /// Legacy factory method - Creates a build config aware feature gating service with standard subscription logic as fallback
    @available(*, deprecated, message: "Use BuildConfigFeatureGatingBusinessService.create instead")
    public static func create(userService: UserService, errorHandler: ErrorHandlingActor? = nil) -> FeatureGatingService {
        let buildConfigService = DefaultBuildConfigurationService()
        let standardFeatureGating = DefaultFeatureGatingService(userService: userService, errorHandler: errorHandler)
        
        return BuildConfigFeatureGatingService(
            buildConfigService: buildConfigService,
            standardFeatureGating: standardFeatureGating
        )
    }
}