//
//  AccessibilityUtilitiesTests.swift
//  RitualistTests
//
//  Tests for accessibility utilities in RitualistCore/Styling/Accessibility.swift
//  and RitualistCore/Styling/Animations.swift
//

import Foundation
import Testing
import SwiftUI
@testable import RitualistCore
@testable import Ritualist

/// Tests for accessibility helper functions and utilities
@Suite("Accessibility Utilities - Animation Constants")
struct AccessibilityAnimationTests {

    // MARK: - AnimationDuration Tests

    @Test("AnimationDuration constants have correct values")
    func animationDurationConstants() {
        #expect(AnimationDuration.fast == 0.2)
        #expect(AnimationDuration.medium == 0.3)
        #expect(AnimationDuration.slow == 0.5)
        #expect(AnimationDuration.verySlow == 1.0)
    }

    // MARK: - SpringAnimation Tests

    @Test("SpringAnimation constants have correct values")
    func springAnimationConstants() {
        #expect(SpringAnimation.fastResponse == 0.3)
        #expect(SpringAnimation.slowResponse == 0.5)
        #expect(SpringAnimation.standardDamping == 0.8)
        #expect(SpringAnimation.interactiveResponse == 0.4)
        #expect(SpringAnimation.interactiveDamping == 0.7)
    }

    // MARK: - ToastVisualHierarchy Tests

    @Test("ToastVisualHierarchy constants have correct values")
    func toastVisualHierarchyConstants() {
        #expect(ToastVisualHierarchy.scaleReductionPerIndex == 0.06)
        #expect(ToastVisualHierarchy.opacityReductionPerIndex == 0.10)
    }
}

/// Tests for accessibility configuration values
@Suite("Accessibility Utilities - Configuration")
struct AccessibilityConfigTests {

    @Test("AccessibilityConfig has Apple HIG compliant values")
    func accessibilityConfigValues() {
        // Apple HIG requires 44pt minimum touch targets
        #expect(AccessibilityConfig.minimumTouchTarget == 44)

        // WCAG 2.1 contrast ratios
        #expect(AccessibilityConfig.minimumContrastRatio == 4.5)
        #expect(AccessibilityConfig.minimumLargeTextContrastRatio == 3.0)
    }
}

/// Tests for scaled spacing and icon size utilities
@Suite("Accessibility Utilities - Scaled Metrics")
struct AccessibilityScaledMetricsTests {

    @Test("ScaledSpacing default values are correct")
    func scaledSpacingDefaults() {
        let spacing = ScaledSpacing()

        // These are the base values before scaling
        #expect(spacing.xxsmall == 4)
        #expect(spacing.xsmall == 6)
        #expect(spacing.small == 8)
        #expect(spacing.medium == 12)
        #expect(spacing.large == 16)
        #expect(spacing.xlarge == 24)
        #expect(spacing.xxlarge == 32)
    }

    @Test("ScaledIconSize default values are correct")
    func scaledIconSizeDefaults() {
        let iconSize = ScaledIconSize()

        // These are the base values before scaling
        #expect(iconSize.xsmall == 12)
        #expect(iconSize.small == 16)
        #expect(iconSize.medium == 20)
        #expect(iconSize.large == 24)
        #expect(iconSize.xlarge == 32)
        #expect(iconSize.xxlarge == 40)
    }
}

/// Tests for accessibility layout mode
@Suite("Accessibility Utilities - Layout Mode")
struct AccessibilityLayoutModeTests {

    @Test("AccessibilityLayoutMode has expected cases")
    func accessibilityLayoutModeCases() {
        // Verify the enum cases exist and are distinct
        let standard = AccessibilityLayoutMode.standard
        let accessible = AccessibilityLayoutMode.accessible

        #expect(standard != accessible)
    }
}

/// Tests for AccessibilityID - the primary accessibility identifier system
/// Note: AccessibilityIdentifiers in RitualistCore is deprecated in favor of AccessibilityID.
@Suite("AccessibilityID - Primary Identifier System")
struct AccessibilityIDTests {

