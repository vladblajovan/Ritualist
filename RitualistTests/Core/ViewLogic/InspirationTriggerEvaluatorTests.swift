//
//  InspirationTriggerEvaluatorTests.swift
//  RitualistTests
//
//  Tests for InspirationTriggerEvaluator pure function logic.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("InspirationTriggerEvaluator - Trigger Evaluation")
@MainActor
struct InspirationTriggerEvaluatorTests {

    // MARK: - Edge Cases

    @Test("Returns sessionStart when user has no habits")
    func noHabitsReturnsSessionStart() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.0,
            completedCount: 0,
            totalHabits: 0,
            totalHabitsInApp: 0, // No habits at all
            hour: 10,
            timeOfDay: .morning,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers == [.sessionStart], "Should return sessionStart for brand new user")
    }

    @Test("Returns emptyDay when no habits scheduled today")
    func noScheduledHabitsReturnsEmptyDay() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.0,
            completedCount: 0,
            totalHabits: 0, // No habits scheduled today
            totalHabitsInApp: 5, // But user has habits
            hour: 10,
            timeOfDay: .morning,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers == [.emptyDay], "Should return emptyDay when no habits scheduled")
    }

    // MARK: - Progress Triggers

    @Test("Returns perfectDay at 100% completion")
    func perfectDayAt100Percent() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 1.0,
            completedCount: 5,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 14,
            timeOfDay: .noon,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.perfectDay), "Should include perfectDay at 100% completion")
    }

    @Test("Returns strongFinish at 75-99% completion")
    func strongFinishAt75Percent() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.8,
            completedCount: 4,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 14,
            timeOfDay: .noon,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.strongFinish), "Should include strongFinish at 80% completion")
    }

    @Test("Returns halfwayPoint at 50-74% completion")
    func halfwayPointAt50Percent() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.6,
            completedCount: 3,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 14,
            timeOfDay: .noon,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.halfwayPoint), "Should include halfwayPoint at 60% completion")
    }

    @Test("Returns firstHabitComplete when exactly 1 habit completed and below 50%")
    func firstHabitCompleteWithOneHabit() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.2,
            completedCount: 1, // Exactly 1 completed
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 10,
            timeOfDay: .morning,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.firstHabitComplete), "Should include firstHabitComplete when exactly 1 habit done")
    }

    // MARK: - Time-of-Day Triggers

    @Test("Returns morningMotivation in morning with 0% completion")
    func morningMotivationInMorning() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.0,
            completedCount: 0,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 8,
            timeOfDay: .morning,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.morningMotivation), "Should include morningMotivation in morning with 0%")
    }

    @Test("Returns strugglingMidDay at noon with low completion")
    func strugglingMidDayAtNoon() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.2,
            completedCount: 1,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 13,
            timeOfDay: .noon,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.strugglingMidDay), "Should include strugglingMidDay at noon with 20%")
    }

    @Test("Returns eveningReflection in evening with good completion")
    func eveningReflectionInEvening() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.7,
            completedCount: 3,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 20,
            timeOfDay: .evening,
            isWeekend: false,
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.eveningReflection), "Should include eveningReflection in evening with 70%")
    }

    // MARK: - Special Triggers

    @Test("Returns comebackStory when detected")
    func comebackStoryWhenDetected() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.6,
            completedCount: 3,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 14,
            timeOfDay: .noon,
            isWeekend: false,
            isComebackStory: true // Comeback detected
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.comebackStory), "Should include comebackStory when detected")
    }

    @Test("Returns weekendMotivation on weekend")
    func weekendMotivationOnWeekend() {
        let context = InspirationTriggerEvaluator.Context(
            completionRate: 0.4,
            completedCount: 2,
            totalHabits: 5,
            totalHabitsInApp: 5,
            hour: 14,
            timeOfDay: .noon,
            isWeekend: true, // It's a weekend
            isComebackStory: false
        )

        let triggers = InspirationTriggerEvaluator.evaluateTriggers(context: context)

        #expect(triggers.contains(.weekendMotivation), "Should include weekendMotivation on weekend")
    }

    // MARK: - Filter and Sort

    @Test("Filters out dismissed triggers")
    func filtersDismissedTriggers() {
        let triggers: [InspirationTrigger] = [.perfectDay, .eveningReflection, .weekendMotivation]
        let dismissed: Set<InspirationTrigger> = [.perfectDay, .weekendMotivation]

        let available = InspirationTriggerEvaluator.filterAndSort(
            triggers: triggers,
            dismissedToday: dismissed
        )

        #expect(available == [.eveningReflection], "Should filter out dismissed triggers")
    }

    @Test("Sorts by priority descending")
    func sortsByPriorityDescending() {
        let triggers: [InspirationTrigger] = [.morningMotivation, .perfectDay, .firstHabitComplete]

        let sorted = InspirationTriggerEvaluator.filterAndSort(
            triggers: triggers,
            dismissedToday: []
        )

        // perfectDay should be first (highest priority)
        #expect(sorted.first == .perfectDay, "Should sort by priority with perfectDay first")
    }

    @Test("Limits to max items")
    func limitsToMaxItems() {
        let triggers: [InspirationTrigger] = [.perfectDay, .eveningReflection, .weekendMotivation, .comebackStory]

        let limited = InspirationTriggerEvaluator.filterAndSort(
            triggers: triggers,
            dismissedToday: [],
            maxItems: 2
        )

        #expect(limited.count == 2, "Should limit to specified max items")
    }

    // MARK: - Animation Delays

    @Test("PerfectDay has celebration delay")
    func perfectDayHasCelebrationDelay() {
        let delay = InspirationTriggerEvaluator.animationDelay(for: .perfectDay)

        #expect(delay == 1200, "PerfectDay should have 1200ms celebration delay")
    }

    @Test("SessionStart has settling delay")
    func sessionStartHasSettlingDelay() {
        let delay = InspirationTriggerEvaluator.animationDelay(for: .sessionStart)

        #expect(delay == 2000, "SessionStart should have 2000ms settling delay")
    }

    @Test("Quick wins have shorter delay")
    func quickWinsHaveShorterDelay() {
        let firstHabitDelay = InspirationTriggerEvaluator.animationDelay(for: .firstHabitComplete)
        let halfwayDelay = InspirationTriggerEvaluator.animationDelay(for: .halfwayPoint)
        let strongFinishDelay = InspirationTriggerEvaluator.animationDelay(for: .strongFinish)

        #expect(firstHabitDelay == 800, "Quick wins should have 800ms delay")
        #expect(halfwayDelay == 800, "Quick wins should have 800ms delay")
        #expect(strongFinishDelay == 800, "Quick wins should have 800ms delay")
    }
}
