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

// MARK: - Implementations

/// Mock implementation for testing and development
public final class MockUserBusinessService: UserBusinessService {
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
        _currentProfile = UserProfile(name: "", subscriptionPlan: .free)
        
        // Load actual profile data from repository
        Task {
            await loadInitialProfile()
        }
    }
    
    public func getCurrentProfile() async throws -> UserProfile {
        return _currentProfile
    }
    
    public func isPremiumUser() async throws -> Bool {
        // If all features are enabled at build time, always return true for mock service
        #if ALL_FEATURES_ENABLED
        return true
        #else
        return _currentProfile.isPremiumUser
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
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        _currentProfile.subscriptionPlan = plan
        _currentProfile.subscriptionExpiryDate = expiryDate
        _currentProfile.updatedAt = Date()
        
        // TODO: In production, also sync to iCloud here
    }
    
    public func syncWithiCloud() async throws {
        // Mock implementation - just simulate delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        // TODO: Implement iCloud sync
    }
    
    // MARK: - Private Methods
    
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
    
    // MARK: - Test Helpers
    
    /// Switch to a different test subscription state (for development)
    public func switchToTestSubscription(_ type: String) {
        guard let (plan, expiryDate) = testSubscriptionStates[type] else { return }
        
        _currentProfile.subscriptionPlan = plan
        _currentProfile.subscriptionExpiryDate = expiryDate
        _currentProfile.updatedAt = Date()
    }
}

/// iCloud-based implementation for production use
public final class ICloudUserBusinessService: UserBusinessService {
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
    
    public func getCurrentProfile() async throws -> UserProfile {
        return _currentProfile
    }
    
    public func isPremiumUser() async throws -> Bool {
        // If all features are enabled at build time, always return true
        #if ALL_FEATURES_ENABLED
        return true
        #else
        return _currentProfile.isPremiumUser
        #endif
    }
    
    public func updateProfile(_ profile: UserProfile) async throws {
        _currentProfile = profile
        _currentProfile.updatedAt = Date()
        
        // TODO: Save to CloudKit and handle sync conflicts
    }
    
    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        _currentProfile.subscriptionPlan = plan
        _currentProfile.subscriptionExpiryDate = expiryDate
        _currentProfile.updatedAt = Date()
        
        // TODO: Update subscription info in CloudKit
    }
    
    public func syncWithiCloud() async throws {
        // TODO: Implement CloudKit sync
        // - Fetch latest from iCloud
        // - Merge with local changes using updatedAt timestamps
        // - Push updates
        // - Handle conflict resolution (local vs cloud)
    }
}
