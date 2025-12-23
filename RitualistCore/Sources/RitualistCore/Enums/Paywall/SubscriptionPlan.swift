//
//  SubscriptionPlan.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum SubscriptionPlan: String, Codable, CaseIterable {
    case free
    case weekly
    case monthly
    case annual

    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }

    public var price: String {
        switch self {
        case .free: return "$0"
        case .weekly: return "$2.99"
        case .monthly: return "$9.99"
        case .annual: return "$49.99"
        }
    }

    /// Indicates if this plan is a recurring subscription (has expiry date)
    public var isRecurring: Bool {
        switch self {
        case .free:
            return false
        case .weekly, .monthly, .annual:
            return true
        }
    }

    /// Indicates if this plan grants premium features
    public var isPremium: Bool {
        switch self {
        case .free:
            return false
        case .weekly, .monthly, .annual:
            return true
        }
    }
}
