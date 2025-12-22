//
//  MockSecureSubscriptionService.swift
//  RitualistCore
//
//  Created by Claude on 08.08.2025.
//

import Foundation

/// Development-safe mock implementation that cannot be bypassed via UserDefaults
/// Uses in-memory storage during development, designed for easy migration to
/// App Store receipt validation or RevenueCat when external services are available
public final class MockSecureSubscriptionService: SecureSubscriptionService {

    // MARK: - Private Properties

    /// In-memory storage of validated purchases (not bypassable via UserDefaults)
    private var validatedPurchases: Set<String> = []

    /// Mock user defaults key for development testing only
    /// In production, this would be replaced with App Store receipt validation
    private let mockStorageKey = UserDefaultsKeys.mockPurchases

    /// UserDefaults instance for storage
    private let userDefaults: UserDefaults

    private let errorHandler: ErrorHandler?

    // MARK: - Static Premium Check (for startup-time use)

    /// Check premium status synchronously from cached values.
    ///
    /// This static method is designed for use during app initialization when
    /// DI is not yet available. Used for feature gating (habit limits, analytics).
    ///
    /// Note: iCloud sync is free for all users and does not depend on premium status.
    ///
    /// ## Check Order
    /// 1. Build configuration cache (ALL_FEATURES_ENABLED scheme)
    /// 2. Mock purchases (development testing with Subscription scheme)
    ///
    /// - Parameter userDefaults: UserDefaults service for checking cached values.
    ///   Defaults to DefaultUserDefaultsService.
    /// - Returns: `true` if user has premium access based on cached values
    public static func isPremiumFromCache(userDefaults: UserDefaultsService = DefaultUserDefaultsService()) -> Bool {
        // 1. Check build configuration cache (set by main app for AllFeatures scheme)
        // This bridges the ALL_FEATURES_ENABLED flag from main app to Swift Package
        if userDefaults.bool(forKey: UserDefaultsKeys.allFeaturesEnabledCache) {
            return true
        }

        // 2. Check mock purchases (for development/testing with Subscription scheme)
        let purchases = userDefaults.stringArray(forKey: UserDefaultsKeys.mockPurchases) ?? []
        return !purchases.isEmpty
    }

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard, errorHandler: ErrorHandler? = nil) {
        self.userDefaults = userDefaults
        self.errorHandler = errorHandler
        loadMockPurchases()
    }
    
    // MARK: - Protocol Implementation
    
    public func validatePurchase(_ productId: String) async -> Bool {
        validatedPurchases.contains(productId)
    }
    
    public func restorePurchases() async -> [String] {
        // In production: App Store receipt validation would happen here
        // For now: return mock validated purchases
        Array(validatedPurchases)
    }
    
    public func isPremiumUser() -> Bool {
        // Check build configuration cache first (AllFeatures scheme)
        if userDefaults.bool(forKey: UserDefaultsKeys.allFeaturesEnabledCache) {
            return true
        }

        // Check mock purchases using instance's userDefaults (not .standard)
        // This allows tests to use isolated UserDefaults
        return !validatedPurchases.isEmpty
    }
    
    public func getValidPurchases() -> [String] {
        Array(validatedPurchases)
    }
    
    public func registerPurchase(_ productId: String) async throws {
        validatedPurchases.insert(productId)
        saveMockPurchases()
    }
    
    public func clearPurchases() async throws {
        validatedPurchases.removeAll()
        saveMockPurchases()
    }

    public func getCurrentSubscriptionPlan() async -> SubscriptionPlan {
        // Check AllFeatures build flag first (returns lifetime for TestFlight/dev builds)
        if userDefaults.bool(forKey: UserDefaultsKeys.allFeaturesEnabledCache) {
            return .lifetime
        }

        // Check for lifetime purchase first (highest priority)
        if validatedPurchases.contains(StoreKitProductID.lifetime) {
            return .lifetime
        }

        // Check for annual subscription
        if validatedPurchases.contains(StoreKitProductID.annual) {
            return .annual
        }

        // Check for monthly subscription
        if validatedPurchases.contains(StoreKitProductID.monthly) {
            return .monthly
        }

        // Check for weekly subscription
        if validatedPurchases.contains(StoreKitProductID.weekly) {
            return .weekly
        }

        // Default to free if no purchases
        return .free
    }

    public func getSubscriptionExpiryDate() async -> Date? {
        let plan = await getCurrentSubscriptionPlan()

        switch plan {
        case .weekly:
            // Mock expiry: 7 days from now
            return Date().addingTimeInterval(7 * 24 * 60 * 60)
        case .monthly:
            // Mock expiry: 30 days from now
            return Date().addingTimeInterval(30 * 24 * 60 * 60)
        case .annual:
            // Mock expiry: 365 days from now
            return Date().addingTimeInterval(365 * 24 * 60 * 60)
        case .lifetime, .free:
            // No expiry for lifetime or free
            return nil
        }
    }

    // MARK: - Private Helpers

    /// Load mock purchases from UserDefaults for development convenience
    /// NOTE: This is only for development - production would use secure receipt validation
    private func loadMockPurchases() {
        if let storedPurchases = userDefaults.stringArray(forKey: mockStorageKey) {
            validatedPurchases = Set(storedPurchases)
        }
    }

    /// Save mock purchases to UserDefaults for development convenience
    /// NOTE: This is only for development - production would use secure receipt validation
    private func saveMockPurchases() {
        userDefaults.set(Array(validatedPurchases), forKey: mockStorageKey)
    }
}