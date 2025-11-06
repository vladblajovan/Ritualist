import Testing
import SwiftUI
@testable import RitualistCore

/// Tests for InspirationStyleViewLogic - demonstrates testable style computation pattern
@Suite("InspirationStyleViewLogic Tests")
struct InspirationStyleViewLogicTests {

    // MARK: - Perfect Day Tests (100% Completion)

    @Test("Perfect day style for 100% completion - morning")
    func perfectDayMorning() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 1.0,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .perfect)
        #expect(style.iconName == "party.popper.fill")
        #expect(style.accentColor == .green)
    }

    @Test("Perfect day style for 100% completion - noon")
    func perfectDayNoon() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 1.0,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .perfect)
        #expect(style.iconName == "party.popper.fill")
        #expect(style.accentColor == .green, "Time doesn't matter for perfect day - always uses perfect gradient")
    }

    @Test("Perfect day style for 100% completion - evening")
    func perfectDayEvening() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 1.0,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .perfect)
        #expect(style.iconName == "party.popper.fill")
        #expect(style.accentColor == .green)
    }

    // MARK: - Strong Progress Tests (75-99% Completion)

    @Test("Strong progress style for 75% completion")
    func strongProgress75() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.75,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .strong)
        #expect(style.iconName == "flame.fill")
        #expect(style.accentColor == .blue)
    }

    @Test("Strong progress style for 85% completion")
    func strongProgress85() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.85,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .strong)
        #expect(style.iconName == "flame.fill")
        #expect(style.accentColor == .blue)
    }

    @Test("Strong progress style for 99% completion")
    func strongProgress99() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.99,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .strong)
        #expect(style.iconName == "flame.fill")
        #expect(style.accentColor == .blue, "Just below 100% should still use strong progress")
    }

    // MARK: - Midway Progress Tests (50-74% Completion)

    @Test("Midway progress style for 50% completion")
    func midwayProgress50() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.5,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .midway)
        #expect(style.iconName == "bolt.fill")
        #expect(style.accentColor == .orange)
    }

    @Test("Midway progress style for 60% completion")
    func midwayProgress60() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.6,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .midway)
        #expect(style.iconName == "bolt.fill")
        #expect(style.accentColor == .orange)
    }

    @Test("Midway progress style for 74% completion")
    func midwayProgress74() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.74,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .midway)
        #expect(style.iconName == "bolt.fill")
        #expect(style.accentColor == .orange, "Just below 75% should use midway style")
    }

    // MARK: - Time-Based Tests (< 50% Completion)

    @Test("Morning style for low completion (0%)")
    func morningStyleZeroCompletion() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.0,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .morning)
        #expect(style.iconName == "sunrise.fill")
        #expect(style.accentColor == .pink)
    }

    @Test("Morning style for low completion (25%)")
    func morningStyle25() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.25,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .morning)
        #expect(style.iconName == "sunrise.fill")
        #expect(style.accentColor == .pink)
    }

    @Test("Morning style for almost midway (49%)")
    func morningStyle49() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.49,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .morning)
        #expect(style.iconName == "sunrise.fill")
        #expect(style.accentColor == .pink, "Just below 50% should still use time-based style")
    }

    @Test("Noon style for low completion (0%)")
    func noonStyleZeroCompletion() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.0,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .noon)
        #expect(style.iconName == "sun.max.fill")
        #expect(style.accentColor == .indigo)
    }

    @Test("Noon style for low completion (30%)")
    func noonStyle30() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.3,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .noon)
        #expect(style.iconName == "sun.max.fill")
        #expect(style.accentColor == .indigo)
    }

    @Test("Evening style for low completion (0%)")
    func eveningStyleZeroCompletion() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.0,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .evening)
        #expect(style.iconName == "moon.stars.fill")
        #expect(style.accentColor == .purple)
    }

    @Test("Evening style for low completion (40%)")
    func eveningStyle40() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.4,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .evening)
        #expect(style.iconName == "moon.stars.fill")
        #expect(style.accentColor == .purple)
    }

    // MARK: - Priority Tests (Completion Takes Precedence Over Time)

    @Test("High completion overrides morning time")
    func highCompletionOverridesMorning() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.9,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        // Should use strong progress, NOT morning style
        #expect(style.gradientType == .strong)
        #expect(style.iconName == "flame.fill")
        #expect(style.accentColor == .blue, "Completion percentage takes priority over time")
    }

    @Test("Midway completion overrides evening time")
    func midwayCompletionOverridesEvening() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.65,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        // Should use midway, NOT evening style
        #expect(style.gradientType == .midway)
        #expect(style.iconName == "bolt.fill")
        #expect(style.accentColor == .orange, "Midway completion overrides time of day")
    }

    // MARK: - Boundary Tests

    @Test("Exact 50% boundary triggers midway style")
    func exact50Boundary() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.5,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .midway, "Exactly 50% should trigger midway style")
    }

    @Test("Exact 75% boundary triggers strong progress style")
    func exact75Boundary() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 0.75,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .strong, "Exactly 75% should trigger strong progress")
    }

    @Test("Exact 100% boundary triggers perfect day style")
    func exact100Boundary() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 1.0,
            timeOfDay: .evening
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .perfect, "Exactly 100% should trigger perfect day")
    }

    // MARK: - Edge Cases

    @Test("Negative completion percentage defaults to time-based")
    func negativeCompletionPercentage() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: -0.1,
            timeOfDay: .morning
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .morning, "Negative completion should use time-based style")
    }

    @Test("Over 100% completion still uses perfect day style")
    func over100Completion() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: 1.5,
            timeOfDay: .noon
        )

        let style = InspirationStyleViewLogic.computeStyle(for: context)

        #expect(style.gradientType == .perfect, "Over 100% should still use perfect day style")
    }
}
