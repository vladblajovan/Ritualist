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

// Current active schema: V7
public typealias ActiveHabitModel = HabitModelV7
public typealias ActiveHabitLogModel = HabitLogModelV7
public typealias ActiveHabitCategoryModel = HabitCategoryModelV7
public typealias ActiveUserProfileModel = UserProfileModelV7
public typealias ActiveOnboardingStateModel = OnboardingStateModelV7
public typealias ActivePersonalityAnalysisModel = PersonalityAnalysisModelV7

// MARK: - Migration History
//
// Schema Version History:
// - V2: Baseline schema (existing database)
// - V3: Added isPinned property to HabitModel
// - V4: Replaced isPinned with notes property in HabitModel
// - V5: Added lastCompletedDate property to HabitModel
// - V6: Added archivedDate property to HabitModel
// - V7: Added location-aware habit support (locationConfigData, lastGeofenceTriggerDate) (current)
