//
//  OfferCodeRedemptionState.swift
//  RitualistCore
//
//  Created on 2025-11-18
//

import Foundation

/// Represents the current state of an offer code redemption flow
///
/// This enum tracks the lifecycle of redeeming an offer code:
/// 1. User enters code → `.validating`
/// 2. Code is checked → `.redeeming`
/// 3. Transaction processed → `.success` or `.failed`
/// 4. UI resets → `.idle`
///
/// **Usage:**
/// ```swift
/// @Observable
/// class PaywallService {
///     var offerCodeRedemptionState: OfferCodeRedemptionState = .idle
///
///     func redeemCode(_ code: String) async {
///         offerCodeRedemptionState = .validating(code)
///         // ... validation logic ...
///         offerCodeRedemptionState = .redeeming(code)
///         // ... redemption logic ...
///         offerCodeRedemptionState = .success(code: code, productId: "product_id")
///     }
/// }
/// ```
///
public enum OfferCodeRedemptionState: Equatable {

    // MARK: - Cases

    /// No redemption in progress
    case idle

    /// Currently validating the offer code
    /// - Parameter code: The code being validated
    case validating(String)

    /// Code is valid and redemption is in progress
    /// - Parameter code: The code being redeemed
    case redeeming(String)

    /// Redemption completed successfully
    /// - Parameters:
    ///   - code: The code that was redeemed
    ///   - productId: The product ID that was granted
    case success(code: String, productId: String)

    /// Redemption failed with an error
    /// - Parameter message: Human-readable error message
    case failed(String)

    // MARK: - Computed Properties

    /// Whether a redemption operation is currently in progress
    ///
    /// Returns `true` for `.validating` or `.redeeming` states
    ///
    public var isProcessing: Bool {
        switch self {
        case .validating, .redeeming:
            return true
        case .idle, .success, .failed:
            return false
        }
    }

    /// Whether the last redemption was successful
    public var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    /// Whether the last redemption failed
    public var isFailed: Bool {
        if case .failed = self {
            return true
        }
        return false
    }

    /// The offer code associated with the current state
    /// Returns `nil` for `.idle`
    public var code: String? {
        switch self {
        case .idle:
            return nil
        case .validating(let code),
             .redeeming(let code),
             .success(let code, _):
            return code
        case .failed:
            return nil
        }
    }

    /// The error message if redemption failed
    /// Returns `nil` for all states except `.failed`
    public var errorMessage: String? {
        if case .failed(let message) = self {
            return message
        }
        return nil
    }

    /// The product ID if redemption succeeded
    /// Returns `nil` for all states except `.success`
    public var productId: String? {
        if case .success(_, let productId) = self {
            return productId
        }
        return nil
    }

    /// Human-readable description of the current state
    public var statusDescription: String {
        switch self {
        case .idle:
            return "Ready"
        case .validating(let code):
            return "Validating \(code)..."
        case .redeeming(let code):
            return "Redeeming \(code)..."
        case .success(let code, let productId):
            return "Successfully redeemed \(code) for \(productId)"
        case .failed(let message):
            return "Failed: \(message)"
        }
    }
}

// MARK: - CustomStringConvertible

extension OfferCodeRedemptionState: CustomStringConvertible {
    public var description: String {
        statusDescription
    }
}

// MARK: - Sendable

extension OfferCodeRedemptionState: Sendable {}
