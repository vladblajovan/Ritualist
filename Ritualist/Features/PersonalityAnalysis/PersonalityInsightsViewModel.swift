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

    // MARK: - Dependencies (Internal for Extension Access)

    private let analyzePersonalityUseCase: AnalyzePersonalityUseCase
    let getPersonalityProfileUseCase: GetPersonalityProfileUseCase
    let validateAnalysisDataUseCase: ValidateAnalysisDataUseCase
    let deletePersonalityDataUseCase: DeletePersonalityDataUseCase
    let markAnalysisAsSeenUseCase: MarkAnalysisAsSeenUseCase
    let getLastSeenAnalysisDateUseCase: GetLastSeenAnalysisDateUseCase
    let loadProfile: LoadProfileUseCase
    let logger: DebugLogger
    var currentUserId: UUID?
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

        guard let userId = await getCurrentUserId() else {
            viewState = .error(.unknownError("Failed to load user profile"))
            return
        }

        await loadPreferences()

        guard isAnalysisEnabled else {
            viewState = .loading
            return
        }

        do {
            if let existingProfile = try await getPersonalityProfileUseCase.execute(for: userId) {
                try await handleExistingProfile(existingProfile, userId: userId)
                return
            }
            try await handleNewUserAnalysis(userId: userId)
        } catch let error as PersonalityAnalysisError {
            viewState = .error(error)
        } catch {
            viewState = .error(.unknownError(error.localizedDescription))
        }
    }

    private func handleExistingProfile(_ profile: PersonalityProfile, userId: UUID) async throws {
        let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)

        if eligibility.isEligible {
            viewState = .ready(profile: profile)
        } else {
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
            let estimatedDays = try await validateAnalysisDataUseCase.getEstimatedDaysToEligibility(for: userId)
            viewState = .readyWithInsufficientData(
                profile: profile,
                requirements: requirements,
                estimatedDays: estimatedDays
            )
        }
    }

    private func handleNewUserAnalysis(userId: UUID) async throws {
        let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)

        if eligibility.isEligible {
            logger.log("Triggering analysis for eligible user", level: .debug, category: .personality)
            await preferencesManager.triggerAnalysis(for: userId)

            if let profile = try await fetchProfileWithRetry(for: userId) {
                viewState = .ready(profile: profile)
            } else {
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
        guard hasProfile else {
            return
        }

        guard let userId = await getCurrentUserId() else {
            viewState = .error(.unknownError("Failed to load user profile"))
            return
        }

        viewState = .loading
        await preferencesManager.triggerAnalysis(for: userId)

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

    // MARK: - Computed Properties

    public var isAnalysisEnabled: Bool {
        preferences?.isEnabled ?? true
    }

    public var isAnalysisCurrentlyActive: Bool {
        preferences?.isCurrentlyActive ?? false
    }

    public var analysisFrequency: AnalysisFrequency {
        preferences?.analysisFrequency ?? .weekly
    }

    public var shouldShowDataUsage: Bool {
        preferences?.showDataUsage ?? true
    }

    public var isForceRedoAnalysisButtonEnabled: Bool {
        preferences?.analysisFrequency == .manual && isAnalysisEnabled && hasProfile
    }

    /// Returns true if there's a new analysis the user hasn't seen yet (requires previously acknowledged analysis)
    public var hasUnseenAnalysis: Bool {
        guard let profile = currentProfile,
              let lastSeen = lastSeenAnalysisDate else {
            return false
        }
        return profile.analysisMetadata.analysisDate > lastSeen
    }
}
