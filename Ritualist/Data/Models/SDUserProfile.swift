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
    public init(id: UUID, name: String, avatarImageData: Data?, firstDayOfWeek: Int, appearance: Int) {
        self.id = id; self.name = name; self.avatarImageData = avatarImageData
        self.firstDayOfWeek = firstDayOfWeek; self.appearance = appearance
    }
}
