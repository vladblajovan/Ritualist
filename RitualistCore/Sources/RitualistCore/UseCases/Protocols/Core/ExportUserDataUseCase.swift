//
//  ExportUserDataUseCase.swift
//  RitualistCore
//
//  Use case for exporting user's data
//  Implements GDPR Article 20 (Right to data portability)
//

import Foundation

/// Use case for exporting user's profile data as JSON
/// This implements GDPR Article 20 (Right to data portability)
public protocol ExportUserDataUseCase: Sendable {
    /// Exports the user's profile data as a JSON string
    /// - Returns: JSON string containing all user data
    /// - Throws: Error if export fails
    func execute() async throws -> String
}
