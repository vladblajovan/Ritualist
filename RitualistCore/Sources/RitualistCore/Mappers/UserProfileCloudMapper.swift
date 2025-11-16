//
//  UserProfileCloudMapper.swift
//  RitualistCore
//
//  CloudKit mapper for UserProfile entity
//  Converts between domain UserProfile and CloudKit CKRecord
//

import Foundation
import CloudKit

/// Maps UserProfile domain entity to/from CloudKit CKRecord
/// Handles all field conversions including CKAsset for avatar images
public enum UserProfileCloudMapper {

    // MARK: - CloudKit Configuration

    /// Record type name in CloudKit schema
    public static let recordType = "UserProfile"

    /// CloudKit zone for UserProfile records (private database, default zone)
    public static let zoneID = CKRecordZone.default().zoneID

    // MARK: - Schema Versioning

    /// Current CloudKit schema version for UserProfile records
    /// Increment when adding/removing/changing fields to support migration
    /// - v1: Original schema with homeTimezone (String?) and displayTimezoneMode (String)
    /// - v2: Three-Timezone Model with currentTimezone, homeTimezone, displayMode, history
    private static let currentSchemaVersion = "v2"

    // MARK: - Field Names (must match CloudKit schema)

    private enum FieldKey {
        static let schemaVersion = "schemaVersion"  // Version tracking for migrations
        static let recordID = "recordID"
        static let name = "name"
        static let appearance = "appearance"

        // V2 Three-Timezone Model fields
        static let currentTimezoneIdentifier = "currentTimezoneIdentifier"
        static let homeTimezoneIdentifier = "homeTimezoneIdentifier"
        static let displayTimezoneMode = "displayTimezoneMode"
        static let timezoneChangeHistoryData = "timezoneChangeHistoryData"

        static let createdAt = "createdAt"
        static let updatedAt = "updatedAt"
        static let avatarAsset = "avatarAsset"

        // V1 Legacy fields (for migration compatibility)
        static let homeTimezone_v1 = "homeTimezone"  // Legacy V1 field
    }

    // MARK: - UserProfile → CKRecord

    /// Convert UserProfile domain entity to CloudKit CKRecord
    /// - Parameter profile: UserProfile to convert
    /// - Returns: CKRecord ready for CloudKit save operation
    /// - Throws: CloudMapperError if conversion fails
    public static func toCKRecord(_ profile: UserProfile) throws -> CKRecord {
        // Create CKRecord with UserProfile ID as recordName
        let recordID = CKRecord.ID(
            recordName: profile.id.uuidString,
            zoneID: zoneID
        )
        let record = CKRecord(recordType: recordType, recordID: recordID)

        // Set schema version for migration tracking
        record[FieldKey.schemaVersion] = currentSchemaVersion

        // Map basic fields
        record[FieldKey.recordID] = profile.id.uuidString
        record[FieldKey.name] = profile.name
        record[FieldKey.appearance] = Int64(profile.appearance)
        record[FieldKey.createdAt] = profile.createdAt
        record[FieldKey.updatedAt] = profile.updatedAt

        // Map V2 Three-Timezone Model fields
        record[FieldKey.currentTimezoneIdentifier] = profile.currentTimezoneIdentifier
        record[FieldKey.homeTimezoneIdentifier] = profile.homeTimezoneIdentifier

        // Encode DisplayTimezoneMode enum to string for CloudKit storage
        record[FieldKey.displayTimezoneMode] = profile.displayTimezoneMode.toLegacyString()

        // Encode timezone change history as Data (JSON)
        if let historyData = try? JSONEncoder().encode(profile.timezoneChangeHistory) {
            record[FieldKey.timezoneChangeHistoryData] = historyData
        } else {
            record[FieldKey.timezoneChangeHistoryData] = Data()  // Empty array if encoding fails
        }

        // Map avatar image as CKAsset
        if let avatarData = profile.avatarImageData {
            do {
                let asset = try createCKAsset(from: avatarData, filename: "avatar.jpg")
                record[FieldKey.avatarAsset] = asset
            } catch {
                throw CloudMapperError.assetCreationFailed(
                    underlying: error,
                    context: "Failed to create CKAsset for avatar image"
                )
            }
        }

        return record
    }

