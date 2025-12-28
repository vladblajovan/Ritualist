//
//  ImportValidationService.swift
//  RitualistCore
//
//  Service for validating imported user data.
//  Provides field-level validation to prevent malicious data injection.
//

import Foundation

// MARK: - Import Validation Errors

/// Errors for specific field validation failures
public enum ImportValidationError: LocalizedError {
    case habitNameTooLong(habitId: UUID, length: Int, maxLength: Int)
    case habitNameEmpty(habitId: UUID)
    case habitColorInvalid(habitId: UUID, value: String)
    case habitNotesTooLong(habitId: UUID, length: Int, maxLength: Int)
    case habitUnitLabelTooLong(habitId: UUID, length: Int, maxLength: Int)
    case habitDailyTargetInvalid(habitId: UUID, value: Double)
    case habitDisplayOrderInvalid(habitId: UUID, value: Int)
    case habitPriorityLevelInvalid(habitId: UUID, value: Int)

    case reminderHourInvalid(habitId: UUID, hour: Int)
    case reminderMinuteInvalid(habitId: UUID, minute: Int)
    case tooManyReminders(habitId: UUID, count: Int, maxCount: Int)

    case locationLatitudeInvalid(habitId: UUID, value: Double)
    case locationLongitudeInvalid(habitId: UUID, value: Double)
    case locationRadiusInvalid(habitId: UUID, value: Double, min: Double, max: Double)
    case locationLabelTooLong(habitId: UUID, length: Int, maxLength: Int)
    case locationCooldownInvalid(habitId: UUID, value: Int)

    case categoryNameTooLong(categoryId: String, length: Int, maxLength: Int)
    case categoryNameEmpty(categoryId: String)
    case categoryDisplayNameTooLong(categoryId: String, length: Int, maxLength: Int)
    case categoryEmojiInvalid(categoryId: String, value: String)
    case categoryOrderInvalid(categoryId: String, value: Int)

    case habitLogValueNegative(logId: UUID, value: Double)
    case habitLogValueTooLarge(logId: UUID, value: Double, maxValue: Double)
    case habitLogTimezoneInvalid(logId: UUID, value: String)

    public var errorDescription: String? {
        switch self {
        case .habitNameTooLong(let id, let length, let max):
            return "Habit \(id.uuidString.prefix(8)) name too long (\(length) > \(max))"
        case .habitNameEmpty(let id):
            return "Habit \(id.uuidString.prefix(8)) has empty name"
        case .habitColorInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid color: \(value)"
        case .habitNotesTooLong(let id, let length, let max):
            return "Habit \(id.uuidString.prefix(8)) notes too long (\(length) > \(max))"
        case .habitUnitLabelTooLong(let id, let length, let max):
            return "Habit \(id.uuidString.prefix(8)) unit label too long (\(length) > \(max))"
        case .habitDailyTargetInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid daily target: \(value)"
        case .habitDisplayOrderInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid display order: \(value)"
        case .habitPriorityLevelInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid priority level: \(value)"

        case .reminderHourInvalid(let id, let hour):
            return "Habit \(id.uuidString.prefix(8)) has invalid reminder hour: \(hour)"
        case .reminderMinuteInvalid(let id, let minute):
            return "Habit \(id.uuidString.prefix(8)) has invalid reminder minute: \(minute)"
        case .tooManyReminders(let id, let count, let max):
            return "Habit \(id.uuidString.prefix(8)) has too many reminders (\(count) > \(max))"

        case .locationLatitudeInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid latitude: \(value)"
        case .locationLongitudeInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid longitude: \(value)"
        case .locationRadiusInvalid(let id, let value, let min, let max):
            return "Habit \(id.uuidString.prefix(8)) has invalid radius: \(value) (must be \(min)-\(max))"
        case .locationLabelTooLong(let id, let length, let max):
            return "Habit \(id.uuidString.prefix(8)) location label too long (\(length) > \(max))"
        case .locationCooldownInvalid(let id, let value):
            return "Habit \(id.uuidString.prefix(8)) has invalid cooldown minutes: \(value)"

        case .categoryNameTooLong(let id, let length, let max):
            return "Category \(id.prefix(8)) name too long (\(length) > \(max))"
        case .categoryNameEmpty(let id):
            return "Category \(id.prefix(8)) has empty name"
        case .categoryDisplayNameTooLong(let id, let length, let max):
            return "Category \(id.prefix(8)) display name too long (\(length) > \(max))"
        case .categoryEmojiInvalid(let id, let value):
            return "Category \(id.prefix(8)) has invalid emoji: \(value)"
        case .categoryOrderInvalid(let id, let value):
            return "Category \(id.prefix(8)) has invalid order: \(value)"

        case .habitLogValueNegative(let id, let value):
            return "Habit log \(id.uuidString.prefix(8)) has negative value: \(value)"
        case .habitLogValueTooLarge(let id, let value, let max):
            return "Habit log \(id.uuidString.prefix(8)) value too large (\(value) > \(max))"
        case .habitLogTimezoneInvalid(let id, let value):
            return "Habit log \(id.uuidString.prefix(8)) has invalid timezone: \(value)"
        }
    }
}

