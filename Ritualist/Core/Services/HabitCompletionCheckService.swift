//
//  HabitCompletionCheckService.swift
//  Ritualist
//
//  Created by Claude on 20.08.2025.
//

import Foundation
import RitualistCore

/// Service responsible for determining if a habit should show a notification
/// based on its completion status for a specific date.
/// 
/// This service has a single responsibility: notification visibility logic.
/// It uses existing completion logic from HabitCompletionService to make decisions.
public protocol HabitCompletionCheckService {
    /// Determines if a notification should be shown for a habit on a specific date
    /// 
    /// - Parameters:
    ///   - habitId: The unique identifier of the habit
    ///   - date: The date to check completion status for
    /// - Returns: 
    ///   - `false` if the habit is completed (don't show notification)
    ///   - `true` if the habit is not completed (show notification)
    ///   - `true` if any error occurs (fail-safe approach - always show notification on error)
    func shouldShowNotification(habitId: UUID, date: Date) async -> Bool
}

/// Default implementation of HabitCompletionCheckService
/// 
/// This service coordinates between repositories and completion logic to determine
/// notification visibility without duplicating existing business logic.
public final class DefaultHabitCompletionCheckService: HabitCompletionCheckService {
    
    // MARK: - Dependencies
    
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    private let habitCompletionService: HabitCompletionServiceProtocol
    private let calendar: Calendar
    private let errorHandler: ErrorHandlingActor?
    
    // MARK: - Initialization
    
    public init(
        habitRepository: HabitRepository,
        logRepository: LogRepository,
        habitCompletionService: HabitCompletionServiceProtocol,
        calendar: Calendar = .current,
        errorHandler: ErrorHandlingActor? = nil
    ) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.habitCompletionService = habitCompletionService
        self.calendar = calendar
        self.errorHandler = errorHandler
    }
    
    // MARK: - Public Methods
    
    public func shouldShowNotification(habitId: UUID, date: Date) async -> Bool {
        do {
            // PERFORMANCE FIX: Use targeted query instead of fetching all habits
            guard let habit = try await habitRepository.fetchHabit(by: habitId) else {
                // Habit not found - fail safe by showing notification
                await logError("Habit not found", context: ["habitId": habitId.uuidString])
                return true
            }
            
            // LIFECYCLE VALIDATIONS: Critical missing checks
            guard habit.isActive else {
                // Don't notify for inactive habits
                return false
            }
            
            let startOfToday = calendar.startOfDay(for: date)
            let startOfHabitStart = calendar.startOfDay(for: habit.startDate)
            
            guard startOfToday >= startOfHabitStart else {
                // Don't notify before habit start date
                return false
            }
            
            if let endDate = habit.endDate {
                let startOfHabitEnd = calendar.startOfDay(for: endDate)
                guard startOfToday < startOfHabitEnd else {
                    // Don't notify after habit end date
                    return false
                }
            }
            
            // SCHEDULE-AWARE LOGIC: Different behavior for different schedule types
            switch habit.schedule {
            case .daily, .daysOfWeek:
                return await shouldShowNotificationForDailyHabit(habit: habit, date: date)
            case .timesPerWeek:
                return await shouldShowNotificationForWeeklyHabit(habit: habit, date: date)
            }
            
        } catch {
            // On any error, fail safe by returning true (show notification)
            // This ensures users don't miss notifications due to technical issues
            await logError("Failed to check habit completion", error: error, context: ["habitId": habitId.uuidString])
            return true
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle notification logic for daily and daysOfWeek habits
    private func shouldShowNotificationForDailyHabit(habit: Habit, date: Date) async -> Bool {
        do {
            // For daysOfWeek habits, check if today is a scheduled day
            if case .daysOfWeek = habit.schedule {
                guard habitCompletionService.isScheduledDay(habit: habit, date: date) else {
                    // Not scheduled today - don't show notification
                    return false
                }
            }
            
            // Check if habit is completed today
            let logs = try await logRepository.logs(for: habit.id)
            let isCompleted = habitCompletionService.isCompleted(habit: habit, on: date, logs: logs)
            
            // Show notification if not completed
            return !isCompleted
            
        } catch {
            // Fail-safe: show notification on error
            await logError("Failed to check daily habit completion", error: error, context: ["habitId": habit.id.uuidString])
            return true
        }
    }
    
    /// Handle notification logic for timesPerWeek habits
    /// KEY FIX: Check weekly progress, not daily completion
    private func shouldShowNotificationForWeeklyHabit(habit: Habit, date: Date) async -> Bool {
        do {
            // Fetch logs for this habit
            let logs = try await logRepository.logs(for: habit.id)
            
            // Check if weekly target is already met
            let (completed, target) = habitCompletionService.getWeeklyProgress(habit: habit, for: date, logs: logs)
            
            // Show notification only if weekly target not yet met
            return completed < target
            
        } catch {
            // Fail-safe: show notification on error
            await logError("Failed to check weekly habit completion", error: error, context: ["habitId": habit.id.uuidString])
            return true
        }
    }
    
    // MARK: - Error Handling
    
    /// Log structured errors for production debugging
    private func logError(_ message: String, error: Error? = nil, context: [String: String] = [:]) async {
        guard let errorHandler = errorHandler else { return }
        
        // Use the correct ErrorHandlingActor method signature
        let contextString = "HabitCompletionCheckService: \(message)"
        var additionalProperties: [String: Any] = [:]
        
        // Add context properties
        for (key, value) in context {
            additionalProperties[key] = value
        }
        
        if let error = error {
            await errorHandler.logError(error, context: contextString, additionalProperties: additionalProperties)
        } else {
            // Create a generic error for non-error logging cases
            let genericError = NSError(domain: "HabitCompletionCheckService", code: 0, 
                                     userInfo: [NSLocalizedDescriptionKey: message])
            await errorHandler.logError(genericError, context: contextString, additionalProperties: additionalProperties)
        }
    }
}