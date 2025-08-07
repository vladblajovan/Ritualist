//
//  CalculateHabitPerformanceUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation

public protocol CalculateHabitPerformanceUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitPerformanceResult]
}

public final class CalculateHabitPerformanceUseCase: CalculateHabitPerformanceUseCaseProtocol {
    private let habitAnalyticsService: HabitAnalyticsService
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        habitAnalyticsService: HabitAnalyticsService,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.habitAnalyticsService = habitAnalyticsService
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitPerformanceResult] {
        let habits = try await habitAnalyticsService.getActiveHabits(for: userId)
        let logs = try await habitAnalyticsService.getHabitLogs(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.calculateHabitPerformance(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}