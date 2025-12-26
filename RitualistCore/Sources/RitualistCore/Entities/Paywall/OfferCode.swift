//
//  OfferCode.swift
//  RitualistCore
//
//  Created on 2025-11-18
//

import Foundation

/// Represents an offer code that can be redeemed for discounts or trials
///
/// Offer codes provide promotional access to subscription products with:
/// - Free trials (e.g., 14 days free)
/// - Discounts (percentage or fixed amount)
/// - Eligibility rules (new subscribers, lapsed subscribers, etc.)
/// - Redemption limits (max uses, expiration dates)
///
/// **Usage:**
/// ```swift
/// let code = OfferCode(
///     id: "RITUALIST2025",
///     displayName: "Launch Promo 2025",
///     productId: StoreKitProductID.annual,
///     offerType: .freeTrial
/// )
///
/// if code.isValid {
///     // Redeem the code
/// }
/// ```
///
public struct OfferCode: Identifiable, Codable, Equatable, Sendable {

    // MARK: - Properties

    /// Unique code identifier (e.g., "RITUALIST2025")
    /// This is what users enter to redeem the offer
    public let id: String

    /// User-friendly display name for internal reference
    /// Example: "Launch Promotion 2025"
    public let displayName: String

    /// Product ID this offer applies to
    /// Must match a StoreKit product ID
    public let productId: String

    /// Type of offer (free trial, discount, etc.)
    public let offerType: OfferType

    /// Discount configuration (if applicable)
    /// `nil` for free trial offers
    public let discount: OfferDiscount?

    /// When this code expires and becomes invalid
    /// `nil` means no expiration
    public let expirationDate: Date?

    /// Whether this code is currently active
    /// Inactive codes cannot be redeemed
    public let isActive: Bool

    /// When this code was created
    public let createdAt: Date

    // MARK: - Eligibility

    /// If true, only new subscribers can redeem
    /// If false, any user can redeem (including existing subscribers)
    public let isNewSubscribersOnly: Bool

    /// Maximum number of total redemptions allowed
    /// `nil` means unlimited redemptions
    public let maxRedemptions: Int?

    /// Current number of times this code has been redeemed
    public var redemptionCount: Int

    // MARK: - Nested Types

    /// Type of promotional offer
    public enum OfferType: String, Codable, Equatable, Sendable {
        /// Free trial period (e.g., 7 days, 14 days)
        case freeTrial

        /// Discount on regular price (percentage or fixed)
        case discount

        /// Instant upgrade to higher tier
        case upgrade
    }

    /// Discount configuration for offer codes
    public struct OfferDiscount: Codable, Equatable, Sendable {
        /// Type of discount (percentage or fixed amount)
        public let type: DiscountType

        /// Discount value
        /// - For percentage: 0-100 (e.g., 50 = 50% off)
        /// - For fixed: amount in currency units (e.g., 5.00 = $5 off)
        public let value: Double

        /// Number of billing cycles the discount applies to
        /// `nil` means discount applies forever
        public let duration: Int?

        /// Type of discount
        public enum DiscountType: String, Codable, Equatable, Sendable {
            /// Percentage discount (0-100)
            case percentage

            /// Fixed amount discount in local currency
            case fixed
        }

        // MARK: - Initialization

        public init(type: DiscountType, value: Double, duration: Int? = nil) {
            self.type = type
            self.value = value
            self.duration = duration
        }

        // MARK: - Computed Properties

        /// Human-readable description of the discount
        public var description: String {
            switch type {
            case .percentage:
                let durationText = duration.map { " for \($0) billing cycle(s)" } ?? ""
                return "\(Int(value))% off\(durationText)"
            case .fixed:
                let durationText = duration.map { " for \($0) billing cycle(s)" } ?? ""
                return "$\(String(format: "%.2f", value)) off\(durationText)"
            }
        }
    }

    // MARK: - Initialization

    public init(
        id: String,
        displayName: String,
        productId: String,
        offerType: OfferType,
        discount: OfferDiscount? = nil,
        expirationDate: Date? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        isNewSubscribersOnly: Bool = false,
        maxRedemptions: Int? = nil,
        redemptionCount: Int = 0
    ) {
        self.id = id
        self.displayName = displayName
        self.productId = productId
        self.offerType = offerType
        self.discount = discount
        self.expirationDate = expirationDate
        self.isActive = isActive
        self.createdAt = createdAt
        self.isNewSubscribersOnly = isNewSubscribersOnly
        self.maxRedemptions = maxRedemptions
        self.redemptionCount = redemptionCount
    }

    // MARK: - Validation

    /// Whether this code has expired based on expiration date
    public var isExpired: Bool {
        guard let expirationDate else { return false }
        return Date() > expirationDate
    }

    /// Whether this code has reached its redemption limit
    public var isRedemptionLimitReached: Bool {
        guard let maxRedemptions else { return false }
        return redemptionCount >= maxRedemptions
    }

    /// Whether this code is currently valid and can be redeemed
    ///
    /// A code is valid if:
    /// - It is marked as active
    /// - It has not expired
    /// - It has not reached its redemption limit
    ///
    public var isValid: Bool {
        isActive && !isExpired && !isRedemptionLimitReached
    }

    /// Human-readable status description
    public var statusDescription: String {
        if !isActive {
            return "Inactive"
        } else if isExpired {
            return "Expired"
        } else if isRedemptionLimitReached {
            return "Limit Reached"
        } else {
            return "Active"
        }
    }

    /// Detailed description of the offer
    public var offerDescription: String {
        switch offerType {
        case .freeTrial:
            return "Free Trial"
        case .discount:
            return discount?.description ?? "Discount"
        case .upgrade:
            return "Upgrade"
        }
    }
}

// MARK: - Hashable

extension OfferCode: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - CustomStringConvertible

extension OfferCode: CustomStringConvertible {
    public var description: String {
        """
        OfferCode(
            id: \(id),
            displayName: "\(displayName)",
            productId: \(productId),
            type: \(offerType),
            status: \(statusDescription),
            redemptions: \(redemptionCount)\(maxRedemptions.map { "/\($0)" } ?? "")
        )
        """
    }
}
