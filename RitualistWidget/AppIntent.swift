//
//  AppIntent.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import AppIntents
import Factory
import RitualistCore

/// App Intent for completing binary habits directly from the widget
/// Provides one-tap completion for binary habits without opening the main app
struct CompleteHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Habit"
    static let description: IntentDescription = IntentDescription("Complete a habit directly from the widget")

    @Parameter(title: "Habit ID")
    var habitId: String

    func perform() async throws -> some IntentResult {
        @Injected(\.widgetLogger) var logger
        @Injected(\.logHabitUseCase) var logHabitUseCase

        logger.log("CompleteHabitIntent started", level: .debug, category: .widget, metadata: [
            "habit_id": habitId,
            "date": Date().description
        ])

        // Check data access availability
        guard let logHabitUseCase else {
            logger.log("Data access unavailable - cannot complete habit", level: .warning, category: .widget)
            return .result()
        }

        // Convert string ID to UUID
        guard let habitUUID = UUID(uuidString: habitId) else {
            logger.log("Invalid habit ID format", level: .warning, category: .widget, metadata: ["habit_id": habitId])
            return .result() // Silent failure - invalid ID
        }

        // Create habit log for binary completion (value = 1.0)
        let log = HabitLog(habitID: habitUUID, date: Date(), value: 1.0)

        do {
            // Execute habit logging through UseCase
            try await logHabitUseCase.execute(log)

            logger.log("Habit completed successfully", level: .info, category: .widget, metadata: ["habit_id": habitId])

            // Refresh widgets on MainActor
            await MainActor.run { @MainActor in
                @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
                widgetRefreshService.refreshWidgets()
            }

            return .result()

        } catch let error as HabitScheduleValidationError {
            // Handle specific validation errors with detailed logging for debugging
            let errorDescription: String
            switch error {
            case .habitUnavailable(let habitName):
                errorDescription = "Habit unavailable: \(habitName)"
            case .alreadyLoggedToday(let habitName):
                errorDescription = "Habit already completed today: \(habitName)"
            case .notScheduledForDate(let habitName, let reason):
                errorDescription = "Habit not scheduled: \(habitName), reason: \(reason)"
            case .invalidSchedule(let habitName):
                errorDescription = "Invalid schedule for habit: \(habitName)"
            case .dateBeforeStartDate(let habitName):
                errorDescription = "Date before start date for habit: \(habitName)"
            }

            logger.log("Validation error completing habit", level: .warning, category: .widget, metadata: [
                "habit_id": habitId,
                "error": errorDescription
            ])

            // All validation errors fail silently in widget context (iOS best practice)
            return .result()

        } catch {
            // Handle any other errors with detailed logging for debugging
            logger.log("Unexpected error completing habit", level: .error, category: .widget, metadata: [
                "habit_id": habitId,
                "error_type": String(describing: type(of: error)),
                "error_description": error.localizedDescription
            ])
            return .result()
        }
    }
}

/// App Intent for completing binary habits on specific historical dates
/// Allows completing habits for any date within bounds (last 30 days)
/// Used primarily for widget interactions where users want to log habits for past dates
struct CompleteHistoricalHabitIntent: AppIntent {
    static let title: LocalizedStringResource = "Complete Historical Habit"
    static let description: IntentDescription = IntentDescription("Complete a habit for a specific date")

    @Parameter(title: "Habit ID")
    var habitId: String

    @Parameter(title: "Target Date")
    var targetDate: String

    func perform() async throws -> some IntentResult {
        @Injected(\.widgetLogger) var logger
        @Injected(\.logHabitUseCase) var logHabitUseCase

        logger.log("CompleteHistoricalHabitIntent started", level: .debug, category: .widget, metadata: [
            "habit_id": habitId,
            "target_date": targetDate
        ])

        // Check data access availability
        guard let logHabitUseCase else {
            logger.log("Data access unavailable - cannot complete historical habit", level: .warning, category: .widget)
            return .result()
        }

        // Convert string ID to UUID
        guard let habitUUID = UUID(uuidString: habitId) else {
            logger.log("Invalid habit ID format", level: .warning, category: .widget, metadata: ["habit_id": habitId])
            return .result() // Silent failure - invalid ID
        }

        // Parse target date from ISO string - match format from WidgetHabitChip
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let validatedDate = formatter.date(from: targetDate) else {
            logger.log("Invalid date format", level: .warning, category: .widget, metadata: ["target_date": targetDate])
            return .result()
        }

        // Validate date is within bounds (last 30 days)
        let calendar = CalendarUtils.currentLocalCalendar
        let today = calendar.startOfDay(for: Date())
        let thirtyDaysAgo = CalendarUtils.addDaysLocal(-30, to: today, timezone: .current)

        guard validatedDate >= thirtyDaysAgo && validatedDate <= today else {
            logger.log("Date out of bounds", level: .warning, category: .widget, metadata: ["target_date": targetDate])
            return .result()
        }

        // Create habit log for binary completion with validated date (value = 1.0)
        let log = HabitLog(habitID: habitUUID, date: validatedDate, value: 1.0)

        do {
            // Execute habit logging through UseCase
            try await logHabitUseCase.execute(log)

            logger.log("Historical habit completed successfully", level: .info, category: .widget, metadata: [
                "habit_id": habitId,
                "target_date": targetDate
            ])

            // Refresh widgets on MainActor
            await MainActor.run { @MainActor in
                @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
                widgetRefreshService.refreshWidgets()
            }

            return .result()

        } catch let error as HabitScheduleValidationError {
            // Handle specific validation errors with silent failure
            let errorDescription: String
            switch error {
            case .habitUnavailable(let habitName):
                errorDescription = "Habit unavailable: \(habitName)"
            case .alreadyLoggedToday(let habitName):
                errorDescription = "Already completed: \(habitName)"
            case .notScheduledForDate(let habitName, let reason):
                errorDescription = "Not scheduled: \(habitName), reason: \(reason)"
            case .invalidSchedule(let habitName):
                errorDescription = "Invalid schedule: \(habitName)"
            case .dateBeforeStartDate(let habitName):
                errorDescription = "Date before start: \(habitName)"
            }

            logger.log("Validation error completing historical habit", level: .warning, category: .widget, metadata: [
                "habit_id": habitId,
                "target_date": targetDate,
                "error": errorDescription
            ])

            // All validation errors fail silently in widget context (iOS best practice)
            return .result()

        } catch {
            // Handle any other errors with silent failure
            logger.log("Unexpected error completing historical habit", level: .error, category: .widget, metadata: [
                "habit_id": habitId,
                "target_date": targetDate,
                "error": error.localizedDescription
            ])
            return .result()
        }
    }
}

