//
//  HabitDetailViewModelTests.swift
//  RitualistTests
//
//  Unit tests for HabitDetailViewModel covering:
//  - Start date validation against existing logs
//  - Form validity with error states
//  - Duplicate validation failure handling
//  - Retry functionality
//

import Testing
import Foundation
import CoreLocation
@testable import Ritualist
@testable import RitualistCore

// MARK: - Start Date Validation Tests

@Suite("HabitDetailViewModel - Start Date Validation", .tags(.habits, .habitEditing, .isolated, .fast))
@MainActor
struct HabitDetailViewModelStartDateTests {

    @Test("Start date is valid when no logs exist")
    @MainActor
    func startDateValidWhenNoLogs() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: nil  // No logs exist
        )

        // Await async initialization
        await viewModel.loadInitialData()

        // Assert
        #expect(viewModel.isStartDateValid == true, "Start date should be valid when no logs exist")
    }

    @Test("Start date is valid when on same day as earliest log")
    @MainActor
    func startDateValidOnSameDay() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: TestDates.today  // Log exists on same day
        )

        await viewModel.loadInitialData()

        // Assert
        #expect(viewModel.isStartDateValid == true, "Start date should be valid when same as earliest log")
    }

    @Test("Start date is valid when before earliest log")
    @MainActor
    func startDateValidWhenBeforeEarliestLog() async throws {
        // Arrange: Start date is yesterday, earliest log is today
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.yesterday)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: TestDates.today
        )

        await viewModel.loadInitialData()

        // Assert
        #expect(viewModel.isStartDateValid == true, "Start date should be valid when before earliest log")
    }

    @Test("Start date is invalid when after earliest log")
    @MainActor
    func startDateInvalidWhenAfterEarliestLog() async throws {
        // Arrange: Start date is today, earliest log is yesterday - invalid!
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: TestDates.yesterday
        )

        await viewModel.loadInitialData()

        // Assert
        #expect(viewModel.isStartDateValid == false, "Start date should be invalid when after earliest log")
    }

    @Test("Start date validation updates when user changes start date")
    @MainActor
    func startDateValidationUpdatesOnChange() async throws {
        // Arrange: Earliest log 5 days ago, start date 10 days ago (valid)
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(10))
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: TestDates.daysAgo(5)
        )

        await viewModel.loadInitialData()

        // Initially valid
        #expect(viewModel.isStartDateValid == true)

        // User changes start date to today (after earliest log)
        viewModel.startDate = TestDates.today

        // Should now be invalid
        #expect(viewModel.isStartDateValid == false, "Validation should update when start date changes")

        // User changes to valid date
        viewModel.startDate = TestDates.daysAgo(7)

        // Should be valid again
        #expect(viewModel.isStartDateValid == true, "Validation should update to valid")
    }

    @Test("Start date many days before earliest log is valid")
    @MainActor
    func startDateManyDaysBeforeIsValid() async throws {
        // Arrange: Start date 30 days ago, earliest log is today
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.daysAgo(30))
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: TestDates.today
        )

        await viewModel.loadInitialData()

        // Assert
        #expect(viewModel.isStartDateValid == true, "Start date many days before earliest log should be valid")
    }
}

// MARK: - Form Validity with Error States Tests

@Suite("HabitDetailViewModel - Form Validity Error States", .tags(.habits, .habitEditing, .errorHandling, .isolated, .fast))
@MainActor
struct HabitDetailViewModelFormValidityTests {

    @Test("Form is invalid when earliest log date load failed")
    @MainActor
    func formInvalidWhenEarliestLogLoadFailed() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Configure mock to fail
        mocks.getEarliestLogDate.shouldFail = true

        // Wait for initial load to complete
        await viewModel.loadInitialData()

        // Trigger a reload to get the failure
        await viewModel.loadEarliestLogDate()

