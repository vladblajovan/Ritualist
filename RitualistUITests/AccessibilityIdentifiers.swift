//
//  AccessibilityIdentifiers.swift
//  RitualistUITests
//
//  Created by Claude on 27.11.2025.
//
//  Centralized accessibility identifiers for UI testing and VoiceOver support.
//  These identifiers should match those set in the app's SwiftUI views.
//
//  IMPORTANT: This file is a mirror copy of Ritualist/Core/Utilities/AccessibilityIdentifiers.swift
//  The UI test target cannot import the app module directly, so both copies are necessary.
//  When adding or modifying identifiers:
//  1. Update the app's copy first (Ritualist/Core/Utilities/AccessibilityIdentifiers.swift)
//  2. Update this file with the same changes
//  3. Run AccessibilityIdentifiersSyncTests to verify consistency
//
//  The Labels enum below is UI-test specific and not present in the app version.
//

import Foundation

/// Centralized accessibility identifiers used throughout the app
/// Usage in views: .accessibilityIdentifier(AccessibilityID.TabBar.overview)
/// Usage in tests: app.buttons[AccessibilityID.TabBar.overview]
enum AccessibilityID {

    // MARK: - Tab Bar

    enum TabBar {
        static let overview = "tab.overview"
        static let habits = "tab.habits"
        static let stats = "tab.stats"
        static let settings = "tab.settings"
    }

    // MARK: - Navigation

    enum Navigation {
        static let backButton = "navigation.back"
        static let closeButton = "navigation.close"
        static let doneButton = "navigation.done"
        static let cancelButton = "navigation.cancel"
    }

    // MARK: - UI Labels (for tests matching by label, not identifier)
    // These are used when matching system buttons or text content
    enum Labels {
        static let welcome = "Welcome"
        static let cancel = "Cancel"
        static let close = "Close"
        static let save = "Save"
        static let done = "Done"
        static let add = "Add"
        static let addHabit = "Add Habit"
        static let debugMenu = "Debug Menu"
    }

    // MARK: - Overview Tab

    enum Overview {
        static let root = "overview.root"
        static let todaySection = "overview.today"
        static let habitsList = "overview.habitsList"
        static let personalityButton = "overview.personalityButton"
    }

    // MARK: - Habits Tab

    enum Habits {
        static let root = "habits.root"
        static let habitsList = "habits.list"
        static let addButton = "habits.add"
        static let assistantButton = "habits.assistant"
        static let emptyState = "habits.emptyState"
    }

    // MARK: - Habit Detail

    enum HabitDetail {
        static let sheet = "habitDetail.sheet"
        static let nameField = "habitDetail.name"
        static let saveButton = "habitDetail.save"
        static let cancelButton = "habitDetail.cancel"
        static let deleteButton = "habitDetail.delete"
        static let startDateSection = "habitDetail.startDate.section"
        static let startDatePicker = "habitDetail.startDate.picker"
    }

    // MARK: - Habits Assistant

    enum HabitsAssistant {
        static let sheet = "habitsAssistant.sheet"
        static let closeButton = "habitsAssistant.close"
        static let inputField = "habitsAssistant.input"
        static let sendButton = "habitsAssistant.send"
    }

    // MARK: - Stats Tab

    enum Stats {
        static let root = "stats.root"
        static let dashboard = "stats.dashboard"
        static let streakCard = "stats.streakCard"
        static let completionCard = "stats.completionCard"
    }

    // MARK: - Settings Tab

    enum Settings {
        static let root = "settings.root"
        static let profileSection = "settings.profile"
        static let appearanceSection = "settings.appearance"
        static let notificationsSection = "settings.notifications"
        static let debugMenuButton = "settings.debugMenu"
        static let aboutSection = "settings.about"
    }

    // MARK: - Debug Menu

    enum DebugMenu {
        static let sheet = "debugMenu.sheet"
        static let clearBadgeButton = "debugMenu.clearBadge"
        static let resetOnboardingButton = "debugMenu.resetOnboarding"
        static let testDataButton = "debugMenu.testData"
        static let fpsToggle = "debugMenu.fpsToggle"
    }

    // MARK: - Personality Analysis

    enum PersonalityAnalysis {
        static let sheet = "personalityAnalysis.sheet"
        static let closeButton = "personalityAnalysis.close"
        static let resultCard = "personalityAnalysis.result"
        static let requirementsCard = "personalityAnalysis.requirements"
    }

    // MARK: - Onboarding

    enum Onboarding {
        static let welcomeScreen = "onboarding.welcome"
        static let nextButton = "onboarding.next"
        static let skipButton = "onboarding.skip"
        static let completeButton = "onboarding.complete"
    }

    // MARK: - Common Components

    enum Common {
        static let loadingIndicator = "common.loading"
        static let errorMessage = "common.error"
        static let emptyState = "common.emptyState"
        static let refreshControl = "common.refresh"
    }

    // MARK: - Sheets

    enum Sheet {
        static let dismissHandle = "sheet.dismissHandle"
    }

    // MARK: - Toasts

    enum Toast {
        static let iCloudSync = "toast.iCloudSync"
        static let success = "toast.success"
        static let error = "toast.error"
    }
}
