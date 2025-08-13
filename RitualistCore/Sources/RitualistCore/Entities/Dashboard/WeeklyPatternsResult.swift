//
//  WeeklyPatternsResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct WeeklyPatternsResult {
    public let dayOfWeekPerformance: [DayOfWeekPerformanceResult]
    public let bestDay: String
    public let worstDay: String
    public let averageWeeklyCompletion: Double
    
    public init(
        dayOfWeekPerformance: [DayOfWeekPerformanceResult],
        bestDay: String,
        worstDay: String,
        averageWeeklyCompletion: Double
    ) {
        self.dayOfWeekPerformance = dayOfWeekPerformance
        self.bestDay = bestDay
        self.worstDay = worstDay
        self.averageWeeklyCompletion = averageWeeklyCompletion
    }
}