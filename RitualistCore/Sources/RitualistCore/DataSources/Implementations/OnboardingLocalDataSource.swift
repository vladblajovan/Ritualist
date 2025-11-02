import Foundation
import SwiftData

/// @ModelActor implementation of OnboardingLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor OnboardingLocalDataSource: OnboardingLocalDataSourceProtocol {
    
    /// Load onboarding state from background thread, return Domain model
    public func load() async throws -> OnboardingState? {
        let descriptor = FetchDescriptor<OnboardingStateModelV1>()
        guard let state = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return state.toEntity()
    }
    
    /// Save onboarding state on background thread - accepts Domain model
    public func save(_ state: OnboardingState) async throws {
        // Check if onboarding state already exists (should be only one)
        let descriptor = FetchDescriptor<OnboardingStateModelV1>()
        
        if let existing = try modelContext.fetch(descriptor).first {
            // Update existing state
            existing.isCompleted = state.isCompleted
            existing.completedDate = state.completedDate
            existing.userName = state.userName
            existing.hasGrantedNotifications = state.hasGrantedNotifications
        } else {
            // Create new state in this ModelContext
            let onboardingStateModel = OnboardingStateModelV1.fromEntity(state)
            modelContext.insert(onboardingStateModel)
        }
        
        try modelContext.save()
    }
}
