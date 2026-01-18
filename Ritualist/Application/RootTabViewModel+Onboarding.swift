//
//  RootTabViewModel+Onboarding.swift
//  Ritualist
//
//  Onboarding flow logic for RootTabViewModel
//

import Foundation
import RitualistCore
import CloudKit

// MARK: - Onboarding Flow

extension RootTabViewModel {

    func performOnboardingCheck() async {
        // IMPORTANT: Capture categorySeedingCompleted flag BEFORE any async operations
        // This avoids race condition where seedCategories() runs in parallel and sets this flag
        let hasRunAppBeforeCapture = userDefaults.bool(forKey: UserDefaultsKeys.categorySeedingCompleted)

        // Synchronize iCloud KV store with short timeout (0.3s)
        // This is enough for cached data; longer waits hurt new user experience
        let syncCompleted = await iCloudKeyValueService.synchronizeAndWait(timeout: 0.3)
        if !syncCompleted {
            logger.log(
                "iCloud KV sync timed out - may affect returning user detection",
                level: .warning,
                category: .ui,
                metadata: ["timeoutSeconds": 0.3]
            )
        }

        // Step 1: Check LOCAL device flag (UserDefaults - not synced)
        // This tells us if THIS device has completed onboarding
        let localDeviceCompleted = iCloudKeyValueService.hasCompletedOnboardingLocally()

        if localDeviceCompleted {
            // This device already went through onboarding - skip everything
            showOnboarding = false
            isCheckingOnboarding = false
            logger.log(
                "Onboarding already completed on this device - skipping",
                level: .info,
                category: .ui
            )
            return
        }

        // Step 2: Check iCloud availability (returns nil on error, to trigger new user flow)
        guard let isICloudAvailable = await checkICloudAvailability() else {
            showOnboarding = true
            isCheckingOnboarding = false
            return
        }
        guard isICloudAvailable else {
            logger.log("No iCloud account available - showing onboarding for new user", level: .info, category: .ui)
            showOnboarding = true
            isCheckingOnboarding = false
            return
        }

        // iCloud flag tells us if user completed onboarding on ANY device
        let iCloudOnboardingCompleted = iCloudKeyValueService.hasCompletedOnboarding()

        // iCloud sync is free for all users, so if the iCloud flag is set,
        // the user is returning and their data will sync automatically
        if iCloudOnboardingCompleted {
            logger.log("Returning user detected - iCloud flag set, data will sync", level: .info, category: .ui)
            showOnboarding = false
            isCheckingOnboarding = false
            pendingReturningUserWelcome = true
            return
        }

        // Step 3: Neither flag set - could be new user OR upgrade from old version
        await handlePotentialMigration(hasRunAppBeforeCapture: hasRunAppBeforeCapture)
    }

    private func handlePotentialMigration(hasRunAppBeforeCapture: Bool) async {
        // Before showing onboarding, check if user has existing data OR has run the app before
        let existingProfile: UserProfile?
        do {
            existingProfile = try await loadProfile.execute()
        } catch {
            // Log but don't block - treat as no existing data for migration purposes
            // This could indicate database issues that warrant investigation
            logger.log(
                "Failed to load profile during upgrade migration check - treating as no data",
                level: .warning,
                category: .ui,
                metadata: ["error": error.localizedDescription]
            )
            existingProfile = nil
        }
        let hasExistingData = !(existingProfile?.name.isEmpty ?? true)

        // Use captured value from start of function to avoid race with category seeding
        if hasExistingData || hasRunAppBeforeCapture {
            // MIGRATION: User has existing data OR has run app before, but flags were never set
            // This happens when upgrading from a version that didn't set these flags (e.g., 0.2.1 → 0.3.0)
            // Set both flags to mark onboarding as complete for this device and iCloud
            logger.log(
                "Migration: existing user detected but no onboarding flags - setting flags",
                level: .info,
                category: .ui,
                metadata: [
                    "hasExistingData": hasExistingData,
                    "hasRunAppBefore": hasRunAppBeforeCapture,
                    "profileName": existingProfile?.name ?? "none"
                ]
            )

            iCloudKeyValueService.setOnboardingCompletedLocally()
            iCloudKeyValueService.setOnboardingCompleted()

            showOnboarding = false
            isCheckingOnboarding = false
            return
        }

        // No existing data - this is truly a new user
        logger.log(
            "No iCloud onboarding flag and no local flag - new user flow",
            level: .info,
            category: .ui
        )
        showOnboarding = true
        isCheckingOnboarding = false
    }

    /// Check if iCloud account is available.
    /// Returns `nil` on error (caller should show new user flow), `true`/`false` for availability.
    func checkICloudAvailability() async -> Bool? {
        // Skip real CloudKit check in unit tests (XCTest environment)
        if NSClassFromString("XCTestCase") != nil {
            return true
        }

        let container = CKContainer(identifier: iCloudConstants.containerIdentifier)
        do {
            let accountStatus = try await container.accountStatus()
            return accountStatus == .available
        } catch {
            logger.log(
                "Failed to check iCloud account status - defaulting to new user flow",
                level: .warning,
                category: .ui,
                metadata: ["error": error.localizedDescription]
            )
            return nil
        }
    }
}

// MARK: - Returning User Welcome

extension RootTabViewModel {

    /// Called from RootTabView when iCloud data has finished loading
    /// Shows the returning user welcome with actual synced data
    func handleReturningUserWelcome(habits: [Habit], profile: UserProfile?) {
        guard pendingReturningUserWelcome else { return }

        // Build summary from actual loaded data
        let summary = SyncedDataSummary(
            habitsCount: habits.count,
            categoriesCount: 0, // Not needed for welcome screen
            hasProfile: profile != nil,
            profileName: profile?.name,
            profileAvatar: profile?.avatarImageData,
            profileGender: profile?.gender,
            profileAgeGroup: profile?.ageGroup
        )

        // Show welcome once profile and demographics are synced
        // We don't require habits - user may have skipped adding them during onboarding
        // The welcome screen shows a generic "data synced" message instead of habit count
        guard summary.hasProfile && !summary.needsProfileCompletion else {
            logger.log(
                "Pending returning user welcome but profile/demographics not synced yet",
                level: .debug,
                category: .ui,
                metadata: [
                    "habitsCount": summary.habitsCount,
                    "hasProfile": summary.hasProfile,
                    "profileName": summary.profileName ?? "nil",
                    "hasGender": summary.profileGender != nil,
                    "hasAgeGroup": summary.profileAgeGroup != nil
                ]
            )
            return
        }

        // Note: Syncing toast is dismissed when ReturningUserOnboardingView appears
        // (via onAppear in RootTabView) to ensure seamless transition

        pendingReturningUserWelcome = false
        returningUserWelcomeTask?.cancel()
        returningUserWelcomeTask = nil
        syncedDataSummary = summary
        showReturningUserWelcome = true

        logger.log(
            "Showing returning user welcome with synced data",
            level: .info,
            category: .ui,
            metadata: [
                "habitsCount": summary.habitsCount,
                "hasProfile": summary.hasProfile,
                "profileName": summary.profileName ?? "nil",
                "hasGender": summary.profileGender != nil,
                "hasAgeGroup": summary.profileAgeGroup != nil
            ]
        )
    }
}
