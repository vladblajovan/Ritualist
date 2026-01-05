//
//  BuildConfigFeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation
import Observation

/// Feature gating service that respects build-time configuration
/// When all features are enabled at build time, this service grants access to everything
/// When subscription gating is enabled, it delegates to the standard feature gating logic
@available(iOS 17.0, macOS 14.0, *)
public final class BuildConfigFeatureGatingService: FeatureGatingService, Sendable {
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

    public func maxHabitsAllowed() async -> Int {
        if buildConfigService.allFeaturesEnabled {
            return Int.max
        }
        return await standardFeatureGating.maxHabitsAllowed()
    }

    public func canCreateMoreHabits(currentCount: Int) async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return await standardFeatureGating.canCreateMoreHabits(currentCount: currentCount)
    }

    public func hasAdvancedAnalytics() async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return await standardFeatureGating.hasAdvancedAnalytics()
    }

    public func hasCustomReminders() async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return await standardFeatureGating.hasCustomReminders()
    }

    public func hasDataExport() async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return true
        }
        return await standardFeatureGating.hasDataExport()
    }

    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
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

    public func isOverActiveHabitLimit(activeCount: Int) async -> Bool {
        if buildConfigService.allFeaturesEnabled {
            return false
        }
        return await standardFeatureGating.isOverActiveHabitLimit(activeCount: activeCount)
    }
}
