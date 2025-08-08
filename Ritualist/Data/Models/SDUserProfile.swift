//
//  SDUserProfile.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDUserProfile: @unchecked Sendable {
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
}
