//
//  MockFeatureGatingBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

public final class MockFeatureGatingBusinessService: FeatureGatingBusinessService {
    private let errorHandler: ErrorHandler?
    
    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int {
        get async { Int.max }
    }
    
    public func canCreateMoreHabits(currentCount: Int) async -> Bool { true }
    
    public var hasAdvancedAnalytics: Bool {
        get async { true }
    }
    
    public var hasCustomReminders: Bool {
        get async { true }
    }
    
    public var hasDataExport: Bool {
        get async { true }
    }

    public var hasICloudSync: Bool {
        get async { true }
    }

    public var hasPremiumThemes: Bool {
        get async { true }
    }
    
    public var hasPrioritySupport: Bool {
        get async { true }
    }
    
    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        "This feature is always available in mock mode."
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        true
    }
}