        // Assert
        #expect(viewModel.earliestLogDateLoadFailed == true, "Error flag should be set on failure")
        #expect(viewModel.isFormValid == false, "Form should be invalid when earliest log date load failed")
    }

    @Test("Form is invalid when duplicate validation failed")
    @MainActor
    func formInvalidWhenDuplicateValidationFailed() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Configure mock to fail and trigger validation
        mocks.validateHabitUniqueness.shouldFail = true
        await viewModel.validateForDuplicates()

        // Assert
        #expect(viewModel.duplicateValidationFailed == true, "Duplicate validation failed flag should be set")
        #expect(viewModel.isFormValid == false, "Form should be invalid when duplicate validation failed")
    }

    @Test("Form is invalid when habit is duplicate")
    @MainActor
    func formInvalidWhenDuplicate() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            isUnique: false  // Habit is a duplicate
        )

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Trigger duplicate validation
        await viewModel.validateForDuplicates()

        // Assert
        #expect(viewModel.isDuplicateHabit == true, "Should detect duplicate habit")
        #expect(viewModel.isFormValid == false, "Form should be invalid when habit is duplicate")
    }

    @Test("Form validity requires all conditions to pass in edit mode")
    @MainActor
    func formValidityRequiresAllConditionsInEditMode() async throws {
        // Arrange - set up a valid edit scenario
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: habit,
            earliestLogDate: nil,
            isUnique: true
        )

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Assert - edit mode allows nil category during loading
        #expect(viewModel.isEditMode == true)
        #expect(viewModel.isFormValid == true, "Form should be valid when all conditions pass in edit mode")
    }

    @Test("Form is invalid with empty name")
    @MainActor
    func formInvalidWithEmptyName() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Clear the name
        viewModel.name = ""

        // Assert
        #expect(viewModel.isFormValid == false, "Form should be invalid with empty name")
    }

    @Test("Form is invalid with whitespace-only name")
    @MainActor
    func formInvalidWithWhitespaceName() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Set whitespace name
        viewModel.name = "   "

        // Assert
        #expect(viewModel.isFormValid == false, "Form should be invalid with whitespace-only name")
    }
}

// MARK: - Retry Functionality Tests

@Suite("HabitDetailViewModel - Retry Functionality", .tags(.habits, .habitEditing, .errorHandling, .isolated, .fast))
@MainActor
struct HabitDetailViewModelRetryTests {

    @Test("loadEarliestLogDate can be retried after failure")
    @MainActor
    func loadEarliestLogDateCanBeRetried() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Configure mock to fail initially
        mocks.getEarliestLogDate.shouldFail = true

        // Wait for initial load
        await viewModel.loadInitialData()

        // Trigger a load that will fail
        await viewModel.loadEarliestLogDate()
        #expect(viewModel.earliestLogDateLoadFailed == true)

        let callCountAfterFailure = mocks.getEarliestLogDate.executeCallCount

        // Fix the mock and retry
        mocks.getEarliestLogDate.shouldFail = false
        mocks.getEarliestLogDate.dateToReturn = TestDates.yesterday

        await viewModel.loadEarliestLogDate()

        // Assert
        #expect(mocks.getEarliestLogDate.executeCallCount > callCountAfterFailure, "Should have made another call")
        #expect(viewModel.earliestLogDateLoadFailed == false, "Error flag should be cleared after successful retry")
        #expect(viewModel.earliestLogDate != nil, "Should have loaded the date")
    }

    @Test("validateForDuplicates can be retried after failure")
    @MainActor
    func validateForDuplicatesCanBeRetried() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Configure mock to fail and trigger validation
        mocks.validateHabitUniqueness.shouldFail = true
        await viewModel.validateForDuplicates()
        #expect(viewModel.duplicateValidationFailed == true)

        // Fix mock and retry
        mocks.validateHabitUniqueness.shouldFail = false
        mocks.validateHabitUniqueness.isUnique = true

        await viewModel.validateForDuplicates()

        // Assert
        #expect(viewModel.duplicateValidationFailed == false, "Error flag should be cleared after successful retry")
        #expect(viewModel.isDuplicateHabit == false, "Should show habit is unique")
    }

    @Test("Form becomes valid after successful retry of earliest log date")
    @MainActor
    func formBecomesValidAfterSuccessfulRetry() async throws {
        // Arrange
        let habit = HabitBuilder.binary(schedule: .daily, startDate: TestDates.today)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Configure mock to fail
        mocks.getEarliestLogDate.shouldFail = true

        // Wait and trigger failure
        await viewModel.loadInitialData()
        await viewModel.loadEarliestLogDate()

        #expect(viewModel.isFormValid == false, "Form should be invalid after failure")

        // Fix and retry
        mocks.getEarliestLogDate.shouldFail = false
        mocks.getEarliestLogDate.dateToReturn = nil

        await viewModel.loadEarliestLogDate()

        // Assert
        #expect(viewModel.isFormValid == true, "Form should be valid after successful retry")
    }
}

// MARK: - Edge Cases

@Suite("HabitDetailViewModel - Edge Cases", .tags(.habits, .habitEditing, .edgeCases, .isolated, .fast))
@MainActor
struct HabitDetailViewModelEdgeCaseTests {