// MARK: - Navigation App Intents

/// App Intent for navigating to previous day in widget date navigation
/// Moves widget display to previous day if within allowed history bounds
struct NavigateToPreviousDayIntent: AppIntent {
    static let title: LocalizedStringResource = "Navigate to Previous Day"
    static let description: IntentDescription = IntentDescription("Navigate widget to previous day")

    func perform() async throws -> some IntentResult {
        @Injected(\.widgetLogger) var logger
        @Injected(\.widgetDateNavigationService) var navigationService

        logger.log("NavigateToPreviousDayIntent started", level: .debug, category: .widget, metadata: [
            "current_date": navigationService.currentDate.description,
            "can_go_back": String(navigationService.canGoBack)
        ])

        // Validate navigation is possible before attempting
        guard navigationService.canGoBack else {
            logger.log("Cannot navigate to previous day - at boundary", level: .debug, category: .widget)
            return .result() // Silent failure at boundary
        }

        // Execute navigation
        let navigationSuccess = navigationService.navigateToPrevious()

        if navigationSuccess {
            logger.log("Navigated to previous day", level: .debug, category: .widget, metadata: [
                "new_date": navigationService.currentDate.description
            ])

            await MainActor.run {
                let widgetRefreshService = Container.shared.widgetRefreshService()
                widgetRefreshService.refreshWidgets()
            }
        } else {
            logger.log("Navigation to previous day failed", level: .warning, category: .widget)
        }

        return .result()
    }
}

/// App Intent for navigating to next day in widget date navigation
/// Moves widget display to next day if not already at today
struct NavigateToNextDayIntent: AppIntent {
    static let title: LocalizedStringResource = "Navigate to Next Day"
    static let description: IntentDescription = IntentDescription("Navigate widget to next day")

    func perform() async throws -> some IntentResult {
        @Injected(\.widgetLogger) var logger
        @Injected(\.widgetDateNavigationService) var navigationService

        logger.log("NavigateToNextDayIntent started", level: .debug, category: .widget)

        // Validate navigation is possible before attempting
        guard navigationService.canGoForward else {
            logger.log("Cannot navigate to next day - at today", level: .debug, category: .widget)
            return .result() // Silent failure at boundary
        }

        // Execute navigation
        let navigationSuccess = navigationService.navigateToNext()

        if navigationSuccess {
            logger.log("Navigated to next day", level: .debug, category: .widget, metadata: [
                "new_date": navigationService.currentDate.description
            ])

            await MainActor.run {
                let widgetRefreshService = Container.shared.widgetRefreshService()
                widgetRefreshService.refreshWidgets()
            }
        } else {
            logger.log("Navigation to next day failed", level: .warning, category: .widget)
        }

        return .result()
    }
}

/// App Intent for navigating directly to today in widget date navigation
/// Resets widget display to current date regardless of previous navigation state
struct NavigateToTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Navigate to Today"
    static let description: IntentDescription = IntentDescription("Navigate widget to today")

    func perform() async throws -> some IntentResult {
        @Injected(\.widgetLogger) var logger
        @Injected(\.widgetDateNavigationService) var navigationService

        logger.log("NavigateToTodayIntent started", level: .debug, category: .widget)

        // Check if already viewing today to avoid unnecessary operations
        if navigationService.isViewingToday {
            logger.log("Already viewing today - no navigation needed", level: .debug, category: .widget)
            return .result()
        }

        // Execute navigation to today (always succeeds)
        navigationService.navigateToToday()

        logger.log("Navigated to today", level: .debug, category: .widget, metadata: [
            "new_date": navigationService.currentDate.description
        ])

        await MainActor.run {
            let widgetRefreshService = Container.shared.widgetRefreshService()
            widgetRefreshService.refreshWidgets()
        }

        return .result()
    }
}
