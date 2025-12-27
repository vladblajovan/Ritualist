//
//  DayOfWeekPerformanceResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct DayOfWeekPerformanceResult {
    public let dayName: String
    public let completionRate: Double
    public let averageHabitsCompleted: Int
    
    public init(dayName: String, completionRate: Double, averageHabitsCompleted: Int) {
        self.dayName = dayName
        self.completionRate = completionRate
        self.averageHabitsCompleted = averageHabitsCompleted
    }
}