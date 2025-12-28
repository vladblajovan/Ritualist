//
//  PaywallResult.swift
//  RitualistCore
//
//  Result types for paywall business operations
//

import Foundation

/// Result of a purchase operation
public enum PurchaseResult: Sendable, Equatable {
    case success(Product)
    case failed(String)
    case cancelled
}

/// Result of a restore operation
public enum RestoreResult: Sendable, Equatable {
    case success(restoredProductIds: [String])
    case noProductsToRestore
    case failed(String)
}
