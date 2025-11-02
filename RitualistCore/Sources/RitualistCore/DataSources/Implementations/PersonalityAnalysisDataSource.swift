//
//  PersonalityAnalysisDataSource.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import SwiftData

@ModelActor
public actor PersonalityAnalysisDataSource: PersonalityAnalysisDataSourceProtocol {
    
    public func getLatestProfile(for userId: UUID) async throws -> PersonalityProfile? {
        let userIdString = userId.uuidString
        let descriptor = FetchDescriptor<PersonalityAnalysisModelV2>(
            predicate: #Predicate<PersonalityAnalysisModelV2> { profile in
                profile.userId == userIdString
            },
            sortBy: [SortDescriptor(\.analysisDate, order: .reverse)]
        )
        
        let models = try modelContext.fetch(descriptor)
        return models.first?.toEntity()
    }
    
    public func saveProfile(_ profile: PersonalityProfile) async throws {
        let personalityProfileModel = PersonalityAnalysisModelV2.fromEntity(profile)
        modelContext.insert(personalityProfileModel)
        try modelContext.save()
    }
    
    public func getProfileHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        let userIdString = userId.uuidString
        let descriptor = FetchDescriptor<PersonalityAnalysisModelV2>(
            predicate: #Predicate<PersonalityAnalysisModelV2> { profile in
                profile.userId == userIdString
            },
            sortBy: [SortDescriptor(\.analysisDate, order: .reverse)]
        )
        
        let models = try modelContext.fetch(descriptor)
        return models.compactMap { $0.toEntity() }
    }
    
    public func deleteProfile(profileId: String) async throws {
        let descriptor = FetchDescriptor<PersonalityAnalysisModelV2>(
            predicate: #Predicate<PersonalityAnalysisModelV2> { profile in
                profile.id == profileId
            }
        )
        
        let models = try modelContext.fetch(descriptor)
        for model in models {
            modelContext.delete(model)
        }
        try modelContext.save()
    }
    
    public func deleteAllProfiles(for userId: UUID) async throws {
        let userIdString = userId.uuidString
        let descriptor = FetchDescriptor<PersonalityAnalysisModelV2>(
            predicate: #Predicate<PersonalityAnalysisModelV2> { profile in
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
