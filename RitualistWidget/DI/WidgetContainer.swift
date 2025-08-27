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
    
    func isCompleted(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        switch habit.kind {
        case .binary:
            return !logs.isEmpty
        case .numeric:
            let totalLogged = logs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
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
        let filteredLogs = logs.filter { DateUtils.isSameDay($0.date, date) }
        
        switch habit.kind {
        case .binary:
            return filteredLogs.isEmpty ? 0.0 : 1.0
        case .numeric:
            let totalLogged = filteredLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            let target = habit.dailyTarget ?? 1.0
            return min(totalLogged / target, 1.0)
        }
    }
}
