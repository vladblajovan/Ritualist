//
//  TodaysSummary.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct TodaysSummary {
    public let completedHabitsCount: Int
    public let completedHabits: [Habit]
    public let totalHabits: Int
    public let completionPercentage: Double
    public let incompleteHabits: [Habit]

    public init(completedHabitsCount: Int, completedHabits: [Habit], totalHabits: Int, incompleteHabits: [Habit]) {
        self.completedHabitsCount = completedHabitsCount
        self.completedHabits = completedHabits
        self.totalHabits = totalHabits
        self.completionPercentage = totalHabits > 0 ? Double(completedHabitsCount) / Double(totalHabits) : 0.0
        self.incompleteHabits = incompleteHabits
    }
}