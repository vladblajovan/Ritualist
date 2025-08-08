//
//  PersonalityInsightsViewModel.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

@MainActor
public final class PersonalityInsightsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published public var viewState: ViewState = .loading
    @Published public var preferences: PersonalityAnalysisPreferences?
    @Published public var isLoadingPreferences = false
    @Published public var isSavingPreferences = false
    
    // MARK: - View State
    
    public enum ViewState {
        case loading
        case insufficientData(requirements: [ThresholdRequirement], estimatedDays: Int?)
        case ready(profile: PersonalityProfile)
        case error(PersonalityAnalysisError)
    }
    
    // MARK: - Dependencies
    
    private let analyzePersonalityUseCase: AnalyzePersonalityUseCase
    private let getPersonalityProfileUseCase: GetPersonalityProfileUseCase
    private let validateAnalysisDataUseCase: ValidateAnalysisDataUseCase
    private let personalityRepository: PersonalityAnalysisRepositoryProtocol
    private let scheduler: PersonalityAnalysisSchedulerProtocol
    private let loadProfile: LoadProfileUseCase
    private var currentUserId: UUID?
    
    // MARK: - Initialization
    
    public init(
        analyzePersonalityUseCase: AnalyzePersonalityUseCase,
        getPersonalityProfileUseCase: GetPersonalityProfileUseCase,
        validateAnalysisDataUseCase: ValidateAnalysisDataUseCase,
        personalityRepository: PersonalityAnalysisRepositoryProtocol,
        scheduler: PersonalityAnalysisSchedulerProtocol,
        loadProfile: LoadProfileUseCase
    ) {
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
        self.getPersonalityProfileUseCase = getPersonalityProfileUseCase
        self.validateAnalysisDataUseCase = validateAnalysisDataUseCase
        self.personalityRepository = personalityRepository
        self.scheduler = scheduler
        self.loadProfile = loadProfile
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
                viewState = .ready(profile: existingProfile)
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
        guard case .ready = viewState else { return }
        
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
        if case .ready = viewState {
            return true
        }
        return false
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
        if case .ready(let profile) = viewState {
            return profile
        }
        return nil
    }
    
    public var progressRequirements: [ThresholdRequirement]? {
        if case .insufficientData(let requirements, _) = viewState {
            return requirements
        }
        return nil
    }
    
    // MARK: - Privacy Management
    
    public func loadPreferences() async {
        await MainActor.run {
            isLoadingPreferences = true
        }
        
        guard let userId = await getCurrentUserId() else {
            await MainActor.run {
                isLoadingPreferences = false
            }
            return
        }
        
        do {
            let loadedPreferences = try await personalityRepository.getAnalysisPreferences(for: userId)
            
            if let loadedPreferences = loadedPreferences {
                await MainActor.run {
                    preferences = loadedPreferences
                    isLoadingPreferences = false
                }
            } else {
                // Create default preferences
                let defaultPreferences = PersonalityAnalysisPreferences(userId: userId)
                
                // Save defaults immediately to persist them
                try? await personalityRepository.saveAnalysisPreferences(defaultPreferences)
                
                await MainActor.run {
                    preferences = defaultPreferences
                    isLoadingPreferences = false
                }
                
                // Start scheduling with default preferences
                await scheduler.startScheduling(for: userId)
            }
            
            // Start scheduling if analysis is enabled
            if let prefs = preferences, prefs.isCurrentlyActive {
                await scheduler.startScheduling(for: userId)
            }
        } catch {
            print("Error loading preferences: \(error)")
            // Create default preferences on error
            if let userId = await getCurrentUserId() {
                await MainActor.run {
                    preferences = PersonalityAnalysisPreferences(userId: userId)
                    isLoadingPreferences = false
                }
            } else {
                await MainActor.run {
                    isLoadingPreferences = false
                }
            }
        }
    }
    
    public func savePreferences(_ newPreferences: PersonalityAnalysisPreferences) async {
        await MainActor.run {
            isSavingPreferences = true
        }
        
        do {
            try await personalityRepository.saveAnalysisPreferences(newPreferences)
            
            await MainActor.run {
                preferences = newPreferences
                isSavingPreferences = false
            }
            
            // Update scheduler based on new preferences
            if let userId = await getCurrentUserId() {
                await scheduler.updateScheduling(for: userId, preferences: newPreferences)
            }
            
            // If analysis was disabled, we might need to update the view state
            if !newPreferences.isCurrentlyActive {
                await loadPersonalityInsights()
            }
        } catch {
            print("Error saving preferences: \(error)")
            await MainActor.run {
                isSavingPreferences = false
            }
        }
    }
    
    public func deleteAllPersonalityData() async {
        guard let userId = await getCurrentUserId() else { return }
        
        do {
            // Delete all personality profiles
            try await personalityRepository.deleteAllPersonalityProfiles(for: userId)
            
            // Reset view state to trigger fresh analysis
            await loadPersonalityInsights()
        } catch {
            print("Error deleting personality data: \(error)")
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
        return preferences?.isEnabled ?? true
    }
    
    public var isAnalysisCurrentlyActive: Bool {
        return preferences?.isCurrentlyActive ?? false
    }
    
    public var analysisFrequency: AnalysisFrequency {
        return preferences?.analysisFrequency ?? .weekly
    }
    
    public var shouldShowDataUsage: Bool {
        return preferences?.showDataUsage ?? true
    }
    
    // MARK: - Scheduling Helper Properties
    
    public func getNextScheduledAnalysisDate() async -> Date? {
        guard let userId = await getCurrentUserId() else { return nil }
        return await scheduler.getNextScheduledAnalysis(for: userId)
    }
    
    public func triggerManualAnalysisCheck() async {
        let timestamp = Date().timeIntervalSince1970
        print("🔄 Manual refresh triggered at \(timestamp)")
        
        guard let userId = await getCurrentUserId() else {
            print("🔄 Failed to get current user ID")
            return
        }
        
        // Check if user is in manual mode - if so, force analysis
        if let prefs = preferences, prefs.analysisFrequency == .manual {
            print("🔄 Using forceManualAnalysis for manual mode")
            await scheduler.forceManualAnalysis(for: userId)
        } else {
            print("🔄 Using regular triggerAnalysisCheck")
            // For other frequencies, use regular check
            await scheduler.triggerAnalysisCheck(for: userId)
        }
        
        print("🔄 Analysis check completed, refreshing view state")
        // Refresh view state after potential analysis
        await loadPersonalityInsights()
        
        let endTimestamp = Date().timeIntervalSince1970
        print("🔄 Manual refresh completed at \(endTimestamp), duration: \(endTimestamp - timestamp)s")
    }
    
    // MARK: - Private Helpers
    
    private func getCurrentUserId() async -> UUID? {
        if let cachedUserId = currentUserId {
            print("🔄 [ViewModel] Using cached user ID: \(cachedUserId)")
            return cachedUserId
        }
        
        do {
            let profile = try await loadProfile.execute()
            currentUserId = profile.id
            print("🆔 [ViewModel] Loaded user ID from profile: \(profile.id)")
            return profile.id
        } catch {
            print("⚠️ Failed to load user profile: \(error)")
            return nil
        }
    }
    
}
