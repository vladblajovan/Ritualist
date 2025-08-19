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
    func getTodaysRemainingHabitsWithProgress() async throws -> [(habit: Habit, currentProgress: Int)] {
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
            var incompleteHabitsWithProgress: [(habit: Habit, currentProgress: Int)] = []
            
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
                    incompleteHabitsWithProgress.append((habit: habit, currentProgress: currentProgress))
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
        let today = DateUtils.startOfDay(Date())
        print("[WIDGET-DEBUG] getTodaysCompletionPercentage - Today: \(today)")
        
        do {
            // Fetch all habits using repository
            let allHabits = try await habitRepository.fetchAllHabits()
            print("[WIDGET-DEBUG] Percentage calc: Fetched \(allHabits.count) total habits")
            
            // Filter to only active habits scheduled for today
            let todaysHabits = allHabits.filter { habit in
                habit.isActive && isScheduledToday(habit, date: today)
            }
            print("[WIDGET-DEBUG] Percentage calc: \(todaysHabits.count) habits scheduled for today")
            
            guard !todaysHabits.isEmpty else {
                print("[WIDGET-DEBUG] Percentage calc: No habits for today, returning 0.0")
                return 0.0
            }
            
            // Count completed habits
            var completedCount = 0
            
            for habit in todaysHabits {
                // Fetch logs for this habit
                let habitLogs = try await logRepository.logs(for: habit.id)
                
                // Filter logs to today only
                let todaysLogs = habitLogs.filter { log in
                    DateUtils.isSameDay(log.date, today)
                }
                
                // Check if habit is completed
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: today,
                    logs: todaysLogs
                )
                
                if isCompleted {
                    completedCount += 1
                    print("[WIDGET-DEBUG] Percentage calc: '\(habit.name)' is completed (\(completedCount)/\(todaysHabits.count))")
                } else {
                    print("[WIDGET-DEBUG] Percentage calc: '\(habit.name)' is NOT completed")
                }
            }
            
            // Calculate completion percentage
            let percentage = Double(completedCount) / Double(todaysHabits.count)
            print("[WIDGET-DEBUG] Percentage calc: Final result: \(completedCount)/\(todaysHabits.count) = \(percentage) (\(percentage * 100)%)")
            return percentage
            
        } catch {
            print("[WIDGET-DEBUG] Percentage calc error: \(error)")
            throw WidgetError.dataFetchFailed
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Check if habit is scheduled for the given date
    /// Reuses schedule checking logic consistent with main app
    private func isScheduledToday(_ habit: Habit, date: Date) -> Bool {
        return habitCompletionService.isScheduledDay(habit: habit, date: date)
    }
}