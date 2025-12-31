//
//  SchemaV12Tests.swift
//  RitualistTests
//
//  Created by Claude on 26.12.2025.
//
//  Unit tests for SchemaV12 file (retained for reference but not in migration plan).
//  V12 was removed from migration plan due to identical checksum with V11.
//

import Testing
import Foundation
import SwiftData
@testable import RitualistCore

@Suite("SchemaV12 Tests", .tags(.database, .fast))
@MainActor
struct SchemaV12Tests {

    // MARK: - Schema Version Tests
    // NOTE: V12 file exists but is NOT in the migration plan
    // These tests verify the file still compiles correctly

    @Test("Schema version is 12.0.0")
    func schemaVersionIsCorrect() {
        let version = SchemaV12.versionIdentifier
        #expect(version == Schema.Version(12, 0, 0))
    }

    @Test("Schema contains all 6 models")
    func schemaContainsAllModels() {
        let models = SchemaV12.models
        #expect(models.count == 6)
    }

    @Test("ActiveSchemaVersion points to V11 (V12 removed due to checksum collision)")
    func activeSchemaIsV11() {
        // V12 was removed from migration plan because it had identical checksum to V11
        // SwiftData's NSLightweightMigrationStage requires unique checksums per version
        #expect(ActiveSchemaVersion.versionIdentifier == Schema.Version(11, 0, 0))
    }

    // MARK: - Migration Plan Tests

    @Test("MigrationPlan does NOT include SchemaV12 (removed due to checksum collision)")
    func migrationPlanExcludesV12() {
        let schemas = RitualistMigrationPlan.schemas
        let hasV12 = schemas.contains { $0.versionIdentifier == Schema.Version(12, 0, 0) }
        #expect(!hasV12, "V12 should NOT be in migration plan - identical checksum to V11 causes crash")
    }

    @Test("MigrationPlan has 9 migration stages (V2→V3 through V10→V11)")
    func migrationPlanHasCorrectStageCount() {
        let stages = RitualistMigrationPlan.stages
        #expect(stages.count == 9) // V2→V3 through V10→V11 (V11→V12 removed)
    }

    @Test("Current schema version is V11")
    func currentSchemaVersionIsV11() {
        let currentVersion = RitualistMigrationPlan.currentSchemaVersion
        #expect(currentVersion == Schema.Version(11, 0, 0))
    }

    // MARK: - Model Type Alias Tests (V12 types still exist in file)

    @Test("V12 type aliases still resolve correctly")
    func typeAliasesPointToV12() {
        // V12 file exists for historical reference, types still compile
        let habitModel = HabitModelV12.self
        let habitLogModel = HabitLogModelV12.self
        let categoryModel = HabitCategoryModelV12.self
        let profileModel = UserProfileModelV12.self
        let onboardingModel = OnboardingStateModelV12.self
        let personalityModel = PersonalityAnalysisModelV12.self

        #expect(habitModel == SchemaV12.HabitModel.self)
        #expect(habitLogModel == SchemaV12.HabitLogModel.self)
        #expect(categoryModel == SchemaV12.HabitCategoryModel.self)
        #expect(profileModel == SchemaV12.UserProfileModel.self)
        #expect(onboardingModel == SchemaV12.OnboardingStateModel.self)
        #expect(personalityModel == SchemaV12.PersonalityAnalysisModel.self)
    }

    @Test("Active model aliases use V11 (not V12)")
    func activeModelAliasesUseV11() {
        // Active aliases now point to V11 since V12 was removed
        #expect(ActiveHabitModel.self == SchemaV11.HabitModel.self)
        #expect(ActiveHabitLogModel.self == SchemaV11.HabitLogModel.self)
        #expect(ActiveHabitCategoryModel.self == SchemaV11.HabitCategoryModel.self)
        #expect(ActiveUserProfileModel.self == SchemaV11.UserProfileModel.self)
        #expect(ActiveOnboardingStateModel.self == SchemaV11.OnboardingStateModel.self)
        #expect(ActivePersonalityAnalysisModel.self == SchemaV11.PersonalityAnalysisModel.self)
    }

    // MARK: - Entity Conversion Tests (V12 conversions still work)

    @Test("HabitLogModel can be created and converted")
    func habitLogModelConversion() {
        let habitLog = HabitLog(
            id: UUID(),
            habitID: UUID(),
            date: Date(),
            value: 5.0,
            timezone: "America/New_York"
        )

        let model = HabitLogModelV12.fromEntity(habitLog)
        let entity = model.toEntity()

        #expect(entity.id == habitLog.id)
        #expect(entity.habitID == habitLog.habitID)
        #expect(entity.value == habitLog.value)
        #expect(entity.timezone == habitLog.timezone)
    }

    @Test("HabitCategoryModel can be created and converted")
    func habitCategoryModelConversion() {
        let category = HabitCategory(
            id: "test-category",
            name: "Test",
            displayName: "Test Category",
            emoji: "🧪",
            order: 1,
            isActive: true,
            isPredefined: false
        )

        let model = HabitCategoryModelV12.fromEntity(category)
        let entity = model.toEntity()

        #expect(entity.id == category.id)
        #expect(entity.name == category.name)
        #expect(entity.isActive == category.isActive)
        #expect(entity.isPredefined == category.isPredefined)
    }

    @Test("PersonalityAnalysisModel can be created and converted")
    func personalityAnalysisModelConversion() {
        let profile = PersonalityProfile(
            id: UUID(),
            userId: UUID(),
            traitScores: [
                .openness: 0.7,
                .conscientiousness: 0.8,
                .extraversion: 0.5,
                .agreeableness: 0.6,
                .neuroticism: 0.3
            ],
            dominantTrait: .conscientiousness,
            confidence: .high,
            analysisMetadata: AnalysisMetadata(
                analysisDate: Date(),
                dataPointsAnalyzed: 100,
                timeRangeAnalyzed: 30,
                version: "1.0"
            )
        )

        let model = PersonalityAnalysisModelV12.fromEntity(profile)
        let entity = model.toEntity()

        #expect(entity != nil)
        #expect(entity?.id == profile.id)
        #expect(entity?.userId == profile.userId)
        #expect(entity?.dominantTrait == profile.dominantTrait)
    }
}

// MARK: - Schema Migration Chain Tests

@Suite("Schema Migration Chain Tests", .tags(.database, .fast))
@MainActor
struct SchemaMigrationChainTests {

    @Test("Migration chain is complete from V2 to V11 (V12 removed)")
    func migrationChainIsComplete() {
        let schemas = RitualistMigrationPlan.schemas
        let stages = RitualistMigrationPlan.stages

        // Should have 10 schemas (V2 through V11) - V12 removed due to checksum collision
        #expect(schemas.count == 10)

        // Should have 9 migration stages (V2→V3 through V10→V11)
        #expect(stages.count == 9)

        // Verify version progression (V12 excluded)
        let versions = schemas.map { $0.versionIdentifier.major }
        #expect(versions == [2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
    }

    @Test("No version gaps in schema chain (V2 to V11)")
    func noVersionGapsInSchemaChain() {
        let schemas = RitualistMigrationPlan.schemas
        let versions = schemas.map { $0.versionIdentifier.major }

        for i in 1..<versions.count {
            let gap = versions[i] - versions[i - 1]
            #expect(gap == 1, "Gap between versions \(versions[i-1]) and \(versions[i])")
        }
    }
}
