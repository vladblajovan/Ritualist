//
//  PersistenceConfiguration.swift
//  RitualistCore
//
//  Centralized configuration for data storage locations.
//  Defines which entities sync to CloudKit vs stay local-only.
//

import Foundation
import SwiftData

// MARK: - Persistence Configuration

/// Configuration for data persistence storage locations
///
/// Separates entities into two storage tiers:
/// - **CloudKit**: Synced across user's devices via iCloud
/// - **Local**: Stays on-device only for privacy-sensitive data
///
/// ## Privacy Policy
/// PersonalityAnalysisModel is kept local-only because personality trait data
/// is sensitive information that should not leave the user's device.
public enum PersistenceConfiguration {

    // MARK: - CloudKit Synced Entities

    /// Entities that sync to iCloud private database
    ///
    /// These entities are synced across all user devices:
    /// - HabitModel: User's habits and their configuration
    /// - HabitLogModel: Completion records for habits
    /// - HabitCategoryModel: Custom habit categories
    /// - UserProfileModel: User preferences and settings
    /// - OnboardingStateModel: Onboarding completion status
    public static var cloudKitSyncedTypes: [any PersistentModel.Type] {
        [
            ActiveHabitModel.self,
            ActiveHabitLogModel.self,
            ActiveHabitCategoryModel.self,
            ActiveUserProfileModel.self,
            ActiveOnboardingStateModel.self
        ]
    }

    /// ModelConfiguration for CloudKit-synced entities
    public static var cloudKitConfiguration: ModelConfiguration {
        ModelConfiguration(
            "CloudKit",
            schema: Schema(cloudKitSyncedTypes),
            cloudKitDatabase: .private(iCloudConstants.containerIdentifier)
        )
    }

    // MARK: - Local-Only Entities

    /// Entities that stay on-device only (privacy-sensitive)
    ///
    /// These entities are NOT synced to iCloud:
    /// - PersonalityAnalysisModel: Big Five personality trait analysis results
    ///
    /// Kept local for privacy reasons per app privacy policy.
    public static var localOnlyTypes: [any PersistentModel.Type] {
        [
            ActivePersonalityAnalysisModel.self
        ]
    }

    /// ModelConfiguration for local-only entities
    public static var localConfiguration: ModelConfiguration {
        ModelConfiguration(
            "Local",
            schema: Schema(localOnlyTypes),
            cloudKitDatabase: .none
        )
    }

    // MARK: - All Configurations

    /// All model configurations for the persistence container
    public static var allConfigurations: [ModelConfiguration] {
        [cloudKitConfiguration, localConfiguration]
    }
}
