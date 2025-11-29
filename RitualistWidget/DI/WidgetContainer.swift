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

    // MARK: - Widget Logger

    var widgetLogger: Factory<DebugLogger> {
        self { DebugLogger(subsystem: WidgetConstants.loggerSubsystem, category: "general") }
            .singleton
    }

    // MARK: - Shared Persistence Container (same as main app)
    var persistenceContainer: Factory<RitualistCore.PersistenceContainer> {
        self { 
            do {
                return try RitualistCore.PersistenceContainer()
            } catch {
                print("[WIDGET-ERROR] Failed to initialize persistence container: \(error)")
                print("[WIDGET-ERROR] App group: group.com.vladblajovan.Ritualist")
                print("[WIDGET-ERROR] Widget cannot access shared data without proper app group setup")
                fatalError("Widget requires access to shared app data: \(error)")
            }
        }
        .singleton
    }
    
    // MARK: - Shared Local Data Sources (same as main app)
    
    var habitDataSource: Factory<HabitLocalDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
            return RitualistCore.HabitLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
            return RitualistCore.LogLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    // MARK: - Shared Repositories (same as main app)
    
    var habitRepository: Factory<HabitRepository> {
        self { HabitRepositoryImpl(local: self.habitDataSource()) }
            .singleton
    }
    
    var logRepository: Factory<LogRepository> {
        self { LogRepositoryImpl(local: self.logDataSource()) }
            .singleton
    }
    
    // MARK: - Shared Services (same as main app)
    
    var habitCompletionService: Factory<HabitCompletionService> {
        self { DefaultHabitCompletionService() }
            .singleton
    }
    
    // MARK: - Shared Use Cases (same as main app)
    
    var getActiveHabits: Factory<GetActiveHabitsUseCase> {
        self { GetActiveHabits(repo: self.habitRepository()) }
    }
    
    var getBatchLogs: Factory<GetBatchLogsUseCase> {
        self { GetBatchLogs(repo: self.logRepository()) }
    }
    
    var logHabitUseCase: Factory<LogHabitUseCase> {
        self { LogHabit(
            repo: self.logRepository(),
            habitRepo: self.habitRepository(),
            validateSchedule: self.validateHabitSchedule()
        ) }
    }
    
    var validateHabitSchedule: Factory<ValidateHabitSchedule> {
        self { ValidateHabitSchedule(habitCompletionService: self.habitCompletionService()) }
    }
    
    // MARK: - Widget Services
    
    var widgetRefreshService: Factory<WidgetRefreshServiceProtocol> {
        self { WidgetRefreshService() }
            .singleton
    }
    
    var widgetDateNavigationService: Factory<WidgetDateNavigationServiceProtocol> {
        self { WidgetDateNavigationService() }
            .singleton
    }
    
    // MARK: - Widget ViewModels
    
    var widgetHabitsViewModel: Factory<WidgetHabitsViewModel> {
        self {
            WidgetHabitsViewModel(
                getActiveHabits: self.getActiveHabits(),
                getBatchLogs: self.getBatchLogs(),
                habitCompletionService: self.habitCompletionService()
            )
        }
    }
}