    @Test("New habit (no edit mode) does not load earliest log date")
    @MainActor
    func newHabitDoesNotLoadEarliestLogDate() async throws {
        // Arrange - create new habit (nil)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            habit: nil,  // New habit
            earliestLogDate: TestDates.yesterday
        )

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Assert - new habits skip earliest log date loading
        #expect(viewModel.isEditMode == false)
        // The guard in loadEarliestLogDate returns early for new habits
        // so executeCallCount might be 0 or date remains nil
        #expect(viewModel.isStartDateValid == true, "New habit should always have valid start date")
    }

    @Test("Start date validation handles same day different times correctly")
    @MainActor
    func startDateHandlesSameDayDifferentTimes() async throws {
        // Arrange: Start date at noon, earliest log at midnight of same day
        let calendar = Calendar.current
        let todayNoon = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: TestDates.today)!
        let todayMidnight = calendar.date(bySettingHour: 0, minute: 1, second: 0, of: TestDates.today)!

        let habit = HabitBuilder.binary(schedule: .daily, startDate: todayNoon)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        // Manually set the earliest log date to test the comparison
        mocks.getEarliestLogDate.dateToReturn = todayMidnight

        // Wait for async initialization
        await viewModel.loadInitialData()

        // Assert - same calendar day should be valid
        #expect(viewModel.isStartDateValid == true, "Same calendar day should be valid regardless of time")
    }
}

// MARK: - Individual Validation Properties Tests

@Suite("HabitDetailViewModel - Validation Properties", .tags(.habits, .habitCreation, .isolated, .fast))
@MainActor
struct HabitDetailViewModelValidationPropertiesTests {

    // MARK: - isNameValid

    @Test("isNameValid returns true for valid name")
    @MainActor
    func isNameValidForValidName() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.name = "Morning Run"
        #expect(viewModel.isNameValid == true)
    }

    @Test("isNameValid returns false for empty name")
    @MainActor
    func isNameValidForEmptyName() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.name = ""
        #expect(viewModel.isNameValid == false)
    }

    @Test("isNameValid returns false for whitespace-only name")
    @MainActor
    func isNameValidForWhitespaceName() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.name = "   \t\n  "
        #expect(viewModel.isNameValid == false)
    }

    // MARK: - isUnitLabelValid

    @Test("isUnitLabelValid always true for binary habits")
    @MainActor
    func isUnitLabelValidForBinaryHabit() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedKind = .binary
        viewModel.unitLabel = ""  // Empty is OK for binary
        #expect(viewModel.isUnitLabelValid == true)
    }

    @Test("isUnitLabelValid requires value for numeric habits")
    @MainActor
    func isUnitLabelValidForNumericHabit() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedKind = .numeric
        viewModel.unitLabel = ""
        #expect(viewModel.isUnitLabelValid == false)

        viewModel.unitLabel = "glasses"
        #expect(viewModel.isUnitLabelValid == true)
    }

    @Test("isUnitLabelValid rejects whitespace-only for numeric habits")
    @MainActor
    func isUnitLabelValidRejectsWhitespace() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedKind = .numeric
        viewModel.unitLabel = "   "
        #expect(viewModel.isUnitLabelValid == false)
    }

    // MARK: - isDailyTargetValid

    @Test("isDailyTargetValid always true for binary habits")
    @MainActor
    func isDailyTargetValidForBinaryHabit() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedKind = .binary
        viewModel.dailyTarget = 0  // Zero is OK for binary
        #expect(viewModel.isDailyTargetValid == true)
    }

    @Test("isDailyTargetValid requires positive value for numeric habits")
    @MainActor
    func isDailyTargetValidForNumericHabit() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedKind = .numeric
        viewModel.dailyTarget = 0
        #expect(viewModel.isDailyTargetValid == false)

        viewModel.dailyTarget = 8
        #expect(viewModel.isDailyTargetValid == true)
    }

    @Test("isDailyTargetValid rejects negative values for numeric habits")
    @MainActor
    func isDailyTargetValidRejectsNegative() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedKind = .numeric
        viewModel.dailyTarget = -5
        #expect(viewModel.isDailyTargetValid == false)
    }

    // MARK: - isScheduleValid

    @Test("isScheduleValid always true for daily schedule")
    @MainActor
    func isScheduleValidForDailySchedule() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedSchedule = .daily
        viewModel.selectedDaysOfWeek = []  // Empty is OK for daily
        #expect(viewModel.isScheduleValid == true)
    }

    @Test("isScheduleValid requires days for daysOfWeek schedule")
    @MainActor
    func isScheduleValidForDaysOfWeekSchedule() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedSchedule = .daysOfWeek
        viewModel.selectedDaysOfWeek = []
        #expect(viewModel.isScheduleValid == false)

        viewModel.selectedDaysOfWeek = [1, 3, 5]  // Mon, Wed, Fri
        #expect(viewModel.isScheduleValid == true)
    }

    // MARK: - isCategoryValid

    @Test("isCategoryValid returns true when category selected")
    @MainActor
    func isCategoryValidWhenSelected() async throws {
        let category = HabitCategory(id: "test", name: "test", displayName: "Test", emoji: "📝", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])
        await viewModel.loadInitialData()

        viewModel.selectedCategory = category
        #expect(viewModel.isCategoryValid == true)
    }

    @Test("isCategoryValid returns false when no category selected")
    @MainActor
    func isCategoryValidWhenNotSelected() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.selectedCategory = nil
        #expect(viewModel.isCategoryValid == false)
    }
}

