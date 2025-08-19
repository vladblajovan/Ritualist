//
//  WidgetDataService.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import Foundation
import RitualistCore

/// Data service for widget that reuses core business logic from RitualistCore
/// Provides habit data for widget timeline using shared repositories
class WidgetDataService {
    private let habitCompletionService: HabitCompletionService
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    
    enum WidgetError: Error {
        case dataFetchFailed
        case repositoryNotAvailable
    }
    
    init(
        habitCompletionService: HabitCompletionService,
        habitRepository: HabitRepository,
        logRepository: LogRepository
    ) {
        self.habitCompletionService = habitCompletionService
        self.habitRepository = habitRepository
        self.logRepository = logRepository
    }
    
    /// Get today's remaining (incomplete) habits with current progress for widget display
    /// Returns tuples of habit and current progress value for display
    func getTodaysRemainingHabitsWithProgress() async throws -> [(habit: Habit, currentProgress: Int, isCompleted: Bool)] {
        let today = DateUtils.startOfDay(Date())
        print("[WIDGET-DEBUG] getTodaysRemainingHabitsWithProgress - Today: \(today)")
        
        do {
            // Fetch all habits using repository
            let allHabits = try await habitRepository.fetchAllHabits()
            print("[WIDGET-DEBUG] Fetched \(allHabits.count) total habits from repository")
            
            for (index, habit) in allHabits.enumerated() {
                print("[WIDGET-DEBUG] Habit \(index): \(habit.name) - Active: \(habit.isActive), Schedule: \(habit.schedule), Kind: \(habit.kind), Target: \(habit.dailyTarget ?? 0)")
            }
            
            // Filter to only active habits scheduled for today
            let todaysHabits = allHabits.filter { habit in
                habit.isActive && isScheduledToday(habit, date: today)
            }
            print("[WIDGET-DEBUG] Filtered to \(todaysHabits.count) habits scheduled for today")
            
            for habit in todaysHabits {
                print("[WIDGET-DEBUG] Today's habit: \(habit.name) - Scheduled: \(isScheduledToday(habit, date: today))")
            }
            
            // Filter to only incomplete habits with their current progress
            var incompleteHabitsWithProgress: [(habit: Habit, currentProgress: Int, isCompleted: Bool)] = []
            
            for habit in todaysHabits {
                // Fetch logs for this habit
                let habitLogs = try await logRepository.logs(for: habit.id)
                print("[WIDGET-DEBUG] Habit '\(habit.name)' has \(habitLogs.count) total logs")
                
                // Filter logs to today only
                let todaysLogs = habitLogs.filter { log in
                    DateUtils.isSameDay(log.date, today)
                }
                print("[WIDGET-DEBUG] Habit '\(habit.name)' has \(todaysLogs.count) logs for today")
                
                for log in todaysLogs {
                    print("[WIDGET-DEBUG]   Log: date=\(log.date), value=\(log.value ?? 0), habitID=\(log.habitID)")
                }
                
                // Calculate current progress using same logic as main app
                let currentProgress: Int
                if habit.kind == .binary {
                    currentProgress = todaysLogs.isEmpty ? 0 : 1
                } else {
                    // For numeric habits: sum all today's log values
                    let progressValue = todaysLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                    currentProgress = Int(progressValue)
                }
                print("[WIDGET-DEBUG] Habit '\(habit.name)' current progress: \(currentProgress)")
                
                // Check if habit is completed
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: today,
                    logs: todaysLogs
                )
                print("[WIDGET-DEBUG] Habit '\(habit.name)' completion status: \(isCompleted)")
                
                if !isCompleted {
                    incompleteHabitsWithProgress.append((habit: habit, currentProgress: currentProgress, isCompleted: isCompleted))
                    print("[WIDGET-DEBUG] Added '\(habit.name)' to incomplete habits list with progress \(currentProgress)")
                } else {
                    print("[WIDGET-DEBUG] Habit '\(habit.name)' is completed, not adding to incomplete list")
                }
            }
            
            print("[WIDGET-DEBUG] Returning \(incompleteHabitsWithProgress.count) incomplete habits with progress")
            return incompleteHabitsWithProgress
            
        } catch {
            print("[WIDGET-DEBUG] Error fetching habits: \(error)")
            throw WidgetError.dataFetchFailed
        }
    }
    
    /// Legacy method for backward compatibility
    /// Get today's remaining (incomplete) habits for widget display
    /// Returns habits that are scheduled for today but not yet completed
    func getTodaysRemainingHabits() async throws -> [Habit] {
        let habitsWithProgress = try await getTodaysRemainingHabitsWithProgress()
        return habitsWithProgress.map { $0.habit }
    }
    
    /// Get completion percentage for today's habits
    /// Returns percentage of scheduled habits that are completed today
    func getTodaysCompletionPercentage() async throws -> Double {
        return try await getCompletionPercentage(for: Date())
    }
    
    // MARK: - Date-Aware Methods for Historical Data
    
    /// Get all scheduled habits for a specific date
    /// Returns ALL scheduled habits regardless of completion status for consistent widget display
    /// Both completed and incomplete habits are returned with their current status
    func getRemainingHabits(for date: Date) async throws -> [Habit] {
        let habitsWithProgress = try await getHabitsWithProgress(for: date)
        return habitsWithProgress.map { $0.habit }
    }
    
    /// Get completion percentage for habits on a specific date
    /// Calculates what percentage of scheduled habits were completed on that date
    func getCompletionPercentage(for date: Date) async throws -> Double {
        let targetDate = DateUtils.startOfDay(date)
        print("[WIDGET-DEBUG] getCompletionPercentage(for: \(targetDate))")
        
        do {
            // Fetch all habits using repository
            let allHabits = try await habitRepository.fetchAllHabits()
            print("[WIDGET-DEBUG] Percentage calc: Fetched \(allHabits.count) total habits")
            
            // Filter to only active habits scheduled for the target date
            let scheduledHabits = allHabits.filter { habit in
                habit.isActive && isScheduledDay(habit, date: targetDate)
            }
            print("[WIDGET-DEBUG] Percentage calc: \(scheduledHabits.count) habits scheduled for \(targetDate)")
            
            guard !scheduledHabits.isEmpty else {
                print("[WIDGET-DEBUG] Percentage calc: No habits for \(targetDate), returning 0.0")
                return 0.0
            }
            
            // Count completed habits
            var completedCount = 0
            
            for habit in scheduledHabits {
                // Fetch logs for this habit
                let habitLogs = try await logRepository.logs(for: habit.id)
                
                // Filter logs to target date only
                let dateLogs = habitLogs.filter { log in
                    DateUtils.isSameDay(log.date, targetDate)
                }
                
                // Check if habit is completed
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: targetDate,
                    logs: dateLogs
                )
                
                if isCompleted {
                    completedCount += 1
                    print("[WIDGET-DEBUG] Percentage calc: '\(habit.name)' is completed (\(completedCount)/\(scheduledHabits.count))")
                } else {
                    print("[WIDGET-DEBUG] Percentage calc: '\(habit.name)' is NOT completed")
                }
            }
            
            // Calculate completion percentage
            let percentage = Double(completedCount) / Double(scheduledHabits.count)
            print("[WIDGET-DEBUG] Percentage calc: Final result: \(completedCount)/\(scheduledHabits.count) = \(percentage) (\(percentage * 100)%)")
            return percentage
            
        } catch {
            print("[WIDGET-DEBUG] Percentage calc error: \(error)")
            throw WidgetError.dataFetchFailed
        }
    }
    
    /// Get all scheduled habits with progress for a specific date
    /// Returns ALL scheduled habits with their completion status for consistent widget display
    /// Both completed and incomplete habits are shown with appropriate visual indicators
    func getHabitsWithProgress(for date: Date) async throws -> [(habit: Habit, currentProgress: Int, isCompleted: Bool)] {
        let targetDate = DateUtils.startOfDay(date)
        let isToday = DateUtils.isSameDay(targetDate, Date())
        
        print("[WIDGET-DEBUG] getHabitsWithProgress(for: \(targetDate)) - isToday: \(isToday)")
        
        do {
            // Fetch all habits using repository
            let allHabits = try await habitRepository.fetchAllHabits()
            print("[WIDGET-DEBUG] Fetched \(allHabits.count) total habits from repository")
            
            // Filter to only active habits scheduled for target date
            let scheduledHabits = allHabits.filter { habit in
                habit.isActive && isScheduledDay(habit, date: targetDate)
            }
            print("[WIDGET-DEBUG] Filtered to \(scheduledHabits.count) habits scheduled for \(targetDate)")
            
            // Process habits with their progress
            var habitsWithProgress: [(habit: Habit, currentProgress: Int, isCompleted: Bool)] = []
            
            for habit in scheduledHabits {
                // Fetch logs for this habit
                let habitLogs = try await logRepository.logs(for: habit.id)
                
                // Filter logs to target date only
                let dateLogs = habitLogs.filter { log in
                    DateUtils.isSameDay(log.date, targetDate)
                }
                
                // Calculate current progress using same logic as main app
                let currentProgress: Int
                if habit.kind == .binary {
                    currentProgress = dateLogs.isEmpty ? 0 : 1
                } else {
                    // For numeric habits: sum all date's log values
                    let progressValue = dateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                    currentProgress = Int(progressValue)
                }
                
                // Check if habit is completed
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: targetDate,
                    logs: dateLogs
                )
                
                print("[WIDGET-DEBUG] Habit '\(habit.name)' - progress: \(currentProgress), completed: \(isCompleted)")
                
                // Always add all habits regardless of completion status for consistent widget display
                // This ensures widgets show the same habit grid for today and historical dates
                habitsWithProgress.append((habit: habit, currentProgress: currentProgress, isCompleted: isCompleted))
                print("[WIDGET-DEBUG] Added '\(habit.name)' to habits list - completed: \(isCompleted), progress: \(currentProgress)")
            }
            
            print("[WIDGET-DEBUG] Returning \(habitsWithProgress.count) habits with progress for \(targetDate)")
            return habitsWithProgress
            
        } catch {
            print("[WIDGET-DEBUG] Error fetching habits for \(targetDate): \(error)")
            throw WidgetError.dataFetchFailed
        }
    }
    
    /// Get all habits with completion status for a specific date
    /// Useful for detailed historical view where we need completion flags
    func getAllHabitsWithStatus(for date: Date) async throws -> [(habit: Habit, currentProgress: Int, isCompleted: Bool)] {
        let targetDate = DateUtils.startOfDay(date)
        print("[WIDGET-DEBUG] getAllHabitsWithStatus(for: \(targetDate))")
        
        do {
            // Fetch all habits using repository
            let allHabits = try await habitRepository.fetchAllHabits()
            
            // Filter to only active habits scheduled for target date
            let scheduledHabits = allHabits.filter { habit in
                habit.isActive && isScheduledDay(habit, date: targetDate)
            }
            
            // Process habits with their status
            var habitsWithStatus: [(habit: Habit, currentProgress: Int, isCompleted: Bool)] = []
            
            for habit in scheduledHabits {
                // Fetch logs for this habit
                let habitLogs = try await logRepository.logs(for: habit.id)
                
                // Filter logs to target date only
                let dateLogs = habitLogs.filter { log in
                    DateUtils.isSameDay(log.date, targetDate)
                }
                
                // Calculate current progress
                let currentProgress: Int
                if habit.kind == .binary {
                    currentProgress = dateLogs.isEmpty ? 0 : 1
                } else {
                    let progressValue = dateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                    currentProgress = Int(progressValue)
                }
                
                // Check completion status
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: targetDate,
                    logs: dateLogs
                )
                
                habitsWithStatus.append((
                    habit: habit,
                    currentProgress: currentProgress,
                    isCompleted: isCompleted
                ))
            }
            
            return habitsWithStatus
            
        } catch {
            print("[WIDGET-DEBUG] Error fetching habits with status for \(targetDate): \(error)")
            throw WidgetError.dataFetchFailed
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Check if habit is scheduled for the given date
    /// Reuses schedule checking logic consistent with main app
    private func isScheduledToday(_ habit: Habit, date: Date) -> Bool {
        return habitCompletionService.isScheduledDay(habit: habit, date: date)
    }
    
    /// Generic method to check if habit is scheduled for any date
    /// Consistent with main app scheduling logic
    private func isScheduledDay(_ habit: Habit, date: Date) -> Bool {
        return habitCompletionService.isScheduledDay(habit: habit, date: date)
    }
    
    // MARK: - Date Boundary Validation
    
    /// Validate that the requested date is within acceptable bounds for widget data
    /// Prevents unnecessary data loading for dates outside navigation limits
    private func isDateWithinBounds(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let today = calendar.startOfDay(for: Date())
        
        // Use same limits as WidgetDateState (30 days back, not beyond today)
        let earliestAllowed = calendar.date(byAdding: .day, value: -30, to: today)!
        
        return normalizedDate >= earliestAllowed && normalizedDate <= today
    }
    
    /// Get optimized data for date - uses caching for today, fresh data for historical
    /// This is a performance optimization method that could be used by timeline provider
    private func shouldUseCachedData(for date: Date) -> Bool {
        return DateUtils.isSameDay(date, Date())
    }
}