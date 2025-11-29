import Foundation
import SwiftData

/// @ModelActor implementation of ProfileLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor ProfileLocalDataSource: ProfileLocalDataSourceProtocol {

    /// Load user profile from background thread, return Domain model
    public func load() async throws -> UserProfile? {
        let descriptor = FetchDescriptor<ActiveUserProfileModel>()
        guard let profile = try modelContext.fetch(descriptor).first else {
            return nil
        }

        return profile.toEntity()
    }
    
    /// Save user profile on background thread - accepts Domain model
    public func save(_ profile: UserProfile) async throws {
        // Check if profile already exists
        let profileIdString = profile.id.uuidString
        let descriptor = FetchDescriptor<ActiveUserProfileModel>(
            predicate: #Predicate { $0.id == profileIdString }
        )
        
        if let existing = try modelContext.fetch(descriptor).first {
            // Update existing profile - use fromEntity for consistent mapping
            existing.name = profile.name
            existing.avatarImageData = profile.avatarImageData
            existing.appearance = String(profile.appearance)

            // V9 Three-Timezone Model fields
            existing.currentTimezoneIdentifier = profile.currentTimezoneIdentifier
            existing.homeTimezoneIdentifier = profile.homeTimezoneIdentifier

            // Encode DisplayTimezoneMode to Data
            if let modeData = try? JSONEncoder().encode(profile.displayTimezoneMode) {
                existing.displayTimezoneModeData = modeData
            }

            // Encode timezone change history to Data
            if let historyData = try? JSONEncoder().encode(profile.timezoneChangeHistory) {
                existing.timezoneChangeHistoryData = historyData
            }

            // V11 Demographics fields
            existing.gender = profile.gender
            existing.ageGroup = profile.ageGroup

            existing.updatedAt = profile.updatedAt
        } else {
            // Create new profile in this ModelContext
            let userProfileModel = ActiveUserProfileModel.fromEntity(profile)
            modelContext.insert(userProfileModel)
        }
        
        try modelContext.save()
    }
}
