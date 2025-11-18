//
//  OfferCodeStorageService.swift
//  RitualistCore
//
//  Created on 2025-11-18
//

import Foundation

/// Protocol for storing and retrieving offer codes
///
/// This abstraction allows different storage implementations:
/// - **Debug/Mock:** UserDefaults for local testing
/// - **Production:** App Store Connect API or custom backend
///
/// **Usage:**
/// ```swift
/// let storage: OfferCodeStorageService = MockOfferCodeStorageService()
///
/// // Get all available codes
/// let codes = try await storage.getAllOfferCodes()
///
/// // Validate a specific code
/// if let code = try await storage.getOfferCode("RITUALIST2025") {
///     if code.isValid {
///         // Redeem the code
///     }
/// }
/// ```
///
public protocol OfferCodeStorageService {

    // MARK: - Offer Code Management

    /// Get all available offer codes
    ///
    /// - Returns: Array of all offer codes (active and inactive)
    /// - Throws: Storage errors if retrieval fails
    ///
    func getAllOfferCodes() async throws -> [OfferCode]

    /// Get a specific offer code by its ID
    ///
    /// - Parameter codeId: The unique code identifier (e.g., "RITUALIST2025")
    /// - Returns: The offer code if found, `nil` otherwise
    /// - Throws: Storage errors if retrieval fails
    ///
    /// **Note:** Code matching is case-insensitive
    ///
    func getOfferCode(_ codeId: String) async throws -> OfferCode?

    /// Save an offer code (create or update)
    ///
    /// Used for:
    /// - Creating new offer codes (debug/admin)
    /// - Updating existing codes (incrementing redemption count)
    ///
    /// - Parameter code: The offer code to save
    /// - Throws: Storage errors if save fails
    ///
    func saveOfferCode(_ code: OfferCode) async throws

    /// Delete an offer code
    ///
    /// - Parameter codeId: The unique code identifier to delete
    /// - Throws: Storage errors if deletion fails
    ///
    /// **Note:** Only available in debug/admin mode
    ///
    func deleteOfferCode(_ codeId: String) async throws

    /// Increment the redemption count for a code
    ///
    /// Called after successful redemption to track usage
    ///
    /// - Parameter codeId: The code ID whose count should be incremented
    /// - Throws: Storage errors or if code doesn't exist
    ///
    func incrementRedemptionCount(_ codeId: String) async throws

    // MARK: - Redemption History

    /// Get redemption history for the current user
    ///
    /// - Returns: Array of all redemptions by this user
    /// - Throws: Storage errors if retrieval fails
    ///
    func getRedemptionHistory() async throws -> [OfferCodeRedemption]

    /// Record a successful redemption
    ///
    /// Called after offer code is redeemed to track history
    ///
    /// - Parameter redemption: The redemption event to record
    /// - Throws: Storage errors if recording fails
    ///
    func recordRedemption(_ redemption: OfferCodeRedemption) async throws
}

// MARK: - OfferCodeRedemption

/// Represents a single offer code redemption event
///
/// Tracks when a user redeemed a specific offer code
/// for analytics and duplicate prevention.
///
/// **Usage:**
/// ```swift
/// let redemption = OfferCodeRedemption(
///     codeId: "RITUALIST2025",
///     productId: "com.ritualist.annual"
/// )
///
/// try await storage.recordRedemption(redemption)
/// ```
///
public struct OfferCodeRedemption: Identifiable, Codable, Equatable {

    // MARK: - Properties

    /// Unique redemption identifier
    public let id: String

    /// The offer code that was redeemed
    public let codeId: String

    /// The product ID that was granted
    public let productId: String

    /// When the redemption occurred
    public let redeemedAt: Date

    /// Optional user identifier for analytics
    /// `nil` for privacy-preserving storage
    public let userId: String?

    // MARK: - Initialization

    public init(
        id: String = UUID().uuidString,
        codeId: String,
        productId: String,
        redeemedAt: Date = Date(),
        userId: String? = nil
    ) {
        self.id = id
        self.codeId = codeId
        self.productId = productId
        self.redeemedAt = redeemedAt
        self.userId = userId
    }
}

// MARK: - Hashable

extension OfferCodeRedemption: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sendable

extension OfferCodeRedemption: Sendable {}

// MARK: - CustomStringConvertible

extension OfferCodeRedemption: CustomStringConvertible {
    public var description: String {
        """
        OfferCodeRedemption(
            id: \(id),
            code: \(codeId),
            product: \(productId),
            date: \(redeemedAt.formatted())
        )
        """
    }
}
