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
    
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
    
    public var price: String {
        switch self {
        case .free: return "$0"
        case .monthly: return "$9.99"
        case .annual: return "$39.99"
        }
    }
}
