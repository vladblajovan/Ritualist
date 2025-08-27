//
//  HabitAnalyticsService.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//

import Foundation

/// PHASE 2: Utility service for habit analytics calculations only
/// Business operations moved to UseCases following Clean Architecture
public protocol HabitAnalyticsService {
    
    /// Get logs for a single habit using optimized batch loading
    /// Delegates to proper UseCase following Clean Architecture
    func getSingleHabitLogs(habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
}

public final class HabitAnalyticsServiceImpl: HabitAnalyticsService {
    
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let calendar: Calendar
    
    // PHASE 3: Add batch loading capability to eliminate N+1 queries
    private let getBatchLogs: GetBatchLogsUseCase
    private let getSingleHabitLogs: GetSingleHabitLogsUseCase
    
    public init(
        habitRepository: HabitRepository,
        logRepository: LogRepository,
        scheduleAnalyzer: HabitScheduleAnalyzerProtocol,
        getBatchLogs: GetBatchLogsUseCase,
        getSingleHabitLogs: GetSingleHabitLogsUseCase,
        calendar: Calendar = Calendar.current
    ) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.scheduleAnalyzer = scheduleAnalyzer
        self.getBatchLogs = getBatchLogs
        self.getSingleHabitLogs = getSingleHabitLogs
        self.calendar = calendar
    }
    
    // PHASE 2: Business methods removed - use GetHabitLogsForAnalyticsUseCase and GetHabitCompletionStatsUseCase instead
    // This service now delegates to proper UseCases following Clean Architecture
    
    /// Get logs for a single habit using optimized batch loading
    /// Delegates to proper UseCase following Clean Architecture
    public func getSingleHabitLogs(habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        return try await getSingleHabitLogs.execute(for: habitId, from: startDate, to: endDate)
    }
}
