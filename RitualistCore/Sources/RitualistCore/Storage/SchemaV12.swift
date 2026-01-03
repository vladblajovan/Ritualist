//
//  SchemaV12.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 26.12.2025.
//
//  Schema Version 12: No Schema Changes (Index Experiment Reverted)
//
//  Changes from V11:
//  - None - this version is identical to V11
//
//  IMPORTANT LEARNING: #Index macro breaks CloudKit sync silently!
//  We attempted to add #Index for performance but discovered:
//  - SwiftData's #Index macro causes CloudKit sync to fail with NO errors
//  - Data changes (creates, updates, deletes) simply don't sync
//  - CloudKit has its own indexing (Queryable, Searchable, Sortable) in CloudKit Console
//  - DO NOT use #Index on any models until Apple fixes this
//

import Foundation
import SwiftData

/// Schema V12: No Schema Changes (Index Experiment Reverted)
///
/// This schema is identical to V11. We originally planned to add #Index macros
/// for performance optimization, but discovered they break CloudKit sync silently.
///
/// CRITICAL LEARNING: #Index macro breaks CloudKit sync!
/// - SwiftData's #Index causes CloudKit sync to fail with NO errors
/// - Creates, updates, and deletes simply don't sync to/from CloudKit
/// - CloudKit Console has its own indexing (Queryable, Searchable, Sortable)
/// - DO NOT use #Index on any models until Apple fixes this issue
///
/// Migration Strategy:
/// - Lightweight migration from V11 to V12
/// - No data loss or transformation (schemas are identical)
public enum SchemaV12: VersionedSchema {
    public static let versionIdentifier: Schema.Version = Schema.Version(12, 0, 0)

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

    // MARK: - HabitModel V12
    // No changes from V11

    @Model
    public final class HabitModel {
        public var id: UUID = UUID()
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
        public var notes: String?
        public var lastCompletedDate: Date?
        public var archivedDate: Date?
        public var locationConfigData: Data?
        public var lastGeofenceTriggerDate: Date?

        // MARK: - Relationships
        @Relationship(deleteRule: .cascade, inverse: \HabitLogModel.habit)
        public var logs: [HabitLogModel]?

