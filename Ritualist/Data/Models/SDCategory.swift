//
//  SDCategory.swift
//  Ritualist
//
//  Created by Claude on 03.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDCategory: @unchecked Sendable {
    @Attribute(.unique) public var id: String
    public var name: String
    public var displayName: String
    public var emoji: String
    public var order: Int
    public var isActive: Bool
    public var isPredefined: Bool
    
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