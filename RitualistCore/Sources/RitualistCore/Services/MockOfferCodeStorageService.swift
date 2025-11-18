//
//  MockOfferCodeStorageService.swift
//  RitualistCore
//
//  Created on 2025-11-18
//

import Foundation

/// Mock implementation of OfferCodeStorageService using UserDefaults
///
/// This service provides a complete testing environment for offer codes:
/// - Pre-configured test codes for various scenarios
/// - Local storage using UserDefaults
/// - Full CRUD operations for debug menu
/// - Redemption history tracking
///
/// **Usage:**
/// ```swift
/// let storage = MockOfferCodeStorageService()
///
/// // Get all codes
/// let codes = try await storage.getAllOfferCodes()
///
/// // Validate a code
/// if let code = try await storage.getOfferCode("RITUALIST2025") {
///     if code.isValid {
///         // Redeem
///     }
/// }
/// ```
///
public final class MockOfferCodeStorageService: OfferCodeStorageService {

    // MARK: - Constants

    private let codesKey = "mock_offer_codes"
    private let redemptionsKey = "mock_offer_code_redemptions"

    // MARK: - Pre-configured Test Codes

    /// Default test codes for various testing scenarios
    ///
    /// These codes cover all common use cases:
    /// - Free trials
    /// - Percentage discounts
    /// - Fixed amount discounts
    /// - Expired codes
    /// - Limit-reached codes
    ///
    public static let defaultTestCodes: [OfferCode] = [
        // Valid free trial offer
        OfferCode(
            id: "RITUALIST2025",
            displayName: "Launch Promo 2025",
            productId: StoreKitProductID.annual,
            offerType: .freeTrial,
            expirationDate: Date().addingTimeInterval(90 * 24 * 60 * 60), // 90 days from now
            isNewSubscribersOnly: true
        ),

        // Valid percentage discount (50% off for 3 months)
        OfferCode(
            id: "WELCOME50",
            displayName: "Welcome 50% Off",
            productId: StoreKitProductID.monthly,
            offerType: .discount,
            discount: OfferCode.OfferDiscount(
                type: .percentage,
                value: 50,
                duration: 3  // 3 billing cycles
            ),
            expirationDate: Date().addingTimeInterval(60 * 24 * 60 * 60)  // 60 days from now
        ),

        // Valid annual discount (30% off for 1 year)
        OfferCode(
            id: "ANNUAL30",
            displayName: "Annual 30% Discount",
            productId: StoreKitProductID.annual,
            offerType: .discount,
            discount: OfferCode.OfferDiscount(
                type: .percentage,
                value: 30,
                duration: 1
            ),
            maxRedemptions: 100
        ),

        // Lifetime discount (fixed $20 off)
        OfferCode(
            id: "LIFETIME20",
            displayName: "Lifetime $20 Off",
            productId: StoreKitProductID.lifetime,
            offerType: .discount,
            discount: OfferCode.OfferDiscount(
                type: .fixed,
                value: 20.00,
                duration: nil  // One-time purchase, no duration
            ),
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60)
        ),

        // Expired code (for testing expiration logic)
        OfferCode(
            id: "EXPIRED2024",
            displayName: "Expired Test Code",
            productId: StoreKitProductID.monthly,
            offerType: .freeTrial,
            expirationDate: Date().addingTimeInterval(-30 * 24 * 60 * 60), // 30 days ago
            isActive: false
        ),

        // Limit reached code (for testing redemption limits)
        OfferCode(
            id: "LIMITREACHED",
            displayName: "Limit Reached Test",
            productId: StoreKitProductID.annual,
            offerType: .discount,
            discount: OfferCode.OfferDiscount(type: .percentage, value: 20, duration: 1),
            maxRedemptions: 1,
            redemptionCount: 1
        ),

