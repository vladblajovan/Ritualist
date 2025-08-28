//
//  UserProfileModel.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class UserProfileModel: @unchecked Sendable {
    @Attribute(.unique) public var id: String // TODO: Remove .unique when enabling CloudKit
    public var name: String = "" // CloudKit requires default values
    public var avatarImageData: Data?
    public var appearance: String = "followSystem" // CloudKit requires default values
    
    // Subscription info (consolidated from User entity)
    public var subscriptionPlan: String = "free" // CloudKit requires default values
    public var subscriptionExpiryDate: Date?
    
    // Metadata
    public var createdAt: Date = Date() // CloudKit requires default values
    public var updatedAt: Date = Date() // CloudKit requires default values
    
    public init(id: String, 
                name: String, 
                avatarImageData: Data?, 
                appearance: String,
                subscriptionPlan: String = "free",
                subscriptionExpiryDate: Date? = nil,
                createdAt: Date = Date(),
                updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.avatarImageData = avatarImageData
        self.appearance = appearance
        self.subscriptionPlan = subscriptionPlan
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    /// Convert SwiftData model to domain entity
    public func toEntity() -> UserProfile {
        let subscriptionPlan = SubscriptionPlan(rawValue: self.subscriptionPlan) ?? .free
        let id = UUID(uuidString: self.id) ?? UUID()
        let appearance = Int(self.appearance) ?? 0
        
        return UserProfile(
            id: id, 
            name: name, 
            avatarImageData: avatarImageData,
            appearance: appearance,
            subscriptionPlan: subscriptionPlan,
            subscriptionExpiryDate: subscriptionExpiryDate,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    /// Create SwiftData model from domain entity
    public static func fromEntity(_ profile: UserProfile) -> UserProfileModel {
        return UserProfileModel(
            id: profile.id.uuidString, 
            name: profile.name, 
            avatarImageData: profile.avatarImageData,
            appearance: String(profile.appearance),
            subscriptionPlan: profile.subscriptionPlan.rawValue,
            subscriptionExpiryDate: profile.subscriptionExpiryDate,
            createdAt: profile.createdAt,
            updatedAt: profile.updatedAt
        )
    }
}
