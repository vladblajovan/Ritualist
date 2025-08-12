//
//  PersonalityAnalysisDataSource.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftData

/// Data source for personality analysis SwiftData operations
public protocol PersonalityAnalysisDataSource {
    /// Get the latest personality profile for a user
    @MainActor func getLatestProfile(for userId: UUID) async throws -> PersonalityProfile?
    
    /// Save a personality profile
    @MainActor func saveProfile(_ profile: PersonalityProfile) async throws
    
    /// Get profile history for a user
    @MainActor func getProfileHistory(for userId: UUID) async throws -> [PersonalityProfile]
    
    /// Delete a specific profile
    @MainActor func deleteProfile(profileId: String) async throws
    
    /// Delete all profiles for a user
    @MainActor func deleteAllProfiles(for userId: UUID) async throws
}

public final class SwiftDataPersonalityAnalysisDataSource: PersonalityAnalysisDataSource {
    
    private let modelContext: ModelContext?
    
    public init(modelContext: ModelContext?) {
        self.modelContext = modelContext
    }
    
    @MainActor public func getLatestProfile(for userId: UUID) async throws -> PersonalityProfile? {
        guard let modelContext else { return nil }
        let userIdString = userId.uuidString
        let descriptor = FetchDescriptor<SDPersonalityProfile>(
            predicate: #Predicate<SDPersonalityProfile> { profile in
                profile.userId == userIdString
            },
            sortBy: [SortDescriptor(\.analysisDate, order: .reverse)]
        )
        
        let models = try modelContext.fetch(descriptor)
        return models.first?.toEntity()
    }
    
    @MainActor public func saveProfile(_ profile: PersonalityProfile) async throws {
        guard let modelContext else { return }
        let model = SDPersonalityProfile.fromEntity(profile)
        modelContext.insert(model)
        try modelContext.save()
    }
    
    @MainActor public func getProfileHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        guard let modelContext else { return [] }
        let userIdString = userId.uuidString
        let descriptor = FetchDescriptor<SDPersonalityProfile>(
            predicate: #Predicate<SDPersonalityProfile> { profile in
                profile.userId == userIdString
            },
            sortBy: [SortDescriptor(\.analysisDate, order: .reverse)]
        )
        
        let models = try modelContext.fetch(descriptor)
        return models.compactMap { $0.toEntity() }
    }
    
    @MainActor public func deleteProfile(profileId: String) async throws {
        guard let modelContext else { return }
        let descriptor = FetchDescriptor<SDPersonalityProfile>(
            predicate: #Predicate<SDPersonalityProfile> { profile in
                profile.id == profileId
            }
        )
        
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }
    
    @MainActor public func deleteAllProfiles(for userId: UUID) async throws {
        guard let modelContext else { return }
        let userIdString = userId.uuidString
        let descriptor = FetchDescriptor<SDPersonalityProfile>(
            predicate: #Predicate<SDPersonalityProfile> { profile in
                profile.userId == userIdString
            }
        )
        
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }
}