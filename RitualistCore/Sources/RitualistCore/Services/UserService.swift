//
//  UserService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation
import Observation

/// Simplified user service that manages the single UserProfile entity
/// No authentication required - designed for iCloud sync
/// Acts as a bridge between local ProfileRepository and cloud storage
public protocol UserService: Sendable {
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

// MARK: - Implementations

@Observable
public final class MockUserService: UserService, @unchecked Sendable {
    private var _currentProfile = UserProfile()
    private let loadProfile: LoadProfileUseCase?
    private let saveProfile: SaveProfileUseCase?
    private let errorHandler: ErrorHandler?
    
    // Store different test subscription states for easy switching
    private let testSubscriptionStates: [String: (SubscriptionPlan, Date?)] = [
        "free": (.free, nil),
        "monthly": (.monthly, CalendarUtils.addMonths(1, to: Date())),
        "annual": (.annual, CalendarUtils.addYears(1, to: Date()))
    ]
    
    public init(
        loadProfile: LoadProfileUseCase? = nil, 
        saveProfile: SaveProfileUseCase? = nil,
        errorHandler: ErrorHandler? = nil
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.errorHandler = errorHandler
        
        // Initialize with default profile - will be loaded from repository if available
        _currentProfile = UserProfile(name: "")
        
        // Load actual profile data from repository
        Task {
            await loadInitialProfile()
        }
    }
    
    private func loadInitialProfile() async {
        guard let loadProfile = loadProfile else { return }
        
        do {
            let profile = try await loadProfile.execute()
            _currentProfile = profile
        } catch {
            // Log the error but keep the default profile
            await errorHandler?.logError(
                error,
                context: ErrorContext.userInterface + "_profile_load",
                additionalProperties: ["operation": "loadInitialProfile"]
            )
        }
    }
    
    public var currentProfile: UserProfile {
        _currentProfile
    }
    
    public var isPremiumUser: Bool {
        // NOTE: Subscription status is now managed by SubscriptionService
        // This property is deprecated
        #if ALL_FEATURES_ENABLED
        return true
        #else
        return false  // Use SubscriptionService for actual premium checks
        #endif
    }
    
    public func updateProfile(_ profile: UserProfile) async throws {
        // Simulate network delay for mock
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        _currentProfile = profile
        _currentProfile.updatedAt = Date()
        
        // Sync back to repository to maintain consistency
        if let saveProfile = saveProfile {
            do {
                try await saveProfile.execute(_currentProfile)
            } catch {
                // Log the sync error but continue
                await errorHandler?.logError(
                    error,
                    context: ErrorContext.userInterface + "_profile_sync",
                    additionalProperties: [
                        "operation": "updateProfile_sync",
                        "profile_name": profile.name ?? "unnamed"
                    ]
                )
            }
        }
        
        // TODO: In production, also sync to iCloud here
    }
    
    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        // NOTE: Subscription management is now handled by SubscriptionService
        // This method is deprecated and no longer updates profile
        // Simulate network delay for compatibility
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
    
    public func syncWithiCloud() async throws {
        // Mock implementation - just simulate delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // TODO: Implement iCloud sync
    }
    
    // MARK: - Test Helpers
    
    /// Switch to a different test subscription state (for development)
    /// NOTE: Deprecated - subscription state is now managed by SubscriptionService
    public func switchToTestSubscription(_ type: String) {
        // No-op: Subscription state no longer stored in profile
    }
}

@Observable
public final class ICloudUserService: UserService, @unchecked Sendable {
    private var _currentProfile = UserProfile()
    private let errorHandler: ErrorHandler?
    
    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler
        // Initialize with default profile
        _currentProfile = UserProfile()
        
        // TODO: Implement CloudKit integration
        // - Create CKRecord for user profile
        // - Set up CloudKit subscriptions for real-time sync
        // - Handle conflict resolution
    }
    
    public var currentProfile: UserProfile {
        _currentProfile
    }
    
    public var isPremiumUser: Bool {
        // NOTE: Subscription status is now managed by SubscriptionService
        // This property is deprecated
        #if ALL_FEATURES_ENABLED
        return true
        #else
        return false  // Use SubscriptionService for actual premium checks
        #endif
    }
    
    public func updateProfile(_ profile: UserProfile) async throws {
        _currentProfile = profile
        _currentProfile.updatedAt = Date()
        
        // TODO: Save to CloudKit and handle sync conflicts
    }
    
    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        // NOTE: Subscription management is now handled by SubscriptionService
        // This method is deprecated and no longer updates profile
        // No-op for compatibility
    }
    
    public func syncWithiCloud() async throws {
        // TODO: Implement CloudKit sync
        // - Fetch latest from iCloud
        // - Merge with local changes using updatedAt timestamps
        // - Push updates
        // - Handle conflict resolution (local vs cloud)
    }
}

@Observable
public final class NoOpUserService: UserService {
    public let currentProfile = UserProfile()
    public let isPremiumUser = false
    
    public init() {}
    
    public func updateProfile(_ profile: UserProfile) async throws {}
    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {}
    public func syncWithiCloud() async throws {}
}
