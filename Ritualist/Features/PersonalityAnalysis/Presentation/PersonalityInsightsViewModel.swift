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
        startAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase,
        updateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase,
        getNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase,
        triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase,
        forceManualAnalysisUseCase: ForceManualAnalysisUseCase,
        loadProfile: LoadProfileUseCase,
        logger: DebugLogger
    ) {
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
        self.getPersonalityProfileUseCase = getPersonalityProfileUseCase
        self.validateAnalysisDataUseCase = validateAnalysisDataUseCase
        self.deletePersonalityDataUseCase = deletePersonalityDataUseCase
        self.loadProfile = loadProfile
        self.logger = logger
        self.currentUserId = nil
        self.preferencesManager = PersonalityPreferencesManager(
            getAnalysisPreferencesUseCase: getAnalysisPreferencesUseCase,
            saveAnalysisPreferencesUseCase: saveAnalysisPreferencesUseCase,
            startAnalysisSchedulingUseCase: startAnalysisSchedulingUseCase,
            updateAnalysisSchedulingUseCase: updateAnalysisSchedulingUseCase,
            getNextScheduledAnalysisUseCase: getNextScheduledAnalysisUseCase,
            triggerAnalysisCheckUseCase: triggerAnalysisCheckUseCase,
            forceManualAnalysisUseCase: forceManualAnalysisUseCase,
            logger: logger
        )
    }
    
    // MARK: - Public Methods
    
    public func loadPersonalityInsights() async {
        viewState = .loading
        
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
                // User has sufficient data, perform analysis
                let profile = try await analyzePersonalityUseCase.execute(for: userId)
                viewState = .ready(profile: profile)
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
        
        do {
            let profile = try await analyzePersonalityUseCase.execute(for: userId)
            viewState = .ready(profile: profile)
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
        guard let userId = await getCurrentUserId() else {
            isSavingPreferences = false
            return
        }
        let success = await preferencesManager.savePreferences(newPreferences, for: userId)
        if success {
            preferences = newPreferences
            if !newPreferences.isCurrentlyActive {
                await loadPersonalityInsights()
            }
        }
        isSavingPreferences = false
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

    // MARK: - Scheduling

    public func getNextScheduledAnalysisDate() async -> Date? {
        guard let userId = await getCurrentUserId() else { return nil }
        return await preferencesManager.getNextScheduledAnalysisDate(for: userId)
    }

    public func triggerManualAnalysisCheck() async {
        guard let userId = await getCurrentUserId() else { return }
        await preferencesManager.triggerManualAnalysisCheck(for: userId, preferences: preferences)
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
