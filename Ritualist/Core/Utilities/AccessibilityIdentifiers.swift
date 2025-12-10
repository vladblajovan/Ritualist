//
//  AccessibilityIdentifiers.swift
//  Ritualist
//
//  Created by Claude on 27.11.2025.
//
//  Centralized accessibility identifiers for UI testing and VoiceOver support.
//  Used by both the app (for setting identifiers) and UI tests (for finding elements).
//
//  IMPORTANT: This file has a mirror copy in RitualistUITests/AccessibilityIdentifiers.swift
//  that must be kept in sync. The UI test target cannot import the app module directly,
//  so both copies are necessary. When adding or modifying identifiers:
//  1. Update this file first
//  2. Update the UI tests copy with the same changes
//  3. Run AccessibilityIdentifiersSyncTests to verify consistency
//

import Foundation

/// Centralized accessibility identifiers used throughout the app.
///
/// ## Usage in Views
/// ```swift
/// Button("Add") { }
///     .accessibilityIdentifier(AccessibilityID.Habits.addButton)
/// ```
///
/// ## Usage in UI Tests
/// ```swift
/// let addButton = app.buttons[AccessibilityID.Habits.addButton]
/// addButton.tap()
/// ```
///
/// ## Benefits
/// - Consistent identifiers across app and tests
/// - Better VoiceOver support
/// - Easier UI test maintenance
public enum AccessibilityID {

    // MARK: - Tab Bar

    public enum TabBar {
        public static let overview = "tab.overview"
        public static let habits = "tab.habits"
        public static let stats = "tab.stats"
        public static let settings = "tab.settings"
    }

    // MARK: - Navigation

    public enum Navigation {
        public static let backButton = "navigation.back"
        public static let closeButton = "navigation.close"
        public static let doneButton = "navigation.done"
        public static let cancelButton = "navigation.cancel"
    }

    // MARK: - Overview Tab

    public enum Overview {
        public static let root = "overview.root"
        public static let todaySection = "overview.today"
        public static let habitsList = "overview.habitsList"
        public static let personalityButton = "overview.personalityButton"
        public static let streaksCard = "overview.streaksCard"
        public static let summaryCard = "overview.summaryCard"
        public static let todaysSummaryCard = "overview.todaysSummaryCard"
        public static let calendarCard = "overview.calendarCard"
        public static let insightsCard = "overview.insightsCard"
        public static let previousDayButton = "overview.previousDay"
        public static let nextDayButton = "overview.nextDay"
        public static let todayButton = "overview.todayButton"
        public static func habitRow(_ id: String) -> String { "overview.habit.\(id)" }
        public static func habitCheckbox(_ id: String) -> String { "overview.habit.checkbox.\(id)" }
    }

    // MARK: - Habits Tab

    public enum Habits {
        public static let root = "habits.root"
        public static let habitsList = "habits.list"
        public static let addButton = "habits.add"
        public static let assistantButton = "habits.assistant"
        public static let emptyState = "habits.emptyState"
    }

    // MARK: - Habit Detail

    public enum HabitDetail {
        public static let sheet = "habitDetail.sheet"
        public static let nameField = "habitDetail.name"
        public static let saveButton = "habitDetail.save"
        public static let cancelButton = "habitDetail.cancel"
        public static let deleteButton = "habitDetail.delete"
        public static let startDateSection = "habitDetail.startDate.section"
        public static let startDatePicker = "habitDetail.startDate.picker"
    }

    // MARK: - Habits Assistant

    public enum HabitsAssistant {
        public static let sheet = "habitsAssistant.sheet"
        public static let closeButton = "habitsAssistant.close"
        public static let inputField = "habitsAssistant.input"
        public static let sendButton = "habitsAssistant.send"
    }

    // MARK: - Stats Tab (Dashboard)

    public enum Stats {
        public static let root = "stats.root"
        public static let dashboard = "stats.dashboard"
        public static let streakCard = "stats.streakCard"
        public static let completionCard = "stats.completionCard"
        public static let weeklyProgressCard = "stats.weeklyProgress"
        public static let performanceCard = "stats.performance"
        public static let habitPerformanceList = "stats.habitPerformanceList"
        public static func habitPerformanceRow(_ id: String) -> String { "stats.habitPerformance.\(id)" }
        public static let circularProgress = "stats.circularProgress"
        public static let statCard = "stats.statCard"
        public static func statCardNamed(_ title: String) -> String { "stats.statCard.\(title.lowercased().replacingOccurrences(of: " ", with: "_"))" }
    }

    // MARK: - Settings Tab

    public enum Settings {
        public static let root = "settings.root"
        public static let profileSection = "settings.profile"
        public static let appearanceSection = "settings.appearance"
        public static let notificationsSection = "settings.notifications"
        public static let debugMenuButton = "settings.debugMenu"
        public static let aboutSection = "settings.about"
    }

    // MARK: - Debug Menu

    public enum DebugMenu {
        public static let sheet = "debugMenu.sheet"
        public static let clearBadgeButton = "debugMenu.clearBadge"
        public static let resetOnboardingButton = "debugMenu.resetOnboarding"
        public static let testDataButton = "debugMenu.testData"
        public static let fpsToggle = "debugMenu.fpsToggle"
    }

    // MARK: - Personality Analysis

    public enum PersonalityAnalysis {
        public static let sheet = "personalityAnalysis.sheet"
        public static let closeButton = "personalityAnalysis.close"
        public static let resultCard = "personalityAnalysis.result"
        public static let requirementsCard = "personalityAnalysis.requirements"
    }

    // MARK: - Onboarding

    public enum Onboarding {
        public static let welcomeScreen = "onboarding.welcome"
        public static let nextButton = "onboarding.next"
        public static let skipButton = "onboarding.skip"
        public static let completeButton = "onboarding.complete"
    }

    // MARK: - Common Components

    public enum Common {
        public static let loadingIndicator = "common.loading"
        public static let errorMessage = "common.error"
        public static let emptyState = "common.emptyState"
        public static let refreshControl = "common.refresh"
    }

    // MARK: - Sheets

    public enum Sheet {
        public static let dismissHandle = "sheet.dismissHandle"
    }

    // MARK: - Toasts

    public enum Toast {
        public static let iCloudSync = "toast.iCloudSync"
        public static let success = "toast.success"
        public static let error = "toast.error"
        public static let dismissButton = "toast.dismiss"
    }

    // MARK: - Inspiration Carousel

    public enum InspirationCarousel {
        public static let carousel = "inspiration.carousel"
        public static let dismissAllButton = "inspiration.dismissAll"
        public static let pageIndicators = "inspiration.pageIndicators"
        public static func card(_ index: Int) -> String { "inspiration.card.\(index)" }
        public static let cardDismissButton = "inspiration.card.dismiss"
    }
}
