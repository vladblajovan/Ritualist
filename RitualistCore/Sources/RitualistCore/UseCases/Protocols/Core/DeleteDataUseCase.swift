//
//  DeleteDataUseCase.swift
//  RitualistCore
//
//  Use case for deleting all user data
//  Implements GDPR "Right to be forgotten"
//

import Foundation

/// Use case for deleting all user data (local and CloudKit-synced)
/// This implements GDPR Article 17 (Right to erasure/"Right to be forgotten")
public protocol DeleteDataUseCase: Sendable {
    /// Permanently deletes all user data from the device
    /// CloudKit will sync deletions when available
    /// - Throws: Error if deletion fails
    func execute() async throws
}
