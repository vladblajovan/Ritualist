//
//  SchemaV2.swift
//  RitualistCore
//
//  Created for Migration Testing on 11.02.2025.
//
//  Schema Version 2: Add isPinned property to habits
//  This is a test migration to validate the migration system works correctly.
//

import Foundation
import SwiftData

/// Schema V2: Adds isPinned property to HabitModel
///
/// Changes from V1:
/// - HabitModelV2: Added `isPinned: Bool` property with default value `false`
/// - All other models unchanged
enum SchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            HabitModelV2.self,
            HabitLogModelV2.self,
            HabitCategoryModelV2.self,
            UserProfileModelV2.self,
            OnboardingStateModelV2.self,
            PersonalityAnalysisModelV2.self
        ]
    }

    // MARK: - HabitModel V2 (MODIFIED)

    @Model
    final class HabitModelV2 {
        @Attribute(.unique) var id: UUID
        var name: String = ""
        var colorHex: String = "#007AFF"
        var emoji: String?
        var kindRaw: Int = 0
        var unitLabel: String?
        var dailyTarget: Double?
        var scheduleData: Data = Data()
        var remindersData: Data = Data()
        var startDate: Date = Date()
        var endDate: Date?
        var isActive: Bool = true
        var displayOrder: Int = 0
        var suggestionId: String?

        // NEW PROPERTY IN V2
        var isPinned: Bool = false

        // MARK: - Relationships
        @Relationship(deleteRule: .cascade, inverse: \HabitLogModelV2.habit)
        var logs: [HabitLogModelV2] = []

        var category: HabitCategoryModelV2?

        init(
            id: UUID,
            name: String,
            colorHex: String,
            emoji: String?,
            kindRaw: Int,
            unitLabel: String?,
            dailyTarget: Double?,
            scheduleData: Data,
            remindersData: Data,
            startDate: Date,
            endDate: Date?,
            isActive: Bool,
            displayOrder: Int,
            category: HabitCategoryModelV2? = nil,
            suggestionId: String?,
            isPinned: Bool = false  // NEW PARAMETER
        ) {
            self.id = id
            self.name = name
            self.colorHex = colorHex
            self.emoji = emoji
            self.kindRaw = kindRaw
            self.unitLabel = unitLabel
            self.dailyTarget = dailyTarget
            self.scheduleData = scheduleData
            self.remindersData = remindersData
            self.startDate = startDate
            self.endDate = endDate
            self.isActive = isActive
            self.displayOrder = displayOrder
            self.suggestionId = suggestionId
            self.category = category
            self.isPinned = isPinned  // NEW PROPERTY
        }
    }

    // MARK: - HabitLogModel V2 (UNCHANGED)

    @Model
    final class HabitLogModelV2 {
        @Attribute(.unique) var id: UUID
        var habitID: UUID = UUID()
        @Relationship var habit: HabitModelV2?
        var date: Date = Date()
        var value: Double?
        var timezone: String = "UTC"

        init(
            id: UUID,
            habitID: UUID,
            habit: HabitModelV2?,
            date: Date,
            value: Double?,
            timezone: String = "UTC"
        ) {
            self.id = id
            self.habitID = habitID
            self.date = date
            self.value = value
            self.timezone = timezone
            self.habit = habit
        }
    }

    // MARK: - HabitCategoryModel V2 (UNCHANGED)

    @Model
    final class HabitCategoryModelV2 {
        @Attribute(.unique) var id: String
        var name: String = ""
        var displayName: String = ""
        var emoji: String = "📂"
        var order: Int = 0
        var isActive: Bool = true
        var isPredefined: Bool = false

        // MARK: - Relationships
        @Relationship(deleteRule: .nullify, inverse: \HabitModelV2.category)
        var habits: [HabitModelV2] = []

        init(
            id: String,
            name: String,
            displayName: String,
            emoji: String,
            order: Int,
            isActive: Bool = true,
            isPredefined: Bool = false
        ) {
            self.id = id
            self.name = name
            self.displayName = displayName
            self.emoji = emoji
            self.order = order
            self.isActive = isActive
            self.isPredefined = isPredefined
        }
    }

    // MARK: - UserProfileModel V2 (UNCHANGED)

    @Model
    final class UserProfileModelV2 {
        @Attribute(.unique) var id: String
        var name: String = ""
        var avatarImageData: Data?
        var appearance: String = "followSystem"
        var homeTimezone: String?
        var displayTimezoneMode: String = "original"
        var subscriptionPlan: String = "free"
        var subscriptionExpiryDate: Date?
        var createdAt: Date = Date()
        var updatedAt: Date = Date()

        init(
            id: String,
            name: String,
            avatarImageData: Data?,
            appearance: String,
            homeTimezone: String? = nil,
            displayTimezoneMode: String = "original",
            subscriptionPlan: String = "free",
            subscriptionExpiryDate: Date? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.avatarImageData = avatarImageData
            self.appearance = appearance
            self.homeTimezone = homeTimezone
            self.displayTimezoneMode = displayTimezoneMode
            self.subscriptionPlan = subscriptionPlan
            self.subscriptionExpiryDate = subscriptionExpiryDate
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    // MARK: - OnboardingStateModel V2 (UNCHANGED)

    @Model
    final class OnboardingStateModelV2 {
        @Attribute(.unique) var id: UUID
        var isCompleted: Bool = false
        var completedDate: Date?
        var userName: String?
        var hasGrantedNotifications: Bool = false

        init(
            id: UUID = UUID(),
            isCompleted: Bool = false,
            completedDate: Date? = nil,
            userName: String? = nil,
            hasGrantedNotifications: Bool = false
        ) {
            self.id = id
            self.isCompleted = isCompleted
            self.completedDate = completedDate
            self.userName = userName
            self.hasGrantedNotifications = hasGrantedNotifications
        }
    }

    // MARK: - PersonalityAnalysisModel V2 (UNCHANGED)

    @Model
    final class PersonalityAnalysisModelV2 {
        @Attribute(.unique) var id: String
        var userId: String
        var analysisDate: Date
        var dominantTraitRawValue: String
        var confidenceRawValue: String
        var version: String
        var dataPointsAnalyzed: Int
        var timeRangeAnalyzed: Int
        var opennessScore: Double
        var conscientiousnessScore: Double
        var extraversionScore: Double
        var agreeablenessScore: Double
        var neuroticismScore: Double

        init(
            id: String,
            userId: String,
            analysisDate: Date,
            dominantTraitRawValue: String,
            confidenceRawValue: String,
            version: String,
            dataPointsAnalyzed: Int,
            timeRangeAnalyzed: Int,
            opennessScore: Double,
            conscientiousnessScore: Double,
            extraversionScore: Double,
            agreeablenessScore: Double,
            neuroticismScore: Double
        ) {
            self.id = id
            self.userId = userId
            self.analysisDate = analysisDate
            self.dominantTraitRawValue = dominantTraitRawValue
            self.confidenceRawValue = confidenceRawValue
            self.version = version
            self.dataPointsAnalyzed = dataPointsAnalyzed
            self.timeRangeAnalyzed = timeRangeAnalyzed
            self.opennessScore = opennessScore
            self.conscientiousnessScore = conscientiousnessScore
            self.extraversionScore = extraversionScore
            self.agreeablenessScore = agreeablenessScore
            self.neuroticismScore = neuroticismScore
        }
    }
}

// MARK: - Migration Type Aliases

/// Type aliases for V2 models
typealias HabitModelV2 = SchemaV2.HabitModelV2
typealias HabitLogModelV2 = SchemaV2.HabitLogModelV2
typealias HabitCategoryModelV2 = SchemaV2.HabitCategoryModelV2
typealias UserProfileModelV2 = SchemaV2.UserProfileModelV2
typealias OnboardingStateModelV2 = SchemaV2.OnboardingStateModelV2
typealias PersonalityAnalysisModelV2 = SchemaV2.PersonalityAnalysisModelV2
