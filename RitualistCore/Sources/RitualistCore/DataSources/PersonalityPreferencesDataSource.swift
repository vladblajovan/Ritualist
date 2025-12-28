//
//  PersonalityPreferencesDataSource.swift
//  RitualistCore
//
//  Created by Claude on 14.11.2025.
//

import Foundation

/// Data source for managing personality analysis preferences
public protocol PersonalityPreferencesDataSource: Sendable {
    /// Get user's analysis preferences
    func getPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences?

    /// Save user's analysis preferences
    func savePreferences(_ preferences: PersonalityAnalysisPreferences) async throws
}

public final class DefaultPersonalityPreferencesDataSource: PersonalityPreferencesDataSource, Sendable {

    // UserDefaults is thread-safe but not Sendable, so we use nonisolated(unsafe)
    nonisolated(unsafe) private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func getPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
        if let data = userDefaults.data(forKey: UserDefaultsKeys.personalityPreferencesMainUser),
           let preferences = try? JSONDecoder().decode(PersonalityAnalysisPreferences.self, from: data) {
            return preferences
        }

        return nil
    }

    public func savePreferences(_ preferences: PersonalityAnalysisPreferences) async throws {
        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: UserDefaultsKeys.personalityPreferencesMainUser)
        } catch {
            throw PersonalityAnalysisError.dataEncodingFailed(underlying: error)
        }
    }
}
