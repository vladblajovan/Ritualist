//
//  DeleteiCloudDataUseCase.swift
//  RitualistCore
//
//  Use case for deleting user's iCloud data
//  Implements GDPR "Right to be forgotten"
//

import Foundation

/// Use case for deleting user's profile data from iCloud
/// This implements GDPR Article 17 (Right to erasure/"Right to be forgotten")
public protocol DeleteiCloudDataUseCase {
    /// Permanently deletes the user's profile from iCloud CloudKit
    /// Local data remains intact on the device
    /// - Throws: Error if deletion fails
    func execute() async throws
}
