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
    private let logger: DebugLogger

    public init(
        loadProfile: LoadProfileUseCase,
        saveProfile: SaveProfileUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        personalityRepository: PersonalityAnalysisRepositoryProtocol,
        logDataSource: LogLocalDataSourceProtocol,
        updateLastSyncDate: UpdateLastSyncDateUseCase,
        logger: DebugLogger
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.personalityRepository = personalityRepository
        self.logDataSource = logDataSource
        self.updateLastSyncDate = updateLastSyncDate
        self.logger = logger
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
        } catch let decodingError {
            // Log the underlying decode error for debugging before throwing user-friendly error
            logger.log(
                "Import JSON decode error",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": decodingError.localizedDescription]
            )
            throw ImportError.invalidJSON
        }

        // Validate required fields
        guard !importedData.profile.name.isEmpty else {
            throw ImportError.missingRequiredFields
        }

        // Validate profile ID format (must be valid UUID)
        guard UUID(uuidString: importedData.syncMetadata.profileId) != nil else {
            throw ImportError.invalidProfileId
        }

        // Validate data size limits to prevent malicious imports
        try validateDataLimits(importedData)

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

        // Import avatar if available and valid
        if let avatarBase64 = avatar, let avatarData = Data(base64Encoded: avatarBase64) {
            // Validate decoded data is actually an image before saving
            if isValidImageData(avatarData) {
                currentProfile.avatarImageData = avatarData
            } else {
                logger.log(
                    "Avatar import skipped - invalid image data",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["dataSize": avatarData.count]
                )
            }
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
        // HabitRepository.update() uses upsert semantics internally,
        // so it will insert new habits or update existing ones
        for habit in habits {
            try await habitRepository.update(habit)
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

    // MARK: - Validation

    private func validateDataLimits(_ data: ImportedUserData) throws {
        // Validate habits count
        guard data.habits.count <= ImportValidationLimits.maxHabits else {
            throw ImportError.dataTooLarge(reason: "Too many habits (\(data.habits.count) > \(ImportValidationLimits.maxHabits))")
        }

        // Validate habit logs count
        guard data.habitLogs.count <= ImportValidationLimits.maxHabitLogs else {
            throw ImportError.dataTooLarge(reason: "Too many habit logs (\(data.habitLogs.count) > \(ImportValidationLimits.maxHabitLogs))")
        }

        // Validate categories count
        guard data.categories.count <= ImportValidationLimits.maxCategories else {
            throw ImportError.dataTooLarge(reason: "Too many categories (\(data.categories.count) > \(ImportValidationLimits.maxCategories))")
        }

        // Validate avatar size
        if let avatarBase64 = data.avatar {
            guard avatarBase64.count <= ImportValidationLimits.maxAvatarBase64Length else {
                throw ImportError.dataTooLarge(reason: "Avatar image too large")
            }
        }

        // Validate profile name length
        guard data.profile.name.count <= ImportValidationLimits.maxProfileNameLength else {
            throw ImportError.dataTooLarge(reason: "Profile name too long")
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

    /// Validate that data represents a valid image by checking magic bytes
    private func isValidImageData(_ data: Data) -> Bool {
        guard data.count >= 8 else { return false }

        let bytes = [UInt8](data.prefix(8))

        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return true
        }

        // PNG: 89 50 4E 47 0D 0A 1A 0A
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
           bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A {
            return true
        }

        // HEIC/HEIF: Check for ftyp box with heic/mif1 brand (starts at byte 4)
        if data.count >= 12 {
            let ftypBytes = [UInt8](data[4..<8])
            if ftypBytes == [0x66, 0x74, 0x79, 0x70] { // "ftyp"
                return true
            }
        }

        return false
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
