//
//  UserGuideItem.swift
//  Ritualist
//
//  Data model for individual guide items in the User Guide.
//

import Foundation

struct UserGuideItem: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let emoji: String?
    let content: String

    init(title: String, subtitle: String? = nil, emoji: String? = nil, content: String) {
        self.title = title
        self.subtitle = subtitle
        self.emoji = emoji
        self.content = content
    }
}
