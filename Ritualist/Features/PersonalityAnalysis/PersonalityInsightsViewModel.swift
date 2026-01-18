//
//  PersonalityInsightsViewModel.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.08.2025.
//

import Foundation
import RitualistCore

@MainActor @Observable
public final class PersonalityInsightsViewModel {

    // MARK: - Observable Properties

    public var viewState: ViewState = .loading
    public var preferences: PersonalityAnalysisPreferences?
    public var isLoadingPreferences = false
    public var isSavingPreferences = false
    public var lastSeenAnalysisDate: Date?
    /// Error message shown when preference save fails - cleared on next successful save or manual dismissal
    public var preferenceSaveError: String?

    // MARK: - View State

    public enum ViewState {
        case loading
        case insufficientData(requirements: [ThresholdRequirement], estimatedDays: Int?)
        case ready(profile: PersonalityProfile)
        case readyWithInsufficientData(profile: PersonalityProfile, requirements: [ThresholdRequirement], estimatedDays: Int?)
        case error(PersonalityAnalysisError)
    }

    // MARK: - Dependencies

    private let analyzePersonalityUseCase: AnalyzePersonalityUseCase
    private let getPersonalityProfileUseCase: GetPersonalityProfileUseCase
    private let validateAnalysisDataUseCase: ValidateAnalysisDataUseCase
    private let deletePersonalityDataUseCase: DeletePersonalityDataUseCase
    private let markAnalysisAsSeenUseCase: MarkAnalysisAsSeenUseCase
    private let getLastSeenAnalysisDateUseCase: GetLastSeenAnalysisDateUseCase
    private let loadProfile: LoadProfileUseCase
    private let logger: DebugLogger
    private var currentUserId: UUID?
    let preferencesManager: PersonalityPreferencesManager

    // MARK: - Initialization

    public init(
        analyzePersonalityUseCase: AnalyzePersonalityUseCase,
        getPersonalityProfileUseCase: GetPersonalityProfileUseCase,
        validateAnalysisDataUseCase: ValidateAnalysisDataUseCase,
        getAnalysisPreferencesUseCase: GetAnalysisPreferencesUseCase,
        saveAnalysisPreferencesUseCase: SaveAnalysisPreferencesUseCase,
        deletePersonalityDataUseCase: DeletePersonalityDataUseCase,
        markAnalysisAsSeenUseCase: MarkAnalysisAsSeenUseCase,
        getLastSeenAnalysisDateUseCase: GetLastSeenAnalysisDateUseCase,
        startAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase,
        updateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase,
        getNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase,
        triggerAppropriateAnalysisUseCase: TriggerAppropriateAnalysisUseCase,
        triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase,
        loadProfile: LoadProfileUseCase,
        userDefaults: UserDefaultsService,
        logger: DebugLogger
    ) {
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
        self.getPersonalityProfileUseCase = getPersonalityProfileUseCase
        self.validateAnalysisDataUseCase = validateAnalysisDataUseCase
        self.deletePersonalityDataUseCase = deletePersonalityDataUseCase
        self.markAnalysisAsSeenUseCase = markAnalysisAsSeenUseCase
        self.getLastSeenAnalysisDateUseCase = getLastSeenAnalysisDateUseCase
        self.loadProfile = loadProfile
        self.logger = logger
        self.currentUserId = nil
        self.preferencesManager = PersonalityPreferencesManager(
            getAnalysisPreferencesUseCase: getAnalysisPreferencesUseCase,
            saveAnalysisPreferencesUseCase: saveAnalysisPreferencesUseCase,
            startAnalysisSchedulingUseCase: startAnalysisSchedulingUseCase,
            updateAnalysisSchedulingUseCase: updateAnalysisSchedulingUseCase,
            getNextScheduledAnalysisUseCase: getNextScheduledAnalysisUseCase,
            triggerAppropriateAnalysisUseCase: triggerAppropriateAnalysisUseCase,
            triggerAnalysisCheckUseCase: triggerAnalysisCheckUseCase,
            userDefaults: userDefaults,
            logger: logger
        )
    }
    
    // MARK: - Public Methods
    
