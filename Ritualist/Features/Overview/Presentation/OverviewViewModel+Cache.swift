//
//  OverviewViewModel+Cache.swift
//  Ritualist
//
//  Cache management methods extracted from OverviewViewModel to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Migration Check

extension OverviewViewModel {

    /// Check if migration just completed and invalidate cache if needed.
    /// Returns true if cache was invalidated (caller should reload).
    func checkMigrationAndInvalidateCache() -> Bool {
        let currentlyMigrating = getMigrationStatus.isMigrating

        let justCompletedMigration = wasMigrating && !currentlyMigrating
        wasMigrating = currentlyMigrating

        if justCompletedMigration {
            logger.logStateTransition(
                from: "migration_completed",
                to: "cache_invalidated",
                context: ["action": "Force reload required"]
            )
            overviewData = nil
            hasLoadedInitialData = false
            return true
        }

        return false
    }
}

// MARK: - Cache Update Helpers

extension OverviewViewModel {

    /// Update cache after successful database write.
    func updateCachedLog(_ log: HabitLog) {
        guard let data = overviewData else {
            logger.log("Cache miss - no cache available", level: .debug, category: .stateManagement, metadata: ["operation": "updateCachedLog"])
            return
        }

        var habitLogs = data.habitLogs[log.habitID] ?? []

        if let existingIndex = habitLogs.firstIndex(where: { $0.id == log.id }) {
            habitLogs[existingIndex] = log
            logger.log("Cache updated - existing log modified", level: .debug, category: .stateManagement, metadata: ["habit_id": log.habitID.uuidString])
        } else {
            habitLogs.append(log)
            logger.log("Cache updated - new log added", level: .debug, category: .stateManagement, metadata: ["habit_id": log.habitID.uuidString])
        }

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[log.habitID] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange,
            timezone: data.timezone
        )

        refreshUIState(with: updatedData)
    }

    /// Remove logs from cache after successful database delete.
    func removeCachedLogs(habitId: UUID, on date: Date) {
        guard let data = overviewData else {
            logger.log("Cache miss - no cache available for delete", level: .debug, category: .stateManagement, metadata: ["habit_id": habitId.uuidString])
            return
        }

        var habitLogs = data.habitLogs[habitId] ?? []
        let beforeCount = habitLogs.count
        habitLogs.removeAll { log in
            let logTimezone = log.resolvedTimezone(fallback: displayTimezone)
            return CalendarUtils.areSameDayAcrossTimezones(log.date, timezone1: logTimezone, date, timezone2: displayTimezone)
        }
        let removedCount = beforeCount - habitLogs.count
        logger.log("Cache updated - logs removed", level: .debug, category: .stateManagement, metadata: ["habit_id": habitId.uuidString, "removed_count": removedCount])

        var updatedHabitLogs = data.habitLogs
        updatedHabitLogs[habitId] = habitLogs

        let updatedData = OverviewData(
            habits: data.habits,
            habitLogs: updatedHabitLogs,
            dateRange: data.dateRange,
            timezone: data.timezone
        )

        refreshUIState(with: updatedData)
    }

    /// Refresh all derived UI properties from OverviewData.
    func refreshUIState(with data: OverviewData) {
        self.overviewData = data
        self.todaysSummary = extractTodaysSummary(from: data)
        self.activeStreaks = extractActiveStreaks(from: data)
        self.monthlyCompletionData = extractMonthlyData(from: data)

        // Cancel existing task before creating new one to prevent race conditions
        childVMConfigTask?.cancel()
        childVMConfigTask = Task { @MainActor in
            defer { childVMConfigTask = nil }
            guard !Task.isCancelled else { return }
            let userName = await getUserName()
            guard !Task.isCancelled else { return }
            configureChildViewModels(userName: userName)
            inspirationVM.checkAndShowInspirationCard()
        }
    }
}
