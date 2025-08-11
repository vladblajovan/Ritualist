//
//  ReminderTime.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct ReminderTime: Codable, Hashable {
    public var hour: Int; public var minute: Int
    public init(hour: Int, minute: Int) { self.hour = hour; self.minute = minute }
}
