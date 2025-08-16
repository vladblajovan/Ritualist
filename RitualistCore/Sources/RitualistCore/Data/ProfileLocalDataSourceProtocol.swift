//
//  ProfileLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Protocol for local user profile data source operations
public protocol ProfileLocalDataSourceProtocol {
    /// Load the user profile from local storage
    func load() async throws -> UserProfile?
    
    /// Save the user profile to local storage
    func save(_ profile: UserProfile) async throws
}