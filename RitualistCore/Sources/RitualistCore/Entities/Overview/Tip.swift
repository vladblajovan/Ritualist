//
//  Tip.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct Tip: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String // Short description for carousel
    public var content: String // Full content for detail view
    public var category: TipCategory
    public var order: Int // For carousel ordering
    public var isFeaturedInCarousel: Bool
    public var icon: String? // SF Symbol name
    
    public init(id: UUID = UUID(), title: String, description: String, content: String,
                category: TipCategory, order: Int = 0, isFeaturedInCarousel: Bool = false,
                icon: String? = nil) {
        self.id = id; self.title = title; self.description = description; self.content = content
        self.category = category; self.order = order
        self.isFeaturedInCarousel = isFeaturedInCarousel; self.icon = icon
    }
}