    // MARK: - CKRecord → UserProfile

    /// Convert CloudKit CKRecord to UserProfile domain entity
    /// - Parameter record: CKRecord from CloudKit fetch
    /// - Returns: UserProfile domain entity
    /// - Throws: CloudMapperError if required fields are missing or invalid
    public static func fromCKRecord(_ record: CKRecord) throws -> UserProfile {
        // Read schema version for backward compatibility
        // Default to v1 for old records that don't have schemaVersion field
        let schemaVersion = record[FieldKey.schemaVersion] as? String ?? "v1"

        // Extract and validate required fields
        guard let recordIDString = record[FieldKey.recordID] as? String,
              let id = UUID(uuidString: recordIDString) else {
            throw CloudMapperError.missingRequiredField(
                field: FieldKey.recordID,
                recordType: recordType
            )
        }

        guard let name = record[FieldKey.name] as? String else {
            throw CloudMapperError.missingRequiredField(
                field: FieldKey.name,
                recordType: recordType
            )
        }

        guard let appearanceInt64 = record[FieldKey.appearance] as? Int64 else {
            throw CloudMapperError.missingRequiredField(
                field: FieldKey.appearance,
                recordType: recordType
            )
        }
        let appearance = Int(appearanceInt64)

        guard let createdAt = record[FieldKey.createdAt] as? Date else {
            throw CloudMapperError.missingRequiredField(
                field: FieldKey.createdAt,
                recordType: recordType
            )
        }

        guard let updatedAt = record[FieldKey.updatedAt] as? Date else {
            throw CloudMapperError.missingRequiredField(
                field: FieldKey.updatedAt,
                recordType: recordType
            )
        }

        // Extract timezone fields based on schema version
        let currentTimezoneIdentifier: String
        let homeTimezoneIdentifier: String
        let displayTimezoneMode: DisplayTimezoneMode
        let timezoneChangeHistory: [TimezoneChange]

        if schemaVersion >= "v2" {
            // V2 schema: Three-Timezone Model
            currentTimezoneIdentifier = record[FieldKey.currentTimezoneIdentifier] as? String ?? TimeZone.current.identifier
            homeTimezoneIdentifier = record[FieldKey.homeTimezoneIdentifier] as? String ?? TimeZone.current.identifier

            // Decode displayTimezoneMode from string
            if let modeString = record[FieldKey.displayTimezoneMode] as? String {
                displayTimezoneMode = DisplayTimezoneMode.fromLegacyString(modeString)
            } else {
                displayTimezoneMode = .current  // Safe default
            }

            // Decode timezone change history from Data
            if let historyData = record[FieldKey.timezoneChangeHistoryData] as? Data,
               let history = try? JSONDecoder().decode([TimezoneChange].self, from: historyData) {
                timezoneChangeHistory = history
            } else {
                timezoneChangeHistory = []  // Empty history for new records
            }
        } else {
            // V1 schema: Legacy migration path
            // Initialize all three timezones to device timezone (safe default)
            currentTimezoneIdentifier = TimeZone.current.identifier

            // Try to preserve V1 homeTimezone if it existed
            if let legacyHomeTimezone = record[FieldKey.homeTimezone_v1] as? String {
                homeTimezoneIdentifier = legacyHomeTimezone
            } else {
                homeTimezoneIdentifier = TimeZone.current.identifier
            }

            // Convert V1 displayTimezoneMode string to V2 enum
            if let legacyModeString = record[FieldKey.displayTimezoneMode] as? String {
                displayTimezoneMode = DisplayTimezoneMode.fromLegacyString(legacyModeString)
            } else {
                displayTimezoneMode = .current
            }

            // No history in V1 records
            timezoneChangeHistory = []
        }

        // NOTE: Version-aware field parsing pattern for future migrations
        // Example pattern for version-aware field parsing:
        //
        // let favoriteColor: String?
        // if schemaVersion >= "v2" {
        //     favoriteColor = record[FieldKey.favoriteColor] as? String
        // } else {
        //     favoriteColor = nil  // v1 records don't have this field
        // }
        //
        // This ensures:
        // - v2.0 app reads v1 records → favoriteColor = nil (safe)
        // - v1.0 app reads v2 records → ignores favoriteColor (safe)
        // - No crashes, no data loss

        // Extract avatar image from CKAsset
        var avatarImageData: Data?
        if let avatarAsset = record[FieldKey.avatarAsset] as? CKAsset {
            do {
                avatarImageData = try extractData(from: avatarAsset)
            } catch {
                // Log warning but don't fail - avatar is optional
                DebugLogger(subsystem: "com.ritualist.app", category: "data").log("Failed to extract avatar asset: \(error.localizedDescription)", level: .warning, category: .dataIntegrity)
            }
        }

        // Construct UserProfile entity with V2 Three-Timezone Model
        return UserProfile(
            id: id,
            name: name,
            avatarImageData: avatarImageData,
            appearance: appearance,
            currentTimezoneIdentifier: currentTimezoneIdentifier,
            homeTimezoneIdentifier: homeTimezoneIdentifier,
            displayTimezoneMode: displayTimezoneMode,
            timezoneChangeHistory: timezoneChangeHistory,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - CKAsset Helpers

    /// Create CKAsset from image data
    /// - Parameters:
    ///   - data: Image data (JPEG, PNG, etc.)
    ///   - filename: Filename for temporary file
    /// - Returns: CKAsset ready for CloudKit upload
    /// - Throws: CloudMapperError if file operations fail
    private static func createCKAsset(from data: Data, filename: String) throws -> CKAsset {
        // Create temporary directory for CKAsset
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(filename)

        do {
            // Write data to temporary file
            try data.write(to: fileURL)

            // Create CKAsset from file URL
            let asset = CKAsset(fileURL: fileURL)
            return asset
        } catch {
            throw CloudMapperError.assetCreationFailed(
                underlying: error,
                context: "Failed to write avatar data to temporary file"
            )
        }
    }

    /// Extract data from CKAsset
    /// - Parameter asset: CKAsset from CloudKit record
    /// - Returns: Image data extracted from asset
    /// - Throws: CloudMapperError if file read fails
    private static func extractData(from asset: CKAsset) throws -> Data {
        guard let fileURL = asset.fileURL else {
            throw CloudMapperError.assetExtractionFailed(
                context: "CKAsset has no fileURL"
            )
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return data
        } catch {
            throw CloudMapperError.assetExtractionFailed(
                context: "Failed to read data from CKAsset file: \(error.localizedDescription)"
            )
        }
    }
}

// MARK: - CloudMapperError

/// Errors that can occur during UserProfile ↔ CKRecord mapping
public enum CloudMapperError: LocalizedError {
    case missingRequiredField(field: String, recordType: String)
    case invalidFieldValue(field: String, value: Any, expectedType: String)
    case assetCreationFailed(underlying: Error, context: String)
    case assetExtractionFailed(context: String)

    public var errorDescription: String? {
        switch self {
        case .missingRequiredField(let field, let recordType):
            return "Missing required field '\(field)' in CloudKit record type '\(recordType)'"
        case .invalidFieldValue(let field, let value, let expectedType):
            return "Invalid value for field '\(field)': got '\(value)', expected \(expectedType)"
        case .assetCreationFailed(let underlying, let context):
            return "Failed to create CKAsset: \(context). Underlying error: \(underlying.localizedDescription)"
        case .assetExtractionFailed(let context):
            return "Failed to extract data from CKAsset: \(context)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .missingRequiredField:
            return "Ensure CloudKit schema matches UserProfile entity structure. Check CloudKit Dashboard."
        case .invalidFieldValue:
            return "Verify data types in CloudKit schema match expected types."
        case .assetCreationFailed:
            return "Check file system permissions and available disk space."
        case .assetExtractionFailed:
            return "Verify CKAsset was properly uploaded to CloudKit."
        }
    }
}
