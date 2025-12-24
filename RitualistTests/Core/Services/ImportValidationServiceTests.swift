//
//  ImportValidationServiceTests.swift
//  RitualistTests
//
//  Comprehensive tests for ImportValidationService field-level validation.
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - Habit Validation Tests

@Suite("ImportValidationService - Habit Validation")
struct HabitValidationTests {

    // MARK: - Name Validation

    @Test("Valid habit name passes validation")
    func validHabitNamePasses() {
        let service = createService()
        let habit = createHabit(name: "Morning Meditation")
        let result = service.validateHabits([habit])
        #expect(result.isValid)
        #expect(result.errors.isEmpty)
    }

    @Test("Empty habit name fails validation")
    func emptyHabitNameFails() {
        let service = createService()
        let habit = createHabit(name: "")
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        #expect(result.errors.count == 1)
        if case .habitNameEmpty = result.errors.first {} else {
            Issue.record("Expected habitNameEmpty error")
        }
    }

    @Test("Habit name at max length passes validation")
    func habitNameAtMaxLengthPasses() {
        let service = createService()
        let name = String(repeating: "a", count: ImportFieldLimits.maxHabitNameLength)
        let habit = createHabit(name: name)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Habit name exceeding max length fails validation")
    func habitNameExceedingMaxLengthFails() {
        let service = createService()
        let name = String(repeating: "a", count: ImportFieldLimits.maxHabitNameLength + 1)
        let habit = createHabit(name: name)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .habitNameTooLong = result.errors.first {} else {
            Issue.record("Expected habitNameTooLong error")
        }
    }

    // MARK: - Color Validation

    @Test("Valid hex color passes validation")
    func validHexColorPasses() {
        let service = createService()
        let habit = createHabit(colorHex: "#2DA9E3")
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Valid lowercase hex color passes validation")
    func validLowercaseHexColorPasses() {
        let service = createService()
        let habit = createHabit(colorHex: "#2da9e3")
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Invalid hex color fails validation - missing hash")
    func invalidHexColorMissingHashFails() {
        let service = createService()
        let habit = createHabit(colorHex: "2DA9E3")
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .habitColorInvalid = result.errors.first {} else {
            Issue.record("Expected habitColorInvalid error")
        }
    }

    @Test("Invalid hex color fails validation - wrong length")
    func invalidHexColorWrongLengthFails() {
        let service = createService()
        let habit = createHabit(colorHex: "#FFF")
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    @Test("Invalid hex color fails validation - invalid characters")
    func invalidHexColorInvalidCharsFails() {
        let service = createService()
        let habit = createHabit(colorHex: "#GGGGGG")
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - Notes Validation

    @Test("Notes at max length passes validation")
    func notesAtMaxLengthPasses() {
        let service = createService()
        let notes = String(repeating: "x", count: ImportFieldLimits.maxHabitNotesLength)
        let habit = createHabit(notes: notes)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Notes exceeding max length fails validation")
    func notesExceedingMaxLengthFails() {
        let service = createService()
        let notes = String(repeating: "x", count: ImportFieldLimits.maxHabitNotesLength + 1)
        let habit = createHabit(notes: notes)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .habitNotesTooLong = result.errors.first {} else {
            Issue.record("Expected habitNotesTooLong error")
        }
    }

    // MARK: - Daily Target Validation

    @Test("Valid daily target passes validation")
    func validDailyTargetPasses() {
        let service = createService()
        let habit = createHabit(dailyTarget: 8.0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Negative daily target fails validation")
    func negativeDailyTargetFails() {
        let service = createService()
        let habit = createHabit(dailyTarget: -1.0)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .habitDailyTargetInvalid = result.errors.first {} else {
            Issue.record("Expected habitDailyTargetInvalid error")
        }
    }

    @Test("Excessive daily target fails validation")
    func excessiveDailyTargetFails() {
        let service = createService()
        let habit = createHabit(dailyTarget: ImportFieldLimits.maxDailyTarget + 1)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - Priority Level Validation

    @Test("Valid priority level passes validation")
    func validPriorityLevelPasses() {
        let service = createService()
        for priority in 1...3 {
            let habit = createHabit(priorityLevel: priority)
            let result = service.validateHabits([habit])
            #expect(result.isValid, "Priority \(priority) should be valid")
        }
    }

    @Test("Invalid priority level fails validation - too low")
    func invalidPriorityLevelTooLowFails() {
        let service = createService()
        let habit = createHabit(priorityLevel: 0)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .habitPriorityLevelInvalid = result.errors.first {} else {
            Issue.record("Expected habitPriorityLevelInvalid error")
        }
    }

    @Test("Invalid priority level fails validation - too high")
    func invalidPriorityLevelTooHighFails() {
        let service = createService()
        let habit = createHabit(priorityLevel: 4)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - Helpers

    private func createService() -> ImportValidationService {
        DefaultImportValidationService(logger: DebugLogger(subsystem: "test", category: "validation"))
    }

    private func createHabit(
        name: String = "Test Habit",
        colorHex: String = "#2DA9E3",
        notes: String? = nil,
        dailyTarget: Double? = nil,
        priorityLevel: Int? = nil
    ) -> Habit {
        Habit(
            name: name,
            colorHex: colorHex,
            kind: dailyTarget != nil ? .numeric : .binary,
            dailyTarget: dailyTarget,
            notes: notes,
            priorityLevel: priorityLevel
        )
    }
}

// MARK: - Reminder Validation Tests

@Suite("ImportValidationService - Reminder Validation")
struct ReminderValidationTests {

    @Test("Valid reminders pass validation")
    func validRemindersPasses() {
        let service = createService()
        let habit = createHabitWithReminders([
            ReminderTime(hour: 9, minute: 0),
            ReminderTime(hour: 18, minute: 30)
        ])
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Reminder with invalid hour fails validation - too high")
    func reminderInvalidHourTooHighFails() {
        let service = createService()
        let habit = createHabitWithReminders([ReminderTime(hour: 24, minute: 0)])
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .reminderHourInvalid = result.errors.first {} else {
            Issue.record("Expected reminderHourInvalid error")
        }
    }

    @Test("Reminder with invalid hour fails validation - negative")
    func reminderInvalidHourNegativeFails() {
        let service = createService()
        let habit = createHabitWithReminders([ReminderTime(hour: -1, minute: 0)])
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    @Test("Reminder with invalid minute fails validation - too high")
    func reminderInvalidMinuteTooHighFails() {
        let service = createService()
        let habit = createHabitWithReminders([ReminderTime(hour: 9, minute: 60)])
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .reminderMinuteInvalid = result.errors.first {} else {
            Issue.record("Expected reminderMinuteInvalid error")
        }
    }

    @Test("Reminder with invalid minute fails validation - negative")
    func reminderInvalidMinuteNegativeFails() {
        let service = createService()
        let habit = createHabitWithReminders([ReminderTime(hour: 9, minute: -1)])
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    @Test("Too many reminders fails validation")
    func tooManyRemindersFails() {
        let service = createService()
        var reminders: [ReminderTime] = []
        for hour in 0...ImportFieldLimits.maxRemindersPerHabit {
            reminders.append(ReminderTime(hour: hour % 24, minute: 0))
        }
        let habit = createHabitWithReminders(reminders)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .tooManyReminders = result.errors.first {} else {
            Issue.record("Expected tooManyReminders error")
        }
    }

    @Test("Edge case - hour 23 and minute 59 is valid")
    func edgeCaseMaxValidTimeIsValid() {
        let service = createService()
        let habit = createHabitWithReminders([ReminderTime(hour: 23, minute: 59)])
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Edge case - hour 0 and minute 0 is valid")
    func edgeCaseMinValidTimeIsValid() {
        let service = createService()
        let habit = createHabitWithReminders([ReminderTime(hour: 0, minute: 0)])
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    // MARK: - Helpers

    private func createService() -> ImportValidationService {
        DefaultImportValidationService(logger: DebugLogger(subsystem: "test", category: "validation"))
    }

    private func createHabitWithReminders(_ reminders: [ReminderTime]) -> Habit {
        Habit(name: "Test", colorHex: "#2DA9E3", reminders: reminders)
    }
}

// MARK: - Location Configuration Validation Tests

@Suite("ImportValidationService - Location Configuration Validation")
struct LocationConfigurationValidationTests {

    // MARK: - Latitude Validation

    @Test("Valid latitude passes validation")
    func validLatitudePasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 45.5231, longitude: -122.6765)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
        #expect(result.hasLocationConfigurations)
    }

    @Test("Latitude at minimum bound passes validation")
    func latitudeAtMinimumBoundPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: -90.0, longitude: 0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Latitude at maximum bound passes validation")
    func latitudeAtMaximumBoundPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 90.0, longitude: 0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Latitude below minimum fails validation")
    func latitudeBelowMinimumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: -90.1, longitude: 0)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .locationLatitudeInvalid = result.errors.first {} else {
            Issue.record("Expected locationLatitudeInvalid error")
        }
    }

    @Test("Latitude above maximum fails validation")
    func latitudeAboveMaximumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 90.1, longitude: 0)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - Longitude Validation

    @Test("Longitude at minimum bound passes validation")
    func longitudeAtMinimumBoundPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: -180.0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Longitude at maximum bound passes validation")
    func longitudeAtMaximumBoundPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 180.0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Longitude below minimum fails validation")
    func longitudeBelowMinimumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: -180.1)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .locationLongitudeInvalid = result.errors.first {} else {
            Issue.record("Expected locationLongitudeInvalid error")
        }
    }

    @Test("Longitude above maximum fails validation")
    func longitudeAboveMaximumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 180.1)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - Radius Validation

    @Test("Radius at minimum bound passes validation")
    func radiusAtMinimumBoundPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, radius: 50.0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Radius at maximum bound passes validation")
    func radiusAtMaximumBoundPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, radius: 500.0)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Radius below minimum fails validation")
    func radiusBelowMinimumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, radius: 49.9)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .locationRadiusInvalid = result.errors.first {} else {
            Issue.record("Expected locationRadiusInvalid error")
        }
    }

    @Test("Radius above maximum fails validation")
    func radiusAboveMaximumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, radius: 500.1)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - Location Label Validation

    @Test("Location label at max length passes validation")
    func locationLabelAtMaxLengthPasses() {
        let service = createService()
        let label = String(repeating: "a", count: ImportFieldLimits.maxLocationLabelLength)
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, locationLabel: label)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Location label exceeding max length fails validation")
    func locationLabelExceedingMaxLengthFails() {
        let service = createService()
        let label = String(repeating: "a", count: ImportFieldLimits.maxLocationLabelLength + 1)
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, locationLabel: label)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .locationLabelTooLong = result.errors.first {} else {
            Issue.record("Expected locationLabelTooLong error")
        }
    }

    // MARK: - Cooldown Validation

    @Test("Valid cooldown minutes passes validation")
    func validCooldownMinutesPasses() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, cooldownMinutes: 30)
        let result = service.validateHabits([habit])
        #expect(result.isValid)
    }

