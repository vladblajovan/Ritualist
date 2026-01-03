//
//  ProfileLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Protocol for local user profile data source operations
public protocol ProfileLocalDataSourceProtocol: Sendable {
    /// Load the user profile from local storage
    func load() async throws -> UserProfile?
    
    /// Save the user profile to local storage
    func save(_ profile: UserProfile) async throws
}
