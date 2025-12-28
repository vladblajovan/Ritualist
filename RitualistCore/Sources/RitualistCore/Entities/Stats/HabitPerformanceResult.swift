//
//  HabitPerformanceResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct HabitPerformanceResult {
    public let habitId: UUID
    public let habitName: String
    public let emoji: String
    public let completionRate: Double
    public let completedDays: Int
    public let expectedDays: Int
    
    public init(habitId: UUID, habitName: String, emoji: String, completionRate: Double, completedDays: Int, expectedDays: Int) {
        self.habitId = habitId
        self.habitName = habitName
        self.emoji = emoji
        self.completionRate = completionRate
        self.completedDays = completedDays
        self.expectedDays = expectedDays
    }
}