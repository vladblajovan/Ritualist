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
    
    public func getActiveHabits(for userId: UUID) async throws -> [Habit] {
        let allHabits = try await habitRepository.fetchAllHabits()
        return allHabits.filter { $0.isActive }
    }
    
    public func getHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        let habits = try await getActiveHabits(for: userId)
        
        // PHASE 3: Eliminate N+1 query pattern - use batch loading instead
        // BEFORE: N queries (1 per habit)
        // AFTER: 1 batch query for all habits
        
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(
            for: habitIds,
            since: startDate,
            until: endDate
        )
        
        // Flatten the results into a single array
        return logsByHabitId.values.flatMap { $0 }
    }
    
    public func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        let habits = try await getActiveHabits(for: userId)
        let logs = try await getHabitLogs(for: userId, from: startDate, to: endDate)
        
        let totalHabits = habits.count
        let logsByDate = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
        
        var totalExpectedDays = 0
        var totalCompletedDays = 0
        var habitsWithCompletions: Set<UUID> = []
        
        // Calculate expected days based on each habit's schedule
        var currentDate = startDate
        while currentDate <= endDate {
            let dayLogs = logsByDate[calendar.startOfDay(for: currentDate)] ?? []
            
            for habit in habits {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate) {
                    totalExpectedDays += 1
                    
                    if dayLogs.contains(where: { $0.habitID == habit.id }) {
                        totalCompletedDays += 1
                        habitsWithCompletions.insert(habit.id)
                    }
                }
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }
        
        let completionRate = totalExpectedDays > 0 ? Double(totalCompletedDays) / Double(totalExpectedDays) : 0.0
        let successfulHabits = habitsWithCompletions.count
        
        return HabitCompletionStats(
            totalHabits: totalHabits,
            completedHabits: successfulHabits,
            completionRate: completionRate
        )
    }
    
    /// Get logs for a single habit using optimized batch loading
    /// Delegates to proper UseCase following Clean Architecture
    public func getSingleHabitLogs(habitId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        return try await getSingleHabitLogs.execute(for: habitId, from: startDate, to: endDate)
    }
}
