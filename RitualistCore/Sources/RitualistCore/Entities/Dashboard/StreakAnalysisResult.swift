//
//  StreakAnalysisResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct StreakAnalysisResult {
    public let currentStreak: Int
    public let longestStreak: Int
    public let streakTrend: String // "improving", "declining", "stable"
    public let daysWithFullCompletion: Int
    public let consistencyScore: Double // 0-1
    
    public init(
        currentStreak: Int,
        longestStreak: Int,
        streakTrend: String,
        daysWithFullCompletion: Int,
        consistencyScore: Double
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.streakTrend = streakTrend
        self.daysWithFullCompletion = daysWithFullCompletion
        self.consistencyScore = consistencyScore
    }
}