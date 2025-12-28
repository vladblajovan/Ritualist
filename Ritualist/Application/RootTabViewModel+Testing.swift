//
//  RootTabViewModel+Testing.swift
//  Ritualist
//
//  Debug/testing helpers for onboarding flow control
//

import Foundation
import RitualistCore

#if DEBUG
extension RootTabViewModel {
    /// Handles UI testing launch arguments for onboarding flow control.
    /// Returns true if a testing argument was handled (caller should return early).
    func handleTestingLaunchArguments() -> Bool {
        // Skip onboarding entirely during UI tests
        if LaunchArgument.uiTesting.isActive {
            showOnboarding = false
            isCheckingOnboarding = false
            logger.log("UI testing mode - skipping onboarding", level: .info, category: .ui)
            return true
        }

        // Force onboarding for onboarding UI tests
        if LaunchArgument.forceOnboarding.isActive {
            showOnboarding = true
            isCheckingOnboarding = false
            logger.log("Force onboarding mode - showing onboarding", level: .info, category: .ui)
            return true
        }

        // Force returning user flow for UI tests (with incomplete profile)
        if LaunchArgument.forceReturningUser.isActive {
            configureReturningUserTest(
                profileName: "Test User",
                profileGender: nil,
                profileAgeGroup: nil,
                logMessage: "Force returning user mode - incomplete profile"
            )
            return true
        }

        // Force returning user flow with complete profile (skips profile completion)
        if LaunchArgument.forceReturningUserComplete.isActive {
            configureReturningUserTest(
                profileName: "Test User",
                profileGender: "male",
                profileAgeGroup: "25_34",
                logMessage: "Force returning user mode - complete profile"
            )
            return true
        }

        // Force returning user flow with no name (shows name input)
        if LaunchArgument.forceReturningUserNoName.isActive {
            configureReturningUserTest(
                profileName: nil,
                profileGender: nil,
                profileAgeGroup: nil,
                logMessage: "Force returning user mode - no name"
            )
            return true
        }

        return false
    }

    /// Configures state for returning user UI tests.
    func configureReturningUserTest(
        profileName: String?,
        profileGender: String?,
        profileAgeGroup: String?,
        logMessage: String
    ) {
        showOnboarding = false
        isCheckingOnboarding = false
        syncedDataSummary = SyncedDataSummary(
            habitsCount: 5,
            categoriesCount: 2,
            hasProfile: true,
            profileName: profileName,
            profileAvatar: nil,
            profileGender: profileGender,
            profileAgeGroup: profileAgeGroup
        )
        showReturningUserWelcome = true
        logger.log(logMessage, level: .info, category: .ui)
    }
}
#endif
