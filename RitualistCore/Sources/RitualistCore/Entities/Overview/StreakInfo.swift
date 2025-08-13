//
//  StreakInfo.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct StreakInfo: Identifiable {
    public let id: String
    public let habitName: String
    public let emoji: String
    public let currentStreak: Int
    public let isActive: Bool
    
    public var flameCount: Int {
        if currentStreak >= 30 { return 3 }
        else if currentStreak >= 14 { return 2 }
        else if currentStreak >= 7 { return 1 }
        else { return 0 }
    }
    
    public var flameEmoji: String {
        String(repeating: "🔥", count: flameCount)
    }
    
    public init(id: String, habitName: String, emoji: String, currentStreak: Int, isActive: Bool) {
        self.id = id
        self.habitName = habitName
        self.emoji = emoji
        self.currentStreak = currentStreak
        self.isActive = isActive
    }
}