//
//  SDUserProfile.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDUserProfile: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var avatarImageData: Data?
    public var firstDayOfWeek: Int
    public var appearance: Int
    
    // Subscription info (consolidated from User entity)
    public var subscriptionPlan: String // Raw value of SubscriptionPlan enum
    public var subscriptionExpiryDate: Date?
    
    // Metadata
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID, 
                name: String, 
                avatarImageData: Data?, 
                firstDayOfWeek: Int, 
                appearance: Int,
                subscriptionPlan: String = "free",
                subscriptionExpiryDate: Date? = nil,
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.avatarImageData = avatarImageData
        self.firstDayOfWeek = firstDayOfWeek
        self.appearance = appearance
        self.subscriptionPlan = subscriptionPlan
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
