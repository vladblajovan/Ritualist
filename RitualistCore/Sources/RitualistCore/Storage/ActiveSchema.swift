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

// Current active schema: V6
public typealias ActiveHabitModel = HabitModelV6
public typealias ActiveHabitLogModel = HabitLogModelV6
public typealias ActiveHabitCategoryModel = HabitCategoryModelV6
public typealias ActiveUserProfileModel = UserProfileModelV6
public typealias ActiveOnboardingStateModel = OnboardingStateModelV6
public typealias ActivePersonalityAnalysisModel = PersonalityAnalysisModelV6

// MARK: - Migration History
//
// Schema Version History:
// - V2: Baseline schema (existing database)
// - V3: Added isPinned property to HabitModel
// - V4: Replaced isPinned with notes property in HabitModel
// - V5: Added lastCompletedDate property to HabitModel
// - V6: Added archivedDate property to HabitModel (current)
//
// When V5 is added, uncomment and update:
// - V5: [Description of changes]
// public typealias ActiveHabitModel = HabitModelV5
// ... (update all other type aliases)
