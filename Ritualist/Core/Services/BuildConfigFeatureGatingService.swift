import Foundation
import Observation

// MARK: - Build Config Feature Gating Service

/// Feature gating service that respects build-time configuration
/// When all features are enabled at build time, this service grants access to everything
/// When subscription gating is enabled, it delegates to the standard feature gating logic
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
    
    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
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

// MARK: - Convenience Factory

extension BuildConfigFeatureGatingService {
    /// Creates a build config aware feature gating service with standard subscription logic as fallback
    public static func create(userService: UserService) -> FeatureGatingService {
        let buildConfigService = DefaultBuildConfigurationService()
        let standardFeatureGating = DefaultFeatureGatingService(userService: userService)
        
        return BuildConfigFeatureGatingService(
            buildConfigService: buildConfigService,
            standardFeatureGating: standardFeatureGating
        )
    }
}