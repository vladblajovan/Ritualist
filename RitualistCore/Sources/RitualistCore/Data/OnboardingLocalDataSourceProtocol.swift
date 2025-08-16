//
//  OnboardingLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
//

import Foundation

/// Protocol for local onboarding state data source operations
public protocol OnboardingLocalDataSourceProtocol {
    /// Load the onboarding state from local storage
    func load() async throws -> OnboardingState?
    
    /// Save the onboarding state to local storage
    func save(_ state: OnboardingState) async throws
}