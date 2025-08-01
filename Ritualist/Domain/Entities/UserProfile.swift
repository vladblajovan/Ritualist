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
    public var firstDayOfWeek: Int // 1..7
    public var appearance: Int // 0 followSystem, 1 light, 2 dark
    public init(id: UUID = UUID(), name: String = "", avatarImageData: Data? = nil,
                firstDayOfWeek: Int = 2, appearance: Int = 0) {
        self.id = id; self.name = name; self.avatarImageData = avatarImageData
        self.firstDayOfWeek = firstDayOfWeek; self.appearance = appearance
    }
}
