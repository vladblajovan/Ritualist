import Foundation
import SwiftData

/// @ModelActor implementation of ProfileLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor ProfileLocalDataSource: ProfileLocalDataSourceProtocol {

    /// Local logger instance - @ModelActor cannot use DI injection (SwiftData limitation)
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "data")

    /// Load user profile from background thread, return Domain model
    public func load() async throws -> UserProfile? {
        do {
            let descriptor = FetchDescriptor<ActiveUserProfileModel>()
            guard let profile = try modelContext.fetch(descriptor).first else {
                return nil
            }
            return profile.toEntity()
        } catch {
            logger.log(
                "Failed to load user profile",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }

    /// Save user profile on background thread - accepts Domain model
    public func save(_ profile: UserProfile) async throws {
        // Validate profile ID is not empty before saving
        guard !profile.id.uuidString.isEmpty else {
            logger.log(
                "Attempted to save profile with empty ID",
                level: .error,
                category: .dataIntegrity
            )
            throw ProfileDataSourceError.invalidProfileId
        }

        do {
            // Check if profile already exists
            let profileIdString = profile.id.uuidString
            let descriptor = FetchDescriptor<ActiveUserProfileModel>(
                predicate: #Predicate { $0.id == profileIdString }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                // Update existing profile - use fromEntity for consistent mapping
                existing.name = profile.name
                existing.avatarImageData = profile.avatarImageData
                existing.appearance = String(profile.appearance)

                // V9 Three-Timezone Model fields
                existing.currentTimezoneIdentifier = profile.currentTimezoneIdentifier
                existing.homeTimezoneIdentifier = profile.homeTimezoneIdentifier

                // Encode DisplayTimezoneMode to Data with proper error handling
                // CRITICAL: Don't use try? - it silently loses data on encoding failure
                do {
                    existing.displayTimezoneModeData = try JSONEncoder().encode(profile.displayTimezoneMode)
                } catch {
                    logger.log(
                        "Failed to encode displayTimezoneMode - keeping existing data",
                        level: .error,
                        category: .dataIntegrity,
                        metadata: [
                            "error": error.localizedDescription,
                            "profile_id": profileIdString,
                            "mode": String(describing: profile.displayTimezoneMode)
                        ]
                    )
                    // Don't update the field - keep existing valid data instead of corrupting it
                }

                // Encode timezone change history to Data with proper error handling
                do {
                    existing.timezoneChangeHistoryData = try JSONEncoder().encode(profile.timezoneChangeHistory)
                } catch {
                    logger.log(
                        "Failed to encode timezoneChangeHistory - keeping existing data",
                        level: .error,
                        category: .dataIntegrity,
                        metadata: [
                            "error": error.localizedDescription,
                            "profile_id": profileIdString,
                            "history_count": profile.timezoneChangeHistory.count
                        ]
                    )
                    // Don't update the field - keep existing valid data
                }

                // V11 Demographics fields
                existing.gender = profile.gender
                existing.ageGroup = profile.ageGroup

                existing.updatedAt = profile.updatedAt

                logger.log(
                    "Updated existing profile",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["profile_id": profileIdString]
                )
            } else {
                // Create new profile in this ModelContext
                let userProfileModel = ActiveUserProfileModel.fromEntity(profile)

                // Validate that encoding succeeded (fromEntity uses try? with empty Data fallback)
                // Log warning if timezone data appears to be lost during encoding
                if !profile.timezoneChangeHistory.isEmpty && userProfileModel.timezoneChangeHistoryData.isEmpty {
                    logger.log(
                        "New profile timezone history encoding may have failed - empty data stored",
                        level: .warning,
                        category: .dataIntegrity,
                        metadata: [
                            "profile_id": profileIdString,
                            "expected_history_count": profile.timezoneChangeHistory.count
                        ]
                    )
                }

                modelContext.insert(userProfileModel)

                logger.log(
                    "Created new profile",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["profile_id": profileIdString]
                )
            }

            try modelContext.save()
        } catch {
            logger.log(
                "Failed to save user profile",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "error": error.localizedDescription,
                    "profile_id": profile.id.uuidString
                ]
            )
            throw error
        }
    }
}

// MARK: - Profile Data Source Errors

public enum ProfileDataSourceError: LocalizedError {
    case invalidProfileId

    public var errorDescription: String? {
        switch self {
        case .invalidProfileId:
            return "Cannot save profile with empty or invalid ID"
        }
    }
}
