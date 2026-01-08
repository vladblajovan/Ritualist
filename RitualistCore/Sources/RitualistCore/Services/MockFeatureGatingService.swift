//
//  MockFeatureGatingService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation
import Observation

public final class MockFeatureGatingService: FeatureGatingService, Sendable {
    private let errorHandler: ErrorHandler?

    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler
    }

    public func maxHabitsAllowed() async -> Int { Int.max }

    public func canCreateMoreHabits(currentCount: Int) async -> Bool { true }

    public func hasAdvancedAnalytics() async -> Bool { true }

    public func hasCustomReminders() async -> Bool { true }

    public func hasDataExport() async -> Bool { true }

    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        "This feature is always available in mock mode."
    }

    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        true
    }

    public func isOverActiveHabitLimit(activeCount: Int) async -> Bool {
        false // Mock always allows all habits
    }
}
