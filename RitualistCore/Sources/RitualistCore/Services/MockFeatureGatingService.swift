//
//  MockFeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation
import Observation

@available(*, deprecated, message: "Use FeatureGatingUIService with MockFeatureGatingBusinessService instead")
public final class MockFeatureGatingService: FeatureGatingService {
    private let errorHandler: ErrorHandler?
    
    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int { Int.max }
    
    public func canCreateMoreHabits(currentCount: Int) -> Bool { true }
    
    public var hasAdvancedAnalytics: Bool { true }
    
    public var hasCustomReminders: Bool { true }
    
    public var hasDataExport: Bool { true }

    public var hasICloudSync: Bool { true }

    public var hasPremiumThemes: Bool { true }
    
    public var hasPrioritySupport: Bool { true }
    
    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        "This feature is always available in mock mode."
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) -> Bool {
        true
    }
}
