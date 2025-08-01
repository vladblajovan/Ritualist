//
//  User.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct User: Identifiable, Codable, Hashable {
    public var id: UUID
    public var email: String
    public var name: String
    public var subscriptionPlan: SubscriptionPlan
    public var subscriptionExpiryDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), email: String, name: String, 
                subscriptionPlan: SubscriptionPlan = .free, 
                subscriptionExpiryDate: Date? = nil,
                createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.subscriptionPlan = subscriptionPlan
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var hasActiveSubscription: Bool {
        switch subscriptionPlan {
        case .free: return false
        case .monthly, .annual:
            guard let expiryDate = subscriptionExpiryDate else { return false }
            return expiryDate > Date()
        }
    }
    
    public var isPremiumUser: Bool {
        hasActiveSubscription
    }
}
