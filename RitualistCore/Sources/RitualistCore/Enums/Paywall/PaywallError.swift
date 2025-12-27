//
//  PaywallError.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum PaywallError: Error, LocalizedError, Equatable {
    case productsNotAvailable
    case purchaseFailed(String)
    case userCancelled
    case networkError
    case noPurchasesToRestore
    case unknown(String)

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
        }
    }
}
