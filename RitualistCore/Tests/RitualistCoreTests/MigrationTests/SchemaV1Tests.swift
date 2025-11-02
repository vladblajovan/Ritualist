//
//  SchemaV1Tests.swift
//  RitualistCoreTests
//
//  Created by Claude on 11.02.2025.
//
//  Tests for SchemaV1 validation
//

import Testing
import SwiftData
@testable import RitualistCore

/// Tests for Schema V1 structure and initialization
struct SchemaV1Tests {

    // MARK: - Schema Version Tests

    @Test("SchemaV1 has correct version identifier")
    func testSchemaV1VersionIdentifier() throws {
        let version = SchemaV1.versionIdentifier
        #expect(version == Schema.Version(1, 0, 0))
    }

    @Test("SchemaV1 includes all required models")
    func testSchemaV1ModelsCount() throws {
        let models = SchemaV1.models
        #expect(models.count == 6, "SchemaV1 should include exactly 6 models")
    }

    @Test("SchemaV1 includes HabitModel")
    func testSchemaV1IncludesHabitModel() throws {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        #expect(modelTypes.contains(String(describing: HabitModelV1.self)))
    }

    @Test("SchemaV1 includes HabitLogModel")
    func testSchemaV1IncludesHabitLogModel() throws {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        #expect(modelTypes.contains(String(describing: HabitLogModelV1.self)))
    }

    @Test("SchemaV1 includes HabitCategoryModel")
    func testSchemaV1IncludesHabitCategoryModel() throws {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        #expect(modelTypes.contains(String(describing: HabitCategoryModelV1.self)))
    }

    @Test("SchemaV1 includes UserProfileModel")
    func testSchemaV1IncludesUserProfileModel() throws {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        #expect(modelTypes.contains(String(describing: UserProfileModelV1.self)))
    }

    @Test("SchemaV1 includes OnboardingStateModel")
    func testSchemaV1IncludesOnboardingStateModel() throws {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        #expect(modelTypes.contains(String(describing: OnboardingStateModelV1.self)))
    }

    @Test("SchemaV1 includes PersonalityAnalysisModel")
    func testSchemaV1IncludesPersonalityAnalysisModel() throws {
        let modelTypes = SchemaV1.models.map { String(describing: $0) }
        #expect(modelTypes.contains(String(describing: PersonalityAnalysisModelV1.self)))
    }

    // MARK: - Model Initialization Tests

    @Test("HabitModelV1 initializes with required properties")
    func testHabitModelV1Initialization() throws {
        let habit = HabitModelV1(
            id: UUID(),
            name: "Test Habit",
            colorHex: "#FF0000",
            emoji: "🏃",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: Data(),
            remindersData: Data(),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            category: nil,
            suggestionId: nil
        )

        #expect(habit.name == "Test Habit")
        #expect(habit.colorHex == "#FF0000")
        #expect(habit.emoji == "🏃")
        #expect(habit.kindRaw == 0)
        #expect(habit.isActive == true)
    }

    @Test("HabitLogModelV1 initializes with required properties")
    func testHabitLogModelV1Initialization() throws {
        let habitId = UUID()
        let log = HabitLogModelV1(
            id: UUID(),
            habitID: habitId,
            habit: nil,
            date: Date(),
            value: 5.0,
            timezone: "UTC"
        )

        #expect(log.habitID == habitId)
        #expect(log.value == 5.0)
        #expect(log.timezone == "UTC")
    }

    @Test("HabitCategoryModelV1 initializes with required properties")
    func testHabitCategoryModelV1Initialization() throws {
        let category = HabitCategoryModelV1(
            id: "health",
            name: "Health",
            displayName: "Health & Fitness",
            emoji: "💪",
            order: 1,
            isActive: true,
            isPredefined: true
        )

        #expect(category.id == "health")
        #expect(category.name == "Health")
        #expect(category.displayName == "Health & Fitness")
        #expect(category.emoji == "💪")
        #expect(category.order == 1)
        #expect(category.isPredefined == true)
    }

    @Test("UserProfileModelV1 initializes with required properties")
    func testUserProfileModelV1Initialization() throws {
        let profile = UserProfileModelV1(
            id: UUID().uuidString,
            name: "Test User",
            avatarImageData: nil,
            appearance: "followSystem",
            homeTimezone: "America/New_York",
            displayTimezoneMode: "original",
            subscriptionPlan: "free",
            subscriptionExpiryDate: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        #expect(profile.name == "Test User")
        #expect(profile.appearance == "followSystem")
        #expect(profile.homeTimezone == "America/New_York")
        #expect(profile.subscriptionPlan == "free")
    }

    @Test("OnboardingStateModelV1 initializes with required properties")
    func testOnboardingStateModelV1Initialization() throws {
        let state = OnboardingStateModelV1(
            id: UUID(),
            isCompleted: false,
            completedDate: nil,
            userName: "Test User",
            hasGrantedNotifications: false
        )

        #expect(state.isCompleted == false)
        #expect(state.userName == "Test User")
        #expect(state.hasGrantedNotifications == false)
    }

    @Test("PersonalityAnalysisModelV1 initializes with required properties")
    func testPersonalityAnalysisModelV1Initialization() throws {
        let analysis = PersonalityAnalysisModelV1(
            id: UUID().uuidString,
            userId: UUID().uuidString,
            analysisDate: Date(),
            dominantTraitRawValue: "openness",
            confidenceRawValue: "high",
            version: "1.0",
            dataPointsAnalyzed: 50,
            timeRangeAnalyzed: 30,
            opennessScore: 0.8,
            conscientiousnessScore: 0.6,
            extraversionScore: 0.7,
            agreeablenessScore: 0.5,
            neuroticismScore: 0.4
        )

        #expect(analysis.dominantTraitRawValue == "openness")
        #expect(analysis.confidenceRawValue == "high")
        #expect(analysis.version == "1.0")
        #expect(analysis.dataPointsAnalyzed == 50)
        #expect(analysis.opennessScore == 0.8)
    }

    // MARK: - Relationship Tests

    @Test("HabitModelV1 and HabitLogModelV1 relationship works")
    func testHabitLogRelationship() throws {
        let habit = HabitModelV1(
            id: UUID(),
            name: "Test",
            colorHex: "#000000",
            emoji: nil,
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: Data(),
            remindersData: Data(),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            category: nil,
            suggestionId: nil
        )

        #expect(habit.logs.isEmpty, "New habit should have empty logs array")
    }

    @Test("HabitCategoryModelV1 and HabitModelV1 relationship works")
    func testCategoryHabitRelationship() throws {
        let category = HabitCategoryModelV1(
            id: "test",
            name: "Test",
            displayName: "Test Category",
            emoji: "📁",
            order: 0,
            isActive: true,
            isPredefined: false
        )

        #expect(category.habits.isEmpty, "New category should have empty habits array")
    }
}
