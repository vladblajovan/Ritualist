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
public protocol SecureSubscriptionService: Sendable {
    /// Validate if a specific product is purchased and valid
    func validatePurchase(_ productId: String) async -> Bool

    /// Restore and validate all purchased products
    func restorePurchases() async -> [String]

    /// Check if user has any premium subscription
    func isPremiumUser() async -> Bool

    /// Get all currently valid product IDs
    func getValidPurchases() async -> [String]

    /// Register a purchase after successful transaction
    /// In production: Updates cache immediately after StoreKit purchase
    /// In testing: Simulates a purchase for mock implementation
    func registerPurchase(_ productId: String) async throws

    /// Clear all purchases (for mock implementation and testing)
    func clearPurchases() async throws

    /// Get current subscription plan based on active purchases
    /// Returns .free if no active subscription
    func getCurrentSubscriptionPlan() async -> SubscriptionPlan

    /// Get subscription expiry date for active subscriptions
    /// Returns nil for free users
    func getSubscriptionExpiryDate() async -> Date?
}