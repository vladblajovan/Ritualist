//
//  PersonalityAnalysisDataSource.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation

/// Data source for personality analysis SwiftData operations
public protocol PersonalityAnalysisDataSourceProtocol: Sendable {
    /// Get the latest personality profile for a user
    func getLatestProfile(for userId: UUID) async throws -> PersonalityProfile?
    
    /// Save a personality profile
    func saveProfile(_ profile: PersonalityProfile) async throws
    
    /// Get profile history for a user
    func getProfileHistory(for userId: UUID) async throws -> [PersonalityProfile]
    
    /// Delete a specific profile
    func deleteProfile(profileId: String) async throws
    
    /// Delete all profiles for a user
    func deleteAllProfiles(for userId: UUID) async throws
}
