import Foundation
import FactoryKit

// MARK: - Factory Container Extensions
// This file tests that FactoryKit import works correctly

extension Container {
    // Test factory to verify Factory package integration
    var testService: Factory<String> {
        self { "Factory package is working!" }
    }
}