//
//  AnalyzeWeeklyPatternsUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation

public protocol AnalyzeWeeklyPatternsUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult
}

public final class AnalyzeWeeklyPatternsUseCase: AnalyzeWeeklyPatternsUseCaseProtocol {
    private let habitAnalyticsService: HabitAnalyticsService
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        habitAnalyticsService: HabitAnalyticsService,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.habitAnalyticsService = habitAnalyticsService
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult {
        let habits = try await habitAnalyticsService.getActiveHabits(for: userId)
        let logs = try await habitAnalyticsService.getHabitLogs(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.analyzeWeeklyPatterns(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}