// MARK: - Validation Limits

public enum ImportFieldLimits {
    // Habit limits
    public static let maxHabitNameLength = 200
    public static let maxHabitNotesLength = 10_000
    public static let maxHabitUnitLabelLength = 50
    public static let maxDailyTarget: Double = 1_000_000
    public static let minDailyTarget: Double = 0.01
    public static let maxDisplayOrder = 100_000
    public static let maxRemindersPerHabit = 24

    // Location limits
    public static let minLatitude: Double = -90.0
    public static let maxLatitude: Double = 90.0
    public static let minLongitude: Double = -180.0
    public static let maxLongitude: Double = 180.0
    public static let minRadius: Double = 50.0
    public static let maxRadius: Double = 500.0
    public static let maxLocationLabelLength = 100
    public static let minCooldownMinutes = 1
    public static let maxCooldownMinutes = 1440 // 24 hours

    // Category limits
    public static let maxCategoryNameLength = 100
    public static let maxCategoryDisplayNameLength = 200
    public static let maxCategoryEmojiLength = 10
    public static let maxCategoryOrder = 10_000

    // Habit log limits
    public static let maxLogValue: Double = 1_000_000

    // Color validation regex (hex color)
    public static let hexColorPattern = "^#[0-9A-Fa-f]{6}$"
}

// MARK: - Validation Result

public struct ImportValidationResult {
    /// All validation errors found
    public let errors: [ImportValidationError]

    /// Whether any imported habits have location configurations
    public let hasLocationConfigurations: Bool

    /// Whether validation passed (no errors)
    public var isValid: Bool { errors.isEmpty }

    public init(errors: [ImportValidationError], hasLocationConfigurations: Bool) {
        self.errors = errors
        self.hasLocationConfigurations = hasLocationConfigurations
    }
}

// MARK: - Import Validation Service Protocol

public protocol ImportValidationService {
    /// Validates imported habits and returns validation result
    func validateHabits(_ habits: [Habit]) -> ImportValidationResult

    /// Validates imported categories and returns errors
    func validateCategories(_ categories: [HabitCategory]) -> [ImportValidationError]

    /// Validates imported habit logs and returns errors
    func validateHabitLogs(_ logs: [HabitLog]) -> [ImportValidationError]
}

// MARK: - Default Implementation

public final class DefaultImportValidationService: ImportValidationService {
    private let hexColorRegex: NSRegularExpression?
    private let logger: DebugLogger

    public init(logger: DebugLogger) {
        self.logger = logger
        self.hexColorRegex = try? NSRegularExpression(
            pattern: ImportFieldLimits.hexColorPattern,
            options: []
        )
    }

    // MARK: - Habit Validation

    public func validateHabits(_ habits: [Habit]) -> ImportValidationResult {
        var errors: [ImportValidationError] = []
        var hasLocationConfigs = false

        for habit in habits {
            errors.append(contentsOf: validateHabit(habit))

            if habit.locationConfiguration != nil {
                hasLocationConfigs = true
            }
        }

        if !errors.isEmpty {
            logger.log(
                "Import validation found errors in habits",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["errorCount": errors.count, "habitCount": habits.count]
            )
        }

        return ImportValidationResult(
            errors: errors,
            hasLocationConfigurations: hasLocationConfigs
        )
    }

