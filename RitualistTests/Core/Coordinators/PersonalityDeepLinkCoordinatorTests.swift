//
//  PersonalityDeepLinkCoordinatorTests.swift
//  RitualistTests
//
//  Created by Claude on 27.11.2025.
//

import Testing
import Foundation
@testable import RitualistCore

// MARK: - PersonalityNotificationAction Tests

@Suite("PersonalityNotificationAction - Enum Cases")
struct PersonalityNotificationActionTests {

    @Test("Can create openAnalysis action with trait and confidence")
    func openAnalysisWithTraitAndConfidence() {
        let action = PersonalityDeepLinkCoordinator.PersonalityNotificationAction.openAnalysis(
            dominantTrait: .conscientiousness,
            confidence: .high
        )

        if case .openAnalysis(let trait, let confidence) = action {
            #expect(trait == .conscientiousness)
            #expect(confidence == .high)
        } else {
            Issue.record("Expected openAnalysis action")
        }
    }

    @Test("Can create openAnalysis action with nil values")
    func openAnalysisWithNilValues() {
        let action = PersonalityDeepLinkCoordinator.PersonalityNotificationAction.openAnalysis(
            dominantTrait: nil,
            confidence: nil
        )

        if case .openAnalysis(let trait, let confidence) = action {
            #expect(trait == nil)
            #expect(confidence == nil)
        } else {
            Issue.record("Expected openAnalysis action")
        }
    }

    @Test("Can create openRequirements action")
    func openRequirementsAction() {
        let action = PersonalityDeepLinkCoordinator.PersonalityNotificationAction.openRequirements

        if case .openRequirements = action {
            // Success
        } else {
            Issue.record("Expected openRequirements action")
        }
    }

    @Test("Can create checkAnalysis action")
    func checkAnalysisAction() {
        let action = PersonalityDeepLinkCoordinator.PersonalityNotificationAction.checkAnalysis

        if case .checkAnalysis = action {
            // Success
        } else {
            Issue.record("Expected checkAnalysis action")
        }
    }

    @Test("Can create directNavigation action")
    func directNavigationAction() {
        let action = PersonalityDeepLinkCoordinator.PersonalityNotificationAction.directNavigation

        if case .directNavigation = action {
            // Success
        } else {
            Issue.record("Expected directNavigation action")
        }
    }
}

// MARK: - PersonalityDeepLinkCoordinator Tests

@Suite("PersonalityDeepLinkCoordinator - Core Functionality")
@MainActor
struct PersonalityDeepLinkCoordinatorTests {

    /// Creates a fresh coordinator instance for each test (complete isolation)
    private func makeCoordinator() -> PersonalityDeepLinkCoordinator {
        PersonalityDeepLinkCoordinator()
    }

    // MARK: - Initial State Tests

    @Test("New coordinator has shouldShowPersonalityAnalysis set to false")
    func initialShouldShowPersonalityAnalysisIsFalse() {
        let coordinator = makeCoordinator()
        #expect(coordinator.shouldShowPersonalityAnalysis == false)
    }

    @Test("New coordinator has pendingNotificationAction set to nil")
    func initialPendingNotificationActionIsNil() {
        let coordinator = makeCoordinator()
        #expect(coordinator.pendingNotificationAction == nil)
    }

    @Test("New coordinator has shouldSwitchTab set to true")
    func initialShouldSwitchTabIsTrue() {
        let coordinator = makeCoordinator()
        #expect(coordinator.shouldSwitchTab == true)
    }

    // MARK: - navigateToPersonalityAnalysis Tests

    @Test("navigateToPersonalityAnalysis sets shouldShowPersonalityAnalysis to true")
    func navigateToPersonalityAnalysisSetsShowFlag() {
        let coordinator = makeCoordinator()

        coordinator.navigateToPersonalityAnalysis()

        #expect(coordinator.shouldShowPersonalityAnalysis == true)
    }

    @Test("navigateToPersonalityAnalysis sets shouldSwitchTab to true")
    func navigateToPersonalityAnalysisSetsSwitchTab() {
        let coordinator = makeCoordinator()

        coordinator.navigateToPersonalityAnalysis()

        #expect(coordinator.shouldSwitchTab == true)
    }

    @Test("navigateToPersonalityAnalysis sets pendingNotificationAction to openAnalysis")
    func navigateToPersonalityAnalysisSetsAction() {
        let coordinator = makeCoordinator()

        coordinator.navigateToPersonalityAnalysis()

        if case .openAnalysis(let trait, let confidence) = coordinator.pendingNotificationAction {
            #expect(trait == nil)
            #expect(confidence == nil)
        } else {
            Issue.record("Expected openAnalysis action")
        }
    }

    // MARK: - showPersonalityAnalysisDirectly Tests