    @Test("Cooldown below minimum fails validation")
    func cooldownBelowMinimumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, cooldownMinutes: 0)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        if case .locationCooldownInvalid = result.errors.first {} else {
            Issue.record("Expected locationCooldownInvalid error")
        }
    }

    @Test("Cooldown above maximum fails validation")
    func cooldownAboveMaximumFails() {
        let service = createService()
        let habit = createHabitWithLocation(latitude: 0, longitude: 0, cooldownMinutes: 1441)
        let result = service.validateHabits([habit])
        #expect(!result.isValid)
    }

    // MARK: - hasLocationConfigurations Flag

    @Test("Habits without location configs - hasLocationConfigurations is false")
    func habitsWithoutLocationConfigsHasLocationConfigurationsFalse() {
        let service = createService()
        let habit = Habit(name: "Test", colorHex: "#2DA9E3")
        let result = service.validateHabits([habit])
        #expect(result.isValid)
        #expect(!result.hasLocationConfigurations)
    }

    @Test("At least one habit with location configs - hasLocationConfigurations is true")
    func atLeastOneHabitWithLocationConfigsHasLocationConfigurationsTrue() {
        let service = createService()
        let habitWithoutLocation = Habit(name: "Test1", colorHex: "#2DA9E3")
        let habitWithLocation = createHabitWithLocation(latitude: 0, longitude: 0)
        let result = service.validateHabits([habitWithoutLocation, habitWithLocation])
        #expect(result.isValid)
        #expect(result.hasLocationConfigurations)
    }

    // MARK: - Helpers

    private func createService() -> ImportValidationService {
        DefaultImportValidationService(logger: DebugLogger(subsystem: "test", category: "validation"))
    }

    private func createHabitWithLocation(
        latitude: Double,
        longitude: Double,
        radius: Double = 100.0,
        locationLabel: String? = nil,
        cooldownMinutes: Int? = nil
    ) -> Habit {
        let frequency: NotificationFrequency = cooldownMinutes != nil
            ? .everyEntry(cooldownMinutes: cooldownMinutes!)
            : .oncePerDay

        let locationConfig = LocationConfiguration(
            latitude: latitude,
            longitude: longitude,
            radius: radius,
            frequency: frequency,
            locationLabel: locationLabel
        )

        return Habit(
            name: "Test Habit",
            colorHex: "#2DA9E3",
            locationConfiguration: locationConfig
        )
    }
}