    private func validateHabit(_ habit: Habit) -> [ImportValidationError] {
        var errors: [ImportValidationError] = []

        // Name validation
        if habit.name.isEmpty {
            errors.append(.habitNameEmpty(habitId: habit.id))
        } else if habit.name.count > ImportFieldLimits.maxHabitNameLength {
            errors.append(.habitNameTooLong(
                habitId: habit.id,
                length: habit.name.count,
                maxLength: ImportFieldLimits.maxHabitNameLength
            ))
        }

        // Color validation
        if !isValidHexColor(habit.colorHex) {
            errors.append(.habitColorInvalid(habitId: habit.id, value: habit.colorHex))
        }

        // Notes validation
        if let notes = habit.notes, notes.count > ImportFieldLimits.maxHabitNotesLength {
            errors.append(.habitNotesTooLong(
                habitId: habit.id,
                length: notes.count,
                maxLength: ImportFieldLimits.maxHabitNotesLength
            ))
        }

        // Unit label validation
        if let unitLabel = habit.unitLabel, unitLabel.count > ImportFieldLimits.maxHabitUnitLabelLength {
            errors.append(.habitUnitLabelTooLong(
                habitId: habit.id,
                length: unitLabel.count,
                maxLength: ImportFieldLimits.maxHabitUnitLabelLength
            ))
        }

        // Daily target validation
        if let dailyTarget = habit.dailyTarget {
            if dailyTarget < 0 || dailyTarget > ImportFieldLimits.maxDailyTarget {
                errors.append(.habitDailyTargetInvalid(habitId: habit.id, value: dailyTarget))
            }
        }

        // Display order validation
        if habit.displayOrder < 0 || habit.displayOrder > ImportFieldLimits.maxDisplayOrder {
            errors.append(.habitDisplayOrderInvalid(habitId: habit.id, value: habit.displayOrder))
        }

        // Priority level validation
        if let priority = habit.priorityLevel {
            if priority < 1 || priority > 3 {
                errors.append(.habitPriorityLevelInvalid(habitId: habit.id, value: priority))
            }
        }

        // Reminders validation
        errors.append(contentsOf: validateReminders(habit.reminders, habitId: habit.id))

        // Location configuration validation
        if let locationConfig = habit.locationConfiguration {
            errors.append(contentsOf: validateLocationConfiguration(locationConfig, habitId: habit.id))
        }

        return errors
    }

    // MARK: - Reminder Validation

    private func validateReminders(_ reminders: [ReminderTime], habitId: UUID) -> [ImportValidationError] {
        var errors: [ImportValidationError] = []

        // Check count
        if reminders.count > ImportFieldLimits.maxRemindersPerHabit {
            errors.append(.tooManyReminders(
                habitId: habitId,
                count: reminders.count,
                maxCount: ImportFieldLimits.maxRemindersPerHabit
            ))
        }

        // Validate each reminder
        for reminder in reminders {
            if reminder.hour < 0 || reminder.hour > 23 {
                errors.append(.reminderHourInvalid(habitId: habitId, hour: reminder.hour))
            }
            if reminder.minute < 0 || reminder.minute > 59 {
                errors.append(.reminderMinuteInvalid(habitId: habitId, minute: reminder.minute))
            }
        }

        return errors
    }

    // MARK: - Location Configuration Validation

