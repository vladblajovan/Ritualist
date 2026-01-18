//
//  TodaysSummaryCard+Animations.swift
//  Ritualist
//
//  Animation methods extracted from TodaysSummaryCard to reduce type body length.
//

import SwiftUI
import RitualistCore
import TipKit

// MARK: - Animation Methods

extension TodaysSummaryCard {

    func performCompletionAnimation(for habit: Habit) {
        // Start completion animation
        animatingHabitId = habit.id
        isAnimatingCompletion = true
        animatingProgress = 0.0

        // Animate progress circle from 0 to 100%
        withAnimation(.easeInOut(duration: 0.6)) {
            animatingProgress = 1.0
        }

        // Cancel any existing completion animation task
        completionAnimationTask?.cancel()

        // After animation completes, fade and trigger actual completion
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        completionAnimationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: AnimationTiming.completionAnimationDelay)

            // Start fade out
            withAnimation(.easeOut(duration: 0.4)) {
                // Fade effect handled by opacity in view
            }

            // Complete the habit
            onQuickAction(habit)

            // Trigger tip for completed habits (so second tip can appear)
            TapCompletedHabitTip.firstHabitCompleted.sendDonation()
            logger.log("Habit completed - donated firstHabitCompleted event", level: .debug, category: .ui)

            // Clean up animation state
            try? await Task.sleep(nanoseconds: AnimationTiming.animationCleanupDelay)
            resetAnimationState()
        }
    }

    func performRemovalAnimation(for habit: Habit) {
        // Start removal animation (reverse of completion)
        animatingHabitId = habit.id
        isAnimatingCompletion = false // Different animation type
        animatingProgress = 1.0

        // Animate progress circle from 100% to 0% (reverse)
        withAnimation(.easeInOut(duration: 0.6)) {
            animatingProgress = 0.0
        }

        // Cancel any existing completion animation task
        completionAnimationTask?.cancel()

        // After animation completes, fade and trigger actual removal
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        completionAnimationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: AnimationTiming.completionAnimationDelay)

            // Start fade out
            withAnimation(.easeOut(duration: 0.4)) {
                // Fade effect handled by opacity in view
            }

            // Remove the habit log
            onDeleteHabitLog(habit)

            // Clean up animation state
            try? await Task.sleep(nanoseconds: AnimationTiming.animationCleanupDelay)
            resetAnimationState()
        }
    }

    func resetAnimationState() {
        animatingHabitId = nil
        animatingProgress = 0.0
        isAnimatingCompletion = false
    }
}
