//
//  Container+StatsUserCases.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 07.08.2025.
//

import Foundation
import FactoryKit
import RitualistCore

extension Container {
    
    // MARK: - Stats Services
    
    var habitScheduleAnalyzer: Factory<HabitScheduleAnalyzerProtocol> {
        self { HabitScheduleAnalyzer() }
    }

    var performanceAnalysisService: Factory<PerformanceAnalysisService> {
        self {
            PerformanceAnalysisServiceImpl(
                scheduleAnalyzer: self.habitScheduleAnalyzer(),
                streakCalculationService: self.streakCalculationService()
            )
        }
        .singleton
    }
    
    var calculateHabitPerformanceUseCase: Factory<CalculateHabitPerformanceUseCaseProtocol> {
        self {
            CalculateHabitPerformanceUseCase(
                getActiveHabitsUseCase: self.getActiveHabits(),
                getHabitLogsUseCase: self.getHabitLogsForAnalytics(),
                performanceAnalysisService: self.performanceAnalysisService(),
                timezoneService: self.timezoneService()
            )
        }
    }

    var generateProgressChartDataUseCase: Factory<GenerateProgressChartDataUseCaseProtocol> {
        self {
            GenerateProgressChartDataUseCase(
                getHabitCompletionStatsUseCase: self.getHabitCompletionStats(),
                performanceAnalysisService: self.performanceAnalysisService(),
                timezoneService: self.timezoneService()
            )
        }
    }

    var analyzeWeeklyPatternsUseCase: Factory<AnalyzeWeeklyPatternsUseCaseProtocol> {
        self {
            AnalyzeWeeklyPatternsUseCase(
                getActiveHabitsUseCase: self.getActiveHabits(),
                getHabitLogsUseCase: self.getHabitLogsForAnalytics(),
                performanceAnalysisService: self.performanceAnalysisService(),
                timezoneService: self.timezoneService()
            )
        }
    }
    
    // MARK: - Basic Analytics UseCases
    
    var getHabitLogsForAnalytics: Factory<GetHabitLogsForAnalytics> {
        self {
            GetHabitLogsForAnalytics(
                habitRepository: self.habitRepository(),
                getBatchLogs: self.getBatchLogs()
            )
        }
    }
    
    var getHabitCompletionStats: Factory<GetHabitCompletionStats> {
        self {
            GetHabitCompletionStats(
                habitRepository: self.habitRepository(),
                scheduleAnalyzer: self.habitScheduleAnalyzer(),
                getBatchLogs: self.getBatchLogs(),
                timezoneService: self.timezoneService()
            )
        }
    }

    var calculateStreakAnalysis: Factory<CalculateStreakAnalysis> {
        self {
            CalculateStreakAnalysis(
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }

    var getConsistencyHeatmapData: Factory<GetConsistencyHeatmapDataUseCase> {
        self {
            GetConsistencyHeatmapData(
                habitRepository: self.habitRepository(),
                getLogsUseCase: self.getLogs()
            )
        }
    }
}