    public func loadPersonalityInsights() async {
        viewState = .loading
        await loadLastSeenAnalysisDate()
        guard let userId = await getCurrentUserId() else { viewState = .error(.unknownError("Failed to load user profile")); return }
        await loadPreferences()
        guard isAnalysisEnabled else { viewState = .loading; return }
        do {
            if let existingProfile = try await getPersonalityProfileUseCase.execute(for: userId) {
                try await handleExistingProfile(existingProfile, userId: userId); return
            }
            try await handleNewUserAnalysis(userId: userId)
        } catch let error as PersonalityAnalysisError { viewState = .error(error) } catch { viewState = .error(.unknownError(error.localizedDescription)) }
    }

    private func handleExistingProfile(_ profile: PersonalityProfile, userId: UUID) async throws {
        let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
        if eligibility.isEligible { viewState = .ready(profile: profile) } else {
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
            let estimatedDays = try await validateAnalysisDataUseCase.getEstimatedDaysToEligibility(for: userId)
            viewState = .readyWithInsufficientData(profile: profile, requirements: requirements, estimatedDays: estimatedDays)
        }
    }

    private func handleNewUserAnalysis(userId: UUID) async throws {
        let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
        if eligibility.isEligible {
            logger.log("Triggering analysis for eligible user", level: .debug, category: .personality)
            await preferencesManager.triggerAnalysis(for: userId)
            if let profile = try await fetchProfileWithRetry(for: userId) { viewState = .ready(profile: profile) } else {
                logger.log("Analysis triggered but profile not created", level: .error, category: .personality)
                viewState = .error(.unknownError("Unable to generate your personality analysis. Please try again."))
            }
        } else {
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
            let estimatedDays = try await validateAnalysisDataUseCase.getEstimatedDaysToEligibility(for: userId)
            viewState = .insufficientData(requirements: requirements, estimatedDays: estimatedDays)
        }
    }
    
    public func refresh() async {
        await loadPersonalityInsights()
    }
    
    public func regenerateAnalysis() async {
        guard hasProfile else { return }
        guard let userId = await getCurrentUserId() else { viewState = .error(.unknownError("Failed to load user profile")); return }
        viewState = .loading
        await preferencesManager.triggerAnalysis(for: userId)
        do {
            if let profile = try await getPersonalityProfileUseCase.execute(for: userId) { viewState = .ready(profile: profile) } else { viewState = .error(.unknownError("Failed to regenerate analysis")) }
        } catch let error as PersonalityAnalysisError { viewState = .error(error) } catch { viewState = .error(.unknownError(error.localizedDescription)) }
    }
    
    // MARK: - Helper Properties

    public var isLoading: Bool { if case .loading = viewState { return true }; return false }
    public var hasProfile: Bool { if case .ready = viewState { return true }; if case .readyWithInsufficientData = viewState { return true }; return false }
    public var requiresMoreData: Bool { if case .insufficientData = viewState { return true }; return false }
    public var errorMessage: String? { if case .error(let error) = viewState { return error.localizedDescription }; return nil }
    public var currentProfile: PersonalityProfile? {
        if case .ready(let profile) = viewState { return profile }
        if case .readyWithInsufficientData(let profile, _, _) = viewState { return profile }
        return nil
    }
    public var progressRequirements: [ThresholdRequirement]? {
        if case .insufficientData(let requirements, _) = viewState { return requirements }
        if case .readyWithInsufficientData(_, let requirements, _) = viewState { return requirements }
        return nil
    }
    
    // MARK: - Preferences Management (delegated)

    public func loadPreferences() async {
        isLoadingPreferences = true
        defer { isLoadingPreferences = false }
        guard let userId = await getCurrentUserId() else { return }
        preferences = await preferencesManager.loadPreferences(for: userId)
    }

    public func savePreferences(_ newPreferences: PersonalityAnalysisPreferences) async {
        isSavingPreferences = true; preferenceSaveError = nil
        defer { isSavingPreferences = false }
        guard let userId = await getCurrentUserId() else { preferenceSaveError = "Unable to save preferences. Please try again."; return }
        if await preferencesManager.savePreferences(newPreferences, for: userId) {
            preferences = newPreferences
            if !newPreferences.isCurrentlyActive { await loadPersonalityInsights() }
        } else {
            preferenceSaveError = "Unable to save preferences. Please try again."
            logger.log("Failed to save personality analysis preferences", level: .error, category: .personality)
        }
    }

