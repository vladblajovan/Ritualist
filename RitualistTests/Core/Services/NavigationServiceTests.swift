//
//  NavigationServiceTests.swift
//  RitualistTests
//
//  Created by Vlad Blajovan on 27.11.2025.
//

import Testing
import Foundation
@testable import Ritualist
@testable import RitualistCore

// MARK: - Pages Enum Tests

@Suite("Pages - Enum Verification")
struct PagesTests {

    @Test("Pages enum has overview case")
    func hasOverviewCase() {
        let page: Pages = .overview
        #expect(page == .overview)
    }

    @Test("Pages enum has habits case")
    func hasHabitsCase() {
        let page: Pages = .habits
        #expect(page == .habits)
    }

    @Test("Pages enum has stats case")
    func hasStatsCase() {
        let page: Pages = .stats
        #expect(page == .stats)
    }

    @Test("Pages enum has settings case")
    func hasSettingsCase() {
        let page: Pages = .settings
        #expect(page == .settings)
    }

    @Test("Pages enum is Hashable")
    func isHashable() {
        var pageSet: Set<Pages> = []
        pageSet.insert(.overview)
        pageSet.insert(.habits)
        pageSet.insert(.stats)
        pageSet.insert(.settings)
        #expect(pageSet.count == 4)
    }
}

// MARK: - NavigationService Tests

@Suite("NavigationService - Core Functionality")
@MainActor
struct NavigationServiceTests {

    // MARK: - Initial State Tests

    @Test("Initial selected tab is overview")
    func initialSelectedTabIsOverview() {
        let service = NavigationService()
        #expect(service.selectedTab == .overview)
    }

    @Test("Initial shouldRefreshOverview is false")
    func initialShouldRefreshOverviewIsFalse() {
        let service = NavigationService()
        #expect(service.shouldRefreshOverview == false)
    }

    // MARK: - Navigation Tests

    @Test("navigateToOverview sets selectedTab to overview")
    func navigateToOverviewSetsTab() {
        let service = NavigationService()
        service.selectedTab = .settings // Start from different tab
        service.navigateToOverview()
        #expect(service.selectedTab == .overview)
    }

    @Test("navigateToOverview with refresh sets shouldRefreshOverview")
    func navigateToOverviewWithRefresh() {
        let service = NavigationService()
        service.selectedTab = .settings
        service.navigateToOverview(shouldRefresh: true)
        #expect(service.selectedTab == .overview)
        #expect(service.shouldRefreshOverview == true)
    }

    @Test("navigateToHabits sets selectedTab to habits")
    func navigateToHabitsSetsTab() {
        let service = NavigationService()
        service.navigateToHabits()
        #expect(service.selectedTab == .habits)
    }

    @Test("navigateToStats sets selectedTab to stats")
    func navigateToStatsSetsTab() {
        let service = NavigationService()
        service.navigateToStats()
        #expect(service.selectedTab == .stats)
    }

    @Test("navigateToSettings sets selectedTab to settings")
    func navigateToSettingsSetsTab() {
        let service = NavigationService()
        service.navigateToSettings()
        #expect(service.selectedTab == .settings)
    }

    // MARK: - Refresh State Tests

    @Test("didRefreshOverview clears shouldRefreshOverview")
    func didRefreshOverviewClearsFlag() {
        let service = NavigationService()
        service.shouldRefreshOverview = true
        service.didRefreshOverview()
        #expect(service.shouldRefreshOverview == false)
    }

    // MARK: - Sequential Navigation Tests

    @Test("Can navigate through all tabs sequentially")
    func sequentialNavigationThroughAllTabs() {
        let service = NavigationService()

        service.navigateToOverview()
        #expect(service.selectedTab == .overview)

        service.navigateToHabits()
        #expect(service.selectedTab == .habits)

        service.navigateToStats()
        #expect(service.selectedTab == .stats)

        service.navigateToSettings()
        #expect(service.selectedTab == .settings)

        // Navigate back to overview
        service.navigateToOverview()
        #expect(service.selectedTab == .overview)
    }
}
