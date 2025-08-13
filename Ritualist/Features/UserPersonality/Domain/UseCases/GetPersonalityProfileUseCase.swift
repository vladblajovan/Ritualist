//
//  GetPersonalityProfileUseCase.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import RitualistCore

/// Use case for retrieving personality profiles
public protocol GetPersonalityProfileUseCase {
    /// Get the latest personality profile for a user
    func execute(for userId: UUID) async throws -> PersonalityProfile?
    
    /// Get historical personality profiles for a user
    func getHistory(for userId: UUID) async throws -> [PersonalityProfile]
    
    /// Check if user has any personality profiles
    func hasProfiles(for userId: UUID) async throws -> Bool
}

public final class DefaultGetPersonalityProfileUseCase: GetPersonalityProfileUseCase {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile? {
        return try await repository.getPersonalityProfile(for: userId)
    }
    
    public func getHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        return try await repository.getPersonalityHistory(for: userId)
    }
    
    public func hasProfiles(for userId: UUID) async throws -> Bool {
        let profile = try await repository.getPersonalityProfile(for: userId)
        return profile != nil
    }
}