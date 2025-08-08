//
//  SDCategory.swift
//  Ritualist
//
//  Created by Claude on 03.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDCategory: @unchecked Sendable {
    @Attribute(.unique) public var id: String // TODO: Remove .unique when enabling CloudKit
    public var name: String = "" // CloudKit requires default values
    public var displayName: String = "" // CloudKit requires default values
    public var emoji: String = "📂" // CloudKit requires default values
    public var order: Int = 0 // CloudKit requires default values
    public var isActive: Bool = true // CloudKit requires default values
    public var isPredefined: Bool = false // CloudKit requires default values
    
    // MARK: - SwiftData Relationships
    @Relationship(deleteRule: .nullify)
    var habits = [SDHabit]()
    
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