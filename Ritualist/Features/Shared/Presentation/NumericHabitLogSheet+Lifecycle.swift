//
//  NumericHabitLogSheet+Lifecycle.swift
//  Ritualist
//
//  Lifecycle and data loading methods extracted from NumericHabitLogSheetDirect to reduce type body length.
//

import SwiftUI
import RitualistCore
import TipKit

// MARK: - Lifecycle & Data Loading

extension NumericHabitLogSheetDirect {

    /// Handles the onAppear lifecycle event.
    func handleOnAppear() {
        if let initial = initialValue, initial > 0 {
            currentValue = initial
            value = initial
            isLoading = false
        } else {
            loadCurrentValue()
        }
        // Announce sheet to VoiceOver for focus management
        DispatchQueue.main.asyncAfter(deadline: .now() + AccessibilityConfig.voiceOverAnnouncementDelay) {
            UIAccessibility.post(notification: .screenChanged, argument: "Log \(habit.name)")
        }
    }

    /// Handles the onDisappear lifecycle event.
    func handleOnDisappear() {
        loadTask?.cancel()
        loadTask = nil

        // Save on dismiss if value changed - user sees Overview animate with new progress
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        if value != currentValue {
            Task { @MainActor in
                do {
                    try await onSave(value)
                } catch {
                    logger.log(
                        "Failed to save habit value on dismiss",
                        level: .error,
                        category: .dataIntegrity,
                        metadata: ["habit_id": habit.id.uuidString, "value": "\(value)", "error": error.localizedDescription]
                    )
                }
            }
        }
    }

    /// Handles changes to the current value.
    func handleCurrentValueChange(_ newValue: Double) {
        value = newValue
    }

    /// Handles changes to the value, managing extra mile text and celebrations.
    func handleValueChange(oldValue: Double, newValue: Double) {
        // Set extra mile text when first exceeding target
        if newValue > dailyTarget && extraMileText == nil {
            extraMileText = Strings.NumericHabitLog.extraMilePhrases.randomElement()
        }

        // Trigger celebration and tip when reaching target for the first time
        if newValue >= dailyTarget && oldValue < dailyTarget {
            showCelebration = true
            TapCompletedHabitTip.firstHabitCompleted.sendDonation()
            logger.log("Numeric habit completed - donated firstHabitCompleted event", level: .debug, category: .ui)
        }
    }

    /// Loads the current value from existing logs for the viewing date.
    func loadCurrentValue() {
        loadTask = Task { @MainActor in
            do {
                let logs = try await getLogs.execute(for: habit.id, since: nil, until: nil)

                guard !Task.isCancelled else { return }

                // Use cross-timezone comparison: log's calendar day (in its stored timezone) vs viewing date (in display timezone)
                let targetDateLogs = logs.filter { log in
                    let logTimezone = log.resolvedTimezone(fallback: timezone)
                    return CalendarUtils.areSameDayAcrossTimezones(
                        log.date,
                        timezone1: logTimezone,
                        viewingDate,
                        timezone2: timezone
                    )
                }
                let totalValue = targetDateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }

                guard !Task.isCancelled else { return }
                currentValue = totalValue
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                currentValue = 0.0
                isLoading = false
            }
        }
    }
}