// MARK: - Category Validation Tests

@Suite("ImportValidationService - Category Validation")
struct CategoryValidationTests {

    @Test("Valid category passes validation")
    func validCategoryPasses() {
        let service = createService()
        let category = HabitCategory(
            id: "health",
            name: "Health",
            displayName: "Health & Wellness",
            emoji: "💪",
            order: 1
        )
        let errors = service.validateCategories([category])
        #expect(errors.isEmpty)
    }

    @Test("Empty category name fails validation")
    func emptyCategoryNameFails() {
        let service = createService()
        let category = HabitCategory(
            id: "health",
            name: "",
            displayName: "Health",
            emoji: "💪",
            order: 1
        )
        let errors = service.validateCategories([category])
        #expect(!errors.isEmpty)
        if case .categoryNameEmpty = errors.first {} else {
            Issue.record("Expected categoryNameEmpty error")
        }
    }

    @Test("Category name exceeding max length fails validation")
    func categoryNameExceedingMaxLengthFails() {
        let service = createService()
        let longName = String(repeating: "a", count: ImportFieldLimits.maxCategoryNameLength + 1)
        let category = HabitCategory(
            id: "health",
            name: longName,
            displayName: "Health",
            emoji: "💪",
            order: 1
        )
        let errors = service.validateCategories([category])
        #expect(!errors.isEmpty)
        if case .categoryNameTooLong = errors.first {} else {
            Issue.record("Expected categoryNameTooLong error")
        }
    }

