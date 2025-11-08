//
//  UserBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation
import CloudKit

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
/// Uses CloudKit private database for cross-device UserProfile sync
public final class ICloudUserBusinessService: UserBusinessService {
    private var _currentProfile: UserProfile
    private let errorHandler: ErrorHandler?
    private let syncErrorHandler: CloudSyncErrorHandler
    private let container: CKContainer
    private let privateDatabase: CKDatabase

    /// Initialize with CloudKit container
    /// - Parameter errorHandler: Optional error handler for logging
    public init(errorHandler: ErrorHandler? = nil) {
        self.errorHandler = errorHandler
        self.syncErrorHandler = CloudSyncErrorHandler(
            errorHandler: errorHandler,
            maxRetries: 3,
            baseDelay: 1.0
        )

        // Initialize CloudKit container
        self.container = CKContainer(identifier: "iCloud.com.vladblajovan.Ritualist")
        self.privateDatabase = container.privateCloudDatabase

        // Initialize with default profile
        self._currentProfile = UserProfile()

        // Validate CloudKit availability and load profile (async)
        Task {
            do {
                // Check if user is signed into iCloud
                try await syncErrorHandler.validateCloudKitAvailability()

                // Load profile from CloudKit with retry logic
                _currentProfile = try await syncErrorHandler.executeWithRetry(
                    operation: { try await self.loadProfileFromCloud() },
                    operationName: "initial_profile_load"
                )
            } catch let error as CloudKitAvailabilityError {
                // iCloud not available - log and continue with local-only mode
                await errorHandler?.logError(
                    error,
                    context: ErrorContext.sync + "_icloud_unavailable",
                    additionalProperties: ["operation": "init_load_profile", "mode": "local_only"]
                )
            } catch {
                // Other errors - log but continue with default profile
                await errorHandler?.logError(
                    error,
                    context: ErrorContext.sync + "_cloud_initial_load",
                    additionalProperties: ["operation": "init_load_profile"]
                )
            }
        }
    }

    public func getCurrentProfile() async throws -> UserProfile {
        // Fetch latest from CloudKit with retry logic
        do {
            let cloudProfile = try await syncErrorHandler.executeWithRetry(
                operation: { try await self.loadProfileFromCloud() },
                operationName: "get_current_profile"
            )
            _currentProfile = cloudProfile
            return cloudProfile
        } catch {
            // If CloudKit fetch fails after retries, return cached profile
            await errorHandler?.logError(
                error,
                context: ErrorContext.sync + "_cloud_get_profile_failed",
                additionalProperties: ["operation": "getCurrentProfile", "using_cached": "true"]
            )
            return _currentProfile
        }
    }

    public func isPremiumUser() async throws -> Bool {
        // If all features are enabled at build time, always return true
        #if ALL_FEATURES_ENABLED
        return true
        #else
        let profile = try await getCurrentProfile()
        return profile.isPremiumUser
        #endif
    }

    public func updateProfile(_ profile: UserProfile) async throws {
        var updatedProfile = profile
        updatedProfile.updatedAt = Date()

        // Save to CloudKit with retry logic
        try await syncErrorHandler.executeWithRetry(
            operation: { try await self.saveProfileToCloud(updatedProfile) },
            operationName: "update_profile"
        )

        // Update local cache
        _currentProfile = updatedProfile
    }

    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        var updatedProfile = _currentProfile
        updatedProfile.subscriptionPlan = plan
        updatedProfile.subscriptionExpiryDate = expiryDate
        updatedProfile.updatedAt = Date()

        // Save to CloudKit with retry logic
        try await syncErrorHandler.executeWithRetry(
            operation: { try await self.saveProfileToCloud(updatedProfile) },
            operationName: "update_subscription"
        )

