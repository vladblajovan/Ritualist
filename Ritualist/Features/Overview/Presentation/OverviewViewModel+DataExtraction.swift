//
//  OverviewViewModel+DataExtraction.swift
//  Ritualist
//
//  Data extraction methods extracted from OverviewViewModel to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Data Extraction Methods

extension OverviewViewModel {

    /// Extract TodaysSummary from overview data.
    func extractTodaysSummary(from data: OverviewData) -> TodaysSummary {
        let targetDate = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: data.timezone)
        let habits = data.scheduledHabits(for: targetDate)

        logExtractTodaysSummaryDebugInfo(data: data, habits: habits, targetDate: targetDate)

        let result = categorizeHabitsByCompletion(habits: habits, data: data, targetDate: targetDate)
        let sortedCompleted = sortCompletedHabitsByLatestLog(result.completed, logs: result.logs)

        return TodaysSummary(
            completedHabitsCount: sortedCompleted.count,
            completedHabits: sortedCompleted,
            totalHabits: habits.count,
            incompleteHabits: result.incomplete
        )
    }

    /// Log debug info for extractTodaysSummary.
    private func logExtractTodaysSummaryDebugInfo(data: OverviewData, habits: [Habit], targetDate: Date) {
        if let firstHabit = habits.first {
            let allLogs = data.habitLogs[firstHabit.id] ?? []
            let filteredLogs = data.logs(for: firstHabit.id, on: targetDate)
            logger.log(
                "DEBUG extractTodaysSummary",
                level: .debug,
                category: .stateManagement,
                metadata: [
                    "viewingDate_utc": viewingDate.description,
                    "targetDate_utc": targetDate.description,
                    "data_timezone": data.timezone.identifier,
                    "habit_name": firstHabit.name,
                    "all_logs_count": allLogs.count,
                    "filtered_logs_count": filteredLogs.count
                ]
            )
        }
    }

    /// Result of categorizing habits by completion status.
    struct HabitCategorizationResult {
        let completed: [Habit]
        let incomplete: [Habit]
        let logs: [HabitLog]
    }

    /// Categorize habits into completed and incomplete lists.
    func categorizeHabitsByCompletion(
        habits: [Habit],
        data: OverviewData,
        targetDate: Date
    ) -> HabitCategorizationResult {
        var allTargetDateLogs: [HabitLog] = []
        var incompleteHabits: [Habit] = []
        var completedHabits: [Habit] = []
        let isFutureDate = targetDate > Date()

        for habit in habits {
            let logs = data.logs(for: habit.id, on: targetDate)
            allTargetDateLogs.append(contentsOf: logs)

            let isCompleted = isHabitCompleted.execute(habit: habit, on: targetDate, logs: logs, timezone: data.timezone)

            if isCompleted {
                completedHabits.append(habit)
            } else if !isFutureDate {
                incompleteHabits.append(habit)
            }
        }

        return HabitCategorizationResult(completed: completedHabits, incomplete: incompleteHabits, logs: allTargetDateLogs)
    }

    /// Sort completed habits by latest log time (most recent first).
    func sortCompletedHabitsByLatestLog(_ habits: [Habit], logs: [HabitLog]) -> [Habit] {
        habits.sorted { habit1, habit2 in
            let habit1LatestTime = logs.filter { $0.habitID == habit1.id }.map { $0.date }.max() ?? .distantPast
            let habit2LatestTime = logs.filter { $0.habitID == habit2.id }.map { $0.date }.max() ?? .distantPast
            return habit1LatestTime > habit2LatestTime
        }
    }

    /// Extract monthly completion data from overview data.
    func extractMonthlyData(from data: OverviewData) -> [Date: Double] {
        var result: [Date: Double] = [:]
        let timezone = data.timezone

        for dayOffset in 0...30 {
            let date = CalendarUtils.addDaysLocal(-dayOffset, to: Date(), timezone: timezone)
            let startOfDay = CalendarUtils.startOfDayLocal(for: date, timezone: timezone)
            let scheduledHabits = data.scheduledHabits(for: startOfDay)
            if scheduledHabits.isEmpty {
                result[startOfDay] = 0.0
            } else {
                let completedCount = scheduledHabits.count { habit in
                    let logs = data.logs(for: habit.id, on: startOfDay)
                    return isHabitCompleted.execute(habit: habit, on: startOfDay, logs: logs, timezone: timezone)
                }
                result[startOfDay] = Double(completedCount) / Double(scheduledHabits.count)
            }
        }

        return result
    }

    /// Extract active streaks from overview data.
    func extractActiveStreaks(from data: OverviewData) -> [StreakInfo] {
        var streaks: [StreakInfo] = []
        let today = Date()

        for habit in data.habits {
            let logs = data.habitLogs[habit.id] ?? []
            let streakStatus = getStreakStatusUseCase.execute(habit: habit, logs: logs, asOf: today, timezone: data.timezone)

            let displayStreak = streakStatus.displayStreak
            if displayStreak >= 1 {
                let streakInfo = StreakInfo(
                    id: habit.id.uuidString,
                    habitName: habit.name,
                    emoji: habit.emoji ?? "📊",
                    currentStreak: displayStreak,
                    isActive: !streakStatus.isAtRisk
                )
                streaks.append(streakInfo)
            }
        }

        return streaks.sorted { $0.currentStreak > $1.currentStreak }
    }

    /// Get user name from profile.
    func getUserName() async -> String? {
        let profile = await getCurrentUserProfile.execute()
        return profile.name.isEmpty ? nil : profile.name
    }

    /// Check habit limit status.
    func checkHabitLimitStatus(habitCount: Int) async {
        activeHabitsCount = habitCount
        showDeactivateHabitsBanner = await featureGating.isOverActiveHabitLimit(activeCount: habitCount)

        if showDeactivateHabitsBanner {
            logger.log(
                "User over free tier habit limit",
                level: .info,
                category: .stateManagement,
                metadata: ["activeCount": habitCount, "maxFree": BusinessConstants.freeMaxHabits]
            )
        }
    }

    /// Load overview data from database.
    func loadOverviewData() async throws -> OverviewData {
        let habits = try await getActiveHabits.execute()
        let today = Date()
        let startDate = CalendarUtils.addDaysLocal(-30, to: today, timezone: displayTimezone)
        let habitIds = habits.map(\.id)
        let habitLogs = try await getBatchLogs.execute(for: habitIds, since: nil, until: nil, timezone: displayTimezone)

        return OverviewData(habits: habits, habitLogs: habitLogs, dateRange: startDate...today, timezone: displayTimezone)
    }

    /// Configure child ViewModels with current context.
    func configureChildViewModels(userName: String?) {
        let configuration = InspirationCardConfiguration(
            activeStreaks: activeStreaks,
            todaysSummary: todaysSummary,
            displayTimezone: displayTimezone,
            isViewingToday: isViewingToday,
            totalHabitsCount: overviewData?.habits.count ?? 0,
            userName: userName
        )
        inspirationVM.configure(with: configuration)
    }
}