    @Test("Negative order fails validation")
    func negativeOrderFails() {
        let service = createService()
        let category = HabitCategory(
            id: "health",
            name: "Health",
            displayName: "Health",
            emoji: "💪",
            order: -1
        )
        let errors = service.validateCategories([category])
        #expect(!errors.isEmpty)
        if case .categoryOrderInvalid = errors.first {} else {
            Issue.record("Expected categoryOrderInvalid error")
        }
    }

    @Test("Order exceeding max fails validation")
    func orderExceedingMaxFails() {
        let service = createService()
        let category = HabitCategory(
            id: "health",
            name: "Health",
            displayName: "Health",
            emoji: "💪",
            order: ImportFieldLimits.maxCategoryOrder + 1
        )
        let errors = service.validateCategories([category])
        #expect(!errors.isEmpty)
    }

    // MARK: - Helper

    private func createService() -> ImportValidationService {
        DefaultImportValidationService(logger: DebugLogger(subsystem: "test", category: "validation"))
    }
}

// MARK: - Habit Log Validation Tests

@Suite("ImportValidationService - Habit Log Validation")
struct HabitLogValidationTests {

    @Test("Valid habit log passes validation")
    func validHabitLogPasses() {
        let service = createService()
        let log = HabitLog(habitID: UUID(), date: Date(), value: 5.0, timezone: "America/New_York")
        let errors = service.validateHabitLogs([log])
        #expect(errors.isEmpty)
    }