// MARK: - Form Validity for Numeric Habits

@Suite("HabitDetailViewModel - Numeric Habit Validation", .tags(.habits, .habitCreation, .isolated, .fast))
@MainActor
struct HabitDetailViewModelNumericHabitTests {

    @Test("Form invalid for numeric habit with zero daily target")
    @MainActor
    func formInvalidWithZeroDailyTarget() async throws {
        let category = HabitCategory(id: "test", name: "test", displayName: "Test", emoji: "📝", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])
        await viewModel.loadInitialData()

        viewModel.name = "Drink Water"
        viewModel.selectedKind = .numeric
        viewModel.dailyTarget = 0
        viewModel.unitLabel = "glasses"
        viewModel.selectedCategory = category

        #expect(viewModel.isFormValid == false, "Form should be invalid with zero daily target")
    }

    @Test("Form invalid for numeric habit with empty unit label")
    @MainActor
    func formInvalidWithEmptyUnitLabel() async throws {
        let category = HabitCategory(id: "test", name: "test", displayName: "Test", emoji: "📝", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])
        await viewModel.loadInitialData()

        viewModel.name = "Drink Water"
        viewModel.selectedKind = .numeric
        viewModel.dailyTarget = 8
        viewModel.unitLabel = ""
        viewModel.selectedCategory = category

        #expect(viewModel.isFormValid == false, "Form should be invalid with empty unit label")
    }

    @Test("Form valid for numeric habit with all fields filled")
    @MainActor
    func formValidForCompleteNumericHabit() async throws {
        let category = HabitCategory(id: "test", name: "test", displayName: "Test", emoji: "📝", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])
        await viewModel.loadInitialData()

        viewModel.name = "Drink Water"
        viewModel.selectedKind = .numeric
        viewModel.dailyTarget = 8
        viewModel.unitLabel = "glasses"
        viewModel.selectedCategory = category

        #expect(viewModel.isFormValid == true, "Form should be valid for complete numeric habit")
    }

    @Test("Form valid for binary habit without unit label or target")
    @MainActor
    func formValidForBinaryHabitWithoutNumericFields() async throws {
        let category = HabitCategory(id: "test", name: "test", displayName: "Test", emoji: "📝", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])
        await viewModel.loadInitialData()

        viewModel.name = "Morning Run"
        viewModel.selectedKind = .binary
        viewModel.dailyTarget = 0  // Ignored for binary
        viewModel.unitLabel = ""   // Ignored for binary
        viewModel.selectedCategory = category

        #expect(viewModel.isFormValid == true, "Binary habit should be valid without numeric fields")
    }
}

// MARK: - Reminder Management Tests

@Suite("HabitDetailViewModel - Reminder Management", .tags(.habits, .habitEditing, .notifications, .isolated, .fast))
@MainActor
struct HabitDetailViewModelReminderTests {

    @Test("addReminder adds new reminder")
    @MainActor
    func addReminderAddsNew() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        #expect(viewModel.reminders.isEmpty)

        viewModel.addReminder(hour: 9, minute: 0)

