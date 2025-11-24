//
//  StoreKitConstants.swift
//  RitualistCore
//
//  Created on 2025-01-09
//

import Foundation

/// StoreKit product identifiers for in-app purchases
///
/// These product IDs must match exactly with the products configured in:
/// - App Store Connect (when ready for production)
/// - Configuration/Ritualist.storekit (for local testing)
///
/// **IMPORTANT:** Do not change these IDs after products are live in App Store Connect.
/// Any changes require creating new products and migrating users.
public enum StoreKitProductID {

    // MARK: - Subscription Products

    /// Weekly subscription - $2.99/week
    ///
    /// Provides access to all premium features with weekly billing.
    /// Ideal for users wanting to try premium with minimal commitment.
    /// Auto-renews until cancelled by user.
    public static let weekly = "com.vladblajovan.ritualist.weekly"

    /// Monthly subscription - $9.99/month
    ///
    /// Provides access to all premium features with monthly billing.
    /// Auto-renews until cancelled by user.
    public static let monthly = "com.vladblajovan.ritualist.monthly"

    /// Annual subscription - $49.99/year
    ///
    /// Provides access to all premium features with annual billing.
    /// Includes 7-day free trial for new subscribers.
    /// Auto-renews until cancelled by user.
    /// **Best value** - saves 58% compared to monthly.
    public static let annual = "com.vladblajovan.ritualist.annual"

    // MARK: - Non-Consumable Products

    /// Lifetime purchase - $99.99 one-time
    ///
    /// One-time purchase providing permanent access to all premium features.
    /// Never expires, no recurring charges.
    /// Restores across devices via Apple ID.
    public static let lifetime = "com.vladblajovan.ritualist.lifetime"

    // MARK: - Product Collections

    /// All subscription product IDs (weekly, monthly and annual)
    ///
    /// Use this for loading subscription offerings from StoreKit.
    public static let subscriptionProducts: [String] = [
        weekly,
        monthly,
        annual
    ]

    /// All non-consumable product IDs (lifetime)
    ///
    /// Use this for loading one-time purchase offerings from StoreKit.
    public static let nonConsumableProducts: [String] = [
        lifetime
    ]

    /// All product IDs (subscriptions + non-consumables)
    ///
    /// Use this for loading all products from StoreKit in one request.
    public static let allProducts: [String] = subscriptionProducts + nonConsumableProducts

    // MARK: - Subscription Group

    /// Subscription group identifier in App Store Connect
    ///
    /// All subscriptions (monthly, annual) belong to this group.
    /// Users can only have one active subscription per group.
    /// Upgrades/downgrades are handled automatically by StoreKit.
    public static let subscriptionGroupID = "ritualist_pro"

    // MARK: - Product Validation

    /// Checks if a product ID is a subscription
    ///
    /// - Parameter productID: The product identifier to check
    /// - Returns: `true` if the product is a subscription, `false` otherwise
    public static func isSubscription(_ productID: String) -> Bool {
        subscriptionProducts.contains(productID)
    }

    /// Checks if a product ID is a non-consumable (lifetime)
    ///
    /// - Parameter productID: The product identifier to check
    /// - Returns: `true` if the product is a non-consumable, `false` otherwise
    public static func isNonConsumable(_ productID: String) -> Bool {
        nonConsumableProducts.contains(productID)
    }

    /// Maps a product ID to a SubscriptionPlan
    ///
    /// - Parameter productID: The product identifier
    /// - Returns: The corresponding `SubscriptionPlan`, or `.free` if unknown
    public static func subscriptionPlan(for productID: String) -> SubscriptionPlan {
        switch productID {
        case weekly:
            return .weekly
        case monthly:
            return .monthly
        case annual:
            return .annual
        case lifetime:
            return .lifetime
        default:
            return .free
        }
    }
}

// MARK: - Test/Debug Support

#if DEBUG
extension StoreKitProductID {
    /// Test mode product IDs for local testing
    ///
    /// Use these during development to avoid conflicting with production IDs.
    /// Note: Not currently used - using production IDs with .storekit file.
    public enum Test {
        public static let monthly = "com.vladblajovan.ritualist.test.monthly"
        public static let annual = "com.vladblajovan.ritualist.test.annual"
        public static let lifetime = "com.vladblajovan.ritualist.test.lifetime"
    }
}
#endif
