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

/// Tests for accessibility identifiers consistency
@Suite("Accessibility Identifiers - Consistency")
struct AccessibilityIdentifiersTests {

    @Test("Overview identifiers have expected string format")
    func overviewIdentifiers() {
        // Verify identifiers follow consistent naming convention
        #expect(AccessibilityIdentifiers.Overview.screen == "overview_screen")
        #expect(AccessibilityIdentifiers.Overview.dateSelector == "overview_date_selector")
        #expect(AccessibilityIdentifiers.Overview.previousDayButton == "overview_previous_day")
        #expect(AccessibilityIdentifiers.Overview.nextDayButton == "overview_next_day")
        #expect(AccessibilityIdentifiers.Overview.todayButton == "overview_today_button")
        #expect(AccessibilityIdentifiers.Overview.habitList == "overview_habit_list")
        #expect(AccessibilityIdentifiers.Overview.addHabitButton == "overview_add_habit")
        #expect(AccessibilityIdentifiers.Overview.emptyState == "overview_empty_state")
    }

    @Test("Dashboard identifiers have expected string format")
    func dashboardIdentifiers() {
        #expect(AccessibilityIdentifiers.Dashboard.screen == "dashboard_screen")
        #expect(AccessibilityIdentifiers.Dashboard.scrollView == "dashboard_scroll_view")
        #expect(AccessibilityIdentifiers.Dashboard.streaksCard == "dashboard_streaks_card")
        #expect(AccessibilityIdentifiers.Dashboard.statsCard == "dashboard_stats_card")
        #expect(AccessibilityIdentifiers.Dashboard.calendarCard == "dashboard_calendar_card")
        #expect(AccessibilityIdentifiers.Dashboard.insightsCard == "dashboard_insights_card")
    }

    @Test("HabitCard identifiers generate unique IDs per habit")
    func habitCardIdentifiersAreUnique() {
        let habitId1 = "habit-123"
        let habitId2 = "habit-456"

        // Card identifiers should be unique per habit
        #expect(AccessibilityIdentifiers.HabitCard.card(habitId: habitId1) != AccessibilityIdentifiers.HabitCard.card(habitId: habitId2))
        #expect(AccessibilityIdentifiers.HabitCard.checkbox(habitId: habitId1) != AccessibilityIdentifiers.HabitCard.checkbox(habitId: habitId2))
        #expect(AccessibilityIdentifiers.HabitCard.title(habitId: habitId1) != AccessibilityIdentifiers.HabitCard.title(habitId: habitId2))
        #expect(AccessibilityIdentifiers.HabitCard.progress(habitId: habitId1) != AccessibilityIdentifiers.HabitCard.progress(habitId: habitId2))

        // Identifiers should contain the habit ID
        #expect(AccessibilityIdentifiers.HabitCard.card(habitId: habitId1).contains(habitId1))
        #expect(AccessibilityIdentifiers.HabitCard.card(habitId: habitId2).contains(habitId2))
    }

    @Test("Navigation identifiers have expected string format")
    func navigationIdentifiers() {
        #expect(AccessibilityIdentifiers.Navigation.tabBar == "main_tab_bar")
        #expect(AccessibilityIdentifiers.Navigation.overviewTab == "overview_tab")
        #expect(AccessibilityIdentifiers.Navigation.dashboardTab == "dashboard_tab")
        #expect(AccessibilityIdentifiers.Navigation.settingsTab == "settings_tab")
    }

    @Test("Common identifiers have expected string format")
    func commonIdentifiers() {
        #expect(AccessibilityIdentifiers.Common.loadingIndicator == "loading_indicator")
        #expect(AccessibilityIdentifiers.Common.errorView == "error_view")
        #expect(AccessibilityIdentifiers.Common.retryButton == "retry_button")
        #expect(AccessibilityIdentifiers.Common.closeButton == "close_button")
        #expect(AccessibilityIdentifiers.Common.saveButton == "save_button")
        #expect(AccessibilityIdentifiers.Common.cancelButton == "cancel_button")
        #expect(AccessibilityIdentifiers.Common.deleteButton == "delete_button")
    }

    @Test("Settings identifiers have expected string format")
    func settingsIdentifiers() {
        #expect(AccessibilityIdentifiers.Settings.screen == "settings_screen")
        #expect(AccessibilityIdentifiers.Settings.notificationsSection == "settings_notifications")
        #expect(AccessibilityIdentifiers.Settings.appearanceSection == "settings_appearance")
        #expect(AccessibilityIdentifiers.Settings.dataSection == "settings_data")
        #expect(AccessibilityIdentifiers.Settings.aboutSection == "settings_about")
    }
}
