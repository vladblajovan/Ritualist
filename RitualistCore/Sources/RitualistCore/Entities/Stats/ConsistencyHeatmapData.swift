//
//  ConsistencyHeatmapData.swift
//  RitualistCore
//
//  Domain model for habit consistency heatmap visualization.
//  Contains daily completion data for a single habit over a time period.
//

import Foundation

public struct ConsistencyHeatmapData: Sendable {
    public let habitId: UUID
    public let habitName: String
    public let habitEmoji: String
    /// Daily completion rates: Date → completion rate (0.0 = not done, 1.0 = fully complete)
    public let dailyCompletions: [Date: Double]

    public init(
        habitId: UUID,
        habitName: String,
        habitEmoji: String,
        dailyCompletions: [Date: Double]
    ) {
        self.habitId = habitId
        self.habitName = habitName
        self.habitEmoji = habitEmoji
        self.dailyCompletions = dailyCompletions
    }
}
