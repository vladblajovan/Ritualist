//
//  PersonalityInsightsViewModel.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
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
    private let getAnalysisPreferencesUseCase: GetAnalysisPreferencesUseCase
    private let saveAnalysisPreferencesUseCase: SaveAnalysisPreferencesUseCase
    private let deletePersonalityDataUseCase: DeletePersonalityDataUseCase
    private let startAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase
    private let updateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase
    private let getNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase
    private let triggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase
    private let forceManualAnalysisUseCase: ForceManualAnalysisUseCase
    private let loadProfile: LoadProfileUseCase
    private let logger: DebugLogger
    private var currentUserId: UUID?

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
        self.getAnalysisPreferencesUseCase = getAnalysisPreferencesUseCase
        self.saveAnalysisPreferencesUseCase = saveAnalysisPreferencesUseCase
        self.deletePersonalityDataUseCase = deletePersonalityDataUseCase
        self.startAnalysisSchedulingUseCase = startAnalysisSchedulingUseCase
        self.updateAnalysisSchedulingUseCase = updateAnalysisSchedulingUseCase
        self.getNextScheduledAnalysisUseCase = getNextScheduledAnalysisUseCase
        self.triggerAnalysisCheckUseCase = triggerAnalysisCheckUseCase
        self.forceManualAnalysisUseCase = forceManualAnalysisUseCase
        self.loadProfile = loadProfile
        self.logger = logger
        self.currentUserId = nil
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
    
    // MARK: - Privacy Management
    
    public func loadPreferences() async {
        isLoadingPreferences = true
        
        guard let userId = await getCurrentUserId() else {
            isLoadingPreferences = false
            return
        }
        
        do {
            let loadedPreferences = try await getAnalysisPreferencesUseCase.execute(for: userId)
            
            if let loadedPreferences = loadedPreferences {
                preferences = loadedPreferences
                isLoadingPreferences = false
            } else {
                // Create default preferences
                let defaultPreferences = PersonalityAnalysisPreferences(userId: userId)
                
                // Save defaults immediately to persist them
                try? await saveAnalysisPreferencesUseCase.execute(defaultPreferences)
                
                preferences = defaultPreferences
                isLoadingPreferences = false
                
                // Start scheduling with default preferences
                await startAnalysisSchedulingUseCase.execute(for: userId)
            }
            
            // Start scheduling if analysis is enabled
            if let prefs = preferences, prefs.isCurrentlyActive {
                await startAnalysisSchedulingUseCase.execute(for: userId)
            }
        } catch {
            logger.log("Error loading personality analysis preferences: \(error)", level: .error, category: .personality)
            // Create default preferences on error
            if let userId = await getCurrentUserId() {
                preferences = PersonalityAnalysisPreferences(userId: userId)
                isLoadingPreferences = false
            } else {
                isLoadingPreferences = false
            }
        }
    }
    
    public func savePreferences(_ newPreferences: PersonalityAnalysisPreferences) async {
        isSavingPreferences = true
        
        do {
            try await saveAnalysisPreferencesUseCase.execute(newPreferences)
            
            preferences = newPreferences
            isSavingPreferences = false
            
            // Update scheduler based on new preferences
            if let userId = await getCurrentUserId() {
                await updateAnalysisSchedulingUseCase.execute(for: userId, preferences: newPreferences)
            }
            
            // If analysis was disabled, we might need to update the view state
            if !newPreferences.isCurrentlyActive {
                await loadPersonalityInsights()
            }
        } catch {
            logger.log("Error saving personality analysis preferences: \(error)", level: .error, category: .personality)
            isSavingPreferences = false
        }
    }
    
    public func deleteAllPersonalityData() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            // Delete all personality profiles
            try await deletePersonalityDataUseCase.execute(for: userId)
            
            // Reset view state to trigger fresh analysis
            await loadPersonalityInsights()
        } catch {
            logger.log("Error deleting personality data: \(error)", level: .error, category: .personality)
        }
    }
    
    public func pauseAnalysisUntil(_ date: Date) async {
        guard let currentPrefs = preferences else { return }
        
        let updatedPrefs = currentPrefs.updated(pausedUntil: date)
        await savePreferences(updatedPrefs)
    }
    
    public func resumeAnalysis() async {
        guard let currentPrefs = preferences else { return }
        
        let updatedPrefs = currentPrefs.updated(pausedUntil: nil)
        await savePreferences(updatedPrefs)
    }
    
    public func toggleAnalysis() async {
        guard let currentPrefs = preferences else { return }
        
        let newEnabledState = !currentPrefs.isEnabled
        let updatedPrefs = currentPrefs.updated(isEnabled: newEnabledState)
        await savePreferences(updatedPrefs)
        
        // If we just enabled analysis, try to load insights
        if newEnabledState {
            await loadPersonalityInsights()
        }
    }
    
    // MARK: - Privacy Helper Properties
    
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
    
    /// Determines if the force redo analysis button should be enabled
    /// Requires: frequency = manual AND analysis enabled AND sufficient data
    public var isForceRedoAnalysisButtonEnabled: Bool {
        // Check if frequency is manual
        guard preferences?.analysisFrequency == .manual else { return false }
        
        // Check if analysis is enabled
        guard isAnalysisEnabled else { return false }
        
        // Check if has sufficient data (based on view state)
        switch viewState {
        case .ready:
            // Has sufficient data and valid profile
            return true
        case .loading, .insufficientData, .readyWithInsufficientData, .error:
            // Either loading, insufficient data, or error state
            return false
        }
    }
    
    // MARK: - Scheduling Helper Properties
    
    public func getNextScheduledAnalysisDate() async -> Date? {
        guard let userId = await getCurrentUserId() else { return nil }
        return await getNextScheduledAnalysisUseCase.execute(for: userId)
    }
    
    public func triggerManualAnalysisCheck() async {
        let timestamp = Date().timeIntervalSince1970
        guard let userId = await getCurrentUserId() else {
            return
        }
        
        // Check if user is in manual mode - if so, force analysis
        if let prefs = preferences, prefs.analysisFrequency == .manual {
            await forceManualAnalysisUseCase.execute(for: userId)
        } else {
            // For other frequencies, use regular check
            await triggerAnalysisCheckUseCase.execute(for: userId)
        }
        // Refresh view state after potential analysis
        await loadPersonalityInsights()
        let endTimestamp = Date().timeIntervalSince1970
    }
    
    // MARK: - Private Helpers
    
    private func getCurrentUserId() async -> UUID? {
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
}
