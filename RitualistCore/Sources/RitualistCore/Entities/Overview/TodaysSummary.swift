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
    public let motivationalMessage: String
    public let incompleteHabits: [Habit]
    
    public init(completedHabitsCount: Int, completedHabits: [Habit], totalHabits: Int, incompleteHabits: [Habit]) {
        self.completedHabitsCount = completedHabitsCount
        self.completedHabits = completedHabits
        self.totalHabits = totalHabits
        self.completionPercentage = totalHabits > 0 ? Double(completedHabitsCount) / Double(totalHabits) : 0.0
        self.incompleteHabits = incompleteHabits
        
        // Generate motivational message based on progress
        if completionPercentage >= 1.0 {
            self.motivationalMessage = "Perfect day! All habits completed! 🎉"
        } else if completionPercentage >= 0.8 {
            let remaining = totalHabits - completedHabitsCount
            self.motivationalMessage = "Great work! \(remaining) habit\(remaining == 1 ? "" : "s") left"
        } else if completionPercentage >= 0.5 {
            self.motivationalMessage = "Keep going! You're halfway there"
        } else if completedHabitsCount > 0 {
            self.motivationalMessage = "Good start! Let's build momentum"
        } else {
            self.motivationalMessage = "Ready to start your day?"
        }
    }
}