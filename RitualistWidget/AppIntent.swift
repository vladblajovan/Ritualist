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
