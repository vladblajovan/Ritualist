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

    var timezoneLogger: Factory<DebugLogger> {
        self { DebugLogger(subsystem: WidgetConstants.loggerSubsystem, category: "timezone") }
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

    // MARK: - Shared Local Data Sources (Optional - nil if persistence unavailable)

    var habitDataSource: Factory<HabitLocalDataSourceProtocol?> {
        self {
            guard let persistence = self.persistenceContainer() else { return nil }
            return RitualistCore.HabitLocalDataSource(modelContainer: persistence.container)
        }
        .singleton
    }

    var logDataSource: Factory<LogLocalDataSourceProtocol?> {
        self {
            guard let persistence = self.persistenceContainer() else { return nil }
            return RitualistCore.LogLocalDataSource(modelContainer: persistence.container)
        }
        .singleton
    }

    var profileDataSource: Factory<ProfileLocalDataSourceProtocol?> {
        self {
            guard let persistence = self.persistenceContainer() else { return nil }
            return RitualistCore.ProfileLocalDataSource(modelContainer: persistence.container)
        }
        .singleton
    }

    // MARK: - Shared Repositories (Optional - nil if data sources unavailable)

    var habitRepository: Factory<HabitRepository?> {
        self {
            guard let dataSource = self.habitDataSource() else { return nil }
            return HabitRepositoryImpl(local: dataSource)
        }
        .singleton
    }

    var logRepository: Factory<LogRepository?> {
        self {
            guard let dataSource = self.logDataSource() else { return nil }
            return LogRepositoryImpl(local: dataSource)
        }
        .singleton
    }

    var profileRepository: Factory<ProfileRepository?> {
        self {
            guard let dataSource = self.profileDataSource() else { return nil }
            return ProfileRepositoryImpl(local: dataSource)
        }
        .singleton
    }

    // MARK: - Shared Use Cases for Timezone (Optional)

    var loadProfile: Factory<LoadProfileUseCase?> {
        self {
            guard let repo = self.profileRepository() else { return nil }
            return LoadProfile(repo: repo)
        }
    }

    var saveProfile: Factory<SaveProfileUseCase?> {
        self {
            guard let repo = self.profileRepository() else { return nil }
            return SaveProfile(repo: repo)
        }
    }

    // MARK: - Shared Services (same as main app)

    var habitCompletionService: Factory<HabitCompletionService> {
        self { DefaultHabitCompletionService() }
            .singleton
    }

    var timezoneService: Factory<TimezoneService?> {
        self {
            guard let loadProfile = self.loadProfile(),
                  let saveProfile = self.saveProfile() else { return nil }
            return DefaultTimezoneService(
                loadProfile: loadProfile,
                saveProfile: saveProfile,
                logger: self.timezoneLogger()
            )
        }
        .singleton
    }

    // MARK: - Shared Use Cases (Optional - nil if repositories unavailable)

    var getActiveHabits: Factory<GetActiveHabitsUseCase?> {
        self {
            guard let repo = self.habitRepository() else { return nil }
            return GetActiveHabits(repo: repo)
        }
    }

    var getBatchLogs: Factory<GetBatchLogsUseCase?> {
        self {
            guard let repo = self.logRepository() else { return nil }
            return GetBatchLogs(repo: repo)
        }
    }

    var logHabitUseCase: Factory<LogHabitUseCase?> {
        self {
            guard let logRepo = self.logRepository(),
                  let habitRepo = self.habitRepository() else { return nil }
            return LogHabit(
                repo: logRepo,
                habitRepo: habitRepo,
                validateSchedule: self.validateHabitSchedule()
            )
        }
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

    // MARK: - Widget ViewModels (Optional - nil if dependencies unavailable)

    var widgetHabitsViewModel: Factory<WidgetHabitsViewModel?> {
        self {
            guard let getActiveHabits = self.getActiveHabits(),
                  let getBatchLogs = self.getBatchLogs(),
                  let timezoneService = self.timezoneService() else { return nil }
            return WidgetHabitsViewModel(
                getActiveHabits: getActiveHabits,
                getBatchLogs: getBatchLogs,
                habitCompletionService: self.habitCompletionService(),
                timezoneService: timezoneService
            )
        }
    }
}
