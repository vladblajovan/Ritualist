//
//  ImportUserDataUseCase.swift
//  RitualistCore
//
//  Protocol for importing user data from JSON export
//  GDPR Article 20 compliance - Right to data portability
//

import Foundation

/// Result of a successful import operation
public struct ImportResult {
    /// Whether any imported habits have location configurations
    public let hasLocationConfigurations: Bool

    /// Number of habits imported
    public let habitsImported: Int

    /// Number of habit logs imported
    public let habitLogsImported: Int

    /// Number of categories imported
    public let categoriesImported: Int

    public init(
        hasLocationConfigurations: Bool,
        habitsImported: Int,
        habitLogsImported: Int,
        categoriesImported: Int
    ) {
        self.hasLocationConfigurations = hasLocationConfigurations
        self.habitsImported = habitsImported
        self.habitLogsImported = habitLogsImported
        self.categoriesImported = categoriesImported
    }
}

/// Use case for importing user data from JSON export
public protocol ImportUserDataUseCase: Sendable {
    /// Imports user data from a JSON string
    /// - Parameter jsonString: The JSON string containing exported user data
    /// - Returns: Import result containing metadata about what was imported
    /// - Throws: ImportError if parsing or import fails
    func execute(jsonString: String) async throws -> ImportResult
}

// MARK: - Import Errors

public enum ImportError: LocalizedError {
    case invalidJSON
    case incompatibleFormat
    case missingRequiredFields
    case invalidProfileId
    case dataTooLarge(reason: String)
    case validationFailed(errorCount: Int, firstError: String)
    case importFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "The file is not valid JSON"
        case .incompatibleFormat:
            return "The file format is not compatible with this app version"
        case .missingRequiredFields:
            return "The file is missing required data fields"
        case .invalidProfileId:
            return "The file contains an invalid profile identifier"
        case .dataTooLarge(let reason):
            return "The import data is too large: \(reason)"
        case .validationFailed(let errorCount, let firstError):
            return "Import data validation failed: \(firstError)" + (errorCount > 1 ? " (and \(errorCount - 1) more issues)" : "")
        case .importFailed(let error):
            return "Import failed: \(error.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidJSON:
            return "Make sure you're importing a valid Ritualist export file."
        case .incompatibleFormat:
            return "This file may be from a different version of Ritualist or another app."
        case .missingRequiredFields:
            return "The export file is incomplete. Try exporting again."
        case .invalidProfileId:
            return "The file may be corrupted or from an incompatible source."
        case .dataTooLarge:
            return "The import file contains too much data. Contact support if this is unexpected."
        case .validationFailed:
            return "The import file contains invalid data. Check for corrupted values or try exporting again."
        case .importFailed:
            return "Try importing again. If the problem persists, contact support."
        }
    }
}

// MARK: - Import Validation Limits

public enum ImportValidationLimits {
    /// Maximum number of habits allowed in import
    public static let maxHabits = 1000
    /// Maximum number of habit logs allowed in import
    public static let maxHabitLogs = 100_000
    /// Maximum number of categories allowed in import
    public static let maxCategories = 100
    /// Maximum avatar size in bytes (~7.5MB base64 encoded)
    public static let maxAvatarBase64Length = 10_000_000
    /// Maximum profile name length
    public static let maxProfileNameLength = 200
}
