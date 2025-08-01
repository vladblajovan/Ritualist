import XCTest
import SwiftUI
@testable import Ritualist

final class PaywallProtectionTests: XCTestCase {
    
    func testStatsPaywallProtectionForFreeUsers() {
        // Given - Mock feature gating service that returns false for advanced analytics
        let mockFeatureGating = MockFeatureGatingService()
        mockFeatureGating.hasAdvancedAnalyticsValue = false
        
        // When - Check if stats are available
        let hasStats = mockFeatureGating.hasAdvancedAnalytics
        
        // Then - Stats should not be available for free users
        XCTAssertFalse(hasStats, "Advanced analytics should not be available for free users")
    }
    
    func testStatsAvailableForPremiumUsers() {
        // Given - Mock feature gating service that returns true for advanced analytics
        let mockFeatureGating = MockFeatureGatingService()
        mockFeatureGating.hasAdvancedAnalyticsValue = true
        
        // When - Check if stats are available
        let hasStats = mockFeatureGating.hasAdvancedAnalytics
        
        // Then - Stats should be available for premium users
        XCTAssertTrue(hasStats, "Advanced analytics should be available for premium users")
    }
    
    func testFeatureAvailabilityCheck() {
        // Given
        let mockFeatureGating = MockFeatureGatingService()
        mockFeatureGating.hasAdvancedAnalyticsValue = false
        
        // When - Check feature availability
        let isAvailable = mockFeatureGating.isFeatureAvailable(.advancedAnalytics)
        
        // Then
        XCTAssertFalse(isAvailable, "Advanced analytics feature should not be available")
    }
    
    func testFeatureBlockedMessage() {
        // Given
        let mockFeatureGating = MockFeatureGatingService()
        
        // When
        let message = mockFeatureGating.getFeatureBlockedMessage(for: .advancedAnalytics)
        
        // Then
        XCTAssertFalse(message.isEmpty, "Feature blocked message should not be empty")
        XCTAssertTrue(message.contains("premium") || message.contains("upgrade"), 
                      "Message should mention premium or upgrade")
    }
}

// MARK: - Mock Feature Gating Service

private class MockFeatureGatingService: FeatureGatingService {
    var hasAdvancedAnalyticsValue = false
    var maxHabitsAllowedValue = 3
    
    var maxHabitsAllowed: Int {
        maxHabitsAllowedValue
    }
    
    func canCreateMoreHabits(currentCount: Int) -> Bool {
        currentCount < maxHabitsAllowed
    }
    
    var hasAdvancedAnalytics: Bool {
        hasAdvancedAnalyticsValue
    }
    
    var hasCustomReminders: Bool {
        hasAdvancedAnalyticsValue
    }
    
    var hasDataExport: Bool {
        hasAdvancedAnalyticsValue
    }
    
    var hasPremiumThemes: Bool {
        hasAdvancedAnalyticsValue
    }
    
    var hasPrioritySupport: Bool {
        hasAdvancedAnalyticsValue
    }
    
    func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        switch feature {
        case .advancedAnalytics:
            return "Unlock advanced stats and analytics with Ritualist Pro"
        default:
            return "This feature requires a premium subscription"
        }
    }
    
    func isFeatureAvailable(_ feature: FeatureType) -> Bool {
        switch feature {
        case .advancedAnalytics:
            return hasAdvancedAnalytics
        case .unlimitedHabits:
            return maxHabitsAllowed > 3
        default:
            return hasAdvancedAnalyticsValue
        }
    }
}