//
//  HabitLogCompletionValidator.swift
//  RitualistCore
//
//  Created by Claude Code on 15/11/2025.
//  Phase 2, Week 4: Shared Utilities Extraction
//

import Foundation

/// Shared utility for validating whether a habit log meets completion criteria
///
/// Extracted from duplicate implementations in:
/// - HabitCompletionService
/// - StreakCalculationService
/// - ScheduleAwareCompletionCalculator
///
/// This provides a single source of truth for habit log completion validation logic.
public enum HabitLogCompletionValidator {

    /// Check if a single log meets the completion criteria for its habit
    ///
    /// - Parameters:
    ///   - log: The habit log to validate
    ///   - habit: The habit that defines the completion criteria
    /// - Returns: `true` if the log is considered complete based on the habit's kind and target
    ///
    /// **Completion Rules:**
    /// - **Binary habits**: Log must exist with `value > 0`
    /// - **Numeric habits with target**: Log value must be `>= dailyTarget`
    /// - **Numeric habits without target**: Log value must be `> 0`
    public static func isLogCompleted(log: HabitLog, habit: Habit) -> Bool {
        switch habit.kind {
        case .binary:
            // For binary habits: log exists AND value > 0
            guard let value = log.value else { return false }
            return value > 0

        case .numeric:
            guard let logValue = log.value else { return false }

            // For numeric habits: must meet daily target if set, otherwise any positive value
            if let target = habit.dailyTarget {
                return logValue >= target
            } else {
                return logValue > 0
            }
        }
    }
}
