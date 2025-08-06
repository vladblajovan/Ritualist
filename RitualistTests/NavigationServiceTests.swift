import XCTest
@testable import Ritualist

// MARK: - Navigation Service Tests

@MainActor
class NavigationServiceTests: XCTestCase {
    
    var navigationService: NavigationService!
    
    override func setUp() async throws {
        try await super.setUp()
        navigationService = NavigationService()
    }
    
    override func tearDown() async throws {
        navigationService = nil
        try await super.tearDown()
    }
    
    // MARK: - Basic Navigation Tests
    
    func testInitialState() {
        XCTAssertEqual(navigationService.selectedTab, .overview)
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
    
    func testNavigateToOverview() {
        navigationService.selectedTab = .habits
        
        navigationService.navigateToOverview()
        
        XCTAssertEqual(navigationService.selectedTab, .overview)
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
    
    func testNavigateToOverviewWithRefresh() {
        navigationService.selectedTab = .habits
        
        navigationService.navigateToOverview(shouldRefresh: true)
        
        XCTAssertEqual(navigationService.selectedTab, .overview)
        XCTAssertTrue(navigationService.shouldRefreshOverview)
    }
    
    func testNavigateToHabits() {
        navigationService.navigateToHabits()
        
        XCTAssertEqual(navigationService.selectedTab, .habits)
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
    
    func testNavigateToSettings() {
        navigationService.navigateToSettings()
        
        XCTAssertEqual(navigationService.selectedTab, .settings)
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
    
    func testDidRefreshOverview() {
        navigationService.navigateToOverview(shouldRefresh: true)
        XCTAssertTrue(navigationService.shouldRefreshOverview)
        
        navigationService.didRefreshOverview()
        
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
    
    // MARK: - Notification Integration Tests
    
    func testNavigationFromNotificationLogAction() {
        // Simulate being on a different tab
        navigationService.selectedTab = .settings
        
        // Simulate notification log action navigation
        navigationService.navigateToOverview(shouldRefresh: true)
        
        XCTAssertEqual(navigationService.selectedTab, .overview)
        XCTAssertTrue(navigationService.shouldRefreshOverview)
    }
    
    func testMultipleRefreshRequests() {
        // First refresh request
        navigationService.navigateToOverview(shouldRefresh: true)
        XCTAssertTrue(navigationService.shouldRefreshOverview)
        
        // Second refresh request (should still be true)
        navigationService.navigateToOverview(shouldRefresh: true)
        XCTAssertTrue(navigationService.shouldRefreshOverview)
        
        // Reset after handling
        navigationService.didRefreshOverview()
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
    
    func testRefreshFlagPersistsUntilReset() {
        navigationService.navigateToOverview(shouldRefresh: true)
        XCTAssertTrue(navigationService.shouldRefreshOverview)
        
        // Other navigation actions shouldn't affect refresh flag
        navigationService.navigateToHabits()
        XCTAssertTrue(navigationService.shouldRefreshOverview)
        
        navigationService.navigateToSettings()
        XCTAssertTrue(navigationService.shouldRefreshOverview)
        
        // Only explicit reset should clear it
        navigationService.didRefreshOverview()
        XCTAssertFalse(navigationService.shouldRefreshOverview)
    }
}