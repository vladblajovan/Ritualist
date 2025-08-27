//
//  GenerateProgressChartDataUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore

public protocol GenerateProgressChartDataUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [ProgressChartDataPoint]
}

public final class GenerateProgressChartDataUseCase: GenerateProgressChartDataUseCaseProtocol {
    private let getHabitCompletionStatsUseCase: GetHabitCompletionStatsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    private let calendar: Calendar
    
    public init(
        getHabitCompletionStatsUseCase: GetHabitCompletionStatsUseCase,
        performanceAnalysisService: PerformanceAnalysisService,
        calendar: Calendar = Calendar.current
    ) {
        self.getHabitCompletionStatsUseCase = getHabitCompletionStatsUseCase
        self.performanceAnalysisService = performanceAnalysisService
        self.calendar = calendar
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [ProgressChartDataPoint] {
        var completionStatsByDate: [Date: HabitCompletionStats] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            
            let dayStats = try await getHabitCompletionStatsUseCase.execute(
                for: userId,
                from: currentDate,
                to: dayEnd
            )
            
            completionStatsByDate[currentDate] = dayStats
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }
        
        return performanceAnalysisService.generateProgressChartData(
            completionStats: completionStatsByDate
        )
    }
}