    @Test("showPersonalityAnalysisDirectly sets shouldShowPersonalityAnalysis to true")
    func showDirectlySetsShowFlag() {
        let coordinator = makeCoordinator()

        coordinator.showPersonalityAnalysisDirectly()

        #expect(coordinator.shouldShowPersonalityAnalysis == true)
    }

    @Test("showPersonalityAnalysisDirectly sets shouldSwitchTab to false")
    func showDirectlySetsSwitchTabFalse() {
        let coordinator = makeCoordinator()

        coordinator.showPersonalityAnalysisDirectly()

        #expect(coordinator.shouldSwitchTab == false)
    }

    @Test("showPersonalityAnalysisDirectly sets pendingNotificationAction to directNavigation")
    func showDirectlySetsDirectNavigationAction() {
        let coordinator = makeCoordinator()

        coordinator.showPersonalityAnalysisDirectly()

        if case .directNavigation = coordinator.pendingNotificationAction {
            // Success
        } else {
            Issue.record("Expected directNavigation action")
        }
    }

    // MARK: - clearPendingNavigation Tests

    @Test("clearPendingNavigation resets all state")
    func clearPendingNavigationResetsAllState() {
        let coordinator = makeCoordinator()

        // Set some state
        coordinator.navigateToPersonalityAnalysis()
        #expect(coordinator.shouldShowPersonalityAnalysis == true)
        #expect(coordinator.pendingNotificationAction != nil)

        // Clear
        coordinator.clearPendingNavigation()

        #expect(coordinator.shouldShowPersonalityAnalysis == false)
        #expect(coordinator.pendingNotificationAction == nil)
        #expect(coordinator.shouldSwitchTab == true)
    }

    // MARK: - resetAnalysisState Tests

    @Test("resetAnalysisState only resets shouldShowPersonalityAnalysis")
    func resetAnalysisStateOnlyResetsShowFlag() {
        let coordinator = makeCoordinator()

        // Set state via direct navigation (shouldSwitchTab = false)
        coordinator.showPersonalityAnalysisDirectly()
        #expect(coordinator.shouldShowPersonalityAnalysis == true)
        #expect(coordinator.shouldSwitchTab == false)

        // Reset analysis state
        coordinator.resetAnalysisState()

        // Only shouldShowPersonalityAnalysis should be reset
        #expect(coordinator.shouldShowPersonalityAnalysis == false)
        // pendingNotificationAction should still be set
        #expect(coordinator.pendingNotificationAction != nil)
    }

    // MARK: - processPendingNavigation Tests

    @Test("processPendingNavigation returns true when shouldShowPersonalityAnalysis is true")
    func processPendingNavigationReturnsTrueWhenSet() {
        let coordinator = makeCoordinator()
        coordinator.navigateToPersonalityAnalysis()

        let result = coordinator.processPendingNavigation()

        #expect(result == true)
    }

    @Test("processPendingNavigation returns false when shouldShowPersonalityAnalysis is false")
    func processPendingNavigationReturnsFalseWhenNotSet() {
        let coordinator = makeCoordinator()

        let result = coordinator.processPendingNavigation()

        #expect(result == false)
    }

    // MARK: - Integration Tests

    @Test("Full navigation flow: navigate then reset")
    func fullNavigationFlow() {
        let coordinator = makeCoordinator()

        // User triggers navigation
        coordinator.navigateToPersonalityAnalysis()
        #expect(coordinator.shouldShowPersonalityAnalysis == true)
        #expect(coordinator.shouldSwitchTab == true)

        // Check pending navigation
        #expect(coordinator.processPendingNavigation() == true)

        // UI processes and resets
        coordinator.resetAnalysisState()
        #expect(coordinator.shouldShowPersonalityAnalysis == false)
        #expect(coordinator.processPendingNavigation() == false)
    }

    @Test("Direct vs Navigate: shouldSwitchTab differs")
    func directVsNavigateSwitchTabDifference() {
        // Navigate (from notification) - should switch tab
        let navigateCoordinator = makeCoordinator()
        navigateCoordinator.navigateToPersonalityAnalysis()
        #expect(navigateCoordinator.shouldSwitchTab == true)

        // Direct (from settings button) - should NOT switch tab
        let directCoordinator = makeCoordinator()
        directCoordinator.showPersonalityAnalysisDirectly()
        #expect(directCoordinator.shouldSwitchTab == false)
    }

    @Test("Multiple navigations in sequence work correctly")
    func multipleNavigationsInSequence() {
        let coordinator = makeCoordinator()

        // First navigation
        coordinator.navigateToPersonalityAnalysis()
        #expect(coordinator.shouldShowPersonalityAnalysis == true)

        // Clear and navigate again
        coordinator.clearPendingNavigation()
        #expect(coordinator.shouldShowPersonalityAnalysis == false)

        // Second navigation
        coordinator.showPersonalityAnalysisDirectly()
        #expect(coordinator.shouldShowPersonalityAnalysis == true)
        #expect(coordinator.shouldSwitchTab == false)
    }
}
