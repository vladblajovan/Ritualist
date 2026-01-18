//
//  OverviewViewModel+HabitOperations.swift
//  Ritualist
//
//  Habit interaction methods extracted from OverviewViewModel to reduce type body length.
//

import Foundation
import TipKit
import RitualistCore

// MARK: - Habit Completion Methods

extension OverviewViewModel {

    /// Complete a habit (binary or numeric).
    public func completeHabit(_ habit: Habit) async {
        // MIGRATION CHECK: Invalidate cache if migration just completed
        if checkMigrationAndInvalidateCache() {
            await loadData()
        }

        do {
            if habit.kind == .numeric {
                try await updateNumericHabit(habit, value: habit.dailyTarget ?? 1.0)
            } else {
                let effectiveTimezone = overviewData?.timezone ?? displayTimezone
                let logDate = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: effectiveTimezone)
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: logDate,
                    value: 1.0,
                    timezone: effectiveTimezone.identifier
                )

                logger.log(
                    "DEBUG completeHabit creating log",
                    level: .warning,
                    category: .stateManagement,
                    metadata: [
                        "habit_name": habit.name,
                        "viewingDate_utc": viewingDate.description,
                        "effectiveTimezone": effectiveTimezone.identifier,
                        "overviewData_timezone": overviewData?.timezone.identifier ?? "nil",
                        "displayTimezone": displayTimezone.identifier,
                        "logDate_utc": logDate.description,
                        "device_timezone": TimeZone.current.identifier
                    ]
                )

                try await logHabit.execute(log)
                updateCachedLog(log)
                await TapCompletedHabitTip.firstHabitCompleted.donate()
                try? await Task.sleep(nanoseconds: 100_000_000)
                refreshWidget.execute(habitId: habit.id)
            }
        } catch {
            self.error = error
            logger.logError(error, context: "Failed to complete habit", metadata: ["habit_id": habit.id.uuidString])
        }
    }

    /// Get current progress for a habit asynchronously.
    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate, timezone: displayTimezone)
            let logsForDate = allLogs.filter { log in
                let logTimezone = log.resolvedTimezone(fallback: displayTimezone)
                return CalendarUtils.areSameDayAcrossTimezones(log.date, timezone1: logTimezone, viewingDate, timezone2: displayTimezone)
            }

            if habit.kind == .numeric {
                return logsForDate.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            } else {
                return logsForDate.isEmpty ? 0.0 : 1.0
            }
        } catch {
            logger.logError(error, context: "Failed to get current progress", metadata: ["habit_name": habit.name, "habit_id": habit.id.uuidString])
            return 0.0
        }
    }

    /// Update a numeric habit with a new value.
    public func updateNumericHabit(_ habit: Habit, value: Double) async throws {
        if checkMigrationAndInvalidateCache() {
            await loadData()
        }

        do {
            let existingLogsForDate = overviewData?.logs(for: habit.id, on: viewingDate) ?? []
            let log: HabitLog
            let effectiveTimezone = overviewData?.timezone ?? displayTimezone

            if existingLogsForDate.isEmpty {
                log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: effectiveTimezone),
                    value: value,
                    timezone: effectiveTimezone.identifier
                )
                try await logHabit.execute(log)
            } else if existingLogsForDate.count == 1 {
                var updatedLog = existingLogsForDate[0]
                updatedLog.value = value
                log = updatedLog
                try await logHabit.execute(log)
            } else {
                for existingLog in existingLogsForDate {
                    try await deleteLog.execute(id: existingLog.id)
                }
                log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayLocal(for: viewingDate, timezone: effectiveTimezone),
                    value: value,
                    timezone: effectiveTimezone.identifier
                )
                try await logHabit.execute(log)
            }

            updateCachedLog(log)
            await TapCompletedHabitTip.firstHabitCompleted.donate()
            try? await Task.sleep(nanoseconds: 100_000_000)
            refreshWidget.execute(habitId: habit.id)
        } catch {
            self.error = error
            logger.logError(error, context: "Failed to update numeric habit", metadata: ["habit_id": habit.id.uuidString])
            throw error
        }
    }

    /// Get progress synchronously from cache.
    public func getProgressSync(for habit: Habit) -> Double {
        guard let data = overviewData else { return 0.0 }
        let logs = data.logs(for: habit.id, on: viewingDate)

        if habit.kind == .binary {
            return logs.isEmpty ? 0.0 : 1.0
        } else {
            return logs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
        }
    }

    /// Delete a habit log for the current viewing date.
    public func deleteHabitLog(_ habit: Habit) async {
        if checkMigrationAndInvalidateCache() {
            await loadData()
        }

        do {
            let existingLogsForDate = overviewData?.logs(for: habit.id, on: viewingDate) ?? []

            for log in existingLogsForDate {
                try await deleteLog.execute(id: log.id)
            }

            removeCachedLogs(habitId: habit.id, on: viewingDate)
            try? await Task.sleep(nanoseconds: 100_000_000)
            refreshWidget.execute(habitId: habit.id)
        } catch {
            self.error = error
            logger.logError(error, context: "Failed to delete habit log", metadata: ["habit_id": habit.id.uuidString])
        }
    }
}

