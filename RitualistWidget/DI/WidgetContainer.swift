//
//  WidgetContainer.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import Foundation
import Factory
import RitualistCore
import SwiftData
import WidgetKit

// MARK: - Widget Container Extensions
// Using the exact same architecture as the main app

extension Container {
    
    // MARK: - Persistence Container
    var persistenceContainer: Factory<PersistenceContainer?> {
        self { 
            do {
                return try PersistenceContainer()
            } catch {
                print("[WIDGET-ERROR] Failed to initialize persistence container: \(error)")
                return nil
            }
        }
        .singleton
    }
    
    // MARK: - Local Data Sources
    
    var habitDataSource: Factory<HabitLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for HabitLocalDataSource")
            }
            return HabitLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for LogLocalDataSource")
            }
            return LogLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    // MARK: - Repositories
    
    var habitRepository: Factory<HabitRepository> {
        self { HabitRepositoryImpl(local: self.habitDataSource()) }
            .singleton
    }
    
    var logRepository: Factory<LogRepository> {
        self { LogRepositoryImpl(local: self.logDataSource()) }
            .singleton
    }
    
    // MARK: - Services
    
    var habitCompletionService: Factory<HabitCompletionService> {
        self { WidgetHabitCompletionService() }
            .singleton
    }
    
    var historicalDateValidationService: Factory<HistoricalDateValidationServiceProtocol> {
        self { DefaultHistoricalDateValidationService() }
            .singleton
    }
    
    // MARK: - Use Cases
    
    var validateHabitSchedule: Factory<WidgetValidateHabitSchedule> {
        self { WidgetValidateHabitSchedule(habitCompletionService: self.habitCompletionService()) }
    }
    
    var logHabitUseCase: Factory<WidgetLogHabit> {
        self { WidgetLogHabit(
            logRepository: self.logRepository(),
            habitRepository: self.habitRepository(),
            validateSchedule: self.validateHabitSchedule()
        ) }
    }
    
    // MARK: - Widget Services
    
    var widgetRefreshService: Factory<WidgetRefreshServiceProtocol> {
        self { WidgetRefreshService() }
            .singleton
    }
    
    var widgetDataService: Factory<WidgetDataService> {
        self {
            return WidgetDataService(
                habitCompletionService: self.habitCompletionService(),
                habitRepository: self.habitRepository(),
                logRepository: self.logRepository()
            )
        }
        .singleton
    }
}

// MARK: - Widget Habit Completion Service

/// Widget implementation of habit completion service
/// Uses same logic as main app but available to widget target
final class WidgetHabitCompletionService: HabitCompletionService {
    private let calendar = Calendar.current
    
    func isCompleted(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        let dateStart = calendar.startOfDay(for: date)
        let dayLogs = logs.filter { 
            calendar.startOfDay(for: $0.date) == dateStart
        }
        
        switch habit.kind {
        case .binary:
            return dayLogs.contains { ($0.value ?? 0) > 0 }
        case .numeric:
            let totalLogged = dayLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            let target = habit.dailyTarget ?? 1.0
            return totalLogged >= target
        }
    }
    
    func isScheduledDay(habit: Habit, date: Date) -> Bool {
        switch habit.schedule {
        case .daily:
            return true
        case .daysOfWeek(let days):
            return DateUtils.isDateInScheduledDays(date, scheduledDays: days)
        case .timesPerWeek:
            return true
        }
    }
    
    func calculateDailyProgress(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        let dateStart = calendar.startOfDay(for: date)
        let dayLogs = logs.filter { 
            calendar.startOfDay(for: $0.date) == dateStart
        }
        
        switch habit.kind {
        case .binary:
            return dayLogs.contains { ($0.value ?? 0) > 0 } ? 1.0 : 0.0
        case .numeric:
            let totalLogged = dayLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            let target = habit.dailyTarget ?? 1.0
            return min(totalLogged / target, 1.0)
        }
    }
    
