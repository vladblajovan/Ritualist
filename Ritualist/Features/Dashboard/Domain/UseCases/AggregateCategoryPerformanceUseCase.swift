//
//  AggregateCategoryPerformanceUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore

public protocol AggregateCategoryPerformanceUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [CategoryPerformanceResult]
}

public final class AggregateCategoryPerformanceUseCase: AggregateCategoryPerformanceUseCaseProtocol {
    private let habitAnalyticsService: HabitAnalyticsService
    private let performanceAnalysisService: PerformanceAnalysisService
    private let categoryRepository: CategoryRepository
    
    public init(
        habitAnalyticsService: HabitAnalyticsService,
        performanceAnalysisService: PerformanceAnalysisService,
        categoryRepository: CategoryRepository
    ) {
        self.habitAnalyticsService = habitAnalyticsService
        self.performanceAnalysisService = performanceAnalysisService
        self.categoryRepository = categoryRepository
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [CategoryPerformanceResult] {
        let habits = try await habitAnalyticsService.getActiveHabits(for: userId)
        let categories = try await categoryRepository.getActiveCategories()
        let logs = try await habitAnalyticsService.getHabitLogs(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.aggregateCategoryPerformance(
            habits: habits,
            categories: categories,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}