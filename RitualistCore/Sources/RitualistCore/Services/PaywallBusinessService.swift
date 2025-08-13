//
//  PaywallBusinessService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public protocol PaywallBusinessService {
    /// Load available products from the App Store
    func loadProducts() async throws -> [Product]
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool
    
    /// Restore previous purchases
    func restorePurchases() async throws -> Bool
    
    /// Check if a specific product is purchased
    func isProductPurchased(_ productId: String) async -> Bool
    
    /// Clear all purchases for a user (useful when subscription is cancelled)
    func clearPurchases() async throws
}