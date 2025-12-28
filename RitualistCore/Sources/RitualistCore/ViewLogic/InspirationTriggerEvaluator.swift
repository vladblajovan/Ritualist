//
//  InspirationTriggerEvaluator.swift
//  Ritualist
//
//  Pure function evaluator for inspiration triggers.
//  Extracted for testability and to reduce InspirationCardViewModel size.
//

import Foundation

// MARK: - InspirationTriggerEvaluator

/// Pure function evaluator for inspiration triggers
/// Takes completion state and returns applicable triggers
/// Stateless and easily testable
public struct InspirationTriggerEvaluator {

    // MARK: - Evaluation Context

    public struct Context {
        let completionRate: Double
        let completedCount: Int
        let totalHabits: Int
        let totalHabitsInApp: Int
        let hour: Int
        let timeOfDay: TimeOfDay
        let isWeekend: Bool
        let isComebackStory: Bool

        public init(
            completionRate: Double,
            completedCount: Int,
            totalHabits: Int,
            totalHabitsInApp: Int,
            hour: Int,
            timeOfDay: TimeOfDay,
            isWeekend: Bool,
            isComebackStory: Bool
        ) {
            self.completionRate = completionRate
            self.completedCount = completedCount
            self.totalHabits = totalHabits
            self.totalHabitsInApp = totalHabitsInApp
            self.hour = hour
            self.timeOfDay = timeOfDay
            self.isWeekend = isWeekend
            self.isComebackStory = isComebackStory
        }
    }

    // MARK: - Public Methods

    /// Evaluate all applicable inspiration triggers based on current context
    /// Returns triggers from up to 3 categories: progress, time, and special
    public static func evaluateTriggers(context: Context) -> [InspirationTrigger] {
        var triggers: [InspirationTrigger] = []

        // Edge case: No habits created yet (brand new user)
        if context.totalHabitsInApp == 0 {
            return [.sessionStart]
        }

        // Edge case: Empty Day (no habits scheduled today)
        if context.totalHabits == 0 {
            return [.emptyDay]
        }

        // Category 1: Progress-based
        if let progressTrigger = evaluateProgressTrigger(
            completionRate: context.completionRate,
            completedCount: context.completedCount
        ) {
            triggers.append(progressTrigger)
        }

        // Category 2: Time-of-day
        if let timeTrigger = evaluateTimeTrigger(
            completionRate: context.completionRate,
            hour: context.hour,
            timeOfDay: context.timeOfDay
        ) {
            triggers.append(timeTrigger)
        }

        // Category 3: Special context
        if let specialTrigger = evaluateSpecialTrigger(
            isComebackStory: context.isComebackStory,
            isWeekend: context.isWeekend
        ) {
            triggers.append(specialTrigger)
        }

        return triggers
    }

    /// Filter triggers by dismissed set and limit to max items
    public static func filterAndSort(
        triggers: [InspirationTrigger],
        dismissedToday: Set<InspirationTrigger>,
        maxItems: Int = BusinessConstants.maxInspirationCarouselItems
    ) -> [InspirationTrigger] {
        let filtered = triggers.filter { !dismissedToday.contains($0) }
        let sorted = filtered.sorted { $0.priority > $1.priority }
        return Array(sorted.prefix(maxItems))
    }

    /// Calculate animation delay for a trigger
    public static func animationDelay(for trigger: InspirationTrigger) -> Int {
        switch trigger {
        case .perfectDay:
            return 1200  // Celebrate with dramatic pause
        case .firstHabitComplete, .halfwayPoint, .strongFinish:
            return 800   // Quick positive reinforcement
        case .sessionStart:
            return 2000  // Let user settle in first
        case .emptyDay:
            return 1500  // Standard timing
        default:
            return 1500
        }
    }

    // MARK: - Private Evaluation Methods

    /// Evaluates progress-based triggers (Category 1)
    /// Returns at most ONE trigger based on completion percentage
    /// Priority: perfectDay > strongFinish > halfwayPoint > firstHabitComplete
    private static func evaluateProgressTrigger(completionRate: Double, completedCount: Int) -> InspirationTrigger? {
        if completionRate >= 1.0 {
            return .perfectDay
        } else if completionRate >= 0.75 {
            return .strongFinish
        } else if completionRate >= 0.5 {
            return .halfwayPoint
        } else if completionRate > 0.0 && completedCount == 1 {
            return .firstHabitComplete
        }
        return nil
    }

    /// Evaluates time-of-day triggers (Category 2)
    /// Returns at most ONE trigger based on current time and progress
    private static func evaluateTimeTrigger(completionRate: Double, hour: Int, timeOfDay: TimeOfDay) -> InspirationTrigger? {
        switch timeOfDay {
        case .morning:
            if completionRate == 0.0 {
                return .morningMotivation
            }
        case .noon:
            if completionRate < 0.4 {
                return .strugglingMidDay
            }
            if hour >= 15 && hour < 17 && completionRate < 0.6 {
                return .afternoonPush
            }
        case .evening:
            if completionRate >= 0.6 {
                return .eveningReflection
            }
        }
        return nil
    }

    /// Evaluates special context triggers (Category 3)
    /// Returns at most ONE trigger based on situational context
    /// Priority: comebackStory > weekendMotivation
    private static func evaluateSpecialTrigger(isComebackStory: Bool, isWeekend: Bool) -> InspirationTrigger? {
        if isComebackStory {
            return .comebackStory
        }
        if isWeekend {
            return .weekendMotivation
        }
        return nil
    }
}
