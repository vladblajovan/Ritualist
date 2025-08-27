//
//  AggregateCategoryPerformanceUseCase.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore

public final class AggregateCategoryPerformanceUseCase: AggregateCategoryPerformanceUseCaseProtocol {
    private let getActiveHabitsUseCase: GetActiveHabitsUseCase
    private let getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    private let categoryRepository: CategoryRepository
    
    public init(
        getActiveHabitsUseCase: GetActiveHabitsUseCase,
        getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase,
        performanceAnalysisService: PerformanceAnalysisService,
        categoryRepository: CategoryRepository
    ) {
        self.getActiveHabitsUseCase = getActiveHabitsUseCase
        self.getHabitLogsUseCase = getHabitLogsUseCase
        self.performanceAnalysisService = performanceAnalysisService
        self.categoryRepository = categoryRepository
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [CategoryPerformanceResult] {
        let habits = try await getActiveHabitsUseCase.execute()
        let categories = try await categoryRepository.getActiveCategories()
        let logs = try await getHabitLogsUseCase.execute(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.aggregateCategoryPerformance(
            habits: habits,
            categories: categories,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}
