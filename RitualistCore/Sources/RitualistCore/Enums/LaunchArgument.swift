//
//  LaunchArgument.swift
//  RitualistCore
//
//  Centralized launch arguments for testing and debugging.
//  Shared between the app and UI tests to ensure consistency.
//

import Foundation

/// Centralized launch arguments used for testing and debugging.
///
/// **App usage:** `if LaunchArgument.uiTesting.isActive { ... }`
/// **UI test usage:** `app.launchArguments = [LaunchArgument.uiTesting.rawValue]`
public enum LaunchArgument: String, CaseIterable {

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

    /// Returns true if this launch argument is present in the command line.
    /// Use this in the app to check if a specific argument was passed.
    public var isActive: Bool {
        CommandLine.arguments.contains(rawValue)
    }
}