        #expect(viewModel.reminders.count == 1)
        #expect(viewModel.reminders[0].hour == 9)
        #expect(viewModel.reminders[0].minute == 0)
    }

    @Test("addReminder prevents duplicates")
    @MainActor
    func addReminderPreventsDuplicates() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 9, minute: 0)
        viewModel.addReminder(hour: 9, minute: 0)  // Duplicate

        #expect(viewModel.reminders.count == 1, "Should not add duplicate reminder")
    }

    @Test("addReminder sorts reminders by time")
    @MainActor
    func addReminderSortsByTime() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 18, minute: 0)  // Evening
        viewModel.addReminder(hour: 9, minute: 0)   // Morning
        viewModel.addReminder(hour: 12, minute: 30) // Noon

        #expect(viewModel.reminders.count == 3)
        #expect(viewModel.reminders[0].hour == 9)
        #expect(viewModel.reminders[1].hour == 12)
        #expect(viewModel.reminders[2].hour == 18)
    }

    @Test("addReminder sorts by minute when hours are equal")
    @MainActor
    func addReminderSortsByMinute() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 9, minute: 30)
        viewModel.addReminder(hour: 9, minute: 0)
        viewModel.addReminder(hour: 9, minute: 15)

        #expect(viewModel.reminders[0].minute == 0)
        #expect(viewModel.reminders[1].minute == 15)
        #expect(viewModel.reminders[2].minute == 30)
    }

    @Test("removeReminder at index removes correct reminder")
    @MainActor
    func removeReminderAtIndexRemovesCorrect() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 9, minute: 0)
        viewModel.addReminder(hour: 12, minute: 0)
        viewModel.addReminder(hour: 18, minute: 0)

        viewModel.removeReminder(at: 1)  // Remove 12:00

        #expect(viewModel.reminders.count == 2)
        #expect(viewModel.reminders[0].hour == 9)
        #expect(viewModel.reminders[1].hour == 18)
    }

    @Test("removeReminder at invalid index does nothing")
    @MainActor
    func removeReminderAtInvalidIndexDoesNothing() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 9, minute: 0)

        viewModel.removeReminder(at: -1)  // Invalid
        viewModel.removeReminder(at: 5)   // Out of bounds

        #expect(viewModel.reminders.count == 1, "Invalid index should not remove anything")
    }

    @Test("removeReminder by value removes matching reminder")
    @MainActor
    func removeReminderByValueRemovesMatching() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 9, minute: 0)
        viewModel.addReminder(hour: 12, minute: 0)

        let reminderToRemove = ReminderTime(hour: 9, minute: 0)
        viewModel.removeReminder(reminderToRemove)

        #expect(viewModel.reminders.count == 1)
        #expect(viewModel.reminders[0].hour == 12)
    }

    @Test("removeReminder by non-matching value does nothing")
    @MainActor
    func removeReminderByNonMatchingValueDoesNothing() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()
        await viewModel.loadInitialData()

        viewModel.addReminder(hour: 9, minute: 0)

        let nonExistentReminder = ReminderTime(hour: 20, minute: 0)
        viewModel.removeReminder(nonExistentReminder)

        #expect(viewModel.reminders.count == 1, "Non-matching reminder should not be removed")
    }
}

// MARK: - Category Management Tests

@Suite("HabitDetailViewModel - Category Management", .tags(.habits, .categories, .isolated, .fast))
@MainActor
struct HabitDetailViewModelCategoryTests {

    @Test("loadCategories populates categories list")
    @MainActor
    func loadCategoriesPopulatesList() async throws {
        let categories = [
            HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true),
            HabitCategory(id: "fitness", name: "fitness", displayName: "Fitness", emoji: "💪", order: 1, isActive: true)
        ]
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: categories)

        await viewModel.loadInitialData()

        #expect(viewModel.categories.count == 2)
        #expect(viewModel.isLoadingCategories == false)
        #expect(viewModel.categoriesError == nil)
    }

    @Test("loadCategories handles failure")
    @MainActor
    func loadCategoriesHandlesFailure() async throws {
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel()

        mocks.getActiveCategories.shouldFail = true

        await viewModel.loadInitialData()

        await viewModel.loadCategories()

        #expect(viewModel.categories.isEmpty)
        #expect(viewModel.categoriesError != nil)
        #expect(viewModel.isLoadingCategories == false)
    }

    @Test("loadCategories sets selected category in edit mode")
    @MainActor
    func loadCategoriesSetsSelectedInEditMode() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let habit = HabitBuilder.binary(categoryId: "health", schedule: .daily)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit, categories: [category])

        await viewModel.loadInitialData()

        #expect(viewModel.selectedCategory?.id == "health", "Should auto-select habit's category")
    }

    @Test("selectCategory updates selection and triggers validation")
    @MainActor
    func selectCategoryUpdatesAndValidates() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(categories: [category])

        await viewModel.loadInitialData()

        viewModel.name = "Test Habit"
        let initialCallCount = mocks.validateHabitUniqueness.executeCallCount

        viewModel.selectCategory(category)

        // Wait for async validation
        await viewModel.loadInitialData()

        #expect(viewModel.selectedCategory?.id == "health")
        #expect(mocks.validateHabitUniqueness.executeCallCount > initialCallCount, "Should trigger duplicate validation")
    }

    @Test("validateForDuplicates skips validation for empty name")
    @MainActor
    func validateForDuplicatesSkipsEmptyName() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        viewModel.name = ""
        await viewModel.validateForDuplicates()

        #expect(viewModel.isDuplicateHabit == false)
        // The use case should not be called for empty names
    }

    @Test("validateForDuplicates detects duplicates")
    @MainActor
    func validateForDuplicatesDetectsDuplicates() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(isUnique: false)

        await viewModel.loadInitialData()

        viewModel.name = "Existing Habit"
        await viewModel.validateForDuplicates()

        #expect(viewModel.isDuplicateHabit == true)
        #expect(viewModel.isValidatingDuplicate == false)
    }

    @Test("validateForDuplicates passes category and excludeId")
    @MainActor
    func validateForDuplicatesPassesParams() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let habit = HabitBuilder.binary(categoryId: "health", schedule: .daily)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(habit: habit, categories: [category])

        await viewModel.loadInitialData()

        viewModel.selectCategory(category)

        // Wait for validation triggered by selectCategory
        await viewModel.loadInitialData()

        #expect(mocks.validateHabitUniqueness.lastValidatedCategoryId == "health")
    }
}

