//
//  DefaultImportUserDataUseCase.swift
//  RitualistCore
//
//  Default implementation for importing user data from JSON
//  GDPR Article 20 compliance - Right to data portability
//
//  PRIVACY NOTE: PersonalityAnalysis data is intentionally NOT imported.
//  This sensitive psychological data stays on-device only. Any personality
//  data in old exports is silently ignored to protect user privacy.
//

import Foundation
import SwiftData

public final class DefaultImportUserDataUseCase: ImportUserDataUseCase, @unchecked Sendable {
    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let logDataSource: LogLocalDataSourceProtocol
    private let updateLastSyncDate: UpdateLastSyncDateUseCase
    private let validationService: ImportValidationService
    private let modelContext: ModelContext
    private let logger: DebugLogger

    public init(
        loadProfile: LoadProfileUseCase,
        saveProfile: SaveProfileUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        logDataSource: LogLocalDataSourceProtocol,
        updateLastSyncDate: UpdateLastSyncDateUseCase,
        validationService: ImportValidationService,
        modelContext: ModelContext,
        logger: DebugLogger
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.logDataSource = logDataSource
        self.updateLastSyncDate = updateLastSyncDate
        self.validationService = validationService
        self.modelContext = modelContext
        self.logger = logger
    }

    public func execute(jsonString: String) async throws -> ImportResult {
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

        // Field-level validation of habits, categories, and logs
        let habitValidation = validationService.validateHabits(importedData.habits)
        let categoryErrors = validationService.validateCategories(importedData.categories)
        let logErrors = validationService.validateHabitLogs(importedData.habitLogs)

        // Combine all validation errors
        var allErrors: [ImportValidationError] = habitValidation.errors
        allErrors.append(contentsOf: categoryErrors)
        allErrors.append(contentsOf: logErrors)

        if !allErrors.isEmpty {
            logger.log(
                "Import validation failed",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "totalErrors": allErrors.count,
                    "habitErrors": habitValidation.errors.count,
                    "categoryErrors": categoryErrors.count,
                    "logErrors": logErrors.count
                ]
            )
            throw ImportError.validationFailed(
                errorCount: allErrors.count,
                firstError: allErrors.first?.errorDescription ?? "Unknown error"
            )
        }

        logger.log(
            "Import validation passed",
            level: .info,
            category: .dataIntegrity,
            metadata: [
                "habits": importedData.habits.count,
                "categories": importedData.categories.count,
                "logs": importedData.habitLogs.count,
                "hasLocationConfigs": habitValidation.hasLocationConfigurations
            ]
        )

        // ============================================================
        // VALIDATION PASSED - Safe to clear existing data
        // ============================================================
        // Clear existing habits, logs, and categories BEFORE importing
        // to ensure we get exactly what's in the JSON.
        // This prevents merge conflicts and ensures deterministic imports.
        //
        // NOTE: We keep:
        // - UserProfile: Updated by import (not deleted)
        // - OnboardingState: Should persist (don't re-show onboarding)
        // - PersonalityAnalysis: NEVER touched - stays on device for privacy
        // ============================================================

