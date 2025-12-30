//
//  NotificationActionCoordinator.swift
//  Ritualist
//
//  Extracted from Container+Services.swift for SRP compliance
//

import Foundation
import FactoryKit
import RitualistCore

/// Coordinates notification action handling between services and UI
/// Note: This coordinator is NOT MainActor-isolated because it's called from
/// the notification service's action handler which runs in a non-isolated context.
/// All MainActor operations are dispatched explicitly using Task { @MainActor in }.
public final class NotificationActionCoordinator: Sendable {
    private let logger: DebugLogger

    public init(logger: DebugLogger) {
        self.logger = logger
    }

    /// Handle notification action from the notification service
    /// Actions:
    ///   .log = Quick action button ("Mark Complete" / "Log Progress") - auto-log for binary
    ///   .openApp = Notification tap - show confirmation sheet
    ///   .remindLater = Snooze quick action
    ///   .dismiss = Dismiss quick action
    public func handleAction(
        _ action: NotificationAction,
        habitId: UUID,
        habitName: String?,
        habitKind: HabitKind,
        reminderTime: ReminderTime?
    ) async throws {
        switch (action, habitKind) {
        case (.log, .binary):
            try await handleBinaryQuickAction(habitId: habitId, habitName: habitName, reminderTime: reminderTime)

        case (.log, .numeric):
            await handleNumericQuickAction(habitId: habitId)

        case (.openApp, .binary):
            await handleBinaryNotificationTap(habitId: habitId)

        case (.openApp, .numeric):
            await handleNumericNotificationTap(habitId: habitId)

        case (.remindLater, _), (.dismiss, _):
            let useCase = Container.shared.handleNotificationAction()
            try await useCase.execute(
                action: action,
                habitId: habitId,
                habitName: habitName,
                habitKind: habitKind,
                reminderTime: reminderTime
            )
        }
    }

    // MARK: - Private Handlers

    /// Quick action "Mark Complete" for binary habits: auto-log without showing sheet
    private func handleBinaryQuickAction(
        habitId: UUID,
        habitName: String?,
        reminderTime: ReminderTime?
    ) async throws {
        logger.log(
            "🔔 Binary quick action - auto-logging",
            level: .info,
            category: .notifications,
            metadata: ["habitId": habitId.uuidString, "habitName": habitName ?? "unknown"]
        )

        let useCase = Container.shared.handleNotificationAction()
        try await useCase.execute(
            action: .log,
            habitId: habitId,
            habitName: habitName,
            habitKind: .binary,
            reminderTime: reminderTime
        )

        await MainActor.run {
            Container.shared.navigationService().navigateToOverview(shouldRefresh: true)
        }
    }

    /// Quick action "Log Progress" for numeric habits: show value entry sheet
    private func handleNumericQuickAction(habitId: UUID) async {
        logger.log(
            "🔔 Numeric quick action - showing sheet",
            level: .info,
            category: .notifications,
            metadata: ["habitId": habitId.uuidString]
        )

        await showNumericHabitSheet(habitId: habitId)
    }

    /// Notification tap for binary habits: show confirmation sheet
    private func handleBinaryNotificationTap(habitId: UUID) async {
        logger.log(
            "🔔 Binary notification tap - showing confirmation sheet",
            level: .info,
            category: .notifications,
            metadata: ["habitId": habitId.uuidString]
        )

        await showBinaryHabitSheet(habitId: habitId)
    }

    /// Notification tap for numeric habits: show value entry sheet
    private func handleNumericNotificationTap(habitId: UUID) async {
        logger.log(
            "🔔 Numeric notification tap - showing sheet",
            level: .info,
            category: .notifications,
            metadata: ["habitId": habitId.uuidString]
        )

        await showNumericHabitSheet(habitId: habitId)
    }

    // MARK: - UI Helpers

    private func showBinaryHabitSheet(habitId: UUID) async {
        await showHabitSheet(habitId: habitId, isBinary: true)
    }

    private func showNumericHabitSheet(habitId: UUID) async {
        await showHabitSheet(habitId: habitId, isBinary: false)
    }

    private func showHabitSheet(habitId: UUID, isBinary: Bool) async {
        do {
            let repository = Container.shared.habitRepository()
            guard let habit = try await repository.fetchHabit(by: habitId) else {
                logger.log(
                    "⚠️ Habit not found for notification action",
                    level: .warning,
                    category: .notifications,
                    metadata: ["habitId": habitId.uuidString]
                )
                // Still navigate to Overview so user isn't left hanging
                await MainActor.run {
                    Container.shared.navigationService().navigateToOverview(shouldRefresh: true)
                }
                return
            }

            await MainActor.run {
                let viewModel = Container.shared.overviewViewModel()
                if isBinary {
                    viewModel.setPendingBinaryHabit(habit)
                } else {
                    viewModel.setPendingNumericHabit(habit)
                }
                Container.shared.navigationService().navigateToOverview(shouldRefresh: true)
            }
        } catch {
            logger.log(
                "⚠️ Failed to fetch habit for sheet",
                level: .warning,
                category: .notifications,
                metadata: ["habitId": habitId.uuidString, "error": error.localizedDescription]
            )
            // Still navigate to Overview so user isn't left hanging
            await MainActor.run {
                Container.shared.navigationService().navigateToOverview(shouldRefresh: true)
            }
        }
    }
}
