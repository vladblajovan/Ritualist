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
                scheduleAnalyzer: self.habitScheduleAnalyzer()
            )
        }
        .singleton
    }
    
    var performanceAnalysisService: Factory<PerformanceAnalysisService> {
        self {
            PerformanceAnalysisServiceImpl(
                scheduleAnalyzer: self.habitScheduleAnalyzer()
            )
        }
        .singleton
    }
    
    // MARK: - Dashboard UseCases
    
    var calculateHabitPerformanceUseCase: Factory<CalculateHabitPerformanceUseCaseProtocol> {
        self { 
            CalculateHabitPerformanceUseCase(
                habitAnalyticsService: self.habitAnalyticsService(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }
    
    var generateProgressChartDataUseCase: Factory<GenerateProgressChartDataUseCaseProtocol> {
        self {
            GenerateProgressChartDataUseCase(
                habitAnalyticsService: self.habitAnalyticsService(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }
    
    var analyzeWeeklyPatternsUseCase: Factory<AnalyzeWeeklyPatternsUseCaseProtocol> {
        self {
            AnalyzeWeeklyPatternsUseCase(
                habitAnalyticsService: self.habitAnalyticsService(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }
    
    var calculateStreakAnalysisUseCase: Factory<CalculateStreakAnalysisUseCaseProtocol> {
        self {
            CalculateStreakAnalysisUseCase(
                habitAnalyticsService: self.habitAnalyticsService(),
                performanceAnalysisService: self.performanceAnalysisService()
            )
        }
    }
    
    var aggregateCategoryPerformanceUseCase: Factory<AggregateCategoryPerformanceUseCaseProtocol> {
        self {
            AggregateCategoryPerformanceUseCase(
                habitAnalyticsService: self.habitAnalyticsService(),
                performanceAnalysisService: self.performanceAnalysisService(),
                categoryRepository: self.categoryRepository()
            )
        }
    }
}