    @Test("Habit log with nil value passes validation")
    func habitLogWithNilValuePasses() {
        let service = createService()
        let log = HabitLog(habitID: UUID(), date: Date(), value: nil, timezone: "America/New_York")
        let errors = service.validateHabitLogs([log])
        #expect(errors.isEmpty)
    }

    @Test("Negative value fails validation")
    func negativeValueFails() {
        let service = createService()
        let log = HabitLog(habitID: UUID(), date: Date(), value: -1.0, timezone: "America/New_York")
        let errors = service.validateHabitLogs([log])
        #expect(!errors.isEmpty)
        if case .habitLogValueNegative = errors.first {} else {
            Issue.record("Expected habitLogValueNegative error")
        }
    }

    @Test("Excessive value fails validation")
    func excessiveValueFails() {
        let service = createService()
        let log = HabitLog(
            habitID: UUID(),
            date: Date(),
            value: ImportFieldLimits.maxLogValue + 1,
            timezone: "America/New_York"
        )
        let errors = service.validateHabitLogs([log])
        #expect(!errors.isEmpty)
        if case .habitLogValueTooLarge = errors.first {} else {
            Issue.record("Expected habitLogValueTooLarge error")
        }
    }

    @Test("Invalid timezone fails validation")
    func invalidTimezoneFails() {
        let service = createService()
        let log = HabitLog(habitID: UUID(), date: Date(), value: 1.0, timezone: "Invalid/Timezone")
        let errors = service.validateHabitLogs([log])
        #expect(!errors.isEmpty)
        if case .habitLogTimezoneInvalid = errors.first {} else {
            Issue.record("Expected habitLogTimezoneInvalid error")
        }
    }

    @Test("Valid timezone identifiers pass validation")
    func validTimezoneIdentifiersPass() {
        let service = createService()
        let validTimezones = [
            "America/New_York",
            "Europe/London",
            "Asia/Tokyo",
            "UTC",
            "GMT"
        ]

        for tz in validTimezones {
            let log = HabitLog(habitID: UUID(), date: Date(), value: 1.0, timezone: tz)
            let errors = service.validateHabitLogs([log])
            #expect(errors.isEmpty, "Timezone \(tz) should be valid")
        }
    }

    // MARK: - Helper

    private func createService() -> ImportValidationService {
        DefaultImportValidationService(logger: DebugLogger(subsystem: "test", category: "validation"))
    }
}

// MARK: - Multiple Error Aggregation Tests

@Suite("ImportValidationService - Error Aggregation")
struct ErrorAggregationTests {

    @Test("Multiple errors are collected for single habit")
    func multipleErrorsCollectedForSingleHabit() {
        let service = createService()
        // Create habit with multiple issues
        let habit = Habit(
            name: "", // empty name
            colorHex: "invalid", // invalid color
            dailyTarget: -5.0, // negative target
            priorityLevel: 10 // invalid priority
        )

        let result = service.validateHabits([habit])
        #expect(!result.isValid)
        #expect(result.errors.count >= 3, "Should have at least 3 errors")
    }

    @Test("Errors are collected across multiple habits")
    func errorsCollectedAcrossMultipleHabits() {
        let service = createService()
        let habit1 = Habit(name: "", colorHex: "#FFFFFF") // empty name
        let habit2 = Habit(name: "Valid", colorHex: "invalid") // invalid color

        let result = service.validateHabits([habit1, habit2])
        #expect(!result.isValid)
        #expect(result.errors.count == 2)
    }

    @Test("Mixed valid and invalid data - only invalid reported")
    func mixedValidInvalidDataOnlyInvalidReported() {
        let service = createService()
        let validHabit = Habit(name: "Valid Habit", colorHex: "#2DA9E3")
        let invalidHabit = Habit(name: "", colorHex: "#2DA9E3")

        let result = service.validateHabits([validHabit, invalidHabit])
        #expect(!result.isValid)
        #expect(result.errors.count == 1)
    }

    // MARK: - Helper

    private func createService() -> ImportValidationService {
        DefaultImportValidationService(logger: DebugLogger(subsystem: "test", category: "validation"))
    }
}
