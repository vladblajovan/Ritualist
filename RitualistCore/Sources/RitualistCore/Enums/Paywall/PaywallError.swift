//
//  PaywallError.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum PaywallError: Error, LocalizedError {
    case productsNotAvailable
    case purchaseFailed(String)
    case userCancelled
    case networkError
    case noPurchasesToRestore
    case unknown(String)

    // MARK: - Offer Code Errors

    /// Offer code redemption failed with a specific error
    case offerCodeRedemptionFailed(String)

    /// The offer code is not valid or doesn't exist
    case offerCodeInvalid

    /// The offer code has expired
    case offerCodeExpired

    /// The user has already redeemed this offer code
    case offerCodeAlreadyRedeemed

    /// The user is not eligible for this offer (e.g., existing subscriber for new-only offers)
    case offerCodeNotEligible

    /// The offer code has reached its maximum redemption limit
    case offerCodeRedemptionLimitReached
    
    public var errorDescription: String? {
        switch self {
        case .productsNotAvailable:
            return "Products are not available"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .userCancelled:
            return "Purchase was cancelled"
        case .networkError:
            return "Network connection error"
        case .noPurchasesToRestore:
            return "No purchases to restore"
        case .unknown(let message):
            return message

        // MARK: - Offer Code Error Descriptions

        case .offerCodeRedemptionFailed(let message):
            return "Offer code redemption failed: \(message)"
        case .offerCodeInvalid:
            return "This offer code is not valid"
        case .offerCodeExpired:
            return "This offer code has expired"
        case .offerCodeAlreadyRedeemed:
            return "You have already redeemed this offer code"
        case .offerCodeNotEligible:
            return "You are not eligible for this offer"
        case .offerCodeRedemptionLimitReached:
            return "This offer code has reached its redemption limit"
        }
    }
}
