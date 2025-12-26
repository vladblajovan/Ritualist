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

    // MARK: - Dependencies
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "widget")

    // MARK: - Use Cases (from main app)
    private let getActiveHabits: GetActiveHabitsUseCase
    private let getBatchLogs: GetBatchLogsUseCase
    private let habitCompletionService: HabitCompletionService
    private let timezoneService: TimezoneService

    init(
        getActiveHabits: GetActiveHabitsUseCase,
        getBatchLogs: GetBatchLogsUseCase,
        habitCompletionService: HabitCompletionService,
        timezoneService: TimezoneService
    ) {
        self.getActiveHabits = getActiveHabits
        self.getBatchLogs = getBatchLogs
        self.habitCompletionService = habitCompletionService
        self.timezoneService = timezoneService
    }

    // MARK: - Timezone

    /// Get display timezone from user preferences (same as main app)
    func getDisplayTimezone() async -> TimeZone {
        (try? await timezoneService.getDisplayTimezone()) ?? .current
    }
    
    // MARK: - Public Methods
    
    /// Get habits with their progress and completion status for a specific date
    /// Uses main app's business logic for consistent results
    func getHabitsWithProgress(for date: Date, timezone: TimeZone) async -> [(habit: Habit, currentProgress: Int, isCompleted: Bool)] {
        do {
            let targetDate = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)

            // 1. Get active habits using main app's Use Case
            let allHabits = try await getActiveHabits.execute()

            // 2. Filter to habits scheduled for target date (and already started)
            // Note: isScheduledDay already checks start date, but we use habit.isScheduledOn for consistency
            let scheduledHabits = allHabits.filter { $0.isScheduledOn(date: targetDate) }

            // 3. Get batch logs for all scheduled habits using main app's Use Case
            let habitIds = scheduledHabits.map { $0.id }
            let logsByHabitId = try await getBatchLogs.execute(
                for: habitIds,
                since: targetDate,
                until: CalendarUtils.addDaysLocal(1, to: targetDate, timezone: timezone)
            )
            
            // 4. Process each habit with its progress and completion
            var result: [(habit: Habit, currentProgress: Int, isCompleted: Bool)] = []
            
            for habit in scheduledHabits {
                let habitLogs = logsByHabitId[habit.id] ?? []

                // Calculate current progress
                let currentProgress: Int
                if habit.kind == .binary {
                    currentProgress = habitLogs.isEmpty ? 0 : 1
                } else {
                    let progressValue = habitLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                    currentProgress = Int(progressValue)
                }

                // Check completion using main app's service
                let isCompleted = habitCompletionService.isCompleted(
                    habit: habit,
                    on: targetDate,
                    logs: habitLogs
                )

                result.append((
                    habit: habit,
                    currentProgress: currentProgress,
                    isCompleted: isCompleted
                ))
            }

            return result

        } catch {
            logger.log("Failed to get habits with progress: \(error.localizedDescription)", level: .error, category: .system)
            return []
        }
    }
    
    /// Get completion percentage for a specific date
    /// Uses main app's business logic for accurate calculations
    func getCompletionPercentage(for date: Date, timezone: TimeZone) async -> Double {
        let habitsWithProgress = await getHabitsWithProgress(for: date, timezone: timezone)
        guard !habitsWithProgress.isEmpty else { return 0.0 }

        let completedCount = habitsWithProgress.filter { $0.isCompleted }.count
        let percentage = Double(completedCount) / Double(habitsWithProgress.count)

        return percentage
    }
}