        // Update local cache
        _currentProfile = updatedProfile
    }

    public func syncWithiCloud() async throws {
        // Fetch latest from CloudKit with retry logic
        let cloudProfile = try await syncErrorHandler.executeWithRetry(
            operation: { try await self.loadProfileFromCloud() },
            operationName: "sync_fetch"
        )

        // Resolve conflicts using Last-Write-Wins
        let resolvedProfile = resolveConflict(local: _currentProfile, cloud: cloudProfile)

        // If resolved profile is different from cloud, push update with retry
        if resolvedProfile.updatedAt > cloudProfile.updatedAt {
            try await syncErrorHandler.executeWithRetry(
                operation: { try await self.saveProfileToCloud(resolvedProfile) },
                operationName: "sync_push"
            )
        }

        // Update local cache
        _currentProfile = resolvedProfile
    }

    // MARK: - Private CloudKit Operations

    /// Load UserProfile from CloudKit private database
    /// - Returns: UserProfile from CloudKit
    /// - Throws: CloudKitSyncError if fetch fails
    private func loadProfileFromCloud() async throws -> UserProfile {
        // Create record ID from profile UUID
        let recordID = CKRecord.ID(
            recordName: _currentProfile.id.uuidString,
            zoneID: UserProfileCloudMapper.zoneID
        )

        do {
            // Fetch record from CloudKit
            let record = try await privateDatabase.record(for: recordID)

            // Convert CKRecord to UserProfile
            let profile = try UserProfileCloudMapper.fromCKRecord(record)
            return profile

        } catch let error as CKError where error.code == .unknownItem {
            // Profile doesn't exist in CloudKit yet - this is expected on first use
            // Return default profile
            return UserProfile()

        } catch {
            throw CloudKitSyncError.fetchFailed(
                underlying: error,
                context: "Failed to load UserProfile from CloudKit"
            )
        }
    }

    /// Save UserProfile to CloudKit private database
    /// - Parameter profile: UserProfile to save
    /// - Throws: CloudKitSyncError if save fails
    private func saveProfileToCloud(_ profile: UserProfile) async throws {
        do {
            // Convert UserProfile to CKRecord
            let record = try UserProfileCloudMapper.toCKRecord(profile)

            // Save to CloudKit
            _ = try await privateDatabase.save(record)

        } catch {
            throw CloudKitSyncError.saveFailed(
                underlying: error,
                context: "Failed to save UserProfile to CloudKit"
            )
        }
    }

    /// Resolve conflict between local and cloud profiles using Last-Write-Wins
    /// - Parameters:
    ///   - local: Local UserProfile
    ///   - cloud: Cloud UserProfile
    /// - Returns: Winning profile (most recent updatedAt timestamp)
    private func resolveConflict(local: UserProfile, cloud: UserProfile) -> UserProfile {
        // Last-Write-Wins: Compare updatedAt timestamps
        if local.updatedAt > cloud.updatedAt {
            return local  // Local is newer
        } else if cloud.updatedAt > local.updatedAt {
            return cloud  // Cloud is newer
        } else {
            // Same timestamp (rare) - prefer cloud as source of truth
            return cloud
        }
    }
}

// MARK: - CloudKitSyncError

/// Errors specific to CloudKit sync operations
public enum CloudKitSyncError: LocalizedError {
    case fetchFailed(underlying: Error, context: String)
    case saveFailed(underlying: Error, context: String)
    case containerUnavailable
    case notSignedInToiCloud

    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let underlying, let context):
            return "CloudKit fetch failed: \(context). Error: \(underlying.localizedDescription)"
        case .saveFailed(let underlying, let context):
            return "CloudKit save failed: \(context). Error: \(underlying.localizedDescription)"
        case .containerUnavailable:
            return "CloudKit container is unavailable. Check iCloud settings."
        case .notSignedInToiCloud:
            return "User is not signed in to iCloud. Sign in to enable sync."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Check network connection and try again."
        case .saveFailed:
            return "Check network connection and CloudKit quota. Try again later."
        case .containerUnavailable:
            return "Verify CloudKit container is properly configured in Apple Developer Portal."
        case .notSignedInToiCloud:
            return "Go to Settings → Sign in to your iPhone to enable iCloud sync."
        }
    }
}
