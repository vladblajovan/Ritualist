import Foundation
import FactoryKit
import RitualistCore

// MARK: - Overview Use Cases Container Extensions

extension Container {
    
    // MARK: - Habit Operations
    
    var getActiveHabits: Factory<GetActiveHabitsUseCase> {
        self { GetActiveHabits(repo: self.habitRepository()) }
    }
    
    // MARK: - Log Operations
    
    var getLogs: Factory<GetLogsUseCase> {
        self { GetLogs(repo: self.logRepository()) }
    }
    
    var getBatchLogs: Factory<GetBatchLogsUseCase> {
        self { GetBatchLogs(repo: self.logRepository()) }
    }
    
    var getSingleHabitLogs: Factory<GetSingleHabitLogs> {
        self { GetSingleHabitLogs(getBatchLogs: self.getBatchLogs()) }
    }
    
    var getLogForDate: Factory<GetLogForDate> {
        self { GetLogForDate(repo: self.logRepository()) }
    }

    var getEarliestLogDate: Factory<GetEarliestLogDateUseCase> {
        self { GetEarliestLogDate(repo: self.logRepository()) }
    }

    var logHabit: Factory<LogHabitUseCase> {
        self { LogHabit(
            repo: self.logRepository(),
            habitRepo: self.habitRepository(),
            validateSchedule: self.validateHabitSchedule()
        ) }
    }
    
    var deleteLog: Factory<DeleteLogUseCase> {
        self { DeleteLog(repo: self.logRepository()) }
    }
    
    // MARK: - Profile Operations

    /// Shared profile cache for reducing database reads
    /// Used by both loadProfile and saveProfile to maintain consistency
    var profileCache: Factory<ProfileCache> {
        self { ProfileCache() }
            .singleton
    }

    /// Cached LoadProfile with 5-minute TTL
    /// Reduces redundant database reads for profile data
    var loadProfile: Factory<LoadProfileUseCase> {
        self {
            let innerLoadProfile = LoadProfile(
                repo: self.profileRepository(),
                iCloudKeyValueService: self.iCloudKeyValueService()
            )
            return CachedLoadProfile(
                innerLoadProfile: innerLoadProfile,
                cache: self.profileCache()
            )
        }
    }

    var getCurrentUserProfile: Factory<GetCurrentUserProfile> {
        self { GetCurrentUserProfile(userService: self.userService()) }
    }

    // MARK: - Calendar Utilities
    
    var generateCalendarDays: Factory<GenerateCalendarDays> {
        self { GenerateCalendarDays() }
    }
    
    var generateCalendarGrid: Factory<GenerateCalendarGrid> {
        self { GenerateCalendarGrid() }
    }
    
    var validateHabitSchedule: Factory<ValidateHabitSchedule> {
        self { ValidateHabitSchedule(habitCompletionService: self.habitCompletionService()) }
    }
    
    var checkWeeklyTarget: Factory<CheckWeeklyTarget> {
        self { CheckWeeklyTarget() }
    }
    
    // MARK: - Streak Calculations

    var calculateCurrentStreak: Factory<CalculateCurrentStreakUseCase> {
        self {
            CalculateCurrentStreak(streakCalculationService: self.streakCalculationService())
        }
    }

    var getStreakStatus: Factory<GetStreakStatusUseCase> {
        self {
            GetStreakStatus(streakCalculationService: self.streakCalculationService())
        }
    }

    // MARK: - Service-based Use Cases
    
    var trackUserAction: Factory<TrackUserAction> {
        self { TrackUserAction(userActionTracker: self.userActionTracker()) }
    }
    
    var trackHabitLogged: Factory<TrackHabitLogged> {
        self { TrackHabitLogged(userActionTracker: self.userActionTracker()) }
    }
    
    @MainActor
    var refreshWidget: Factory<RefreshWidget> {
        self { @MainActor in RefreshWidget(widgetRefreshService: self.widgetRefreshService()) }
    }
    
    var checkFeatureAccess: Factory<CheckFeatureAccess> {
        self { CheckFeatureAccess(featureGatingService: self.featureGatingService()) }
    }
    
    var getPaywallMessage: Factory<GetPaywallMessage> {
        self { GetPaywallMessage(featureGatingService: self.featureGatingService()) }
    }

    // MARK: - Migration Status

    @MainActor
    var getMigrationStatus: Factory<GetMigrationStatusUseCase> {
        self { @MainActor in GetMigrationStatusUseCaseImpl(migrationStatusService: self.migrationStatusService()) }
    }
}
