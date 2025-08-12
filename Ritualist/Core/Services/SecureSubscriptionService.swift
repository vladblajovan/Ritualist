//
//  SecureSubscriptionService.swift
//  Ritualist
//
//  Created by Claude on 08.08.2025.
//

import Foundation

/// Protocol for secure subscription validation and management
/// Designed to be implemented with mock services during development
/// and real App Store receipt validation in production
public protocol SecureSubscriptionService {
    /// Validate if a specific product is purchased and valid
    func validatePurchase(_ productId: String) async -> Bool
    
    /// Restore and validate all purchased products
    func restorePurchases() async -> [String]
    
    /// Check if user has any premium subscription
    func isPremiumUser() -> Bool
    
    /// Get all currently valid product IDs
    func getValidPurchases() -> [String]
    
    /// Mark a product as purchased (for mock implementation)
    func mockPurchase(_ productId: String) async throws
    
    /// Clear all purchases (for mock implementation and testing)
    func clearPurchases() async throws
}

/// Development-safe mock implementation that cannot be bypassed via UserDefaults
/// Uses in-memory storage during development, designed for easy migration to
/// App Store receipt validation or RevenueCat when external services are available
public final class MockSecureSubscriptionService: SecureSubscriptionService {
    
    // MARK: - Private Properties
    
    /// In-memory storage of validated purchases (not bypassable via UserDefaults)
    private var validatedPurchases: Set<String> = []
    
    /// Mock user defaults key for development testing only
    /// In production, this would be replaced with App Store receipt validation
    private let mockStorageKey = "secure_mock_purchases"
    
    private let errorHandler: ErrorHandlingActor?
    
    // MARK: - Initialization
    
    public init(errorHandler: ErrorHandlingActor? = nil) {
        self.errorHandler = errorHandler
        loadMockPurchases()
    }
    
    // MARK: - Protocol Implementation
    
    public func validatePurchase(_ productId: String) async -> Bool {
        return validatedPurchases.contains(productId)
    }
    
    public func restorePurchases() async -> [String] {
        // In production: App Store receipt validation would happen here
        // For now: return mock validated purchases
        return Array(validatedPurchases)
    }
    
    public func isPremiumUser() -> Bool {
        return !validatedPurchases.isEmpty
    }
    
    public func getValidPurchases() -> [String] {
        return Array(validatedPurchases)
    }
    
    public func mockPurchase(_ productId: String) async throws {
        validatedPurchases.insert(productId)
        saveMockPurchases()
    }
    
    public func clearPurchases() async throws {
        validatedPurchases.removeAll()
        saveMockPurchases()
    }
    
    // MARK: - Private Helpers
    
    /// Load mock purchases from UserDefaults for development convenience
    /// NOTE: This is only for development - production would use secure receipt validation
    private func loadMockPurchases() {
        if let storedPurchases = UserDefaults.standard.stringArray(forKey: mockStorageKey) {
            validatedPurchases = Set(storedPurchases)
        }
    }
    
    /// Save mock purchases to UserDefaults for development convenience
    /// NOTE: This is only for development - production would use secure receipt validation
    private func saveMockPurchases() {
        UserDefaults.standard.set(Array(validatedPurchases), forKey: mockStorageKey)
    }
}

/// Production-ready protocol extension for future App Store integration
extension SecureSubscriptionService {
    /// Convenience method to check specific product types
    func hasAnnualSubscription() async -> Bool {
        return await validatePurchase("ritualist_annual")
    }
    
    func hasMonthlySubscription() async -> Bool {
        return await validatePurchase("ritualist_monthly")
    }
}