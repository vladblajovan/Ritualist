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

        // Load the last seen analysis date for "New Analysis" indicator
        await loadLastSeenAnalysisDate()

        // Load user ID first
        guard let userId = await getCurrentUserId() else {
            viewState = .error(.unknownError("Failed to load user profile"))
            return
        }

        // Always load preferences first to get current analysis state
        await loadPreferences()
        
        // Check if analysis is disabled - exit early and let UI handle disabled state
        guard isAnalysisEnabled else {
            viewState = .loading // UI will show disabled state based on isAnalysisEnabled
            return
        }
        
        do {
            
            // First check if user has existing profile
            if let existingProfile = try await getPersonalityProfileUseCase.execute(for: userId) {
                // Even with existing profile, check if data is sufficient for new analysis
                let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
                
                if eligibility.isEligible {
                    viewState = .ready(profile: existingProfile)
                } else {
                    // User has old profile but insufficient data for new analysis
                    let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
                    let estimatedDays = try await validateAnalysisDataUseCase.getEstimatedDaysToEligibility(for: userId)
                    viewState = .readyWithInsufficientData(profile: existingProfile, requirements: requirements, estimatedDays: estimatedDays)
                }
                return
            }
            
            // Check if user has sufficient data for analysis
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)

            if eligibility.isEligible {
                // User has sufficient data - trigger analysis through scheduler
                // This ensures notification is sent and profile is saved properly
                logger.log("Triggering analysis for eligible user", level: .debug, category: .personality)
                await preferencesManager.triggerAnalysis(for: userId)
                logger.log("Analysis trigger completed, checking for generated profile", level: .debug, category: .personality)

                // Retry fetching profile with exponential backoff to handle SwiftData persistence timing
                // Delays: 500ms, 750ms, 1s, 1.5s = total ~3.75s max wait
                // This handles slow persistence under heavy load while keeping typical case fast
                let maxRetries = 5
                let baseDelayNs: UInt64 = 500_000_000 // 0.5 seconds base

                var generatedProfile: PersonalityProfile?
                for attempt in 1...maxRetries {
                    generatedProfile = try await getPersonalityProfileUseCase.execute(for: userId)
                    if generatedProfile != nil {
                        logger.log("Profile found on attempt \(attempt)", level: .debug, category: .personality)
                        break
                    }
                    if attempt < maxRetries {
                        // Exponential backoff: 500ms, 750ms, 1000ms, 1500ms
                        let delayMultiplier = UInt64(pow(1.5, Double(attempt - 1)))
                        let delay = baseDelayNs * delayMultiplier
                        logger.log("Profile not found on attempt \(attempt), retrying in \(delay / 1_000_000)ms...", level: .debug, category: .personality)
                        try await Task.sleep(nanoseconds: delay)
                    }
                }

                if let profile = generatedProfile {
                    viewState = .ready(profile: profile)
                } else {
                    // User met eligibility but profile generation failed after retries.
                    // This indicates an unexpected internal error (scheduler/repository issue).
                    // Generic message is intentional: user can't act on internal details,
                    // retry is the only actionable advice. Detailed logging captures context for debugging.
                    logger.log("Analysis triggered for eligible user but profile not created after \(maxRetries) attempts - possible scheduler/repository issue", level: .error, category: .personality)
                    viewState = .error(.unknownError("Unable to generate your personality analysis. Please try again."))
                }
            } else {
                // User doesn't have sufficient data
                let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
                let estimatedDays = try await validateAnalysisDataUseCase.getEstimatedDaysToEligibility(for: userId)
                viewState = .insufficientData(requirements: requirements, estimatedDays: estimatedDays)
            }
        } catch let error as PersonalityAnalysisError {
            viewState = .error(error)
        } catch {
            viewState = .error(.unknownError(error.localizedDescription))
        }
    }
    
    public func refresh() async {
        await loadPersonalityInsights()
    }
    
    public func regenerateAnalysis() async {
        switch viewState {
        case .ready, .readyWithInsufficientData:
            break
        default:
            return
        }

        guard let userId = await getCurrentUserId() else {
            viewState = .error(.unknownError("Failed to load user profile"))
            return
        }

        viewState = .loading

        // Trigger analysis through scheduler - ensures notification is sent
        await preferencesManager.triggerAnalysis(for: userId)

        // Reload the generated profile
        do {
            if let profile = try await getPersonalityProfileUseCase.execute(for: userId) {
                viewState = .ready(profile: profile)
            } else {
                viewState = .error(.unknownError("Failed to regenerate analysis"))
            }
        } catch let error as PersonalityAnalysisError {
            viewState = .error(error)
        } catch {
            viewState = .error(.unknownError(error.localizedDescription))
        }
    }
    
    // MARK: - Helper Properties
    
    public var isLoading: Bool {
        if case .loading = viewState {
            return true
        }
        return false
    }
    
    public var hasProfile: Bool {
        switch viewState {
        case .ready, .readyWithInsufficientData:
            return true
        default:
            return false
        }
    }
    
    public var requiresMoreData: Bool {
        if case .insufficientData = viewState {
            return true
        }
        return false
    }
    
    public var errorMessage: String? {
        if case .error(let error) = viewState {
            return error.localizedDescription
        }
        return nil
    }
    
    public var currentProfile: PersonalityProfile? {
        switch viewState {
        case .ready(let profile):
            return profile
        case .readyWithInsufficientData(let profile, _, _):
            return profile
        default:
            return nil
        }
    }
    
    public var progressRequirements: [ThresholdRequirement]? {
        switch viewState {
        case .insufficientData(let requirements, _):
            return requirements
        case .readyWithInsufficientData(_, let requirements, _):
            return requirements
        default:
            return nil
        }
    }
    
    // MARK: - Preferences Management (delegated)

    public func loadPreferences() async {
        isLoadingPreferences = true
        guard let userId = await getCurrentUserId() else {
            isLoadingPreferences = false
            return
        }
        preferences = await preferencesManager.loadPreferences(for: userId)
        isLoadingPreferences = false
    }

    public func savePreferences(_ newPreferences: PersonalityAnalysisPreferences) async {
        isSavingPreferences = true
        preferenceSaveError = nil // Clear any previous error
        guard let userId = await getCurrentUserId() else {
            isSavingPreferences = false
            preferenceSaveError = "Unable to save preferences. Please try again."
            return
        }
        let success = await preferencesManager.savePreferences(newPreferences, for: userId)
        if success {
            preferences = newPreferences
            if !newPreferences.isCurrentlyActive {
                await loadPersonalityInsights()
            }
        } else {
            preferenceSaveError = "Unable to save preferences. Please try again."
            logger.log("Failed to save personality analysis preferences", level: .error, category: .personality)
        }
        isSavingPreferences = false
    }

    /// Clears the preference save error (for manual dismissal from UI)
    public func clearPreferenceSaveError() {
        preferenceSaveError = nil
    }

    public func deleteAllPersonalityData() async {
        guard let userId = await getCurrentUserId() else { return }
        do {
            try await deletePersonalityDataUseCase.execute(for: userId)
            await loadPersonalityInsights()
        } catch {
            logger.log("Error deleting personality data: \(error)", level: .error, category: .personality)
        }
    }

    public func pauseAnalysisUntil(_ date: Date) async {
        guard let currentPrefs = preferences else { return }
        await savePreferences(currentPrefs.updated(pausedUntil: date))
    }

    public func resumeAnalysis() async {
        guard let currentPrefs = preferences else { return }
        await savePreferences(currentPrefs.updated(pausedUntil: nil))
    }

    public func toggleAnalysis() async {
        guard let currentPrefs = preferences else { return }
        let updatedPrefs = currentPrefs.updated(isEnabled: !currentPrefs.isEnabled)
        await savePreferences(updatedPrefs)
        if updatedPrefs.isEnabled { await loadPersonalityInsights() }
    }

    public func setAnalysisEnabled(_ enabled: Bool) async {
        guard let currentPrefs = preferences, currentPrefs.isEnabled != enabled else { return }
        let updatedPrefs = currentPrefs.updated(isEnabled: enabled)
        await savePreferences(updatedPrefs)
        if enabled { await loadPersonalityInsights() }
    }

    // MARK: - Computed Properties

    public var isAnalysisEnabled: Bool { preferences?.isEnabled ?? true }
    public var isAnalysisCurrentlyActive: Bool { preferences?.isCurrentlyActive ?? false }
    public var analysisFrequency: AnalysisFrequency { preferences?.analysisFrequency ?? .weekly }
    public var shouldShowDataUsage: Bool { preferences?.showDataUsage ?? true }

    public var isForceRedoAnalysisButtonEnabled: Bool {
        guard preferences?.analysisFrequency == .manual, isAnalysisEnabled else { return false }
        if case .ready = viewState { return true }
        return false
    }

    /// Returns true if there's a new analysis the user hasn't seen yet
    /// Only returns true when the user has a previously acknowledged analysis date
    /// and the current profile is newer than that date
    public var hasUnseenAnalysis: Bool {
        guard let profile = currentProfile else { return false }
        guard let lastSeen = lastSeenAnalysisDate else {
            // User has never dismissed the banner - don't show it for first-time users
            // The "New Analysis" indicator is meant for users who had a previous baseline
            return false
        }
        // Analysis is unseen if it was generated after the last time user dismissed the banner
        return profile.analysisMetadata.analysisDate > lastSeen
    }

    /// Marks the current analysis as seen, hiding the "New Analysis" indicator
    public func markAnalysisAsSeen() async {
        guard let profile = currentProfile else { return }
        lastSeenAnalysisDate = profile.analysisMetadata.analysisDate
        await markAnalysisAsSeenUseCase.execute(analysisDate: profile.analysisMetadata.analysisDate)
    }

    /// Loads the last seen analysis date from persistence
    private func loadLastSeenAnalysisDate() async {
        lastSeenAnalysisDate = await getLastSeenAnalysisDateUseCase.execute()
    }

    // MARK: - Scheduling

    public func getNextScheduledAnalysisDate() async -> Date? {
        guard let userId = await getCurrentUserId() else { return nil }
        return await preferencesManager.getNextScheduledAnalysisDate(for: userId)
    }

    public func triggerManualAnalysisCheck() async {
        guard let userId = await getCurrentUserId() else { return }
        await preferencesManager.triggerAnalysis(for: userId)
        await loadPersonalityInsights()
    }

    // MARK: - Private Helpers

    private func getCurrentUserId() async -> UUID? {
        if let cachedUserId = currentUserId { return cachedUserId }
        do {
            let profile = try await loadProfile.execute()
            currentUserId = profile.id
            return profile.id
        } catch {
            return nil
        }
    }
}
