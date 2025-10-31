//
//  WidgetUseCases.swift
//  RitualistWidget
//
//  Widget-specific implementations of UseCases for tap-to-complete functionality
//

import Foundation
import RitualistCore

// MARK: - Widget Habit Schedule Validation UseCase

/// Widget implementation of habit schedule validation
/// Uses WidgetHabitCompletionService for schedule checking
final class WidgetValidateHabitSchedule: ValidateHabitScheduleUseCase {
    private let habitCompletionService: HabitCompletionService
    
    init(habitCompletionService: HabitCompletionService) {
        self.habitCompletionService = habitCompletionService
    }
    
    func execute(habit: Habit, date: Date) async throws -> HabitScheduleValidationResult {
        // Use HabitCompletionService to check if the habit is scheduled for this date
        let isScheduled = habitCompletionService.isScheduledDay(habit: habit, date: date)
        
        if isScheduled {
            return .valid()
        } else {
            let reason = generateUserFriendlyReason(for: habit, date: date)
            return .invalid(reason: reason)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func generateUserFriendlyReason(for habit: Habit, date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let formattedDate = dateFormatter.string(from: date)
        
        switch habit.schedule {
        case .daily:
            // This shouldn't happen since daily habits are always valid, but provide a fallback
            return "This habit is not scheduled for \(formattedDate)."
            
        case .daysOfWeek(let scheduledDays):
            let dayNames = scheduledDays.sorted().compactMap { dayNum in
                let calWeekday = CalendarUtils.habitWeekdayToCalendarWeekday(dayNum)
                return CalendarUtils.currentLocalCalendar.weekdaySymbols[calWeekday - 1]
            }
            
            if dayNames.count == 1 {
                return "This habit is only scheduled for \(dayNames[0])s."
            } else if dayNames.count == 2 {
                return "This habit is only scheduled for \(dayNames[0])s and \(dayNames[1])s."
            } else {
                let lastDay = dayNames.last!
                let otherDays = dayNames.dropLast().joined(separator: ", ")
                return "This habit is only scheduled for \(otherDays), and \(lastDay)s."
            }
            
        }
    }
}

// MARK: - Widget Log Habit UseCase

/// Widget implementation of habit logging functionality
/// Provides same validation logic as main app but available to widget target
final class WidgetLogHabit: LogHabitUseCase {
    private let logRepository: LogRepository
    private let habitRepository: HabitRepository
    private let validateSchedule: ValidateHabitScheduleUseCase
    
    init(logRepository: LogRepository, habitRepository: HabitRepository, validateSchedule: ValidateHabitScheduleUseCase) { 
        self.logRepository = logRepository
        self.habitRepository = habitRepository
        self.validateSchedule = validateSchedule
    }
    
    func execute(_ log: HabitLog) async throws {
        // Fetch the habit to validate schedule
        let allHabits = try await habitRepository.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == log.habitID }) else {
            throw HabitScheduleValidationError.habitUnavailable(habitName: "Unknown Habit")
        }
        
        // Check if habit is active
        guard habit.isActive else {
            throw HabitScheduleValidationError.habitUnavailable(habitName: habit.name)
        }
        
        
        // Validate schedule before logging
        let validationResult = try await validateSchedule.execute(habit: habit, date: log.date)
        
        // If validation fails, throw descriptive error
        if !validationResult.isValid {
            throw HabitScheduleValidationError.fromValidationResult(validationResult, habitName: habit.name)
        }
        
        // If validation passes, proceed with logging
        try await logRepository.upsert(log)
    }
}