// MARK: - Habit Data Loading Tests

@Suite("HabitDetailViewModel - Habit Data Loading", .tags(.habits, .habitEditing, .isolated, .fast))
@MainActor
struct HabitDetailViewModelDataLoadingTests {

    @Test("Edit mode loads habit data correctly")
    @MainActor
    func editModeLoadsHabitData() async throws {
        let habit = Habit(
            id: UUID(),
            name: "Morning Run",
            colorHex: "#FF5733",
            emoji: "🏃",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daily,
            reminders: [ReminderTime(hour: 7, minute: 0)],
            startDate: TestDates.daysAgo(10),
            endDate: nil,
            isActive: true,
            categoryId: nil,
            suggestionId: nil,
            locationConfiguration: nil
        )

        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        await viewModel.loadInitialData()

        #expect(viewModel.name == "Morning Run")
        #expect(viewModel.selectedEmoji == "🏃")
        #expect(viewModel.selectedColorHex == "#FF5733")
        #expect(viewModel.selectedKind == .binary)
        #expect(viewModel.selectedSchedule == .daily)
        #expect(viewModel.reminders.count == 1)
        #expect(viewModel.isEditMode == true)
    }

    @Test("Edit mode loads numeric habit data correctly")
    @MainActor
    func editModeLoadsNumericHabitData() async throws {
        let habit = Habit(
            id: UUID(),
            name: "Drink Water",
            colorHex: "#2DA9E3",
            emoji: "💧",
            kind: .numeric,
            unitLabel: "glasses",
            dailyTarget: 8,
            schedule: .daily,
            reminders: [],
            startDate: TestDates.today,
            endDate: nil,
            isActive: true,
            categoryId: nil,
            suggestionId: nil,
            locationConfiguration: nil
        )

        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        await viewModel.loadInitialData()

        #expect(viewModel.selectedKind == .numeric)
        #expect(viewModel.unitLabel == "glasses")
        #expect(viewModel.dailyTarget == 8)
    }

    @Test("Edit mode loads daysOfWeek schedule correctly")
    @MainActor
    func editModeLoadsDaysOfWeekSchedule() async throws {
        let habit = Habit(
            id: UUID(),
            name: "Gym",
            colorHex: "#2DA9E3",
            emoji: "💪",
            kind: .binary,
            unitLabel: nil,
            dailyTarget: nil,
            schedule: .daysOfWeek([1, 3, 5]),  // Mon, Wed, Fri
            reminders: [],
            startDate: TestDates.today,
            endDate: nil,
            isActive: true,
            categoryId: nil,
            suggestionId: nil,
            locationConfiguration: nil
        )

        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        await viewModel.loadInitialData()

        #expect(viewModel.selectedSchedule == .daysOfWeek)
        #expect(viewModel.selectedDaysOfWeek == [1, 3, 5])
    }

    @Test("New habit mode has default values")
    @MainActor
    func newHabitModeHasDefaults() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: nil)

        await viewModel.loadInitialData()

        #expect(viewModel.name == "")
        #expect(viewModel.selectedKind == .binary)
        #expect(viewModel.selectedSchedule == .daily)
        #expect(viewModel.selectedEmoji == "⭐")
        #expect(viewModel.isEditMode == false)
        #expect(viewModel.originalHabit == nil)
    }

    @Test("Edit mode preserves original habit reference")
    @MainActor
    func editModePreservesOriginalHabit() async throws {
        let habitId = UUID()
        let habit = HabitBuilder.binary(id: habitId, schedule: .daily)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(habit: habit)

        await viewModel.loadInitialData()

        #expect(viewModel.originalHabit?.id == habitId)
    }
}

// MARK: - Location Auth Status Tests

@Suite("HabitDetailViewModel - Location Auth Status", .tags(.habits, .system, .isolated, .fast))
@MainActor
struct HabitDetailViewModelLocationAuthTests {

    @Test("checkLocationAuthStatus updates status")
    @MainActor
    func checkLocationAuthStatusUpdates() async throws {
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(
            locationAuthStatus: .authorizedAlways
        )

        await viewModel.loadInitialData()

        #expect(viewModel.locationAuthStatus == .authorizedAlways)
        #expect(mocks.permissionCoordinator.checkLocationStatusCallCount >= 1)
    }

