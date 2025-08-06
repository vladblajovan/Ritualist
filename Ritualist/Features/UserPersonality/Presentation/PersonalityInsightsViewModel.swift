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
    private let currentUserId: UUID // In real app, this would come from user session
    
    // MARK: - Initialization
    
    public init(
        analyzePersonalityUseCase: AnalyzePersonalityUseCase,
        getPersonalityProfileUseCase: GetPersonalityProfileUseCase,
        validateAnalysisDataUseCase: ValidateAnalysisDataUseCase,
        currentUserId: UUID = UUID() // TODO: Replace with actual user ID
    ) {
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
        self.getPersonalityProfileUseCase = getPersonalityProfileUseCase
        self.validateAnalysisDataUseCase = validateAnalysisDataUseCase
        self.currentUserId = currentUserId
    }
    
    // MARK: - Public Methods
    
    public func loadPersonalityInsights() async {
        viewState = .loading
        
        do {
            // First check if user has existing profile
            if let existingProfile = try await getPersonalityProfileUseCase.execute(for: currentUserId) {
                viewState = .ready(profile: existingProfile)
                return
            }
            
            // Check if user has sufficient data for analysis
            let eligibility = try await validateAnalysisDataUseCase.execute(for: currentUserId)
            
            if eligibility.isEligible {
                // User has sufficient data, perform analysis
                let profile = try await analyzePersonalityUseCase.execute(for: currentUserId)
                viewState = .ready(profile: profile)
            } else {
                // User doesn't have sufficient data
                let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: currentUserId)
                let estimatedDays = try await validateAnalysisDataUseCase.getEstimatedDaysToEligibility(for: currentUserId)
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
        
        viewState = .loading
        
        do {
            let profile = try await analyzePersonalityUseCase.execute(for: currentUserId)
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
}