        do {
            logger.log(
                "📥 Import validation passed, clearing existing data before import",
                level: .info,
                category: .dataIntegrity,
                metadata: [
                    "habits_to_import": importedData.habits.count,
                    "logs_to_import": importedData.habitLogs.count,
                    "categories_to_import": importedData.categories.count
                ]
            )

            try await clearExistingData()

            // Import profile data (updates existing profile, doesn't create new)
            try await importProfile(importedData.profile, avatar: importedData.avatar)

            // Import categories first (habits depend on them)
            try await importCategories(importedData.categories)

            // Import habits
            try await importHabits(importedData.habits)

            // Import habit logs (with start date validation)
            try await importHabitLogs(importedData.habitLogs, habits: importedData.habits)

            // NOTE: PersonalityAnalysis is intentionally NOT imported for privacy.
            // Any personality data in old exports is silently ignored.
            // The user's existing personality data on this device is preserved.

            // Update last sync date if available
            if let lastSynced = importedData.syncMetadata.lastSynced {
                await updateLastSyncDate.execute(lastSynced)
            }

            logger.log(
                "✅ Import completed successfully",
                level: .info,
                category: .dataIntegrity,
                metadata: [
                    "habits_imported": importedData.habits.count,
                    "logs_imported": importedData.habitLogs.count,
                    "categories_imported": importedData.categories.count,
                    "hasLocationConfigs": habitValidation.hasLocationConfigurations
                ]
            )

            // NOTE: Notification rescheduling and geofence restoration are handled
            // by the caller (SettingsViewModel) after import completes successfully.
            // This avoids MainActor isolation issues with CLLocationManager.

            return ImportResult(
                hasLocationConfigurations: habitValidation.hasLocationConfigurations,
                habitsImported: importedData.habits.count,
                habitLogsImported: importedData.habitLogs.count,
                categoriesImported: importedData.categories.count
            )

        } catch {
            logger.log(
                "❌ Import failed with error",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "error": error.localizedDescription,
                    "errorType": String(describing: type(of: error)),
                    "fullError": String(describing: error)
                ]
            )
            throw ImportError.importFailed(underlying: error)
        }
    }

    // MARK: - Clear Existing Data

    /// Clears existing user data before import to ensure a clean slate.
    /// This guarantees the imported data exactly matches the JSON file.
    ///
    /// Clears: Habits, HabitLogs, Categories
    /// Keeps:
    /// - UserProfile: Updated by import (not deleted)
    /// - OnboardingState: Should persist (don't re-show onboarding)
    /// - PersonalityAnalysis: NEVER touched - stays on device for privacy
    private func clearExistingData() async throws {
        try await MainActor.run {
            // CRITICAL: Use fetch-and-delete instead of batch delete
            // Batch delete (modelContext.delete(model:)) doesn't work reliably
            // across multiple stores. Fetch-and-delete is more reliable.
            // Order matters: delete children before parents to respect relationships

            // 1. Delete all habit logs first (child of habits)
            let habitLogs = try modelContext.fetch(FetchDescriptor<ActiveHabitLogModel>())
            for log in habitLogs {
                modelContext.delete(log)
            }

            // 2. Delete habits (references categories)
            let habits = try modelContext.fetch(FetchDescriptor<ActiveHabitModel>())
            for habit in habits {
                modelContext.delete(habit)
            }

            // 3. Delete categories
            let categories = try modelContext.fetch(FetchDescriptor<ActiveHabitCategoryModel>())
            for category in categories {
                modelContext.delete(category)
            }

            // NOTE: Do NOT delete:
            // - UserProfile: Will be updated by importProfile()
            // - OnboardingState: Should persist (don't re-show onboarding)
            // - PersonalityAnalysis: Privacy-sensitive, stays on device

            // Save deletions
            try modelContext.save()

            logger.log(
                "🗑️ Cleared existing data before import (personality data preserved)",
                level: .debug,
                category: .dataIntegrity
            )
        }
    }

    // MARK: - Import Methods

    private func importProfile(_ profileData: ImportProfileData, avatar: String?) async throws {
        var currentProfile = try await loadProfile.execute()

        // Update profile with imported data
        currentProfile.name = profileData.name
        currentProfile.appearance = appearanceValue(from: profileData.appearance)

        // Validate and set timezone identifiers (fall back to current if invalid)
        if TimeZone(identifier: profileData.currentTimezone) != nil {
            currentProfile.currentTimezoneIdentifier = profileData.currentTimezone
        } else {
            logger.log(
                "Invalid currentTimezone identifier, keeping existing",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["invalidTimezone": profileData.currentTimezone]
            )
        }

        if TimeZone(identifier: profileData.homeTimezone) != nil {
            currentProfile.homeTimezoneIdentifier = profileData.homeTimezone
        } else {
            logger.log(
                "Invalid homeTimezone identifier, keeping existing",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["invalidTimezone": profileData.homeTimezone]
            )
        }

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
        // Clean slate - just create all categories from the import
        for category in categories {
            try await categoryRepository.createCustomCategory(category)
        }
    }

    private func importHabits(_ habits: [Habit]) async throws {
        // Clean slate - insert all habits from the import
        for habit in habits {
            try await habitRepository.update(habit)
        }
    }

    private func importHabitLogs(_ logs: [HabitLog], habits: [Habit]) async throws {
        // Build habit lookup by ID for start date validation
        let habitById = Dictionary(uniqueKeysWithValues: habits.map { ($0.id, $0) })

        var skippedCount = 0

        // Clean slate - insert all valid logs from the import
        for log in logs {
            // Validate log date is not before habit's start date
            if let habit = habitById[log.habitID] {
                let logDay = CalendarUtils.startOfDayLocal(for: log.date)
                let startDay = CalendarUtils.startOfDayLocal(for: habit.startDate)

                if logDay < startDay {
                    // Skip logs that are before the habit's start date
                    skippedCount += 1
                    continue
                }
            }
            // If habit not found, still import the log (orphan handling is separate)

            try await logDataSource.upsert(log)
        }

        if skippedCount > 0 {
            logger.log(
                "⚠️ Skipped logs during import - dates before habit start",
                level: .warning,
                category: .dataIntegrity,
                metadata: ["skipped_logs": skippedCount]
            )
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
    // NOTE: personalityData intentionally removed - never imported for privacy
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

private struct ImportSyncMetadata: Codable {
    let lastSynced: Date?
    let profileId: String
}
