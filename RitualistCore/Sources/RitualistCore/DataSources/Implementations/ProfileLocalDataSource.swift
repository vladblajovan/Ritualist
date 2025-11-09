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

        // 🔍 DEBUG: Check what fields actually exist in database
        print("🔍 [ProfileLocalDataSource] Loading profile from database")
        print("   📝 Name: \(profile.name)")
        print("   🎨 Appearance: \(profile.appearance)")
        print("   🌍 Display timezone mode: \(profile.displayTimezoneMode)")
        print("   🏠 Home timezone: \(profile.homeTimezone ?? "nil")")

        // Try to access subscription fields (will compile because of type alias, but should not exist in V8)
        let mirror = Mirror(reflecting: profile)
        print("   🔍 All database fields:")
        for child in mirror.children {
            if let label = child.label {
                print("      - \(label): \(child.value)")
            }
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
            // Update existing profile (subscription fields managed by SubscriptionService)
            existing.name = profile.name
            existing.avatarImageData = profile.avatarImageData
            existing.appearance = String(profile.appearance)
            existing.homeTimezone = profile.homeTimezone
            existing.displayTimezoneMode = profile.displayTimezoneMode
            // Note: subscriptionPlan and subscriptionExpiryDate removed in V8 - managed by SubscriptionService
            existing.updatedAt = profile.updatedAt
        } else {
            // Create new profile in this ModelContext
            let userProfileModel = ActiveUserProfileModel.fromEntity(profile)
            modelContext.insert(userProfileModel)
        }
        
        try modelContext.save()
    }
}
