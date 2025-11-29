//
//  LaunchArguments.swift
//  RitualistUITests
//
//  Mirror copy of Ritualist/Core/Utilities/LaunchArguments.swift
//  The UI test target cannot import the app module directly.
//
//  IMPORTANT: Keep in sync with the app's LaunchArguments.swift.
//  When adding or modifying arguments:
//  1. Update the app's copy first (Ritualist/Core/Utilities/LaunchArguments.swift)
//  2. Update this file with the same changes
//

import Foundation

/// Centralized launch arguments used for testing and debugging.
/// Usage: `app.launchArguments = [LaunchArgument.uiTesting.rawValue]`
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
}
