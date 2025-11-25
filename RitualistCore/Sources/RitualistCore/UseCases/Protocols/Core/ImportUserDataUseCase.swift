//
//  ImportUserDataUseCase.swift
//  RitualistCore
//
//  Protocol for importing user data from JSON export
//  GDPR Article 20 compliance - Right to data portability
//

import Foundation

/// Use case for importing user data from JSON export
public protocol ImportUserDataUseCase {
    /// Imports user data from a JSON string
    /// - Parameter jsonString: The JSON string containing exported user data
    /// - Throws: ImportError if parsing or import fails
    func execute(jsonString: String) async throws
}

// MARK: - Import Errors

public enum ImportError: LocalizedError {
    case invalidJSON
    case incompatibleFormat
    case missingRequiredFields
    case importFailed(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .invalidJSON:
            return "The file is not valid JSON"
        case .incompatibleFormat:
            return "The file format is not compatible with this app version"
        case .missingRequiredFields:
            return "The file is missing required data fields"
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
        case .importFailed:
            return "Try importing again. If the problem persists, contact support."
        }
    }
}
