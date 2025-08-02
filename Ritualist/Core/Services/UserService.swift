import Foundation
import Observation

// MARK: - User Service Protocol

/// Simplified user service that manages the single UserProfile entity
/// No authentication required - designed for iCloud sync
/// Acts as a bridge between local ProfileRepository and cloud storage
@MainActor
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

// MARK: - UserService Implementations

// MARK: - Mock User Service

@MainActor @Observable
public final class MockUserService: UserService {
    private var _currentProfile: UserProfile = UserProfile()
    
    // Store different test subscription states for easy switching
    private let testSubscriptionStates: [String: (SubscriptionPlan, Date?)] = [
        "free": (.free, nil),
        "monthly": (.monthly, Calendar.current.date(byAdding: .month, value: 1, to: Date())),
        "annual": (.annual, Calendar.current.date(byAdding: .year, value: 1, to: Date()))
    ]
    
    public init() {
        // Initialize with free user profile
        _currentProfile = UserProfile(name: "", subscriptionPlan: .free)
    }
    
    public var currentProfile: UserProfile {
        _currentProfile
    }
    
    public var isPremiumUser: Bool {
        _currentProfile.isPremiumUser
    }
    
    public func updateProfile(_ profile: UserProfile) async throws {
        // Simulate network delay for mock
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        _currentProfile = profile
        _currentProfile.updatedAt = Date()
        
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
    
    // MARK: - Test Helpers
    
    /// Switch to a different test subscription state (for development)
    public func switchToTestSubscription(_ type: String) {
        guard let (plan, expiryDate) = testSubscriptionStates[type] else { return }
        
        _currentProfile.subscriptionPlan = plan
        _currentProfile.subscriptionExpiryDate = expiryDate
        _currentProfile.updatedAt = Date()
    }
}

// MARK: - iCloud User Service Stub

@MainActor @Observable
public final class ICloudUserService: UserService {
    private var _currentProfile: UserProfile = UserProfile()
    
    public init() {
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
        _currentProfile.isPremiumUser
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

// MARK: - NoOp User Service (for minimal container)

@MainActor @Observable
public final class NoOpUserService: UserService {
    public let currentProfile = UserProfile()
    public let isPremiumUser = false
    
    public init() {}
    
    public func updateProfile(_ profile: UserProfile) async throws {}
    public func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws {}
    public func syncWithiCloud() async throws {}
}