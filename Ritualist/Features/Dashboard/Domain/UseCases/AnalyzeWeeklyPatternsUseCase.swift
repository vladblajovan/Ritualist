//
//  AnalyzeWeeklyPatternsUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore

public protocol AnalyzeWeeklyPatternsUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult
}

public final class AnalyzeWeeklyPatternsUseCase: AnalyzeWeeklyPatternsUseCaseProtocol {
    private let getActiveHabitsUseCase: GetActiveHabitsUseCase
    private let getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        getActiveHabitsUseCase: GetActiveHabitsUseCase,
        getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.getActiveHabitsUseCase = getActiveHabitsUseCase
        self.getHabitLogsUseCase = getHabitLogsUseCase
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult {
        let habits = try await getActiveHabitsUseCase.execute()
        let logs = try await getHabitLogsUseCase.execute(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.analyzeWeeklyPatterns(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}