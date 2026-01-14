//
//  PersonalityPreferencesManager.swift
//  Ritualist
//
//  Extracted from PersonalityInsightsViewModel for SRP compliance
//

import Foundation
import RitualistCore

@MainActor
final class PersonalityPreferencesManager {
    private let getAnalysisPreferencesUseCase: GetAnalysisPreferencesUseCase
    private let saveAnalysisPreferencesUseCase: SaveAnalysisPreferencesUseCase
    private let startAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase
    private let updateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase
    private let getNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase
    private let triggerAppropriateAnalysisUseCase: TriggerAppropriateAnalysisUseCase
    private let triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase
    private let logger: DebugLogger

    /// Minimum interval between automatic trigger checks (5 minutes)
    /// Prevents redundant database queries on rapid app restarts
    private static let triggerCheckDebounceInterval: TimeInterval = 5 * 60

    init(
        getAnalysisPreferencesUseCase: GetAnalysisPreferencesUseCase,
        saveAnalysisPreferencesUseCase: SaveAnalysisPreferencesUseCase,
        startAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase,
        updateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase,
        getNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase,
        triggerAppropriateAnalysisUseCase: TriggerAppropriateAnalysisUseCase,
        triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase,
        logger: DebugLogger
    ) {
        self.getAnalysisPreferencesUseCase = getAnalysisPreferencesUseCase
        self.saveAnalysisPreferencesUseCase = saveAnalysisPreferencesUseCase
        self.startAnalysisSchedulingUseCase = startAnalysisSchedulingUseCase
        self.updateAnalysisSchedulingUseCase = updateAnalysisSchedulingUseCase
        self.getNextScheduledAnalysisUseCase = getNextScheduledAnalysisUseCase
        self.triggerAppropriateAnalysisUseCase = triggerAppropriateAnalysisUseCase
        self.triggerAnalysisCheckUseCase = triggerAnalysisCheckUseCase
        self.logger = logger
    }

    func loadPreferences(for userId: UUID) async -> PersonalityAnalysisPreferences {
        do {
            if let loaded = try await getAnalysisPreferencesUseCase.execute(for: userId) {
                if loaded.isCurrentlyActive {
                    await startAnalysisSchedulingUseCase.execute(for: userId)
                    // Trigger automatic analysis check if frequency-based (not manual)
                    // Only trigger if not recently checked (debounce rapid app restarts)
                    if loaded.analysisFrequency != .manual && shouldTriggerAnalysisCheck() {
                        await triggerAnalysisCheckUseCase.execute(for: userId)
                        recordTriggerCheck()
                    }
                }
                return loaded
            }
            let defaults = PersonalityAnalysisPreferences(userId: userId)
            try? await saveAnalysisPreferencesUseCase.execute(defaults)
            await startAnalysisSchedulingUseCase.execute(for: userId)
            // Trigger automatic analysis check for new users with default frequency
            if defaults.analysisFrequency != .manual && shouldTriggerAnalysisCheck() {
                await triggerAnalysisCheckUseCase.execute(for: userId)
                recordTriggerCheck()
            }
            return defaults
        } catch {
            logger.log("Error loading preferences: \(error)", level: .error, category: .personality)
            return PersonalityAnalysisPreferences(userId: userId)
        }
    }

    // MARK: - Debouncing

    /// Returns true if enough time has passed since the last trigger check
    private func shouldTriggerAnalysisCheck() -> Bool {
        guard let lastCheck = UserDefaults.standard.object(forKey: UserDefaultsKeys.personalityLastTriggerCheckDate) as? Date else {
            return true // Never checked before
        }
        return Date().timeIntervalSince(lastCheck) >= Self.triggerCheckDebounceInterval
    }

    /// Records the current time as the last trigger check
    private func recordTriggerCheck() {
        UserDefaults.standard.set(Date(), forKey: UserDefaultsKeys.personalityLastTriggerCheckDate)
    }

    func savePreferences(_ prefs: PersonalityAnalysisPreferences, for userId: UUID) async -> Bool {
        do {
            try await saveAnalysisPreferencesUseCase.execute(prefs)
            await updateAnalysisSchedulingUseCase.execute(for: userId, preferences: prefs)
            return true
        } catch {
            logger.log("Error saving preferences: \(error)", level: .error, category: .personality)
            return false
        }
    }

    func getNextScheduledAnalysisDate(for userId: UUID) async -> Date? {
        await getNextScheduledAnalysisUseCase.execute(for: userId)
    }

    /// Triggers analysis using the appropriate method based on user preferences
    /// Uses centralized UseCase that handles manual vs automatic frequency
    func triggerAnalysis(for userId: UUID) async {
        await triggerAppropriateAnalysisUseCase.execute(for: userId)
    }
}
