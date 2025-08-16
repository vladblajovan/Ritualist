//
//  UserService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// Simplified user service that manages the single UserProfile entity
/// No authentication required - designed for iCloud sync
/// Acts as a bridge between local ProfileRepository and cloud storage
public protocol UserService {
    /// Current user profile (includes subscription info) - delegates to ProfileRepository
    var currentProfile: UserProfile { get }
    
    /// Check if user has premium features
    var isPremiumUser: Bool { get }
    
    /// Update user profile - syncs to both local and cloud
    func updateProfile(_ profile: UserProfile) async throws
    
    /// Update subscription after purchase - syncs to both local and cloud
    func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws
    
    /// Sync with iCloud (future implementation)
    func syncWithiCloud() async throws
}
