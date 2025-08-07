//
//  HabitAnalyticsService.swift
//  Ritualist
//
//  Created by Claude on 07.08.2025.
//

import Foundation

/// Domain service responsible for habit data access and retrieval
public protocol HabitAnalyticsService {
    
    /// Get all active habits for a user
    func getActiveHabits(for userId: UUID) async throws -> [Habit]
    
    /// Get habit logs for a user within a date range
    func getHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
    
    /// Get habit completion statistics for a user within a date range
    func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats
}

public final class HabitAnalyticsServiceImpl: HabitAnalyticsService {
    
    private let habitRepository: HabitRepository
    private let logRepository: LogRepository
    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let calendar: Calendar
    
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
        var allLogs: [HabitLog] = []
        
        for habit in habits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            let logsInRange = habitLogs.filter { log in
                log.date >= startDate && log.date <= endDate
            }
            allLogs.append(contentsOf: logsInRange)
        }
        
        return allLogs
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
}