    private func validateLocationConfiguration(
        _ config: LocationConfiguration,
        habitId: UUID
    ) -> [ImportValidationError] {
        var errors: [ImportValidationError] = []

        // Latitude validation
        if config.latitude < ImportFieldLimits.minLatitude || config.latitude > ImportFieldLimits.maxLatitude {
            errors.append(.locationLatitudeInvalid(habitId: habitId, value: config.latitude))
        }

        // Longitude validation
        if config.longitude < ImportFieldLimits.minLongitude || config.longitude > ImportFieldLimits.maxLongitude {
            errors.append(.locationLongitudeInvalid(habitId: habitId, value: config.longitude))
        }

        // Radius validation
        if config.radius < ImportFieldLimits.minRadius || config.radius > ImportFieldLimits.maxRadius {
            errors.append(.locationRadiusInvalid(
                habitId: habitId,
                value: config.radius,
                min: ImportFieldLimits.minRadius,
                max: ImportFieldLimits.maxRadius
            ))
        }

        // Location label validation
        if let label = config.locationLabel, label.count > ImportFieldLimits.maxLocationLabelLength {
            errors.append(.locationLabelTooLong(
                habitId: habitId,
                length: label.count,
                maxLength: ImportFieldLimits.maxLocationLabelLength
            ))
        }

        // Cooldown validation for everyEntry frequency
        if case .everyEntry(let cooldownMinutes) = config.frequency {
            if cooldownMinutes < ImportFieldLimits.minCooldownMinutes ||
               cooldownMinutes > ImportFieldLimits.maxCooldownMinutes {
                errors.append(.locationCooldownInvalid(habitId: habitId, value: cooldownMinutes))
            }
        }

        return errors
    }

    // MARK: - Category Validation

    public func validateCategories(_ categories: [HabitCategory]) -> [ImportValidationError] {
        var errors: [ImportValidationError] = []

        for category in categories {
            // Name validation
            if category.name.isEmpty {
                errors.append(.categoryNameEmpty(categoryId: category.id))
            } else if category.name.count > ImportFieldLimits.maxCategoryNameLength {
                errors.append(.categoryNameTooLong(
                    categoryId: category.id,
                    length: category.name.count,
                    maxLength: ImportFieldLimits.maxCategoryNameLength
                ))
            }

            // Display name validation
            if category.displayName.count > ImportFieldLimits.maxCategoryDisplayNameLength {
                errors.append(.categoryDisplayNameTooLong(
                    categoryId: category.id,
                    length: category.displayName.count,
                    maxLength: ImportFieldLimits.maxCategoryDisplayNameLength
                ))
            }

            // Emoji validation (should be a short string, typically 1-4 chars)
            if category.emoji.count > ImportFieldLimits.maxCategoryEmojiLength {
                errors.append(.categoryEmojiInvalid(categoryId: category.id, value: category.emoji))
            }

            // Order validation (must be non-negative and reasonable)
            if category.order < 0 || category.order > ImportFieldLimits.maxCategoryOrder {
                errors.append(.categoryOrderInvalid(categoryId: category.id, value: category.order))
            }
        }

        if !errors.isEmpty {
            logger.log(
                "Import validation found errors in categories",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["errorCount": errors.count, "categoryCount": categories.count]
            )
        }

        return errors
    }

    // MARK: - Habit Log Validation

    public func validateHabitLogs(_ logs: [HabitLog]) -> [ImportValidationError] {
        var errors: [ImportValidationError] = []

        for log in logs {
            // Value validation (only if value is present)
            if let value = log.value {
                // Negative values are invalid
                if value < 0 {
                    errors.append(.habitLogValueNegative(logId: log.id, value: value))
                }

                // Maximum value check (prevent absurd values)
                if value > ImportFieldLimits.maxLogValue {
                    errors.append(.habitLogValueTooLarge(
                        logId: log.id,
                        value: value,
                        maxValue: ImportFieldLimits.maxLogValue
                    ))
                }
            }

            // Timezone validation (must be a valid IANA timezone identifier)
            if TimeZone(identifier: log.timezone) == nil {
                errors.append(.habitLogTimezoneInvalid(logId: log.id, value: log.timezone))
            }
        }

        if !errors.isEmpty {
            logger.log(
                "Import validation found errors in habit logs",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["errorCount": errors.count, "logCount": logs.count]
            )
        }

        return errors
    }

    // MARK: - Helper Methods

    private func isValidHexColor(_ color: String) -> Bool {
        guard let regex = hexColorRegex else {
            // Fallback: basic check if regex failed to compile
            return color.hasPrefix("#") && color.count == 7
        }

        let range = NSRange(color.startIndex..<color.endIndex, in: color)
        return regex.firstMatch(in: color, options: [], range: range) != nil
    }
}
