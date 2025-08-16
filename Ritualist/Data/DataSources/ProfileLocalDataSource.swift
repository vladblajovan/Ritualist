import Foundation
import SwiftData
import RitualistCore

/// @ModelActor implementation of ProfileLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor ProfileLocalDataSource: ProfileLocalDataSourceProtocol {
    
    /// Load user profile from background thread, return Domain model
    public func load() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<UserProfileModel>()
        guard let orofile = try modelContext.fetch(descriptor).first else {
            return nil
        }
        return orofile.toEntity()
    }
    
    /// Save user profile on background thread - accepts Domain model
    public func save(_ profile: UserProfile) async throws {
        // Check if profile already exists
        let profileIdString = profile.id.uuidString
        let descriptor = FetchDescriptor<UserProfileModel>(
            predicate: #Predicate { $0.id == profileIdString }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            // Update existing profile
            existing.name = profile.name
            existing.avatarImageData = profile.avatarImageData
            existing.appearance = String(profile.appearance)
            existing.subscriptionPlan = profile.subscriptionPlan.rawValue
            existing.subscriptionExpiryDate = profile.subscriptionExpiryDate
            existing.updatedAt = profile.updatedAt
        } else {
            // Create new profile in this ModelContext
            let userProfileModel = UserProfileModel.fromEntity(profile)
            modelContext.insert(userProfileModel)
        }
        
        try modelContext.save()
    }
}
