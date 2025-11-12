//
//  WidgetHabitsViewModel.swift
//  RitualistWidget
//
//  Created by Claude on 28.08.2025.
//

import Foundation
import RitualistCore

/// Widget ViewModel that uses main app's Use Cases for proper Clean Architecture
/// Ensures data consistency between widget and main app
final class WidgetHabitsViewModel {
    
    // MARK: - Use Cases (from main app)
    private let getActiveHabits: GetActiveHabitsUseCase
    private let getBatchLogs: GetBatchLogsUseCase
    private let habitCompletionService: HabitCompletionService
    
    init(
        getActiveHabits: GetActiveHabitsUseCase,
        getBatchLogs: GetBatchLogsUseCase,
        habitCompletionService: HabitCompletionService
    ) {
        self.getActiveHabits = getActiveHabits
        self.getBatchLogs = getBatchLogs
        self.habitCompletionService = habitCompletionService
    }
    
    // MARK: - Public Methods
    
    /// Get habits with their progress and completion status for a specific date
    /// Uses main app's business logic for consistent results
    func getHabitsWithProgress(for date: Date) async -> [(habit: Habit, currentProgress: Int, isCompleted: Bool)] {
        do {
            let targetDate = CalendarUtils.startOfDayLocal(for: date)
            print("[WIDGET-VM] Getting habits with progress for: \(targetDate)")
            
            // 1. Get active habits using main app's Use Case
            let allHabits = try await getActiveHabits.execute()
            print("[WIDGET-VM] Fetched \(allHabits.count) active habits")
            
            // 2. Filter to habits scheduled for target date
            let scheduledHabits = allHabits.filter { habit in
                habitCompletionService.isScheduledDay(habit: habit, date: targetDate)
            }
            print("[WIDGET-VM] \(scheduledHabits.count) habits scheduled for \(targetDate)")
            
            // 3. Get batch logs for all scheduled habits using main app's Use Case
            let habitIds = scheduledHabits.map { $0.id }
            let logsByHabitId = try await getBatchLogs.execute(
                for: habitIds,
                since: targetDate,
                until: CalendarUtils.addDays(1, to: targetDate)
            )
            print("[WIDGET-VM] Fetched logs for \(logsByHabitId.count) habits on \(targetDate)")
            
            // 4. Process each habit with its progress and completion
            var result: [(habit: Habit, currentProgress: Int, isCompleted: Bool)] = []
            
            for habit in scheduledHabits {
                let habitLogs = logsByHabitId[habit.id] ?? []
                let dateLogs = habitLogs.filter { log in
                    CalendarUtils.areSameDayLocal(log.date, targetDate)
                }
                
                // DEBUG: Detailed logging for binary habit status calculation
                print("[WIDGET-VM-DEBUG] === Processing habit: \(habit.name) ===")
                print("[WIDGET-VM-DEBUG] Habit kind: \(habit.kind)")
                print("[WIDGET-VM-DEBUG] Target date: \(targetDate)")
                print("[WIDGET-VM-DEBUG] Total logs found: \(habitLogs.count)")
                print("[WIDGET-VM-DEBUG] Logs for target date: \(dateLogs.count)")
                if !habitLogs.isEmpty {
                    print("[WIDGET-VM-DEBUG] Log dates: \(habitLogs.map { $0.date })")
                }
                
                // Calculate current progress
                let currentProgress: Int
                if habit.kind == .binary {
                    currentProgress = habitLogs.isEmpty ? 0 : 1
                    print("[WIDGET-VM-DEBUG] Binary habit - using simple logic: logs.isEmpty=\(habitLogs.isEmpty), progress=\(currentProgress)")
                } else {
                    let progressValue = habitLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                    currentProgress = Int(progressValue)
                    print("[WIDGET-VM-DEBUG] Numeric habit - total value: \(progressValue), progress=\(currentProgress)")
                }
                
                // Check completion using main app's service
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: targetDate,
                    logs: habitLogs
                )
                
                print("[WIDGET-VM-DEBUG] HabitCompletionService result: isCompleted=\(isCompleted)")
                print("[WIDGET-VM-DEBUG] Final status: progress=\(currentProgress), completed=\(isCompleted)")
                
                // DEBUG: Check widget chip logic conditions
                if habit.kind == .binary {
                    print("[WIDGET-VM-DEBUG] 🔍 CHIP LOGIC CHECK:")
                    print("[WIDGET-VM-DEBUG] - habit.kind == .binary: true")
                    print("[WIDGET-VM-DEBUG] - !isCompleted: \(!isCompleted)")
                    print("[WIDGET-VM-DEBUG] - Will show Button (if viewing today): \(habit.kind == .binary && !isCompleted)")
                }
                print("[WIDGET-VM-DEBUG] ==========================================")
                
                result.append((
                    habit: habit,
                    currentProgress: currentProgress,
                    isCompleted: isCompleted
                ))
                
                print("[WIDGET-VM] \(habit.name): progress=\(currentProgress), completed=\(isCompleted)")
            }
            
            print("[WIDGET-VM] Returning \(result.count) habits with progress")
            return result
            
        } catch {
            print("[WIDGET-VM] Error: \(error)")
            return []
        }
    }
    
    /// Get completion percentage for a specific date
    /// Uses main app's business logic for accurate calculations
    func getCompletionPercentage(for date: Date) async -> Double {
        let habitsWithProgress = await getHabitsWithProgress(for: date)
        guard !habitsWithProgress.isEmpty else { return 0.0 }
        
        let completedCount = habitsWithProgress.filter { $0.isCompleted }.count
        let percentage = Double(completedCount) / Double(habitsWithProgress.count)
        
        print("[WIDGET-VM] Completion: \(completedCount)/\(habitsWithProgress.count) = \(percentage * 100)%")
        return percentage
    }
}