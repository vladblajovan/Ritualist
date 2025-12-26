//
//  ActiveDiscountService.swift
//  RitualistCore
//
//  Created on 2025-11-19
//  Service for managing active discount vouchers between redemption and purchase
//

import Foundation

// MARK: - ActiveDiscount Entity

/// Represents an active discount that can be applied to a purchase
///
/// When a user redeems a discount offer code, an ActiveDiscount is stored
/// until they complete the purchase. This bridges the gap between redemption
/// and purchase, allowing the discount to be applied at checkout.
///
/// **Usage:**
/// ```swift
/// let discount = ActiveDiscount(
///     codeId: "WELCOME50",
///     productId: .monthly,
///     discountType: .percentage,
///     discountValue: 50,
///     duration: 3
/// )
/// try await activeDiscountService.setActiveDiscount(discount)
/// ```
///
public struct ActiveDiscount: Codable, Equatable {
    /// The offer code ID that was redeemed
    public let codeId: String

    /// The product this discount applies to
    public let productId: String

    /// Type of discount (percentage or fixed amount)
    public let discountType: OfferCode.OfferDiscount.DiscountType

    /// The discount value (e.g., 50 for 50% off, or 20.00 for $20 off)
    public let discountValue: Double

    /// Number of billing cycles this discount applies to (nil = one-time/lifetime)
    public let duration: Int?

    /// When this discount was redeemed
    public let redeemedAt: Date

    /// When this discount expires (default: 24 hours from redemption)
    public let expiresAt: Date

    // MARK: - Initialization

    public init(
        codeId: String,
        productId: String,
        discountType: OfferCode.OfferDiscount.DiscountType,
        discountValue: Double,
        duration: Int?,
        redeemedAt: Date = Date(),
        expiresAt: Date? = nil
    ) {
        self.codeId = codeId
        self.productId = productId
        self.discountType = discountType
        self.discountValue = discountValue
        self.duration = duration
        self.redeemedAt = redeemedAt
        self.expiresAt = expiresAt ?? Date().addingTimeInterval(BusinessConstants.oneDayInterval) // Default: 24 hours
    }

    // MARK: - Computed Properties

    /// Check if this discount is still valid (not expired)
    public var isValid: Bool {
        Date() < expiresAt
    }

    /// Calculate the discounted price for a given original price
    ///
    /// - Parameter originalPrice: The original price before discount
    /// - Returns: The price after applying the discount
    public func calculateDiscountedPrice(_ originalPrice: Double) -> Double {
        switch discountType {
        case .percentage:
            let discountAmount = originalPrice * (discountValue / 100.0)
            return max(0, originalPrice - discountAmount)
        case .fixed:
            return max(0, originalPrice - discountValue)
        }
    }

    /// Get a user-friendly display string for this discount
    public var displayString: String {
        switch discountType {
        case .percentage:
            return "\(Int(discountValue))% off"
        case .fixed:
            return "$\(String(format: "%.2f", discountValue)) off"
        }
    }
}

// MARK: - ActiveDiscountService Protocol

/// Service for managing active discount vouchers
///
/// This service stores and retrieves discount information between
/// offer code redemption and actual purchase completion.
///
/// **Lifecycle:**
/// 1. User redeems discount code → `setActiveDiscount(_:)`
/// 2. User goes to purchase → `getActiveDiscount(for:)`
/// 3. Purchase completes → `clearActiveDiscount()`
///
public protocol ActiveDiscountService {
    /// Store an active discount for later application
    ///
    /// - Parameter discount: The discount to store
    /// - Throws: Error if storage fails
    func setActiveDiscount(_ discount: ActiveDiscount) async throws

    /// Retrieve the active discount for a specific product
    ///
    /// - Parameter productId: The product to check for discounts
    /// - Returns: The active discount if one exists and is valid, nil otherwise
    func getActiveDiscount(for productId: String) async -> ActiveDiscount?

    /// Clear the active discount (typically after purchase completion)
    func clearActiveDiscount() async

    /// Check if there's an active discount for a specific product
    ///
    /// - Parameter productId: The product to check
    /// - Returns: True if a valid discount exists
    func hasActiveDiscount(for productId: String) async -> Bool
}

// MARK: - MockActiveDiscountService

/// Mock implementation of ActiveDiscountService using UserDefaults
///
/// Stores discount state locally for testing and mock builds.
/// Automatically handles expiration checking.
///
/// **Storage:**
/// - Key: "active_discount"
/// - Format: JSON-encoded ActiveDiscount
/// - Expiration: Checked on retrieval
///
public final class MockActiveDiscountService: ActiveDiscountService, @unchecked Sendable {

    // MARK: - Constants

    private let storageKey = "active_discount"

    // MARK: - Storage

    private let userDefaults: UserDefaults

    // MARK: - Initialization

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // Clean up any expired discounts on init
        Task {
            await cleanupExpiredDiscount()
        }
    }

    // MARK: - ActiveDiscountService Protocol

    public func setActiveDiscount(_ discount: ActiveDiscount) async throws {
        guard discount.isValid else {
            throw PaywallError.offerCodeExpired
        }

        let data = try JSONEncoder().encode(discount)
        userDefaults.set(data, forKey: storageKey)
    }

    public func getActiveDiscount(for productId: String) async -> ActiveDiscount? {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return nil
        }

        do {
            let discount = try JSONDecoder().decode(ActiveDiscount.self, from: data)

            // Check if expired
            guard discount.isValid else {
                await clearActiveDiscount()
                return nil
            }

            // Check if product matches
            guard discount.productId == productId else {
                return nil
            }

            return discount
        } catch {
            // If decoding fails, clear corrupted data
            await clearActiveDiscount()
            return nil
        }
    }

    public func clearActiveDiscount() async {
        userDefaults.removeObject(forKey: storageKey)
    }

    public func hasActiveDiscount(for productId: String) async -> Bool {
        await getActiveDiscount(for: productId) != nil
    }

    // MARK: - Private Helpers

    /// Remove expired discount from storage
    private func cleanupExpiredDiscount() async {
        guard let data = userDefaults.data(forKey: storageKey),
              let discount = try? JSONDecoder().decode(ActiveDiscount.self, from: data) else {
            return
        }

        if !discount.isValid {
            await clearActiveDiscount()
        }
    }

    // MARK: - Debug Helpers

    /// Get the current stored discount (regardless of expiration or product)
    ///
    /// Useful for debug menu display
    ///
    public func getCurrentDiscount() async -> ActiveDiscount? {
        guard let data = userDefaults.data(forKey: storageKey),
              let discount = try? JSONDecoder().decode(ActiveDiscount.self, from: data) else {
            return nil
        }
        return discount
    }
}