    func calculateProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        let habitLogs = logs.filter { $0.habitID == habit.id }
        let effectiveStart = max(habit.startDate, startDate)
        let effectiveEnd = min(habit.endDate ?? endDate, endDate)
        
        guard effectiveStart <= effectiveEnd else { return 0.0 }
        
        switch habit.schedule {
        case .daily, .daysOfWeek:
            return calculateDailyScheduleProgress(habit: habit, logs: habitLogs, from: effectiveStart, to: effectiveEnd)
        case .timesPerWeek(let target):
            return calculateWeeklyScheduleProgress(habit: habit, logs: habitLogs, from: effectiveStart, to: effectiveEnd, weeklyTarget: target)
        }
    }
    
    func getExpectedCompletions(habit: Habit, from startDate: Date, to endDate: Date) -> Int {
        let effectiveStart = max(habit.startDate, startDate)
        let effectiveEnd = min(habit.endDate ?? endDate, endDate)
        
        guard effectiveStart <= effectiveEnd else { return 0 }
        
        switch habit.schedule {
        case .daily:
            return calendar.dateComponents([.day], from: effectiveStart, to: effectiveEnd).day ?? 0
        case .daysOfWeek(let days):
            return countScheduledDays(from: effectiveStart, to: effectiveEnd, scheduledDays: days)
        case .timesPerWeek(let target):
            let weeks = calendar.dateComponents([.weekOfYear], from: effectiveStart, to: effectiveEnd).weekOfYear ?? 0
            return weeks * target
        }
    }
    
    func getWeeklyProgress(habit: Habit, for date: Date, logs: [HabitLog]) -> (completed: Int, target: Int) {
        guard case .timesPerWeek(let target) = habit.schedule else {
            return (0, 1)
        }
        
        let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date)
        guard let weekStart = weekInterval?.start, let weekEnd = weekInterval?.end else {
            return (0, target)
        }
        
        let weekLogs = logs.filter { log in
            log.habitID == habit.id && 
            log.date >= weekStart && 
            log.date < weekEnd &&
            (log.value ?? 0) > 0
        }
        
        let uniqueDays = Set(weekLogs.map { calendar.startOfDay(for: $0.date) })
        return (uniqueDays.count, target)
    }
    
    // MARK: - Private Helpers
    
    private func calculateDailyScheduleProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date) -> Double {
        var completedDays = 0
        var totalExpectedDays = 0
        
        var currentDate = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        while currentDate <= endOfRange {
            if isScheduledDay(habit: habit, date: currentDate) {
                totalExpectedDays += 1
                if isCompleted(habit: habit, on: currentDate, logs: logs) {
                    completedDays += 1
                }
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return totalExpectedDays > 0 ? Double(completedDays) / Double(totalExpectedDays) : 0.0
    }
    
    private func calculateWeeklyScheduleProgress(habit: Habit, logs: [HabitLog], from startDate: Date, to endDate: Date, weeklyTarget: Int) -> Double {
        var completedWeeks = 0
        var totalWeeks = 0
        
        var weekDate = startDate
        while weekDate <= endDate {
            guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: weekDate) else { break }
            
            let (completed, _) = getWeeklyProgress(habit: habit, for: weekDate, logs: logs)
            totalWeeks += 1
            if completed >= weeklyTarget {
                completedWeeks += 1
            }
            
            weekDate = weekInterval.end
        }
        
        return totalWeeks > 0 ? Double(completedWeeks) / Double(totalWeeks) : 0.0
    }
    
    private func countScheduledDays(from startDate: Date, to endDate: Date, scheduledDays: Set<Int>) -> Int {
        var count = 0
        var currentDate = calendar.startOfDay(for: startDate)
        let endOfRange = calendar.startOfDay(for: endDate)
        
        while currentDate <= endOfRange {
            let weekday = calendar.component(.weekday, from: currentDate)
            let habitWeekday = DateUtils.calendarWeekdayToHabitWeekday(weekday)
            
            if scheduledDays.contains(habitWeekday) {
                count += 1
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return count
    }
}
