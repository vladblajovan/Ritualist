//
//  HabitAnalyticsService.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation
import RitualistCore
import FactoryKit

// HabitAnalyticsService protocol moved to RitualistCore/Services/ServiceProtocols.swift

public final class HabitAnalyticsServiceImpl: HabitAnalyticsService {
    
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let calendar: Calendar
    
    // PHASE 3: Add batch loading capability to eliminate N+1 queries
    @Injected(\.getBatchLogs) private var getBatchLogs
    @Injected(\.getSingleHabitLogs) private var getSingleHabitLogs
    
    public init(
        habitRepository: HabitRepository,
        logRepository: LogRepository,
        scheduleAnalyzer: HabitScheduleAnalyzerProtocol,
        calendar: Calendar = Calendar.current
    ) {
        self.habitRepository = habitRepository
        self.logRepository = logRepository
        self.scheduleAnalyzer = scheduleAnalyzer
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
