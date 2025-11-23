//
//  ActiveSchema.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Centralized definition of the active schema version.
//  When migrating to a new schema, only update the type aliases in this file.
//

import Foundation
import SwiftData

// MARK: - Active Schema Type Aliases

/// Current active schema version - UPDATE THIS WHEN MIGRATING TO A NEW SCHEMA
///
/// When adding a new schema version (e.g., SchemaV7):
/// 1. Create SchemaV7.swift with new schema definitions
/// 2. Update MigrationPlan to include SchemaV7 and migration stage
/// 3. Update PersistenceContainer to use SchemaV7
/// 4. Update these type aliases below to point to V7 types
/// 5. All data sources will automatically use the new schema!

// Current active schema: V10 (CloudKit compatible)
public typealias ActiveHabitModel = HabitModelV10
public typealias ActiveHabitLogModel = HabitLogModelV10
public typealias ActiveHabitCategoryModel = HabitCategoryModelV10
public typealias ActiveUserProfileModel = UserProfileModelV10
public typealias ActiveOnboardingStateModel = OnboardingStateModelV10
public typealias ActivePersonalityAnalysisModel = PersonalityAnalysisModelV10

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
// - V10: CloudKit compatibility (removed .unique constraints, optional relationship arrays, default values) (current)
