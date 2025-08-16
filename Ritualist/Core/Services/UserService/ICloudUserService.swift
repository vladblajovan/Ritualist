//
//  ICloudUserService.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//


import Foundation
import Observation
import FactoryKit
import RitualistCore

@Observable
public final class ICloudUserService: UserService {
    private var _currentProfile = UserProfile()
    private let errorHandler: ErrorHandlingActor?
    
    public init(errorHandler: ErrorHandlingActor? = nil) {
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