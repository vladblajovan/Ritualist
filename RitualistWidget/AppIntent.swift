//
//  AppIntent.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import AppIntents
import FactoryKit
import RitualistCore

/// App Intent for completing binary habits directly from the widget
/// Provides one-tap completion for binary habits without opening the main app
struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    static var description: IntentDescription = IntentDescription("Complete a habit directly from the widget")
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    func perform() async throws -> some IntentResult {
        @Injected(\.logHabitUseCase) var logHabitUseCase
        
        print("[WIDGET-INTENT] Attempting to complete habit with ID: \(habitId)")
        
        // Convert string ID to UUID
        guard let habitUUID = UUID(uuidString: habitId) else {
            print("[WIDGET-INTENT] Invalid habit ID format: \(habitId)")
            return .result() // Silent failure - invalid ID
        }
        
        // Create habit log for binary completion (value = 1.0)
        let log = HabitLog(habitID: habitUUID, date: Date(), value: 1.0)
        
        do {
            // Execute habit logging through UseCase
            try await logHabitUseCase.execute(log)
            
            print("[WIDGET-INTENT] Successfully completed habit: \(habitId)")
            
            // Refresh widgets on MainActor
            await MainActor.run { @MainActor in
                @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
                widgetRefreshService.refreshWidgets()
            }
            
            return .result()
            
        } catch let error as HabitScheduleValidationError {
            // Handle specific validation errors with silent failure
            switch error {
            case .habitUnavailable(let habitName):
                print("[WIDGET-INTENT] Habit unavailable: \(habitName)")
            case .alreadyLoggedToday(let habitName):
                print("[WIDGET-INTENT] Habit already completed today: \(habitName)")
            case .notScheduledForDate(let habitName, let reason):
                print("[WIDGET-INTENT] Habit not scheduled for today: \(habitName), reason: \(reason)")
            case .invalidSchedule(let habitName):
                print("[WIDGET-INTENT] Invalid schedule for habit: \(habitName)")
            }
            
            // All validation errors fail silently in widget context (iOS best practice)
            return .result()
            
        } catch {
            // Handle any other errors with silent failure
            print("[WIDGET-INTENT] Unexpected error completing habit: \(error)")
            return .result()
        }
    }
}

/// App Intent for completing binary habits on specific historical dates
/// Allows completing habits for any date within bounds (last 30 days)
/// Used primarily for widget interactions where users want to log habits for past dates
struct CompleteHistoricalHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Historical Habit"
    static var description: IntentDescription = IntentDescription("Complete a habit for a specific date")
    
    @Parameter(title: "Habit ID")
    var habitId: String
    
    @Parameter(title: "Target Date")
    var targetDate: String
    
    func perform() async throws -> some IntentResult {
        @Injected(\.logHabitUseCase) var logHabitUseCase
        @Injected(\.historicalDateValidationService) var dateValidationService
        
        print("[WIDGET-INTENT] Attempting to complete historical habit with ID: \(habitId) for date: \(targetDate)")
        
        // Convert string ID to UUID
        guard let habitUUID = UUID(uuidString: habitId) else {
            print("[WIDGET-INTENT] Invalid habit ID format: \(habitId)")
            return .result() // Silent failure - invalid ID
        }
        
        // Validate and parse target date using service
        let validatedDate: Date
        do {
            validatedDate = try dateValidationService.validateHistoricalDateString(targetDate)
            print("[WIDGET-INTENT] Date validation passed for: \(targetDate)")
        } catch let error as HistoricalDateValidationError {
            // Handle specific validation errors with silent failure (widget best practice)
            print("[WIDGET-INTENT] Date validation failed: \(error.description)")
            return .result()
        } catch {
            print("[WIDGET-INTENT] Unexpected date validation error: \(error)")
            return .result()
        }
        
        // Create habit log for binary completion with validated date (value = 1.0)
        let log = HabitLog(habitID: habitUUID, date: validatedDate, value: 1.0)
        
        do {
            // Execute habit logging through UseCase
            try await logHabitUseCase.execute(log)
            
            print("[WIDGET-INTENT] Successfully completed historical habit: \(habitId) for date: \(targetDate)")
            
            // Refresh widgets on MainActor
            await MainActor.run { @MainActor in
                @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
                widgetRefreshService.refreshWidgets()
            }
            
            return .result()
            
        } catch let error as HabitScheduleValidationError {
            // Handle specific validation errors with silent failure
            switch error {
            case .habitUnavailable(let habitName):
                print("[WIDGET-INTENT] Historical habit unavailable: \(habitName) for date: \(targetDate)")
            case .alreadyLoggedToday(let habitName):
                print("[WIDGET-INTENT] Historical habit already completed: \(habitName) for date: \(targetDate)")
            case .notScheduledForDate(let habitName, let reason):
                print("[WIDGET-INTENT] Historical habit not scheduled: \(habitName) for date: \(targetDate), reason: \(reason)")
            case .invalidSchedule(let habitName):
                print("[WIDGET-INTENT] Invalid schedule for historical habit: \(habitName) for date: \(targetDate)")
            }
            
            // All validation errors fail silently in widget context (iOS best practice)
            return .result()
            
        } catch {
            // Handle any other errors with silent failure
            print("[WIDGET-INTENT] Unexpected error completing historical habit: \(error)")
            return .result()
        }
    }
}

