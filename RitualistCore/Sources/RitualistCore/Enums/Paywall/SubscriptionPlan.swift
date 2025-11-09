//
//  SubscriptionPlan.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case monthly
    case annual
    case lifetime

    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        case .lifetime: return "Lifetime"
        }
    }

    public var price: String {
        switch self {
        case .free: return "$0"
        case .monthly: return "$9.99"
        case .annual: return "$49.99"
        case .lifetime: return "$100.00"
        }
    }

    /// Indicates if this plan is a recurring subscription (has expiry date)
    public var isRecurring: Bool {
        switch self {
        case .free, .lifetime:
            return false
        case .monthly, .annual:
            return true
        }
    }

    /// Indicates if this plan grants premium features
    public var isPremium: Bool {
        switch self {
        case .free:
            return false
        case .monthly, .annual, .lifetime:
            return true
        }
    }
}
