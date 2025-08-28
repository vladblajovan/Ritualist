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
    private let mockStorageKey = "secure_mock_purchases"
    
    private let errorHandler: ErrorHandler?
    
    // MARK: - Initialization
    
    public init(errorHandler: ErrorHandler? = nil) {
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
        !validatedPurchases.isEmpty
    }
    
    public func getValidPurchases() -> [String] {
        Array(validatedPurchases)
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