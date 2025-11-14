//
//  PersonalityPreferencesDataSource.swift
//  RitualistCore
//
//  Created by Claude on 14.11.2025.
//

import Foundation

/// Data source for managing personality analysis preferences
public protocol PersonalityPreferencesDataSource {
    /// Get user's analysis preferences
    func getPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences?

    /// Save user's analysis preferences
    func savePreferences(_ preferences: PersonalityAnalysisPreferences) async throws
}

public final class DefaultPersonalityPreferencesDataSource: PersonalityPreferencesDataSource {

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func getPreferences(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
        let key = "personality_preferences_main_user"

        if let data = userDefaults.data(forKey: key),
           let preferences = try? JSONDecoder().decode(PersonalityAnalysisPreferences.self, from: data) {
            return preferences
        }

        // Migration logic for old userId-based keys
        let oldKey = "personality_preferences_\(userId.uuidString)"
        if let oldData = userDefaults.data(forKey: oldKey),
           let oldPreferences = try? JSONDecoder().decode(PersonalityAnalysisPreferences.self, from: oldData) {
            userDefaults.set(oldData, forKey: key)
            userDefaults.removeObject(forKey: oldKey)
            return oldPreferences
        }

        return nil
    }

    public func savePreferences(_ preferences: PersonalityAnalysisPreferences) async throws {
        let key = "personality_preferences_main_user"

        if let data = try? JSONEncoder().encode(preferences) {
            userDefaults.set(data, forKey: key)
        } else {
            throw PersonalityAnalysisError.dataEncodingFailed
        }
    }
}