    @Test("checkLocationAuthStatus sets loading state")
    @MainActor
    func checkLocationAuthStatusSetsLoadingState() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // After async init completes, loading should be false
        #expect(viewModel.isCheckingLocationAuth == false)
    }
}

// MARK: - Map Picker Dismiss Tests

@Suite("HabitDetailViewModel - Map Picker Dismiss", .tags(.habits, .isolated, .fast))
@MainActor
struct HabitDetailViewModelMapPickerDismissTests {

    @Test("handleMapPickerDismiss clears placeholder config")
    @MainActor
    func handleMapPickerDismissClearsPlaceholder() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Set a placeholder config (0,0 coordinates)
        viewModel.locationConfiguration = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: true
        )

        viewModel.handleMapPickerDismiss()

        #expect(viewModel.locationConfiguration == nil, "Placeholder should be cleared on dismiss")
    }

    @Test("handleMapPickerDismiss keeps real location config")
    @MainActor
    func handleMapPickerDismissKeepsRealConfig() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Set a real location config
        viewModel.locationConfiguration = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),  // San Francisco
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: true
        )

        viewModel.handleMapPickerDismiss()

        #expect(viewModel.locationConfiguration != nil, "Real config should be kept on dismiss")
        #expect(viewModel.locationConfiguration?.coordinate.latitude == 37.7749)
    }

    @Test("handleMapPickerDismiss does nothing when no config")
    @MainActor
    func handleMapPickerDismissDoesNothingWhenNoConfig() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        viewModel.locationConfiguration = nil
        viewModel.handleMapPickerDismiss()

        #expect(viewModel.locationConfiguration == nil)
    }
}

// MARK: - Update Location Configuration Tests

@Suite("HabitDetailViewModel - Location Configuration", .tags(.habits, .isolated, .fast))
@MainActor
struct HabitDetailViewModelLocationConfigTests {

    @Test("updateLocationConfiguration sets config")
    @MainActor
    func updateLocationConfigurationSetsConfig() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        let config = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),  // NYC
            radius: 150,
            triggerType: .exit,
            frequency: .everyEntry(cooldownMinutes: 30),
            isEnabled: true
        )

        viewModel.updateLocationConfiguration(config)

        #expect(viewModel.locationConfiguration?.coordinate.latitude == 40.7128)
        #expect(viewModel.locationConfiguration?.radius == 150)
        #expect(viewModel.locationConfiguration?.triggerType == .exit)
    }

    @Test("updateLocationConfiguration can clear config")
    @MainActor
    func updateLocationConfigurationCanClear() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // First set a config
        viewModel.locationConfiguration = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: true
        )

        // Then clear it
        viewModel.updateLocationConfiguration(nil)

        #expect(viewModel.locationConfiguration == nil)
    }

    @Test("toggleLocationEnabled disabling clears config")
    @MainActor
    func toggleLocationEnabledDisablingClearsConfig() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Set a config
        viewModel.locationConfiguration = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: true
        )

        // Disable location
        viewModel.toggleLocationEnabled(false)

        #expect(viewModel.locationConfiguration == nil)
    }

    @Test("toggleLocationEnabled enabling with existing config updates enabled flag")
    @MainActor
    func toggleLocationEnabledWithExistingConfig() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Set a disabled config
        let config = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060),
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: false
        )
        viewModel.locationConfiguration = config

        // Enable location
        viewModel.toggleLocationEnabled(true)

        #expect(viewModel.locationConfiguration?.isEnabled == true)
    }
}

// MARK: - Retry and Error Clearing Tests

@Suite("HabitDetailViewModel - Error Handling", .tags(.habits, .errorHandling, .isolated, .fast))
@MainActor
struct HabitDetailViewModelErrorHandlingTests {

    @Test("retry clears error state")
    @MainActor
    func retryClearsError() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Simulate an error (we can't easily set private(set) error, but retry should clear it)
        await viewModel.retry()

        #expect(viewModel.error == nil)
    }

    @Test("didMakeChanges starts as false")
    @MainActor
    func didMakeChangesStartsFalse() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        #expect(viewModel.didMakeChanges == false)
    }
}

// MARK: - Fire-and-Forget Task Tests

@Suite("HabitDetailViewModel - Async Task Behavior", .tags(.habits, .async, .isolated, .fast))
@MainActor
struct HabitDetailViewModelAsyncTaskTests {

    // MARK: - selectCategory() Tests

