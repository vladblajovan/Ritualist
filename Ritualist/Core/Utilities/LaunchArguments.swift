//
//  LaunchArguments.swift
//  Ritualist
//
//  Centralized launch arguments for testing and debugging.
//  Ensures consistency and prevents typos in string literals across the codebase.
//

import Foundation

/// Centralized launch arguments used for testing and debugging.
/// Usage: `if LaunchArgument.uiTesting.isActive { ... }`
enum LaunchArgument: String, CaseIterable {

    // MARK: - Testing

    /// Indicates the app is running under UI test automation
    case uiTesting = "--uitesting"

    /// Reduces animations for accessibility testing
    case reduceMotion = "--reduce-motion"

    // MARK: - Onboarding Overrides

    /// Forces the onboarding flow to display
    case forceOnboarding = "--force-onboarding"

    /// Forces the returning user migration flow
    case forceReturningUser = "--force-returning-user"

    /// Forces the returning user flow with completed onboarding
    case forceReturningUserComplete = "--force-returning-user-complete"

    /// Forces the returning user flow without a name set
    case forceReturningUserNoName = "--force-returning-user-no-name"

    // MARK: - Convenience

    /// Returns true if this launch argument is present in the command line
    var isActive: Bool {
        CommandLine.arguments.contains(rawValue)
    }
}