// MARK: - Schedule Status and Validation Methods

extension OverviewViewModel {

    /// Get the schedule status for a habit.
    public func getScheduleStatus(for habit: Habit) -> HabitScheduleStatus {
        HabitScheduleStatus.forHabit(habit, date: viewingDate, isScheduledDay: isScheduledDay, timezone: displayTimezone)
    }

    /// Get streak status synchronously from cache.
    public func getStreakStatusSync(for habit: Habit) -> HabitStreakStatus {
        guard let data = overviewData else {
            return HabitStreakStatus(current: 0, atRisk: 0, isAtRisk: false, isTodayScheduled: false)
        }

        let logs = data.habitLogs[habit.id] ?? []
        return getStreakStatusUseCase.execute(habit: habit, logs: logs, asOf: viewingDate, timezone: data.timezone)
    }

    /// Get schedule validation message for a habit.
    public func getScheduleValidationMessage(for habit: Habit) async -> String? {
        do {
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: viewingDate)
            return nil
        } catch let error as HabitScheduleValidationError {
            return error.localizedDescription
        } catch {
            return "Unable to validate habit schedule"
        }
    }
}

// MARK: - Sheet Presentation Methods

extension OverviewViewModel {

    /// Show numeric habit sheet.
    public func showNumericSheet(for habit: Habit) {
        selectedHabitForSheet = habit
        showingNumericSheet = true
    }

    /// Show binary habit sheet.
    public func showBinarySheet(for habit: Habit) {
        selectedHabitForSheet = habit
        showingCompleteHabitSheet = true
    }
}

// MARK: - Pending Habit Processing Methods

extension OverviewViewModel {

    /// Set pending numeric habit from notification.
    public func setPendingNumericHabit(_ habit: Habit) {
        pendingNumericHabitFromNotification = habit
        hasPendingHabitBeenProcessed = false

        if isViewVisible {
            processPendingNumericHabit()
        }
    }

    /// Check if pending habit has been processed.
    public var isPendingHabitProcessed: Bool {
        hasPendingHabitBeenProcessed
    }

    /// Set view visibility state.
    public func setViewVisible(_ visible: Bool) {
        isViewVisible = visible
        if !visible {
            // Cancel any pending background tasks when view disappears
            childVMConfigTask?.cancel()
            childVMConfigTask = nil
        }
    }

    /// Process pending numeric habit.
    public func processPendingNumericHabit() {
        guard !hasPendingHabitBeenProcessed,
              let habit = pendingNumericHabitFromNotification else {
            return
        }

        showNumericSheet(for: habit)
        pendingNumericHabitFromNotification = nil
        hasPendingHabitBeenProcessed = true
    }

    /// Set pending binary habit from notification.
    public func setPendingBinaryHabit(_ habit: Habit) {
        pendingBinaryHabitFromNotification = habit
        hasPendingBinaryHabitBeenProcessed = false

        if isViewVisible {
            processPendingBinaryHabit()
        }
    }

    /// Check if pending binary habit has been processed.
    public var isPendingBinaryHabitProcessed: Bool {
        hasPendingBinaryHabitBeenProcessed
    }

    /// Process pending binary habit.
    public func processPendingBinaryHabit() {
        guard !hasPendingBinaryHabitBeenProcessed,
              let habit = pendingBinaryHabitFromNotification else {
            return
        }

        selectedHabitForSheet = habit
        showingCompleteHabitSheet = true
        pendingBinaryHabitFromNotification = nil
        hasPendingBinaryHabitBeenProcessed = true
    }
}
