//
//  Category.swift
//  Ritualist
//
//  Created by Claude on 03.08.2025.
//

import Foundation

public struct Category: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let displayName: String
    public let emoji: String
    public let order: Int
    public let isActive: Bool
    public let isPredefined: Bool
    
    public init(
        id: String,
        name: String,
        displayName: String,
        emoji: String,
        order: Int,
        isActive: Bool = true,
        isPredefined: Bool = false
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.emoji = emoji
        self.order = order
        self.isActive = isActive
        self.isPredefined = isPredefined
    }
}