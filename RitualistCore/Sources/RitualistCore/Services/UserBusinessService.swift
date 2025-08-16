//
//  UserBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// Thread-agnostic business logic for user profile operations
public protocol UserBusinessService {
    /// Get current user profile - delegates to ProfileRepository
    func getCurrentProfile() async throws -> UserProfile
    
    /// Check if user has premium features
    func isPremiumUser() async throws -> Bool
    
    /// Update user profile - syncs to both local and cloud
    func updateProfile(_ profile: UserProfile) async throws
    
    /// Update subscription after purchase - syncs to both local and cloud
    func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws
    
    /// Sync with iCloud (future implementation)
    func syncWithiCloud() async throws
}
