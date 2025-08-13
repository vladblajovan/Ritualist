//
//  WeeklyProgress.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct WeeklyProgress {
    public let daysCompleted: [Bool] // 7 days, starting from user's week start day
    public let weeklyCompletionRate: Double
    public let currentDayIndex: Int
    public let weekDescription: String
    
    public init(daysCompleted: [Bool], currentDayIndex: Int) {
        self.daysCompleted = daysCompleted
        self.currentDayIndex = currentDayIndex
        
        let completedDays = daysCompleted.filter { $0 }.count
        self.weeklyCompletionRate = Double(completedDays) / 7.0
        
        let percentage = Int(weeklyCompletionRate * 100)
        self.weekDescription = "\(completedDays) days completed • \(percentage)% weekly"
    }
}