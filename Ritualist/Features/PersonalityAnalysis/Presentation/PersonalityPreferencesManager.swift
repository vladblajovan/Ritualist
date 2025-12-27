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
    private let triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase
    private let forceManualAnalysisUseCase: ForceManualAnalysisUseCase
    private let logger: DebugLogger

    init(
        getAnalysisPreferencesUseCase: GetAnalysisPreferencesUseCase,
        saveAnalysisPreferencesUseCase: SaveAnalysisPreferencesUseCase,
        startAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase,
        updateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase,
        getNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase,
        triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase,
        forceManualAnalysisUseCase: ForceManualAnalysisUseCase,
        logger: DebugLogger
    ) {
        self.getAnalysisPreferencesUseCase = getAnalysisPreferencesUseCase
        self.saveAnalysisPreferencesUseCase = saveAnalysisPreferencesUseCase
        self.startAnalysisSchedulingUseCase = startAnalysisSchedulingUseCase
        self.updateAnalysisSchedulingUseCase = updateAnalysisSchedulingUseCase
        self.getNextScheduledAnalysisUseCase = getNextScheduledAnalysisUseCase
        self.triggerAnalysisCheckUseCase = triggerAnalysisCheckUseCase
        self.forceManualAnalysisUseCase = forceManualAnalysisUseCase
        self.logger = logger
    }

    func loadPreferences(for userId: UUID) async -> PersonalityAnalysisPreferences {
        do {
            if let loaded = try await getAnalysisPreferencesUseCase.execute(for: userId) {
                if loaded.isCurrentlyActive {
                    await startAnalysisSchedulingUseCase.execute(for: userId)
                }
                return loaded
            }
            let defaults = PersonalityAnalysisPreferences(userId: userId)
            try? await saveAnalysisPreferencesUseCase.execute(defaults)
            await startAnalysisSchedulingUseCase.execute(for: userId)
            return defaults
        } catch {
            logger.log("Error loading preferences: \(error)", level: .error, category: .personality)
            return PersonalityAnalysisPreferences(userId: userId)
        }
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

    func triggerManualAnalysisCheck(for userId: UUID, preferences: PersonalityAnalysisPreferences?) async {
        if let prefs = preferences, prefs.analysisFrequency == .manual {
            await forceManualAnalysisUseCase.execute(for: userId)
        } else {
            await triggerAnalysisCheckUseCase.execute(for: userId)
        }
    }
}
