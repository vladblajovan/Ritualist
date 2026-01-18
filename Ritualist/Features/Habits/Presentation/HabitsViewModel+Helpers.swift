//
//  HabitsViewModel+Helpers.swift
//  Ritualist
//
//  Helper methods extracted from HabitsViewModel to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Habit Completion & Schedule Methods

extension HabitsViewModel {

    /// Check if a habit is completed today using IsHabitCompletedUseCase.
    public func isHabitCompletedToday(_ habit: Habit) async -> Bool {
        do {
            // Use dedicated UseCase to get logs for a single habit today
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: today, to: today)
            return isHabitCompleted.execute(habit: habit, on: today, logs: logs, timezone: displayTimezone)
        } catch {
            logger.log(
                "Failed to check habit completion",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": habit.id.uuidString, "error": error.localizedDescription]
            )
            return false
        }
    }

    /// Get current progress for a habit today using CalculateDailyProgressUseCase.
    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            // Use dedicated UseCase to get logs for a single habit today
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            let logs = try await getSingleHabitLogs.execute(for: habit.id, from: today, to: today)
            return calculateDailyProgress.execute(habit: habit, logs: logs, for: today, timezone: displayTimezone)
        } catch {
            logger.log(
                "Failed to get habit progress",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": habit.id.uuidString, "error": error.localizedDescription]
            )
            return 0.0
        }
    }

    /// Check if a habit should be shown as actionable today using IsScheduledDayUseCase.
    public func isHabitActionableToday(_ habit: Habit) -> Bool {
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
        return isScheduledDay.execute(habit: habit, date: today, timezone: displayTimezone)
    }

    /// Get schedule validation message for a habit.
    public func getScheduleValidationMessage(for habit: Habit) async -> String? {
        do {
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: today)
            return nil // No validation errors
        } catch {
            return error.localizedDescription
        }
    }

    /// Get the schedule status for a habit today.
    public func getScheduleStatus(for habit: Habit) -> HabitScheduleStatus {
        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
        return HabitScheduleStatus.forHabit(habit, date: today, isScheduledDay: isScheduledDay, timezone: displayTimezone)
    }

    /// Check if a habit's logging should be disabled based on schedule validation.
    public func shouldDisableLogging(for habit: Habit) async -> Bool {
        do {
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            let validationResult = try await validateHabitScheduleUseCase.execute(habit: habit, date: today)
            return !validationResult.isValid
        } catch {
            return true // Disable if validation fails
        }
    }

    /// Get validation result for a habit (used for real-time UI feedback).
    public func getValidationResult(for habit: Habit) async -> HabitScheduleValidationResult? {
        do {
            let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: displayTimezone)
            return try await validateHabitScheduleUseCase.execute(habit: habit, date: today)
        } catch {
            return nil
        }
    }
}

// MARK: - Category Filter Methods

extension HabitsViewModel {

    /// Handle category filter selection.
    public func selectFilterCategory(_ category: HabitCategory?) {
        selectedFilterCategory = category
    }

    /// Select a category filter by ID (used for deep linking from stats).
    public func selectFilterCategoryById(_ categoryId: String) {
        guard let matchedCategory = categories.first(where: { $0.id == categoryId }) else { return }
        selectFilterCategory(matchedCategory)
    }
}

// MARK: - Assistant Navigation Methods

extension HabitsViewModel {

    /// Handle habit assistant button tap.
    public func handleAssistantTap(source: String = "toolbar") {
        // Cancel any pending reopen tasks to prevent race conditions
        // (user is manually opening, so we don't need the delayed reopen)
        cancelPendingAssistantPaywallTasks()

        userActionTracker.track(.habitsAssistantOpened(source: source == "emptyState" ? .emptyState : .habitsPage))
        showingHabitAssistant = true
    }

    /// Cancel all pending assistant/paywall tasks and reset flags.
    /// Call this when user takes an action that should override any pending async operations.
    func cancelPendingAssistantPaywallTasks() {
        pendingAssistantReopenTask?.cancel()
        pendingAssistantReopenTask = nil
        pendingPaywallShowTask?.cancel()
        pendingPaywallShowTask = nil

        // Reset flags to clean state
        shouldReopenAssistantAfterPaywall = false
        pendingPaywallAfterAssistantDismiss = false
        isHandlingPaywallDismissal = false
    }

    /// Dismiss assistant and show paywall (called from assistant's upgrade button).
    /// Sets flag to show paywall after assistant dismissal completes.
    public func dismissAssistantAndShowPaywall() {
        // Cancel any existing pending tasks before setting up new flow
        pendingAssistantReopenTask?.cancel()
        pendingAssistantReopenTask = nil
        pendingPaywallShowTask?.cancel()
        pendingPaywallShowTask = nil

        pendingPaywallAfterAssistantDismiss = true
        shouldReopenAssistantAfterPaywall = true
        showingHabitAssistant = false
    }

    /// Handle paywall dismissal.
    public func handlePaywallDismissal() {
        // Guard against multiple calls
        guard !isHandlingPaywallDismissal else { return }

        // Track paywall dismissal
        paywallViewModel.trackPaywallDismissed()

        // Refresh premium status in case user purchased
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await refreshPremiumStatus()
        }

        isHandlingPaywallDismissal = true

        if shouldReopenAssistantAfterPaywall {
            // Reset the flag
            shouldReopenAssistantAfterPaywall = false

            // Cancel any existing pending reopen task
            pendingAssistantReopenTask?.cancel()

            // Wait for paywall dismissal animation to complete before reopening assistant
            // Using a cancellable Task instead of DispatchQueue to prevent race conditions
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            pendingAssistantReopenTask = Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.0))
                guard !Task.isCancelled else { return }
                showingHabitAssistant = true
                isHandlingPaywallDismissal = false
            }
        } else {
            isHandlingPaywallDismissal = false
        }
    }

    /// Handle when assistant sheet is dismissed - refresh data and show pending paywall.
    public func handleAssistantDismissal() {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await refresh()
        }

        // Check if we need to show paywall after assistant dismissal
        if pendingPaywallAfterAssistantDismiss {
            pendingPaywallAfterAssistantDismiss = false

            // Cancel any existing pending paywall task
            pendingPaywallShowTask?.cancel()

            // Small delay to let the sheet dismissal animation complete
            // Using a cancellable Task to prevent race conditions
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            pendingPaywallShowTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
                guard !Task.isCancelled else { return }
                await showPaywall()
            }
        }
    }
}