    public func clearPreferenceSaveError() { preferenceSaveError = nil }

    public func deleteAllPersonalityData() async {
        guard let userId = await getCurrentUserId() else { return }
        do { try await deletePersonalityDataUseCase.execute(for: userId); await loadPersonalityInsights() } catch { logger.log("Error deleting personality data: \(error)", level: .error, category: .personality) }
    }

    public func pauseAnalysisUntil(_ date: Date) async { guard let currentPrefs = preferences else { return }; await savePreferences(currentPrefs.updated(pausedUntil: date)) }
    public func resumeAnalysis() async { guard let currentPrefs = preferences else { return }; await savePreferences(currentPrefs.updated(pausedUntil: nil)) }
    public func toggleAnalysis() async {
        guard let currentPrefs = preferences else { return }
        let updatedPrefs = currentPrefs.updated(isEnabled: !currentPrefs.isEnabled); await savePreferences(updatedPrefs)
        if updatedPrefs.isEnabled { await loadPersonalityInsights() }
    }
    public func setAnalysisEnabled(_ enabled: Bool) async {
        guard let currentPrefs = preferences, currentPrefs.isEnabled != enabled else { return }
        let updatedPrefs = currentPrefs.updated(isEnabled: enabled); await savePreferences(updatedPrefs)
        if enabled { await loadPersonalityInsights() }
    }

    // MARK: - Computed Properties

    public var isAnalysisEnabled: Bool { preferences?.isEnabled ?? true }
    public var isAnalysisCurrentlyActive: Bool { preferences?.isCurrentlyActive ?? false }
    public var analysisFrequency: AnalysisFrequency { preferences?.analysisFrequency ?? .weekly }
    public var shouldShowDataUsage: Bool { preferences?.showDataUsage ?? true }
    public var isForceRedoAnalysisButtonEnabled: Bool { preferences?.analysisFrequency == .manual && isAnalysisEnabled && hasProfile }
    /// Returns true if there's a new analysis the user hasn't seen yet (requires previously acknowledged analysis)
    public var hasUnseenAnalysis: Bool {
        guard let profile = currentProfile, let lastSeen = lastSeenAnalysisDate else { return false }
        return profile.analysisMetadata.analysisDate > lastSeen
    }

    public func markAnalysisAsSeen() async {
        guard let profile = currentProfile else { return }
        lastSeenAnalysisDate = profile.analysisMetadata.analysisDate
        await markAnalysisAsSeenUseCase.execute(analysisDate: profile.analysisMetadata.analysisDate)
    }
    private func loadLastSeenAnalysisDate() async { lastSeenAnalysisDate = await getLastSeenAnalysisDateUseCase.execute() }

    // MARK: - Scheduling

    public func getNextScheduledAnalysisDate() async -> Date? { guard let userId = await getCurrentUserId() else { return nil }; return await preferencesManager.getNextScheduledAnalysisDate(for: userId) }
    public func triggerManualAnalysisCheck() async { guard let userId = await getCurrentUserId() else { return }; await preferencesManager.triggerAnalysis(for: userId); await loadPersonalityInsights() }

    // MARK: - Private Helpers

    private func getCurrentUserId() async -> UUID? {
        if let cachedUserId = currentUserId { return cachedUserId }
        do { let profile = try await loadProfile.execute(); currentUserId = profile.id; return profile.id } catch { return nil }
    }

    /// Fetches profile with exponential backoff retry (handles slow SwiftData persistence)
    private func fetchProfileWithRetry(for userId: UUID) async throws -> PersonalityProfile? {
        let maxRetries = 5; let baseDelayNs: UInt64 = 500_000_000
        for attempt in 1...maxRetries {
            let profile = try await getPersonalityProfileUseCase.execute(for: userId)
            if profile != nil { logger.log("Profile found on attempt \(attempt)", level: .debug, category: .personality); return profile }
            if attempt < maxRetries {
                let delay = baseDelayNs * UInt64(pow(1.5, Double(attempt - 1)))
                logger.log("Profile not found on attempt \(attempt), retrying in \(delay / 1_000_000)ms...", level: .debug, category: .personality)
                try await Task.sleep(nanoseconds: delay)
            }
        }
        logger.log("Profile not found after \(maxRetries) attempts", level: .warning, category: .personality); return nil
    }
}
