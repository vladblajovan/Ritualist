//
//  RootTabView+Helpers.swift
//  Ritualist
//
//  Helper methods extracted from RootTabView to reduce type body length.
//

import SwiftUI
import FactoryKit
import RitualistCore

// MARK: - Onboarding & Data Loading Helpers

extension RootTabView {

    /// Checks onboarding status and updates state accordingly.
    /// Ensures launch screen shows for minimum time to avoid jarring flash.
    func checkOnboardingStatus() async {
        let startTime = Date()

        await viewModel.checkOnboardingStatus()

        // Ensure launch screen shows for minimum time to avoid jarring flash
        // Skip delay during UI tests for faster test execution
        if !LaunchArgument.uiTesting.isActive {
            let elapsed = Date().timeIntervalSince(startTime)
            let minimumDisplayTime: TimeInterval = 0.25
            if elapsed < minimumDisplayTime {
                try? await Task.sleep(for: .seconds(minimumDisplayTime - elapsed))
            }
        }

        showOnboarding = viewModel.showOnboarding
        isCheckingOnboarding = viewModel.isCheckingOnboarding
    }

    /// Handle post-onboarding flow - open assistant if user can add more habits.
    /// Called from fullScreenCover's onDismiss, so onboarding is already dismissed.
    /// Note: This is only called for new user onboarding, not returning user welcome.
    func handlePostOnboarding() async {
        await loadCurrentHabits()

        // NOTE: Don't call handleFirstiCloudSync() here - the assistant sheet will open next
        // and the toast would appear behind it. Instead, we trigger the toast when the
        // assistant sheet dismisses (see onDisappear handler).

        let currentHabitCount = existingHabits.count
        let canAddMoreHabits = await checkHabitCreationLimit.execute(currentCount: currentHabitCount)

        // Only open assistant if user hasn't reached the limit
        // For premium users or users with < 5 habits
        if canAddMoreHabits {
            showingPostOnboardingAssistant = true
        }
        // If at limit (5+ habits for free users), don't open assistant
        // User will land on Overview tab naturally
    }

    /// Load current habits to check count.
    func loadCurrentHabits() async {
        do {
            let habitsData = try await loadHabitsData.execute()
            existingHabits = habitsData.habits
        } catch {
            Container.shared.debugLogger().log("Failed to load habits for post-onboarding check: \(error)", level: .error, category: .ui)
            existingHabits = []
        }
    }
}

// MARK: - Returning User Welcome Helpers

extension RootTabView {

    /// Handle returning user welcome - show when iCloud data has loaded.
    /// Uses retry logic to wait for both habits AND profile to sync from CloudKit.
    /// Stores task in viewModel for cancellation when view disappears.
    func handleReturningUserWelcome(retryCount: Int = 0) {
        guard viewModel.pendingReturningUserWelcome else { return }

        // Cancel any existing retry task before starting a new one
        viewModel.returningUserWelcomeTask?.cancel()

        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        viewModel.returningUserWelcomeTask = Task { @MainActor in
            guard !Task.isCancelled else { return }
            await loadCurrentHabits()
            guard !Task.isCancelled else { return }
            let profile = await loadProfileSafely()
            guard !Task.isCancelled else { return }

            // Check if we have complete data (profile with gender/ageGroup set)
            let hasCompleteData = profile != nil && profile?.gender != nil && profile?.ageGroup != nil

            if hasCompleteData {
                viewModel.showReturningUserWelcomeIfNeeded(habits: existingHabits, profile: profile)
            } else {
                await handleIncompleteReturningUserData(profile: profile, retryCount: retryCount)
            }
        }
    }

    /// Safely loads user profile, returning nil on error.
    func loadProfileSafely() async -> UserProfile? {
        do {
            return try await loadProfile.execute()
        } catch {
            logger.log(
                "Failed to load profile for returning user check",
                level: .warning,
                category: .system,
                metadata: ["error": error.localizedDescription]
            )
            return nil
        }
    }

