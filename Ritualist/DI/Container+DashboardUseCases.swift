//
//  Container+DashboardUseCases.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import FactoryKit
import RitualistCore

extension Container {
    
    // MARK: - Dashboard Services
    
    var habitScheduleAnalyzer: Factory<HabitScheduleAnalyzerProtocol> {
        self { HabitScheduleAnalyzer() }
    }
    
    var habitAnalyticsService: Factory<HabitAnalyticsService> {
        self {
            HabitAnalyticsServiceImpl(
                habitRepository: self.habitRepository(),
                logRepository: self.logRepository(),
                scheduleAnalyzer: self.habitScheduleAnalyzer(),
                getBatchLogs: self.getBatchLogs(),
                getSingleHabitLogs: self.getSingleHabitLogs()
            )
        }
        .singleton
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
                getBatchLogs: self.getBatchLogs()
            )
        }
    }
    
    var calculateStreakAnalysis: Factory<CalculateStreakAnalysis> {
        self {
            CalculateStreakAnalysis(performanceAnalysisService: self.performanceAnalysisService())
        }
    }
    
    // MARK: - Dashboard UseCases
    
    var calculateHabitPerformanceUseCase: Factory<CalculateHabitPerformanceUseCaseProtocol> {
        self { 
            CalculateHabitPerformanceUseCase(
                getActiveHabitsUseCase: self.getActiveHabits(),
                getHabitLogsUseCase: self.getHabitLogsForAnalytics(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }
    
    var generateProgressChartDataUseCase: Factory<GenerateProgressChartDataUseCaseProtocol> {
        self {
            GenerateProgressChartDataUseCase(
                getHabitCompletionStatsUseCase: self.getHabitCompletionStats(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }
    
    var analyzeWeeklyPatternsUseCase: Factory<AnalyzeWeeklyPatternsUseCaseProtocol> {
        self {
            AnalyzeWeeklyPatternsUseCase(
                getActiveHabitsUseCase: self.getActiveHabits(),
                getHabitLogsUseCase: self.getHabitLogsForAnalytics(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }

    var aggregateCategoryPerformanceUseCase: Factory<AggregateCategoryPerformanceUseCaseProtocol> {
        self {
            AggregateCategoryPerformanceUseCase(
                getActiveHabitsUseCase: self.getActiveHabits(),
                getHabitLogsUseCase: self.getHabitLogsForAnalytics(),
                performanceAnalysisService: self.performanceAnalysisService(),
                categoryRepository: self.categoryRepository()
            )
        }
    }
}