// MARK: - Navigation App Intents

/// App Intent for navigating to previous day in widget date navigation
/// Moves widget display to previous day if within allowed history bounds
struct NavigateToPreviousDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate to Previous Day"
    static var description: IntentDescription = IntentDescription("Navigate widget to previous day")
    
    func perform() async throws -> some IntentResult {
        print("[WIDGET-INTENT] NavigateToPreviousDayIntent.perform() called")
        print("[WIDGET-INTENT] Current date before navigation: \(WidgetDateState.shared.currentDate)")
        print("[WIDGET-INTENT] Can go back: \(WidgetDateState.shared.canGoBack)")
        
        // Validate navigation is possible before attempting
        guard WidgetDateState.shared.canGoBack else {
            print("[WIDGET-INTENT] Cannot navigate to previous day - already at earliest allowed date")
            return .result() // Silent failure at boundary
        }
        
        // Execute navigation
        print("[WIDGET-INTENT] Calling navigateToPrevious()...")
        let navigationSuccess = WidgetDateState.shared.navigateToPrevious()
        print("[WIDGET-INTENT] Navigation result: \(navigationSuccess)")
        
        if navigationSuccess {
            print("[WIDGET-INTENT] Successfully navigated to previous day: \(WidgetDateState.shared.currentDate)")
            
            // Refresh widgets on MainActor
            await MainActor.run { @MainActor in
                @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
                print("[WIDGET-INTENT] Calling widget refresh...")
                widgetRefreshService.refreshWidgets()
                print("[WIDGET-INTENT] Widget refresh call completed")
            }
            
            print("[WIDGET-INTENT] Widget refresh triggered after previous day navigation")
        } else {
            print("[WIDGET-INTENT] Navigation to previous day failed - boundary check or date calculation error")
        }
        
        print("[WIDGET-INTENT] NavigateToPreviousDayIntent.perform() completed")
        return .result()
    }
}

/// App Intent for navigating to next day in widget date navigation
/// Moves widget display to next day if not already at today
struct NavigateToNextDayIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate to Next Day"
    static var description: IntentDescription = IntentDescription("Navigate widget to next day")
    
    func perform() async throws -> some IntentResult {
        print("[WIDGET-INTENT] Attempting to navigate to next day")
        
        // Validate navigation is possible before attempting
        guard WidgetDateState.shared.canGoForward else {
            print("[WIDGET-INTENT] Cannot navigate to next day - already at today")
            return .result() // Silent failure at boundary
        }
        
        // Execute navigation
        let navigationSuccess = WidgetDateState.shared.navigateToNext()
        
        if navigationSuccess {
            print("[WIDGET-INTENT] Successfully navigated to next day: \(WidgetDateState.shared.currentDate)")
            
            // Refresh widgets on MainActor
            await MainActor.run { @MainActor in
                @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
                widgetRefreshService.refreshWidgets()
            }
            
            print("[WIDGET-INTENT] Widget refresh triggered after next day navigation")
        } else {
            print("[WIDGET-INTENT] Navigation to next day failed - boundary check or date calculation error")
        }
        
        return .result()
    }
}

/// App Intent for navigating directly to today in widget date navigation
/// Resets widget display to current date regardless of previous navigation state
struct NavigateToTodayIntent: AppIntent {
    static var title: LocalizedStringResource = "Navigate to Today"
    static var description: IntentDescription = IntentDescription("Navigate widget to today")
    
    func perform() async throws -> some IntentResult {
        print("[WIDGET-INTENT] Attempting to navigate to today")
        
        // Check if already viewing today to avoid unnecessary operations
        if WidgetDateState.shared.isViewingToday {
            print("[WIDGET-INTENT] Already viewing today - no navigation needed")
            return .result()
        }
        
        // Execute navigation to today (always succeeds)
        WidgetDateState.shared.navigateToToday()
        
        print("[WIDGET-INTENT] Successfully navigated to today: \(WidgetDateState.shared.currentDate)")
        
        // Refresh widgets on MainActor
        await MainActor.run { @MainActor in
            @Injected(\.widgetRefreshService) var widgetRefreshService: WidgetRefreshServiceProtocol
            widgetRefreshService.refreshWidgets()
        }
        
        print("[WIDGET-INTENT] Widget refresh triggered after today navigation")
        
        return .result()
    }
}