    /// Handles incomplete returning user data with retry logic.
    /// Checks Task.isCancelled to support early termination when view disappears.
    func handleIncompleteReturningUserData(profile: UserProfile?, retryCount: Int) async {
        // Check cancellation before retry
        guard !Task.isCancelled else { return }

        // Retry up to ~2.5 minutes - CloudKit profile/avatar may take longer on slow networks
        if retryCount < SyncConstants.maxRetries {
            logger.log(
                "☁️ Returning user data incomplete - will retry",
                level: .debug,
                category: .system,
                metadata: [
                    "retry_count": retryCount + 1,
                    "max_retries": SyncConstants.maxRetries,
                    "has_profile": profile != nil,
                    "has_gender": profile?.gender != nil,
                    "has_ageGroup": profile?.ageGroup != nil
                ]
            )
            try? await Task.sleep(for: .seconds(SyncConstants.retryIntervalSeconds))

            // Check cancellation after sleep (view may have disappeared during wait)
            guard !Task.isCancelled else { return }

            // Continue retry loop within same task (iterative, not recursive)
            await loadCurrentHabits()
            guard !Task.isCancelled else { return }
            let newProfile = await loadProfileSafely()
            guard !Task.isCancelled else { return }

            let hasCompleteData = newProfile != nil && newProfile?.gender != nil && newProfile?.ageGroup != nil
            if hasCompleteData {
                viewModel.showReturningUserWelcomeIfNeeded(habits: existingHabits, profile: newProfile)
            } else {
                await handleIncompleteReturningUserData(profile: newProfile, retryCount: retryCount + 1)
            }
        } else {
            logger.log(
                "☁️ Returning user data still incomplete after retries - showing info toast",
                level: .warning,
                category: .system,
                metadata: ["has_profile": profile != nil, "has_gender": profile?.gender != nil, "has_ageGroup": profile?.ageGroup != nil]
            )
            viewModel.dismissSyncingDataToast()
            viewModel.pendingReturningUserWelcome = false
            viewModel.returningUserWelcomeTask = nil  // Clean up task reference
            viewModel.showStillSyncingToast()
        }
    }
}

// MARK: - iCloud Sync Helpers

extension RootTabView {

    /// Handle first iCloud sync - show toast only once per device lifetime.
    /// Uses retry logic because data may not be available immediately when notification fires.
    func handleFirstiCloudSync(retryCount: Int = 0) {
        guard !userDefaults.bool(forKey: UserDefaultsKeys.hasShownFirstSyncToast) else { return }
        guard !showOnboarding && !isCheckingOnboarding && !showingPostOnboardingAssistant else {
            logModalActiveForSync()
            return
        }

        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await performFirstiCloudSyncCheck(retryCount: retryCount)
        }
    }

    /// Logs when a modal is active during sync detection.
    func logModalActiveForSync() {
        logger.log(
            "☁️ iCloud sync detected but modal active - deferring toast",
            level: .debug,
            category: .system,
            metadata: [
                "showOnboarding": showOnboarding,
                "isCheckingOnboarding": isCheckingOnboarding,
                "showingAssistant": showingPostOnboardingAssistant
            ]
        )
    }

    /// Performs the actual iCloud sync check with retry logic.
    func performFirstiCloudSyncCheck(retryCount: Int) async {
        guard !userDefaults.bool(forKey: UserDefaultsKeys.hasShownFirstSyncToast) else { return }

        guard await PersistenceContainer.isICloudAvailable() else {
            logger.log("☁️ iCloud not available - skipping sync toast", level: .debug, category: .system)
            return
        }

        await loadCurrentHabits()

        guard !existingHabits.isEmpty else {
            await retryFirstiCloudSyncIfNeeded(retryCount: retryCount)
            return
        }

        userDefaults.set(true, forKey: UserDefaultsKeys.hasShownFirstSyncToast)
        logger.log(
            "☁️ First iCloud sync with data - showing welcome toast",
            level: .info,
            category: .system,
            metadata: ["habits_count": existingHabits.count]
        )
        await MainActor.run {
            viewModel.showSyncedToast()
        }
    }

    /// Retries iCloud sync check if no habits found yet.
    func retryFirstiCloudSyncIfNeeded(retryCount: Int) async {
        if retryCount < 3 {
            logger.log(
                "☁️ iCloud sync detected but no habits found yet - will retry",
                level: .debug,
                category: .system,
                metadata: ["retry_count": retryCount + 1]
            )
            try? await Task.sleep(for: .seconds(Double(retryCount + 1)))
            handleFirstiCloudSync(retryCount: retryCount + 1)
        } else {
            logger.log("☁️ iCloud sync detected but no habits found after retries - skipping toast", level: .debug, category: .system)
        }
    }
}

// MARK: - Toast View Builder

extension RootTabView {

    /// Creates a toast view for the given toast item.
    @ViewBuilder
    func toastView(for toast: RootTabViewModel.ToastDisplayItem) -> some View {
        ToastView(
            message: toast.message,
            icon: toast.icon,
            style: toast.style,
            isPersistent: toast.isPersistent
        ) {
            viewModel.dismissToast(toast.id)
        }
    }
}