    @Test("TabBar identifiers have expected string format")
    func tabBarIdentifiers() {
        #expect(AccessibilityID.TabBar.overview == "tab.overview")
        #expect(AccessibilityID.TabBar.habits == "tab.habits")
        #expect(AccessibilityID.TabBar.stats == "tab.stats")
        #expect(AccessibilityID.TabBar.settings == "tab.settings")
    }

    @Test("Overview identifiers have expected string format")
    func overviewIdentifiers() {
        #expect(AccessibilityID.Overview.root == "overview.root")
        #expect(AccessibilityID.Overview.habitsList == "overview.habitsList")
        #expect(AccessibilityID.Overview.previousDayButton == "overview.previousDay")
        #expect(AccessibilityID.Overview.nextDayButton == "overview.nextDay")
        #expect(AccessibilityID.Overview.todayButton == "overview.todayButton")
        #expect(AccessibilityID.Overview.streaksCard == "overview.streaksCard")
        #expect(AccessibilityID.Overview.summaryCard == "overview.summaryCard")
    }

    @Test("Habits identifiers have expected string format")
    func habitsIdentifiers() {
        #expect(AccessibilityID.Habits.root == "habits.root")
        #expect(AccessibilityID.Habits.habitsList == "habits.list")
        #expect(AccessibilityID.Habits.addButton == "habits.add")
        #expect(AccessibilityID.Habits.emptyState == "habits.emptyState")
    }

    @Test("Stats identifiers have expected string format")
    func statsIdentifiers() {
        #expect(AccessibilityID.Stats.root == "stats.root")
        #expect(AccessibilityID.Stats.dashboard == "stats.dashboard")
        #expect(AccessibilityID.Stats.streakCard == "stats.streakCard")
        #expect(AccessibilityID.Stats.completionCard == "stats.completionCard")
    }

    @Test("Dynamic identifiers generate unique IDs")
    func dynamicIdentifiersAreUnique() {
        let habitId1 = "habit-123"
        let habitId2 = "habit-456"

        // Overview habit identifiers should be unique per habit
        #expect(AccessibilityID.Overview.habitRow(habitId1) != AccessibilityID.Overview.habitRow(habitId2))
        #expect(AccessibilityID.Overview.habitCheckbox(habitId1) != AccessibilityID.Overview.habitCheckbox(habitId2))

        // Stats habit performance identifiers should be unique
        #expect(AccessibilityID.Stats.habitPerformanceRow(habitId1) != AccessibilityID.Stats.habitPerformanceRow(habitId2))

        // Identifiers should contain the habit ID
        #expect(AccessibilityID.Overview.habitRow(habitId1).contains(habitId1))
        #expect(AccessibilityID.Stats.habitPerformanceRow(habitId2).contains(habitId2))
    }

    @Test("Common identifiers have expected string format")
    func commonIdentifiers() {
        #expect(AccessibilityID.Common.loadingIndicator == "common.loading")
        #expect(AccessibilityID.Common.errorMessage == "common.error")
        #expect(AccessibilityID.Common.emptyState == "common.emptyState")
        #expect(AccessibilityID.Common.refreshControl == "common.refresh")
    }

    @Test("Navigation identifiers have expected string format")
    func navigationIdentifiers() {
        #expect(AccessibilityID.Navigation.backButton == "navigation.back")
        #expect(AccessibilityID.Navigation.closeButton == "navigation.close")
        #expect(AccessibilityID.Navigation.doneButton == "navigation.done")
        #expect(AccessibilityID.Navigation.cancelButton == "navigation.cancel")
    }

    @Test("Settings identifiers have expected string format")
    func settingsIdentifiers() {
        #expect(AccessibilityID.Settings.root == "settings.root")
        #expect(AccessibilityID.Settings.profileSection == "settings.profile")
        #expect(AccessibilityID.Settings.appearanceSection == "settings.appearance")
        #expect(AccessibilityID.Settings.notificationsSection == "settings.notifications")
    }
}
