//
//  SchemaV1.swift
//  RitualistCore
//
//  Created by Claude on 11.02.2025.
//
//  Schema Version 1: Initial versioned schema snapshot
//  This captures the current state of all SwiftData models as V1,
//  enabling safe migrations for future schema changes.
//

import Foundation
import SwiftData

/// Schema V1: Initial baseline schema for all Ritualist data models
///
/// This schema represents the first versioned snapshot of the database.
/// Any future schema changes must create V2, V3, etc. with migration plans.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            HabitModelV1.self,
            HabitLogModelV1.self,
            HabitCategoryModelV1.self,
            UserProfileModelV1.self,
            OnboardingStateModelV1.self,
            PersonalityAnalysisModelV1.self
        ]
    }

    // MARK: - HabitModel V1

    @Model
    final class HabitModelV1 {
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

        // MARK: - Relationships
        @Relationship(deleteRule: .cascade, inverse: \HabitLogModelV1.habit)
        var logs: [HabitLogModelV1] = []

        var category: HabitCategoryModelV1?

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
            category: HabitCategoryModelV1? = nil,
            suggestionId: String?
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
        }
    }

    // MARK: - HabitLogModel V1

    @Model
    final class HabitLogModelV1 {
        @Attribute(.unique) var id: UUID
        var habitID: UUID = UUID()
        @Relationship var habit: HabitModelV1?
        var date: Date = Date()
        var value: Double?
        var timezone: String = "UTC"

        init(
            id: UUID,
            habitID: UUID,
            habit: HabitModelV1?,
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

    // MARK: - HabitCategoryModel V1

    @Model
    final class HabitCategoryModelV1 {
        @Attribute(.unique) var id: String
        var name: String = ""
        var displayName: String = ""
        var emoji: String = "📂"
        var order: Int = 0
        var isActive: Bool = true
        var isPredefined: Bool = false

        // MARK: - Relationships
        @Relationship(deleteRule: .nullify, inverse: \HabitModelV1.category)
        var habits: [HabitModelV1] = []

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

    // MARK: - UserProfileModel V1

    @Model
    final class UserProfileModelV1 {
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

    // MARK: - OnboardingStateModel V1

    @Model
    final class OnboardingStateModelV1 {
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

    // MARK: - PersonalityAnalysisModel V1

    @Model
    final class PersonalityAnalysisModelV1 {
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

/// Type aliases for easier migration mapping between schema versions
/// These help identify which V1 models correspond to current models
typealias HabitModelV1 = SchemaV1.HabitModelV1
typealias HabitLogModelV1 = SchemaV1.HabitLogModelV1
typealias HabitCategoryModelV1 = SchemaV1.HabitCategoryModelV1
typealias UserProfileModelV1 = SchemaV1.UserProfileModelV1
typealias OnboardingStateModelV1 = SchemaV1.OnboardingStateModelV1
typealias PersonalityAnalysisModelV1 = SchemaV1.PersonalityAnalysisModelV1
