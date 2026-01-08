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
        self { DebugLogger(subsystem: WidgetConstants.loggerSubsystem, category: "widget") }
            .singleton
    }

    // MARK: - Shared Persistence Container (same as main app)
    // Returns optional to handle errors gracefully instead of crashing
    var persistenceContainer: Factory<RitualistCore.PersistenceContainer?> {
        self {
            let logger = self.widgetLogger()
            do {
                let container = try RitualistCore.PersistenceContainer()
                logger.log("Persistence container initialized successfully", level: .info, category: .widget)
                return container
            } catch {
                logger.log(
                    "Failed to initialize persistence container: \(error)",
                    level: .critical,
                    category: .widget,
                    metadata: [
                        "app_group": "group.com.vladblajovan.Ritualist",
                        "error": error.localizedDescription
                    ]
                )
                // Return nil instead of crashing - widget will show error state
                return nil
            }
        }
        .singleton
    }

    /// Indicates whether the widget has valid data access
    var hasValidDataAccess: Factory<Bool> {
        self { self.persistenceContainer() != nil }
    }
    
    // MARK: - Shared Local Data Sources (same as main app)
    // Note: These will crash if persistenceContainer is nil. Check hasValidDataAccess first.

    var habitDataSource: Factory<HabitLocalDataSourceProtocol> {
        self {
            // Force unwrap is safe here because callers should check hasValidDataAccess first
            let persistence = self.persistenceContainer()!
            return RitualistCore.HabitLocalDataSource(modelContainer: persistence.container)
        }
        .singleton
    }

    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self {
            let persistence = self.persistenceContainer()!
            return RitualistCore.LogLocalDataSource(modelContainer: persistence.container)
        }
        .singleton
    }

    var profileDataSource: Factory<ProfileLocalDataSourceProtocol> {
        self {
            let persistence = self.persistenceContainer()!
            return RitualistCore.ProfileLocalDataSource(modelContainer: persistence.container)
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

    var profileRepository: Factory<ProfileRepository> {
        self { ProfileRepositoryImpl(local: self.profileDataSource()) }
            .singleton
    }

    // MARK: - Shared Use Cases for Timezone

    var loadProfile: Factory<LoadProfileUseCase> {
        self { LoadProfile(repo: self.profileRepository()) }
    }

    var saveProfile: Factory<SaveProfileUseCase> {
        self { SaveProfile(repo: self.profileRepository()) }
    }

    // MARK: - Shared Services (same as main app)
    
    var habitCompletionService: Factory<HabitCompletionService> {
        self { DefaultHabitCompletionService() }
            .singleton
    }

    var timezoneService: Factory<TimezoneService> {
        self {
            DefaultTimezoneService(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                logger: DebugLogger(subsystem: WidgetConstants.loggerSubsystem, category: "timezone")
            )
        }
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
    
    @MainActor
    var widgetRefreshService: Factory<WidgetRefreshServiceProtocol> {
        self { @MainActor in WidgetRefreshService() }
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
                habitCompletionService: self.habitCompletionService(),
                timezoneService: self.timezoneService()
            )
        }
    }
}
