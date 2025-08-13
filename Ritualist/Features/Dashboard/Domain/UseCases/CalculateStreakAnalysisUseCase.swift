//
//  CalculateStreakAnalysisUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore

public protocol CalculateStreakAnalysisUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> StreakAnalysisResult
}

public final class CalculateStreakAnalysisUseCase: CalculateStreakAnalysisUseCaseProtocol {
    private let habitAnalyticsService: HabitAnalyticsService
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        habitAnalyticsService: HabitAnalyticsService,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.habitAnalyticsService = habitAnalyticsService
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> StreakAnalysisResult {
        let habits = try await habitAnalyticsService.getActiveHabits(for: userId)
        let logs = try await habitAnalyticsService.getHabitLogs(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.calculateStreakAnalysis(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}