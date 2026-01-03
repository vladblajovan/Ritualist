//
//  SchemaV1.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 11.02.2025.
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
public enum SchemaV1: VersionedSchema {
    public static let versionIdentifier: Schema.Version = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            HabitModel.self,
            HabitLogModel.self,
            HabitCategoryModel.self,
            UserProfileModel.self,
            OnboardingStateModel.self,
            PersonalityAnalysisModel.self
        ]
    }

    // MARK: - HabitModel V1

    @Model
    public final class HabitModel {
        @Attribute(.unique) public var id: UUID
        public var name: String = ""
        public var colorHex: String = "#007AFF"
        public var emoji: String?
        public var kindRaw: Int = 0
        public var unitLabel: String?
        public var dailyTarget: Double?
        public var scheduleData: Data = Data()
        public var remindersData: Data = Data()
        public var startDate: Date = Date()
        public var endDate: Date?
        public var isActive: Bool = true
        public var displayOrder: Int = 0
        public var suggestionId: String?

        // MARK: - Relationships
        @Relationship(deleteRule: .cascade, inverse: \HabitLogModel.habit)
        public var logs: [HabitLogModel] = []

        public var category: SchemaV1.HabitCategoryModel?

        public init(
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
            category: HabitCategoryModel? = nil,
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
    public final class HabitLogModel {
        @Attribute(.unique) public var id: UUID
        public var habitID: UUID = UUID()
        @Relationship var habit: HabitModel?
        public var date: Date = Date()
        public var value: Double?
        public var timezone: String = "UTC"

        public init(
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
    public final class HabitCategoryModel {
        @Attribute(.unique) public var id: String
        public var name: String = ""
        public var displayName: String = ""
        public var emoji: String = "📂"
        public var order: Int = 0
        public var isActive: Bool = true
        public var isPredefined: Bool = false

        // MARK: - Relationships
        @Relationship(deleteRule: .nullify, inverse: \HabitModel.category)
        public var habits: [HabitModel] = []

        public init(
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
    public final class UserProfileModel {
        @Attribute(.unique) public var id: String
        public var name: String = ""
        public var avatarImageData: Data?
        public var appearance: String = "followSystem"
        public var homeTimezone: String?
        public var displayTimezoneMode: String = "original"
        public var subscriptionPlan: String = "free"
        public var subscriptionExpiryDate: Date?
        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()

        public init(
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
    public final class OnboardingStateModel {
        @Attribute(.unique) public var id: UUID
        public var isCompleted: Bool = false
        public var completedDate: Date?
        public var userName: String?
        public var hasGrantedNotifications: Bool = false

        public init(
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
    public final class PersonalityAnalysisModel {
        @Attribute(.unique) public var id: String
        public var userId: String
        public var analysisDate: Date
        public var dominantTraitRawValue: String
        public var confidenceRawValue: String
        public var version: String
        public var dataPointsAnalyzed: Int
        public var timeRangeAnalyzed: Int
        public var opennessScore: Double
        public var conscientiousnessScore: Double
        public var extraversionScore: Double
        public var agreeablenessScore: Double
        public var neuroticismScore: Double

        public init(
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
public typealias HabitModelV1 = SchemaV1.HabitModel
public typealias HabitLogModelV1 = SchemaV1.HabitLogModel
public typealias HabitCategoryModelV1 = SchemaV1.HabitCategoryModel
public typealias UserProfileModelV1 = SchemaV1.UserProfileModel
public typealias OnboardingStateModelV1 = SchemaV1.OnboardingStateModel
public typealias PersonalityAnalysisModelV1 = SchemaV1.PersonalityAnalysisModel

// MARK: - Domain Entity Conversions

/// Extensions to convert between SchemaV1 models and domain entities
/// These methods enable the data layer to work with domain models while
/// SwiftData uses versioned schema types

extension SchemaV1.HabitModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() throws -> Habit {
        let schedule = try JSONDecoder().decode(HabitSchedule.self, from: scheduleData)
        let reminders = try JSONDecoder().decode([ReminderTime].self, from: remindersData)
        let kind: HabitKind = (kindRaw == 0) ? .binary : .numeric

        return Habit(
            id: id,
            name: name,
            colorHex: colorHex,
            emoji: emoji,
            kind: kind,
            unitLabel: unitLabel,
            dailyTarget: dailyTarget,
            schedule: schedule,
            reminders: reminders,
            startDate: startDate,
            endDate: endDate,
            isActive: isActive,
            displayOrder: displayOrder,
            categoryId: category?.id,
            suggestionId: suggestionId,
            isPinned: false  // V1 doesn't have isPinned, default to false
        )
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ habit: Habit, context: ModelContext? = nil) throws -> HabitModelV1 {
        let schedule = try JSONEncoder().encode(habit.schedule)
        let reminders = try JSONEncoder().encode(habit.reminders)
        let kindRaw = (habit.kind == .binary) ? 0 : 1

        // Set relationship from domain entity categoryId
        var category: SchemaV1.HabitCategoryModel?
        if let categoryId = habit.categoryId, let context = context {
            let descriptor = FetchDescriptor<SchemaV1.HabitCategoryModel>(predicate: #Predicate { $0.id == categoryId })
            category = try? context.fetch(descriptor).first
        }

        return SchemaV1.HabitModel(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kindRaw: kindRaw,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            scheduleData: schedule,
            remindersData: reminders,
            startDate: habit.startDate,
            endDate: habit.endDate,
            isActive: habit.isActive,
            displayOrder: habit.displayOrder,
            category: category,
            suggestionId: habit.suggestionId
        )
    }
}

extension SchemaV1.HabitLogModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() -> HabitLog {
        return HabitLog(id: id, habitID: habitID, date: date, value: value, timezone: timezone)
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ log: HabitLog, context: ModelContext? = nil) -> HabitLogModelV1 {
        // Store both habitID (for CloudKit) and relationship (for local queries)
        var habit: HabitModelV1?
        if let context = context {
            let descriptor = FetchDescriptor<SchemaV1.HabitModel>(predicate: #Predicate { $0.id == log.habitID })
            habit = try? context.fetch(descriptor).first
        }
        return SchemaV1.HabitLogModel(id: log.id, habitID: log.habitID, habit: habit, date: log.date, value: log.value, timezone: log.timezone)
    }
}

extension SchemaV1.HabitCategoryModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() -> HabitCategory {
        HabitCategory(
            id: id,
            name: name,
            displayName: displayName,
            emoji: emoji,
            order: order,
            isActive: isActive,
            isPredefined: isPredefined
        )
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ category: HabitCategory) -> HabitCategoryModelV1 {
        HabitCategoryModelV1(
            id: category.id,
            name: category.name,
            displayName: category.displayName,
            emoji: category.emoji,
            order: category.order,
            isActive: category.isActive,
            isPredefined: category.isPredefined
        )
    }
}

extension SchemaV1.UserProfileModel {
    /// Convert SwiftData model to domain entity
    /// NOTE: Subscription fields preserved in database but not passed to domain entity (removed in V8)
    public func toEntity() -> UserProfile {
        let id = UUID(uuidString: self.id) ?? UUID()
        let appearance = Int(self.appearance) ?? 0

        // Convert V1 timezone fields to V9 UserProfile three-timezone model
        let currentTz = TimeZone.current.identifier
        let homeTz = homeTimezone ?? TimeZone.current.identifier
        let displayMode = DisplayTimezoneMode.fromLegacyString(displayTimezoneMode ?? "current")

        return UserProfile(
            id: id,
            name: name,
            avatarImageData: avatarImageData,
            appearance: appearance,
            currentTimezoneIdentifier: currentTz,
            homeTimezoneIdentifier: homeTz,
            displayTimezoneMode: displayMode,
            timezoneChangeHistory: [],  // No history in V1
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Create SwiftData model from domain entity
    /// NOTE: Subscription fields use defaults - actual data comes from migration, not domain entity
    public static func fromEntity(_ profile: UserProfile) -> UserProfileModelV1 {
        // Convert V9 three-timezone model back to V1 format
        let homeTimezoneV1 = profile.homeTimezoneIdentifier
        let displayModeV1 = profile.displayTimezoneMode.toLegacyString()

        return SchemaV1.UserProfileModel(
            id: profile.id.uuidString,
            name: profile.name,
            avatarImageData: profile.avatarImageData,
            appearance: String(profile.appearance),
            homeTimezone: homeTimezoneV1,
            displayTimezoneMode: displayModeV1,
            subscriptionPlan: "free",  // Default - removed from UserProfile in V8
            subscriptionExpiryDate: nil,  // Default - removed from UserProfile in V8
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
    }
}

extension SchemaV1.OnboardingStateModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() -> OnboardingState {
        return OnboardingState(
            isCompleted: isCompleted,
            completedDate: completedDate,
            userName: userName,
            hasGrantedNotifications: hasGrantedNotifications
        )
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ state: OnboardingState) -> OnboardingStateModelV1 {
        return SchemaV1.OnboardingStateModel(
            isCompleted: state.isCompleted,
            completedDate: state.completedDate,
            userName: state.userName,
            hasGrantedNotifications: state.hasGrantedNotifications
        )
    }
}

extension SchemaV1.PersonalityAnalysisModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() -> PersonalityProfile? {
        guard let dominantTrait = PersonalityTrait(rawValue: dominantTraitRawValue),
              let confidence = ConfidenceLevel(rawValue: confidenceRawValue) else {
            return nil
        }

        let traitScores: [PersonalityTrait: Double] = [
            .openness: opennessScore,
            .conscientiousness: conscientiousnessScore,
            .extraversion: extraversionScore,
            .agreeableness: agreeablenessScore,
            .neuroticism: neuroticismScore
        ]

        let metadata = AnalysisMetadata(
            analysisDate: analysisDate,
            dataPointsAnalyzed: dataPointsAnalyzed,
            timeRangeAnalyzed: timeRangeAnalyzed,
            version: version
        )

        return PersonalityProfile(
            id: UUID(uuidString: id) ?? UUID(),
            userId: UUID(uuidString: userId) ?? UUID(),
            traitScores: traitScores,
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: metadata
        )
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ entity: PersonalityProfile) -> PersonalityAnalysisModelV1 {
        PersonalityAnalysisModelV1(
            id: entity.id.uuidString,
            userId: entity.userId.uuidString,
            analysisDate: entity.analysisMetadata.analysisDate,
            dominantTraitRawValue: entity.dominantTrait.rawValue,
            confidenceRawValue: entity.confidence.rawValue,
            version: entity.analysisMetadata.version,
            dataPointsAnalyzed: entity.analysisMetadata.dataPointsAnalyzed,
            timeRangeAnalyzed: entity.analysisMetadata.timeRangeAnalyzed,
            opennessScore: entity.traitScores[.openness] ?? 0.5,
            conscientiousnessScore: entity.traitScores[.conscientiousness] ?? 0.5,
            extraversionScore: entity.traitScores[.extraversion] ?? 0.5,
            agreeablenessScore: entity.traitScores[.agreeableness] ?? 0.5,
            neuroticismScore: entity.traitScores[.neuroticism] ?? 0.5
        )
    }
}