        public var category: SchemaV12.HabitCategoryModel?

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
            suggestionId: String?,
            notes: String? = nil,
            lastCompletedDate: Date? = nil,
            archivedDate: Date? = nil,
            locationConfigData: Data? = nil,
            lastGeofenceTriggerDate: Date? = nil
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
            self.notes = notes
            self.lastCompletedDate = lastCompletedDate
            self.archivedDate = archivedDate
            self.locationConfigData = locationConfigData
            self.lastGeofenceTriggerDate = lastGeofenceTriggerDate
            self.category = category
        }
    }

    // MARK: - HabitLogModel V12
    // NOTE: #Index removed - causes CloudKit sync to fail silently
    // CloudKit-synced models should NOT use SwiftData #Index macro
    // CloudKit has its own indexing (Queryable, Searchable, Sortable) configured in CloudKit Console

    @Model
    public final class HabitLogModel {

        public var id: UUID = UUID()
        public var habitID: UUID = UUID()
        @Relationship var habit: HabitModel?
        public var date: Date = Date()
        public var value: Double?
        public var timezone: String = "UTC"

        public init(
            id: UUID,
            habitID: UUID,
            habit: HabitModelV12?,
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

    // MARK: - HabitCategoryModel V12
    // NOTE: #Index removed - causes CloudKit sync to fail silently
    // CloudKit-synced models should NOT use SwiftData #Index macro

    @Model
    public final class HabitCategoryModel {

        public var id: String = ""
        public var name: String = ""
        public var displayName: String = ""
        public var emoji: String = "📂"
        public var order: Int = 0
        public var isActive: Bool = true
        public var isPredefined: Bool = false

        // MARK: - Relationships
        @Relationship(deleteRule: .nullify, inverse: \HabitModel.category)
        public var habits: [HabitModel]?

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

    // MARK: - UserProfileModel V12
    // No changes from V11

    @Model
    public final class UserProfileModel {
        public var id: String = ""
        public var name: String = ""
        public var avatarImageData: Data?
        public var appearance: String = "followSystem"

        // TIMEZONE TRINITY (from V9)
        public var currentTimezoneIdentifier: String = TimeZone.current.identifier
        public var homeTimezoneIdentifier: String = TimeZone.current.identifier
        public var displayTimezoneModeData: Data = Data()
        public var timezoneChangeHistoryData: Data = Data()

        // DEMOGRAPHICS (from V11)
        public var gender: String?
        public var ageGroup: String?

        public var createdAt: Date = Date()
        public var updatedAt: Date = Date()

        public init(
            id: String,
            name: String,
            avatarImageData: Data?,
            appearance: String,
            currentTimezoneIdentifier: String = TimeZone.current.identifier,
            homeTimezoneIdentifier: String = TimeZone.current.identifier,
            displayTimezoneModeData: Data = Data(),
            timezoneChangeHistoryData: Data = Data(),
            gender: String? = nil,
            ageGroup: String? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.avatarImageData = avatarImageData
            self.appearance = appearance
            self.currentTimezoneIdentifier = currentTimezoneIdentifier
            self.homeTimezoneIdentifier = homeTimezoneIdentifier
            self.displayTimezoneModeData = displayTimezoneModeData
            self.timezoneChangeHistoryData = timezoneChangeHistoryData
            self.gender = gender
            self.ageGroup = ageGroup
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    // MARK: - OnboardingStateModel V12
    // No changes from V11

    @Model
    public final class OnboardingStateModel {
        public var id: UUID = UUID()
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

    // MARK: - PersonalityAnalysisModel V12
    // NOTE: #Index removed for consistency - avoiding #Index entirely until SwiftData stabilizes

    @Model
    public final class PersonalityAnalysisModel {

        public var id: String = ""
        public var userId: String = ""
        public var analysisDate: Date = Date()
        public var dominantTraitRawValue: String = ""
        public var confidenceRawValue: String = ""
        public var version: String = ""
        public var dataPointsAnalyzed: Int = 0
        public var timeRangeAnalyzed: Int = 0
        public var opennessScore: Double = 0.5
        public var conscientiousnessScore: Double = 0.5
        public var extraversionScore: Double = 0.5
        public var agreeablenessScore: Double = 0.5
        public var neuroticismScore: Double = 0.5

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
public typealias HabitModelV12 = SchemaV12.HabitModel
public typealias HabitLogModelV12 = SchemaV12.HabitLogModel
public typealias HabitCategoryModelV12 = SchemaV12.HabitCategoryModel
public typealias UserProfileModelV12 = SchemaV12.UserProfileModel
public typealias OnboardingStateModelV12 = SchemaV12.OnboardingStateModel
public typealias PersonalityAnalysisModelV12 = SchemaV12.PersonalityAnalysisModel

// MARK: - Domain Entity Conversions

/// Extensions to convert between SchemaV12 models and domain entities

extension SchemaV12.HabitModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() throws -> Habit {
        let schedule = try JSONDecoder().decode(HabitSchedule.self, from: scheduleData)
        let reminders = try JSONDecoder().decode([ReminderTime].self, from: remindersData)
        let kind: HabitKind = (kindRaw == 0) ? .binary : .numeric

        // Decode location configuration if present
        var locationConfig: LocationConfiguration?
        if let locationData = locationConfigData {
            locationConfig = try? JSONDecoder().decode(LocationConfiguration.self, from: locationData)
            // Update lastTriggerDate from persistent storage
            if locationConfig != nil {
                locationConfig?.lastTriggerDate = lastGeofenceTriggerDate
            }
        }

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
            isPinned: false,
            notes: notes,
            lastCompletedDate: lastCompletedDate,
            archivedDate: archivedDate,
            locationConfiguration: locationConfig
        )
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ habit: Habit, context: ModelContext? = nil) throws -> HabitModelV12 {
        let schedule = try JSONEncoder().encode(habit.schedule)
        let reminders = try JSONEncoder().encode(habit.reminders)
        let kindRaw = (habit.kind == .binary) ? 0 : 1

        // Encode location configuration if present
        var locationData: Data?
        var lastTriggerDate: Date?
        if let locationConfig = habit.locationConfiguration {
            locationData = try? JSONEncoder().encode(locationConfig)
            lastTriggerDate = locationConfig.lastTriggerDate
        }

        // Set relationship from domain entity categoryId
        var category: SchemaV12.HabitCategoryModel?
        if let categoryId = habit.categoryId, let context = context {
            let descriptor = FetchDescriptor<SchemaV12.HabitCategoryModel>(predicate: #Predicate { $0.id == categoryId })
            category = try? context.fetch(descriptor).first
        }

        return SchemaV12.HabitModel(
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
            suggestionId: habit.suggestionId,
            notes: habit.notes,
            lastCompletedDate: habit.lastCompletedDate,
            archivedDate: habit.archivedDate,
            locationConfigData: locationData,
            lastGeofenceTriggerDate: lastTriggerDate
        )
    }

    /// Update existing SwiftData model from domain entity
    public func updateFromEntity(_ habit: Habit, context: ModelContext, logger: DebugLogger) throws {
        // Update basic properties
        self.name = habit.name
        self.colorHex = habit.colorHex
        self.emoji = habit.emoji
        self.kindRaw = (habit.kind == .binary) ? 0 : 1
        self.unitLabel = habit.unitLabel
        self.dailyTarget = habit.dailyTarget
        self.scheduleData = try JSONEncoder().encode(habit.schedule)
        self.remindersData = try JSONEncoder().encode(habit.reminders)
        self.startDate = habit.startDate
        self.endDate = habit.endDate
        self.isActive = habit.isActive
        self.displayOrder = habit.displayOrder
        self.suggestionId = habit.suggestionId
        self.notes = habit.notes
        self.lastCompletedDate = habit.lastCompletedDate
        self.archivedDate = habit.archivedDate

        // Update category relationship with proper error handling
        if let categoryId = habit.categoryId {
            let categoryDescriptor = FetchDescriptor<SchemaV12.HabitCategoryModel>(
                predicate: #Predicate { $0.id == categoryId }
            )
            if let fetchedCategory = try? context.fetch(categoryDescriptor).first {
                self.category = fetchedCategory
            } else {
                logger.log("Category \(categoryId) not found for habit \(habit.id)", level: .warning, category: .dataIntegrity)
                self.category = nil
            }
        } else {
            self.category = nil
        }

        // Update location configuration with proper error handling
        if let locationConfig = habit.locationConfiguration {
            do {
                self.locationConfigData = try JSONEncoder().encode(locationConfig)
                self.lastGeofenceTriggerDate = locationConfig.lastTriggerDate
            } catch {
                logger.log("Error encoding location configuration for habit \(habit.id): \(error)", level: .error, category: .dataIntegrity)
                throw error
            }
        } else {
            self.locationConfigData = nil
            self.lastGeofenceTriggerDate = nil
        }
    }
}

extension SchemaV12.HabitLogModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() -> HabitLog {
        return HabitLog(id: id, habitID: habitID, date: date, value: value, timezone: timezone)
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ log: HabitLog, context: ModelContext? = nil) -> HabitLogModelV12 {
        var habit: HabitModelV12?
        if let context = context {
            let descriptor = FetchDescriptor<SchemaV12.HabitModel>(predicate: #Predicate { $0.id == log.habitID })
            habit = try? context.fetch(descriptor).first
        }
        return SchemaV12.HabitLogModel(id: log.id, habitID: log.habitID, habit: habit, date: log.date, value: log.value, timezone: log.timezone)
    }
}

extension SchemaV12.HabitCategoryModel {
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
    public static func fromEntity(_ category: HabitCategory) -> HabitCategoryModelV12 {
        HabitCategoryModelV12(
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

extension SchemaV12.UserProfileModel {
    /// Convert SwiftData model to domain entity
    public func toEntity() -> UserProfile {
        let id = UUID(uuidString: self.id) ?? UUID()
        let appearance = Int(self.appearance) ?? 0

        // Decode DisplayTimezoneMode from JSON
        let displayMode: DisplayTimezoneMode
        if !displayTimezoneModeData.isEmpty {
            displayMode = (try? JSONDecoder().decode(DisplayTimezoneMode.self, from: displayTimezoneModeData)) ?? .current
        } else {
            displayMode = .current
        }

        // Decode timezone change history from JSON
        let changeHistory: [TimezoneChange]
        if !timezoneChangeHistoryData.isEmpty {
            changeHistory = (try? JSONDecoder().decode([TimezoneChange].self, from: timezoneChangeHistoryData)) ?? []
        } else {
            changeHistory = []
        }

        return UserProfile(
            id: id,
            name: name,
            avatarImageData: avatarImageData,
            appearance: appearance,
            currentTimezoneIdentifier: currentTimezoneIdentifier,
            homeTimezoneIdentifier: homeTimezoneIdentifier,
            displayTimezoneMode: displayMode,
            timezoneChangeHistory: changeHistory,
            gender: gender,
            ageGroup: ageGroup,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Create SwiftData model from domain entity
    public static func fromEntity(_ profile: UserProfile) -> UserProfileModelV12 {
        // Encode DisplayTimezoneMode to JSON
        let displayModeData = (try? JSONEncoder().encode(profile.displayTimezoneMode)) ?? Data()

        // Encode timezone change history to JSON
        let historyData = (try? JSONEncoder().encode(profile.timezoneChangeHistory)) ?? Data()

        return SchemaV12.UserProfileModel(
            id: profile.id.uuidString,
            name: profile.name,
            avatarImageData: profile.avatarImageData,
            appearance: String(profile.appearance),
            currentTimezoneIdentifier: profile.currentTimezoneIdentifier,
            homeTimezoneIdentifier: profile.homeTimezoneIdentifier,
            displayTimezoneModeData: displayModeData,
            timezoneChangeHistoryData: historyData,
            gender: profile.gender,
            ageGroup: profile.ageGroup,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
    }
}

extension SchemaV12.OnboardingStateModel {
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
    public static func fromEntity(_ state: OnboardingState) -> OnboardingStateModelV12 {
        return SchemaV12.OnboardingStateModel(
            isCompleted: state.isCompleted,
            completedDate: state.completedDate,
            userName: state.userName,
            hasGrantedNotifications: state.hasGrantedNotifications
        )
    }
}

extension SchemaV12.PersonalityAnalysisModel {
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
    public static func fromEntity(_ entity: PersonalityProfile) -> PersonalityAnalysisModelV12 {
        PersonalityAnalysisModelV12(
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