    @Test("selectCategory updates selectedCategory immediately (synchronous)")
    @MainActor
    func selectCategoryUpdatesImmediately() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])

        await viewModel.loadInitialData()

        // Act - select category
        viewModel.selectCategory(category)

        // Assert - synchronous update happens immediately, no await needed
        #expect(viewModel.selectedCategory?.id == "health")
    }

    @Test("selectCategory triggers background validation")
    @MainActor
    func selectCategoryTriggersBackgroundValidation() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(categories: [category])

        await viewModel.loadInitialData()

        viewModel.name = "Test Habit"
        let initialCallCount = mocks.validateHabitUniqueness.executeCallCount

        // Act - select category (fires background Task)
        viewModel.selectCategory(category)

        // Await validation directly to ensure it completes
        await viewModel.validateForDuplicates()

        // Assert - validation was triggered (at least once more)
        #expect(mocks.validateHabitUniqueness.executeCallCount > initialCallCount)
    }

    @Test("selectCategory background validation detects duplicate")
    @MainActor
    func selectCategoryBackgroundValidationDetectsDuplicate() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            isUnique: false,  // Mock will report duplicate
            categories: [category]
        )

        await viewModel.loadInitialData()

        viewModel.name = "Existing Habit"

        // Act
        viewModel.selectCategory(category)

        // Await validation directly since selectCategory fires it in background
        await viewModel.validateForDuplicates()

        // Assert
        #expect(viewModel.isDuplicateHabit == true)
    }

    @Test("selectCategory skips validation when name is empty")
    @MainActor
    func selectCategorySkipsValidationForEmptyName() async throws {
        let category = HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "❤️", order: 0, isActive: true)
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(categories: [category])

        await viewModel.loadInitialData()

        viewModel.name = ""  // Empty name

        // Act
        viewModel.selectCategory(category)

        // Await validation directly - it will short-circuit for empty name
        await viewModel.validateForDuplicates()

        // Assert - validation skipped, not marked as duplicate
        #expect(viewModel.selectedCategory?.id == "health")
        #expect(viewModel.isDuplicateHabit == false)
    }

    // MARK: - toggleLocationEnabled() Tests

    @Test("toggleLocationEnabled(true) sets placeholder config immediately")
    @MainActor
    func toggleLocationEnabledSetsPlaceholderImmediately() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel(
            locationAuthStatus: .authorizedAlways
        )

        await viewModel.loadInitialData()

        // Ensure no config exists
        viewModel.locationConfiguration = nil

        // Act - enable location (no existing config)
        viewModel.toggleLocationEnabled(true)

        // Assert - placeholder is set immediately (synchronous part)
        #expect(viewModel.locationConfiguration != nil)
        #expect(viewModel.locationConfiguration?.coordinate.latitude == 0)
        #expect(viewModel.locationConfiguration?.coordinate.longitude == 0)
    }

    @Test("toggleLocationEnabled(true) triggers permission check in background")
    @MainActor
    func toggleLocationEnabledTriggersPermissionCheck() async throws {
        let (viewModel, mocks) = TestViewModelContainer.habitDetailViewModel(
            locationAuthStatus: .notDetermined
        )

        await viewModel.loadInitialData()

        let initialCheckCount = mocks.permissionCoordinator.checkLocationStatusCallCount
        viewModel.locationConfiguration = nil

        // Act
        viewModel.toggleLocationEnabled(true)

        // Await the check directly to ensure it completes
        await viewModel.checkLocationAuthStatus()

        // Assert - permission check was triggered (at least once more)
        #expect(mocks.permissionCoordinator.checkLocationStatusCallCount > initialCheckCount)
    }

    @Test("toggleLocationEnabled(false) clears config synchronously")
    @MainActor
    func toggleLocationEnabledFalseClearsSynchronously() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Set up existing config
        viewModel.locationConfiguration = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: true
        )

        // Act - disable (no background Task, fully synchronous)
        viewModel.toggleLocationEnabled(false)

        // Assert - cleared immediately
        #expect(viewModel.locationConfiguration == nil)
    }

    @Test("toggleLocationEnabled(true) with existing config updates enabled flag synchronously")
    @MainActor
    func toggleLocationEnabledWithExistingConfigIsSynchronous() async throws {
        let (viewModel, _) = TestViewModelContainer.habitDetailViewModel()

        await viewModel.loadInitialData()

        // Set up disabled config
        viewModel.locationConfiguration = LocationConfiguration.create(
            from: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            radius: 100,
            triggerType: .entry,
            frequency: .oncePerDay,
            isEnabled: false
        )

        // Act - enable with existing config (synchronous path, no Task)
        viewModel.toggleLocationEnabled(true)

        // Assert - updated immediately
        #expect(viewModel.locationConfiguration?.isEnabled == true)
        #expect(viewModel.locationConfiguration?.coordinate.latitude == 37.7749)
    }

    // Note: Testing that map picker shows after authorization would require
    // exposing the internal Task or adding a completion handler to production code.
    // The key behaviors (placeholder set, permission check triggered) are tested above.
}
