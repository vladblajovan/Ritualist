//
//  QuickActionCoordinatorTests.swift
//  RitualistTests
//
//  Created by Claude on 27.11.2025.
//

import Testing
import Foundation
import UIKit
@testable import RitualistCore

// MARK: - QuickActionType Tests

@Suite("QuickActionType - Enum Properties")
struct QuickActionTypeTests {

    @Test("addHabit raw value is correct")
    func addHabitRawValue() {
        #expect(QuickActionType.addHabit.rawValue == "com.ritualist.quickaction.addHabit")
    }

    @Test("habitsAssistant raw value is correct")
    func habitsAssistantRawValue() {
        #expect(QuickActionType.habitsAssistant.rawValue == "com.ritualist.quickaction.habitsAssistant")
    }

    @Test("stats raw value is correct")
    func statsRawValue() {
        #expect(QuickActionType.stats.rawValue == "com.ritualist.quickaction.stats")
    }

    @Test("addHabit icon name is plus.circle.fill")
    func addHabitIconName() {
        #expect(QuickActionType.addHabit.iconName == "plus.circle.fill")
    }

    @Test("habitsAssistant icon name is sparkles")
    func habitsAssistantIconName() {
        #expect(QuickActionType.habitsAssistant.iconName == "sparkles")
    }

    @Test("stats icon name is chart.bar.fill")
    func statsIconName() {
        #expect(QuickActionType.stats.iconName == "chart.bar.fill")
    }

    @Test("All action types have non-empty titles")
    func allActionTypesHaveNonEmptyTitles() {
        #expect(!QuickActionType.addHabit.title.isEmpty)
        #expect(!QuickActionType.habitsAssistant.title.isEmpty)
        #expect(!QuickActionType.stats.title.isEmpty)
    }
}

// MARK: - QuickActionCoordinator Tests

@Suite("QuickActionCoordinator - Core Functionality")
@MainActor
struct QuickActionCoordinatorTests {

    // MARK: - handleShortcutItem Tests

    @Test("handleShortcutItem returns true for addHabit action")
    func handleShortcutItemReturnsTrueForAddHabit() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.pendingAction = nil

        let shortcutItem = UIApplicationShortcutItem(
            type: QuickActionType.addHabit.rawValue,
            localizedTitle: "Add Habit"
        )

        let result = coordinator.handleShortcutItem(shortcutItem)

        #expect(result == true)
        #expect(coordinator.pendingAction == .addHabit)

        // Cleanup
        coordinator.pendingAction = nil
    }

    @Test("handleShortcutItem returns true for habitsAssistant action")
    func handleShortcutItemReturnsTrueForHabitsAssistant() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.pendingAction = nil

        let shortcutItem = UIApplicationShortcutItem(
            type: QuickActionType.habitsAssistant.rawValue,
            localizedTitle: "Habits Assistant"
        )

        let result = coordinator.handleShortcutItem(shortcutItem)

        #expect(result == true)
        #expect(coordinator.pendingAction == .habitsAssistant)

        // Cleanup
        coordinator.pendingAction = nil
    }

    @Test("handleShortcutItem returns true for stats action")
    func handleShortcutItemReturnsTrueForStats() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.pendingAction = nil

        let shortcutItem = UIApplicationShortcutItem(
            type: QuickActionType.stats.rawValue,
            localizedTitle: "Stats"
        )

        let result = coordinator.handleShortcutItem(shortcutItem)

        #expect(result == true)
        #expect(coordinator.pendingAction == .stats)

        // Cleanup
        coordinator.pendingAction = nil
    }

    @Test("handleShortcutItem returns false for unknown action type")
    func handleShortcutItemReturnsFalseForUnknownAction() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.pendingAction = nil

        let shortcutItem = UIApplicationShortcutItem(
            type: "com.ritualist.quickaction.unknown",
            localizedTitle: "Unknown"
        )

        let result = coordinator.handleShortcutItem(shortcutItem)

        #expect(result == false)
        #expect(coordinator.pendingAction == nil)
    }

    // MARK: - processPendingAction Tests

    @Test("processPendingAction sets shouldShowAddHabit for addHabit action")
    func processPendingActionSetsAddHabitFlag() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.resetTriggers()
        coordinator.pendingAction = .addHabit

        coordinator.processPendingAction()

        #expect(coordinator.shouldShowAddHabit == true)
        #expect(coordinator.shouldShowHabitsAssistant == false)
        #expect(coordinator.shouldNavigateToStats == false)
        #expect(coordinator.pendingAction == nil)

        // Cleanup
        coordinator.resetTriggers()
    }

    @Test("processPendingAction sets shouldShowHabitsAssistant for habitsAssistant action")
    func processPendingActionSetsHabitsAssistantFlag() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.resetTriggers()
        coordinator.pendingAction = .habitsAssistant

        coordinator.processPendingAction()

        #expect(coordinator.shouldShowAddHabit == false)
        #expect(coordinator.shouldShowHabitsAssistant == true)
        #expect(coordinator.shouldNavigateToStats == false)
        #expect(coordinator.pendingAction == nil)

        // Cleanup
        coordinator.resetTriggers()
    }

    @Test("processPendingAction sets shouldNavigateToStats for stats action")
    func processPendingActionSetsStatsFlag() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.resetTriggers()
        coordinator.pendingAction = .stats

        coordinator.processPendingAction()

        #expect(coordinator.shouldShowAddHabit == false)
        #expect(coordinator.shouldShowHabitsAssistant == false)
        #expect(coordinator.shouldNavigateToStats == true)
        #expect(coordinator.pendingAction == nil)

        // Cleanup
        coordinator.resetTriggers()
    }

    @Test("processPendingAction does nothing when no pending action")
    func processPendingActionDoesNothingWhenNoPendingAction() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.resetTriggers()
        coordinator.pendingAction = nil

        coordinator.processPendingAction()

        #expect(coordinator.shouldShowAddHabit == false)
        #expect(coordinator.shouldShowHabitsAssistant == false)
        #expect(coordinator.shouldNavigateToStats == false)
    }

    // MARK: - resetTriggers Tests

    @Test("resetTriggers clears all flags")
    func resetTriggersClearsAllFlags() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.shouldShowAddHabit = true
        coordinator.shouldShowHabitsAssistant = true
        coordinator.shouldNavigateToStats = true

        coordinator.resetTriggers()

        #expect(coordinator.shouldShowAddHabit == false)
        #expect(coordinator.shouldShowHabitsAssistant == false)
        #expect(coordinator.shouldNavigateToStats == false)
    }

    // MARK: - Integration Tests

    @Test("Full flow: handle shortcut then process pending action")
    func fullFlowHandleAndProcess() {
        let coordinator = QuickActionCoordinator.shared
        coordinator.resetTriggers()
        coordinator.pendingAction = nil

        // Simulate shortcut item received
        let shortcutItem = UIApplicationShortcutItem(
            type: QuickActionType.addHabit.rawValue,
            localizedTitle: "Add Habit"
        )

        // Handle the shortcut
        let handled = coordinator.handleShortcutItem(shortcutItem)
        #expect(handled == true)
        #expect(coordinator.pendingAction == .addHabit)

        // Process the pending action (simulates what happens in RootTabView.onAppear)
        coordinator.processPendingAction()
        #expect(coordinator.pendingAction == nil)
        #expect(coordinator.shouldShowAddHabit == true)

        // Reset (simulates what happens after sheet is shown)
        coordinator.resetTriggers()
        #expect(coordinator.shouldShowAddHabit == false)
    }
}
