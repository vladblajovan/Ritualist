//
//  PersonalityInsightsViewModel+Preferences.swift
//  Ritualist
//
//  Preferences management and helper methods extracted to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Preferences Management

extension PersonalityInsightsViewModel {

    public func loadPreferences() async {
        isLoadingPreferences = true
        defer { isLoadingPreferences = false }

        guard let userId = await getCurrentUserId() else {
            return
        }

        preferences = await preferencesManager.loadPreferences(for: userId)
    }

    public func savePreferences(_ newPreferences: PersonalityAnalysisPreferences) async {
        isSavingPreferences = true
        preferenceSaveError = nil
        defer { isSavingPreferences = false }

        guard let userId = await getCurrentUserId() else {
            preferenceSaveError = "Unable to save preferences. Please try again."
            return
        }

        let saveSuccessful = await preferencesManager.savePreferences(newPreferences, for: userId)

        if saveSuccessful {
            preferences = newPreferences
            if !newPreferences.isCurrentlyActive {
                await loadPersonalityInsights()
            }
        } else {
            preferenceSaveError = "Unable to save preferences. Please try again."
            logger.log("Failed to save personality analysis preferences", level: .error, category: .personality)
        }
    }

    public func clearPreferenceSaveError() {
        preferenceSaveError = nil
    }

    public func deleteAllPersonalityData() async {
        guard let userId = await getCurrentUserId() else {
            return
        }

        do {
            try await deletePersonalityDataUseCase.execute(for: userId)
            await loadPersonalityInsights()
        } catch {
            logger.log("Error deleting personality data: \(error)", level: .error, category: .personality)
        }
    }

    public func pauseAnalysisUntil(_ date: Date) async {
        guard let currentPrefs = preferences else {
            return
        }
        await savePreferences(currentPrefs.updated(pausedUntil: date))
    }

    public func resumeAnalysis() async {
        guard let currentPrefs = preferences else {
            return
        }
        await savePreferences(currentPrefs.updated(pausedUntil: nil))
    }

    public func toggleAnalysis() async {
        guard let currentPrefs = preferences else {
            return
        }

        let updatedPrefs = currentPrefs.updated(isEnabled: !currentPrefs.isEnabled)
        await savePreferences(updatedPrefs)

        if updatedPrefs.isEnabled {
            await loadPersonalityInsights()
        }
    }

    public func setAnalysisEnabled(_ enabled: Bool) async {
        guard let currentPrefs = preferences,
              currentPrefs.isEnabled != enabled else {
            return
        }

        let updatedPrefs = currentPrefs.updated(isEnabled: enabled)
        await savePreferences(updatedPrefs)

        if enabled {
            await loadPersonalityInsights()
        }
    }
}

// MARK: - Scheduling

extension PersonalityInsightsViewModel {

    public func getNextScheduledAnalysisDate() async -> Date? {
        guard let userId = await getCurrentUserId() else {
            return nil
        }
        return await preferencesManager.getNextScheduledAnalysisDate(for: userId)
    }

    public func triggerManualAnalysisCheck() async {
        guard let userId = await getCurrentUserId() else {
            return
        }
        await preferencesManager.triggerAnalysis(for: userId)
        await loadPersonalityInsights()
    }
}

// MARK: - Analysis Seen State

extension PersonalityInsightsViewModel {

    public func markAnalysisAsSeen() async {
        guard let profile = currentProfile else {
            return
        }
        lastSeenAnalysisDate = profile.analysisMetadata.analysisDate
        await markAnalysisAsSeenUseCase.execute(analysisDate: profile.analysisMetadata.analysisDate)
    }

    func loadLastSeenAnalysisDate() async {
        lastSeenAnalysisDate = await getLastSeenAnalysisDateUseCase.execute()
    }
}

// MARK: - Private Helpers

extension PersonalityInsightsViewModel {

    func getCurrentUserId() async -> UUID? {
        if let cachedUserId = currentUserId {
            return cachedUserId
        }

        do {
            let profile = try await loadProfile.execute()
            currentUserId = profile.id
            return profile.id
        } catch {
            return nil
        }
    }

    /// Fetches profile with exponential backoff retry (handles slow SwiftData persistence)
    func fetchProfileWithRetry(for userId: UUID) async throws -> PersonalityProfile? {
        let maxRetries = 5
        let baseDelayNs: UInt64 = 500_000_000

        for attempt in 1...maxRetries {
            let profile = try await getPersonalityProfileUseCase.execute(for: userId)

            if profile != nil {
                logger.log("Profile found on attempt \(attempt)", level: .debug, category: .personality)
                return profile
            }

            if attempt < maxRetries {
                let delay = baseDelayNs * UInt64(pow(1.5, Double(attempt - 1)))
                logger.log(
                    "Profile not found on attempt \(attempt), retrying in \(delay / 1_000_000)ms...",
                    level: .debug,
                    category: .personality
                )
                try await Task.sleep(nanoseconds: delay)
            }
        }

        logger.log("Profile not found after \(maxRetries) attempts", level: .warning, category: .personality)
        return nil
    }
}
