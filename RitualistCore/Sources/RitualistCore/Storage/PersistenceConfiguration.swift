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
/// ## iCloud Available (Two Stores)
/// When iCloud is available, entities are split into two storage tiers:
/// - **CloudKit Store**: Synced across user's devices via iCloud
/// - **Local Store**: Stays on-device only for privacy-sensitive data
///
/// ## iCloud NOT Available (Two Stores, No Sync)
/// When iCloud is NOT available, we still use dual stores but disable CloudKit sync.
/// This ensures PersonalityAnalysis ALWAYS stays in Local.store and never syncs.
///
/// ## Data Continuity
/// Store file names are kept consistent ("CloudKit", "Local") regardless of iCloud
/// availability. This ensures that if a user temporarily loses iCloud access,
/// their existing data remains accessible. The only difference is whether
/// CloudKit sync is enabled on the CloudKit store.
///
/// ## Privacy Policy
/// PersonalityAnalysisModel is kept local-only because personality trait data
/// is sensitive information that should not leave the user's device.
public enum PersistenceConfiguration {

    // MARK: - iCloud Detection

    /// Check if iCloud is available (synchronous check)
    /// Uses ubiquityIdentityToken which is nil when user is not signed into iCloud
    public static var isICloudAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - All Entity Types

    /// All entity types in the schema
    /// Used for single-store configuration when iCloud is not available
    public static var allTypes: [any PersistentModel.Type] {
        [
            ActiveHabitModel.self,
            ActiveHabitLogModel.self,
            ActiveHabitCategoryModel.self,
            ActiveUserProfileModel.self,
            ActiveOnboardingStateModel.self,
            ActivePersonalityAnalysisModel.self
        ]
    }

    // MARK: - CloudKit Synced Entities

    /// Entities that sync to iCloud private database (when iCloud is available)
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

    // MARK: - Configuration Builders (iCloud Available)

    /// ModelConfiguration for CloudKit-synced entities (iCloud available)
    /// Uses CloudKit private database for cross-device sync
    private static var cloudKitSyncConfiguration: ModelConfiguration {
        ModelConfiguration(
            PersistenceStoreNames.cloudKit,
            schema: Schema(cloudKitSyncedTypes),
            cloudKitDatabase: .private(iCloudConstants.containerIdentifier)
        )
    }

    /// ModelConfiguration for local-only entities (iCloud available)
    /// Personality data stays on-device for privacy
    private static var localOnlyConfiguration: ModelConfiguration {
        ModelConfiguration(
            PersistenceStoreNames.local,
            schema: Schema(localOnlyTypes),
            cloudKitDatabase: .none
        )
    }

    // MARK: - Configuration Builders (iCloud NOT Available)

    /// CloudKit store WITHOUT sync - used when iCloud is not available
    ///
    /// CRITICAL DESIGN DECISIONS:
    /// 1. Uses "CloudKit" as the store name to maintain data continuity with existing data
    /// 2. Includes all SYNCABLE entity types (same as cloudKitSyncedTypes)
    /// 3. Disables CloudKit sync (cloudKitDatabase: .none)
    ///
    /// This ensures:
    /// - Users who temporarily lose iCloud access can still see their data
    /// - SwiftData can resolve relationships (HabitModel ↔ HabitLogModel)
    /// - Data created while offline will sync when iCloud becomes available again
    private static var cloudKitLocalOnlyConfiguration: ModelConfiguration {
        ModelConfiguration(
            PersistenceStoreNames.cloudKit,  // Same name as iCloud config for data continuity
            schema: Schema(cloudKitSyncedTypes),
            cloudKitDatabase: .none
        )
    }

    // MARK: - All Configurations

    /// All model configurations for the persistence container
    ///
    /// ALWAYS uses dual-store architecture for privacy consistency:
    /// - **CloudKit store**: Habits, logs, categories, profile, onboarding
    /// - **Local store**: PersonalityAnalysis (NEVER synced to iCloud)
    ///
    /// The only difference based on iCloud availability:
    /// - **iCloud Available**: CloudKit store syncs to iCloud
    /// - **iCloud NOT Available**: CloudKit store is local-only (no sync)
    ///
    /// This ensures PersonalityAnalysis data ALWAYS stays in Local.store and
    /// never accidentally gets synced to iCloud, even if user starts without
    /// iCloud and later enables it.
    ///
    /// Note: PersonalityAnalysisModel has NO relationships to other models,
    /// so it can safely be in a separate store without relationship resolution issues.
    public static var allConfigurations: [ModelConfiguration] {
        if isICloudAvailable {
            // CloudKit store syncs to iCloud, Local store stays on device
            return [cloudKitSyncConfiguration, localOnlyConfiguration]
        } else {
            // CloudKit store is local-only (no sync), Local store stays on device
            // Both stores use same file names for data continuity
            return [cloudKitLocalOnlyConfiguration, localOnlyConfiguration]
        }
    }
}
