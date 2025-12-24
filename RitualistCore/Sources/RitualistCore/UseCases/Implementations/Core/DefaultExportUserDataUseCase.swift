//
//  DefaultExportUserDataUseCase.swift
//  RitualistCore
//
//  Default implementation for exporting user data
//  GDPR Article 20 compliance - Right to data portability
//
//  PRIVACY NOTE: PersonalityAnalysis data is intentionally NOT exported.
//  This sensitive psychological data stays on-device only and is never
//  included in exports to protect user privacy.
//

import Foundation

public final class DefaultExportUserDataUseCase: ExportUserDataUseCase {
    private let loadProfile: LoadProfileUseCase
    private let getLastSyncDate: GetLastSyncDateUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let logDataSource: LogLocalDataSourceProtocol
    private let logger: DebugLogger

    public init(
        loadProfile: LoadProfileUseCase,
        getLastSyncDate: GetLastSyncDateUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        logDataSource: LogLocalDataSourceProtocol,
        logger: DebugLogger
    ) {
        self.loadProfile = loadProfile
        self.getLastSyncDate = getLastSyncDate
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.logDataSource = logDataSource
        self.logger = logger
    }

    public func execute() async throws -> String {
        // Load current profile
        let profile = try await loadProfile.execute()
        let lastSyncDate = await getLastSyncDate.execute()

        // Fetch all user data (excluding personality data for privacy)
        let habits = try await habitRepository.fetchAllHabits()
        let categories = try await categoryRepository.getAllCategories()

        // Fetch logs for all habits
        let habitIDs = habits.map { $0.id }
        let allLogs = try await logDataSource.logs(for: habitIDs)

        // Create export data structure
        // NOTE: PersonalityAnalysis is intentionally excluded for privacy
        let exportData = ExportedUserData(
            exportedAt: Date(),
            profile: ProfileData(
                name: profile.name,
                appearance: appearanceString(from: profile.appearance),
                currentTimezone: profile.currentTimezoneIdentifier,
                homeTimezone: profile.homeTimezoneIdentifier,
                displayTimezoneMode: profile.displayTimezoneMode.toLegacyString(),
                timezoneChangeHistory: profile.timezoneChangeHistory.map { change in
                    TimezoneChangeData(
                        fromTimezone: change.fromTimezone,
                        toTimezone: change.toTimezone,
                        changedAt: change.timestamp
                    )
                },
                createdAt: profile.createdAt,
                updatedAt: profile.updatedAt
            ),
            avatar: profile.avatarImageData?.base64EncodedString(),
            habits: habits,
            categories: categories,
            habitLogs: allLogs,
            syncMetadata: SyncMetadata(
                lastSynced: lastSyncDate,
                profileId: profile.id.uuidString
            )
        )

        // Encode to JSON with pretty printing
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(exportData)

        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        logger.log(
            "📤 Export completed (personality data excluded for privacy)",
            level: .info,
            category: .dataIntegrity,
            metadata: [
                "habits": habits.count,
                "categories": categories.count,
                "logs": allLogs.count
            ]
        )

        return jsonString
    }

    private func appearanceString(from value: Int) -> String {
        switch value {
        case 0: return "system"
        case 1: return "light"
        case 2: return "dark"
        default: return "unknown"
        }
    }
}

// MARK: - Export Data Models

private struct ExportedUserData: Codable {
    let exportedAt: Date
    let profile: ProfileData
    let avatar: String?
    let habits: [Habit]
    let categories: [HabitCategory]
    let habitLogs: [HabitLog]
    // NOTE: personalityData intentionally removed for privacy
    let syncMetadata: SyncMetadata
}

private struct ProfileData: Codable {
    let name: String
    let appearance: String
    let currentTimezone: String
    let homeTimezone: String
    let displayTimezoneMode: String
    let timezoneChangeHistory: [TimezoneChangeData]
    let createdAt: Date
    let updatedAt: Date
}

private struct TimezoneChangeData: Codable {
    let fromTimezone: String
    let toTimezone: String
    let changedAt: Date
}

private struct SyncMetadata: Codable {
    let lastSynced: Date?
    let profileId: String
}

// MARK: - Export Errors

public enum ExportError: LocalizedError {
    case encodingFailed

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode user data to JSON"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .encodingFailed:
            return "Try exporting again. If the problem persists, contact support."
        }
    }
}