        // Inactive code (for testing inactive state)
        OfferCode(
            id: "INACTIVE2025",
            displayName: "Inactive Test Code",
            productId: StoreKitProductID.monthly,
            offerType: .discount,
            discount: OfferCode.OfferDiscount(type: .percentage, value: 10, duration: 1),
            isActive: false
        )
    ]

    // MARK: - Initialization

    public init() {
        // Auto-initialize with default test codes if storage is empty
        Task {
            let codes = try? await getAllOfferCodes()
            if codes?.isEmpty ?? true {
                await loadDefaultTestCodes()
            }
        }
    }

    // MARK: - OfferCodeStorageService Protocol

    public func getAllOfferCodes() async throws -> [OfferCode] {
        guard let data = UserDefaults.standard.data(forKey: codesKey) else {
            return []
        }

        do {
            let codes = try JSONDecoder().decode([OfferCode].self, from: data)
            return codes
        } catch {
            // If decoding fails, clear corrupted data and return empty
            UserDefaults.standard.removeObject(forKey: codesKey)
            return []
        }
    }

    public func getOfferCode(_ codeId: String) async throws -> OfferCode? {
        let codes = try await getAllOfferCodes()
        // Case-insensitive matching
        return codes.first { $0.id.uppercased() == codeId.uppercased() }
    }

    public func saveOfferCode(_ code: OfferCode) async throws {
        var codes = try await getAllOfferCodes()

        // Update existing or append new
        if let index = codes.firstIndex(where: { $0.id == code.id }) {
            codes[index] = code
        } else {
            codes.append(code)
        }

        let data = try JSONEncoder().encode(codes)
        UserDefaults.standard.set(data, forKey: codesKey)
    }

    public func deleteOfferCode(_ codeId: String) async throws {
        var codes = try await getAllOfferCodes()
        codes.removeAll { $0.id == codeId }

        let data = try JSONEncoder().encode(codes)
        UserDefaults.standard.set(data, forKey: codesKey)
    }

    public func incrementRedemptionCount(_ codeId: String) async throws {
        guard var code = try await getOfferCode(codeId) else {
            throw PaywallError.offerCodeInvalid
        }

        code.redemptionCount += 1
        try await saveOfferCode(code)
    }

    public func getRedemptionHistory() async throws -> [OfferCodeRedemption] {
        guard let data = UserDefaults.standard.data(forKey: redemptionsKey) else {
            return []
        }

        do {
            let redemptions = try JSONDecoder().decode([OfferCodeRedemption].self, from: data)
            return redemptions
        } catch {
            // If decoding fails, clear corrupted data and return empty
            UserDefaults.standard.removeObject(forKey: redemptionsKey)
            return []
        }
    }

    public func recordRedemption(_ redemption: OfferCodeRedemption) async throws {
        var redemptions = try await getRedemptionHistory()
        redemptions.append(redemption)

        let data = try JSONEncoder().encode(redemptions)
        UserDefaults.standard.set(data, forKey: redemptionsKey)
    }

    // MARK: - Debug Helpers

    /// Load default test codes into storage
    ///
    /// Useful for:
    /// - Initial setup
    /// - Resetting to known state
    /// - Debug menu "Reset to Default" action
    ///
    public func loadDefaultTestCodes() async {
        for code in Self.defaultTestCodes {
            try? await saveOfferCode(code)
        }
    }

    /// Clear all offer codes from storage
    ///
    /// **Warning:** This removes all codes including custom ones
    ///
    public func clearAllCodes() async {
        UserDefaults.standard.removeObject(forKey: codesKey)
    }

    /// Clear redemption history
    ///
    /// Useful for testing redemption flows multiple times
    ///
    public func clearRedemptionHistory() async {
        UserDefaults.standard.removeObject(forKey: redemptionsKey)
    }

    /// Reset to default state (codes + history)
    ///
    /// Clears everything and loads default test codes
    ///
    public func resetToDefaults() async {
        await clearAllCodes()
        await clearRedemptionHistory()
        await loadDefaultTestCodes()
    }

    /// Get statistics about current storage
    ///
    /// Useful for debug UI display
    ///
    public func getStatistics() async -> OfferCodeStatistics {
        let codes = (try? await getAllOfferCodes()) ?? []
        let redemptions = (try? await getRedemptionHistory()) ?? []

        return OfferCodeStatistics(
            totalCodes: codes.count,
            activeCodes: codes.filter { $0.isActive }.count,
            expiredCodes: codes.filter { $0.isExpired }.count,
            validCodes: codes.filter { $0.isValid }.count,
            totalRedemptions: redemptions.count
        )
    }
}

// MARK: - OfferCodeStatistics

/// Statistics about offer code storage
public struct OfferCodeStatistics {
    public let totalCodes: Int
    public let activeCodes: Int
    public let expiredCodes: Int
    public let validCodes: Int
    public let totalRedemptions: Int

    public var description: String {
        """
        Offer Code Statistics:
        - Total Codes: \(totalCodes)
        - Active: \(activeCodes)
        - Expired: \(expiredCodes)
        - Valid: \(validCodes)
        - Redemptions: \(totalRedemptions)
        """
    }
}
