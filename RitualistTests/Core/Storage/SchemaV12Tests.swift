//
//  SchemaV12Tests.swift
//  RitualistTests
//
//  Created by Claude on 26.12.2025.
//
//  Unit tests for SchemaV12 (Database Performance Indexes).
//

import Testing
import Foundation
import SwiftData
@testable import RitualistCore

#if swift(>=6.1)
@Suite("SchemaV12 Tests", .tags(.database, .fast))
#else
@Suite("SchemaV12 Tests")
#endif
struct SchemaV12Tests {

    // MARK: - Schema Version Tests

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

    @Test("ActiveSchemaVersion points to V12")
    func activeSchemaIsV12() {
        // This ensures ActiveSchema.swift is updated correctly
        #expect(ActiveSchemaVersion.versionIdentifier == Schema.Version(12, 0, 0))
    }

    // MARK: - Migration Plan Tests

    @Test("MigrationPlan includes SchemaV12")
    func migrationPlanIncludesV12() {
        let schemas = RitualistMigrationPlan.schemas
        let hasV12 = schemas.contains { $0.versionIdentifier == Schema.Version(12, 0, 0) }
        #expect(hasV12)
    }

    @Test("MigrationPlan has V11 to V12 migration stage")
    func migrationPlanHasV11ToV12Stage() {
        // Migration stages count should include V11→V12
        let stages = RitualistMigrationPlan.stages
        #expect(stages.count == 10) // V2→V3 through V11→V12
    }

    @Test("Current schema version is V12")
    func currentSchemaVersionIsV12() {
        let currentVersion = RitualistMigrationPlan.currentSchemaVersion
        #expect(currentVersion == Schema.Version(12, 0, 0))
    }

    // MARK: - Model Type Alias Tests

    @Test("Type aliases point to V12 models")
    func typeAliasesPointToV12() {
        // Verify type aliases resolve correctly
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

    @Test("Active model aliases use V12")
    func activeModelAliasesUseV12() {
        // These should all be V12 models
        #expect(ActiveHabitModel.self == SchemaV12.HabitModel.self)
        #expect(ActiveHabitLogModel.self == SchemaV12.HabitLogModel.self)
        #expect(ActiveHabitCategoryModel.self == SchemaV12.HabitCategoryModel.self)
        #expect(ActiveUserProfileModel.self == SchemaV12.UserProfileModel.self)
        #expect(ActiveOnboardingStateModel.self == SchemaV12.OnboardingStateModel.self)
        #expect(ActivePersonalityAnalysisModel.self == SchemaV12.PersonalityAnalysisModel.self)
    }

    // MARK: - Entity Conversion Tests

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

#if swift(>=6.1)
@Suite("Schema Migration Chain Tests", .tags(.database, .fast))
#else
@Suite("Schema Migration Chain Tests")
#endif
struct SchemaMigrationChainTests {

    @Test("Migration chain is complete from V2 to V12")
    func migrationChainIsComplete() {
        let schemas = RitualistMigrationPlan.schemas
        let stages = RitualistMigrationPlan.stages

        // Should have 11 schemas (V2 through V12)
        #expect(schemas.count == 11)

        // Should have 10 migration stages (V2→V3 through V11→V12)
        #expect(stages.count == 10)

        // Verify version progression
        let versions = schemas.map { $0.versionIdentifier.major }
        #expect(versions == [2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
    }

    @Test("No version gaps in schema chain")
    func noVersionGapsInSchemaChain() {
        let schemas = RitualistMigrationPlan.schemas
        let versions = schemas.map { $0.versionIdentifier.major }

        for i in 1..<versions.count {
            let gap = versions[i] - versions[i - 1]
            #expect(gap == 1, "Gap between versions \(versions[i-1]) and \(versions[i])")
        }
    }
}
