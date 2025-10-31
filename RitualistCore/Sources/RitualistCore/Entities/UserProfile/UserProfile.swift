//
//  UserProfile.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct UserProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var avatarImageData: Data?
    public var appearance: Int // 0 followSystem, 1 light, 2 dark
    
    // Timezone preferences  
    public var homeTimezone: String?  // Optional designated home timezone (e.g., "America/New_York")
    public var displayTimezoneMode: String  // DisplayTimezoneMode as string ("original", "current", "home")
    
    // Subscription info
    public var subscriptionPlan: SubscriptionPlan
    public var subscriptionExpiryDate: Date?
    
    // Metadata
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), 
                name: String = "", 
                avatarImageData: Data? = nil,
                appearance: Int = 0,
                homeTimezone: String? = nil,
                displayTimezoneMode: String = "original",
                subscriptionPlan: SubscriptionPlan = .free,
                subscriptionExpiryDate: Date? = nil,
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.avatarImageData = avatarImageData
        self.appearance = appearance
        self.homeTimezone = homeTimezone
        self.displayTimezoneMode = displayTimezoneMode
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
