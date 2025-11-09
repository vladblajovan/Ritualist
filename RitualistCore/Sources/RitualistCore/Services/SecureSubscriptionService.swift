//
//  SecureSubscriptionService.swift
//  RitualistCore
//
//  Created by Claude on 16.08.2025.
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

    /// Get current subscription plan based on active purchases
    /// Returns .free if no active subscription
    func getCurrentSubscriptionPlan() async -> SubscriptionPlan

    /// Get subscription expiry date for time-limited subscriptions
    /// Returns nil for lifetime subscriptions or free users
    func getSubscriptionExpiryDate() async -> Date?
}