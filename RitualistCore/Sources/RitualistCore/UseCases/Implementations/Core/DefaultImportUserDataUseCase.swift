//
//  DefaultImportUserDataUseCase.swift
//  RitualistCore
//
//  Default implementation for importing user data from JSON
//  GDPR Article 20 compliance - Right to data portability
//

import Foundation

public final class DefaultImportUserDataUseCase: ImportUserDataUseCase {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let personalityRepository: PersonalityAnalysisRepositoryProtocol
    private let logDataSource: LogLocalDataSourceProtocol
    private let updateLastSyncDate: UpdateLastSyncDateUseCase

    public init(
        loadProfile: LoadProfileUseCase,
        saveProfile: SaveProfileUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        personalityRepository: PersonalityAnalysisRepositoryProtocol,
        logDataSource: LogLocalDataSourceProtocol,
        updateLastSyncDate: UpdateLastSyncDateUseCase
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.personalityRepository = personalityRepository
        self.logDataSource = logDataSource
        self.updateLastSyncDate = updateLastSyncDate
    }

    public func execute(jsonString: String) async throws {
        // Parse JSON
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw ImportError.invalidJSON
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let importedData: ImportedUserData
        do {
            importedData = try decoder.decode(ImportedUserData.self, from: jsonData)
        } catch {
            throw ImportError.invalidJSON
        }

        // Validate required fields
        guard !importedData.profile.name.isEmpty else {
            throw ImportError.missingRequiredFields
        }

        do {
            // Import profile data
            try await importProfile(importedData.profile, avatar: importedData.avatar)

            // Import categories first (habits depend on them)
            try await importCategories(importedData.categories)

            // Import habits
            try await importHabits(importedData.habits)

            // Import habit logs
            try await importHabitLogs(importedData.habitLogs)

            // Import personality data
            try await importPersonalityData(importedData.personalityData)

            // Update last sync date if available
            if let lastSynced = importedData.syncMetadata.lastSynced {
                await updateLastSyncDate.execute(lastSynced)
            }

        } catch {
            throw ImportError.importFailed(underlying: error)
        }
    }

    // MARK: - Import Methods

    private func importProfile(_ profileData: ImportProfileData, avatar: String?) async throws {
        var currentProfile = try await loadProfile.execute()

        // Update profile with imported data
        currentProfile.name = profileData.name
        currentProfile.appearance = appearanceValue(from: profileData.appearance)
        currentProfile.currentTimezoneIdentifier = profileData.currentTimezone
        currentProfile.homeTimezoneIdentifier = profileData.homeTimezone
        currentProfile.displayTimezoneMode = DisplayTimezoneMode.fromLegacyString(profileData.displayTimezoneMode)

        // Import timezone history
        currentProfile.timezoneChangeHistory = profileData.timezoneChangeHistory.map { change in
            TimezoneChange(
                timestamp: change.changedAt,
                fromTimezone: change.fromTimezone,
                toTimezone: change.toTimezone,
                trigger: .userUpdate
            )
        }

        // Import avatar if available
        if let avatarBase64 = avatar, let avatarData = Data(base64Encoded: avatarBase64) {
            currentProfile.avatarImageData = avatarData
        }

        try await saveProfile.execute(currentProfile)
    }

    private func importCategories(_ categories: [HabitCategory]) async throws {
        // Get existing categories
        let existingCategories = try await categoryRepository.getAllCategories()
        let existingIDs = Set(existingCategories.map { $0.id })

        for category in categories {
            if existingIDs.contains(category.id) {
                // Update existing category
                try await categoryRepository.updateCategory(category)
            } else {
                // Create new category
                try await categoryRepository.createCustomCategory(category)
            }
        }
    }

    private func importHabits(_ habits: [Habit]) async throws {
        // Get existing habits
        let existingHabits = try await habitRepository.fetchAllHabits()
        let existingIDs = Set(existingHabits.map { $0.id })

        for habit in habits {
            if existingIDs.contains(habit.id) {
                // Update existing habit
                try await habitRepository.update(habit)
            } else {
                // Create new habit - need to insert it into SwiftData
                // Since HabitRepository doesn't have an insert method, we'll use update
                // which should insert if not exists
                try await habitRepository.update(habit)
            }
        }
    }

    private func importHabitLogs(_ logs: [HabitLog]) async throws {
        // Import all logs (upsert will handle duplicates)
        for log in logs {
            try await logDataSource.upsert(log)
        }
    }

    private func importPersonalityData(_ personalityData: ImportPersonalityData) async throws {
        // Get current profile to use correct user ID
        let currentProfile = try await loadProfile.execute()

        // Import current personality profile if available
        if let currentPersonality = personalityData.currentProfile {
            try await personalityRepository.savePersonalityProfile(currentPersonality)
        }

        // Import personality history
        for profile in personalityData.analysisHistory {
            // Only import if it doesn't already exist
            let existing = try? await personalityRepository.getPersonalityProfile(for: currentProfile.id)
            if existing?.id != profile.id {
                try await personalityRepository.savePersonalityProfile(profile)
            }
        }
    }

    // MARK: - Helper Methods

    private func appearanceValue(from string: String) -> Int {
        switch string.lowercased() {
        case "system": return 0
        case "light": return 1
        case "dark": return 2
        default: return 0
        }
    }
}

// MARK: - Import Data Models

private struct ImportedUserData: Codable {
    let exportedAt: Date
    let profile: ImportProfileData
    let avatar: String?
    let habits: [Habit]
    let categories: [HabitCategory]
    let habitLogs: [HabitLog]
    let personalityData: ImportPersonalityData
    let syncMetadata: ImportSyncMetadata
}

private struct ImportProfileData: Codable {
    let name: String
    let appearance: String
    let currentTimezone: String
    let homeTimezone: String
    let displayTimezoneMode: String
    let timezoneChangeHistory: [ImportTimezoneChangeData]
    let createdAt: Date
    let updatedAt: Date
}

private struct ImportTimezoneChangeData: Codable {
    let fromTimezone: String
    let toTimezone: String
    let changedAt: Date
}

private struct ImportPersonalityData: Codable {
    let currentProfile: PersonalityProfile?
    let analysisHistory: [PersonalityProfile]
}

private struct ImportSyncMetadata: Codable {
    let lastSynced: Date?
    let profileId: String
}
