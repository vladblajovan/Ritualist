//
//  ActiveSchema.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 03.11.2025.
//
//  Centralized definition of the active schema version.
//  When migrating to a new schema, only update the type aliases in this file.
//

import Foundation
import SwiftData

// MARK: - Active Schema Type Aliases

/// Current active schema version - UPDATE THIS WHEN MIGRATING TO A NEW SCHEMA
///
/// When adding a new schema version (e.g., SchemaV12):
/// 1. Create SchemaV12.swift with new schema definitions
/// 2. Update MigrationPlan to include SchemaV12 and migration stage
/// 3. Update `ActiveSchemaVersion` below to point to SchemaV12
/// 4. All type aliases and PersistenceContainer automatically use the new schema!

// MARK: - Active Schema Reference (SINGLE SOURCE OF TRUTH)

/// The current active schema - UPDATE THIS SINGLE LINE WHEN MIGRATING
/// NOTE: Reverted from V12 to V11 because V12 had identical checksum (no schema changes)
/// SwiftData crashes when two schemas have the same checksum in migration plan
public typealias ActiveSchemaVersion = SchemaV11

// MARK: - Model Type Aliases (derived from ActiveSchemaVersion)

public typealias ActiveHabitModel = ActiveSchemaVersion.HabitModel
public typealias ActiveHabitLogModel = ActiveSchemaVersion.HabitLogModel
public typealias ActiveHabitCategoryModel = ActiveSchemaVersion.HabitCategoryModel
public typealias ActiveUserProfileModel = ActiveSchemaVersion.UserProfileModel
public typealias ActiveOnboardingStateModel = ActiveSchemaVersion.OnboardingStateModel
public typealias ActivePersonalityAnalysisModel = ActiveSchemaVersion.PersonalityAnalysisModel

// MARK: - Migration History
//
// Schema Version History:
// - V2: Baseline schema (existing database)
// - V3: Added isPinned property to HabitModel
// - V4: Replaced isPinned with notes property in HabitModel
// - V5: Added lastCompletedDate property to HabitModel
// - V6: Added archivedDate property to HabitModel
// - V7: Added location-aware habit support (locationConfigData, lastGeofenceTriggerDate)
// - V8: Removed subscription fields from UserProfileModel (subscriptionPlan, subscriptionExpiryDate)
// - V9: Three-Timezone Model (currentTimezoneIdentifier, homeTimezoneIdentifier, displayTimezoneModeData, timezoneChangeHistoryData)
// - V10: CloudKit compatibility (removed .unique constraints, optional relationship arrays, default values)
// - V11: User Demographics (gender, ageGroup in UserProfileModel) (current)
// - V12: REMOVED - had identical checksum to V11, caused SwiftData migration crash
