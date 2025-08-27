import Foundation
import FactoryKit
import RitualistCore

// MARK: - Overview Use Cases Container Extensions

extension Container {
    
    // MARK: - Habit Operations
    
    var getActiveHabits: Factory<GetActiveHabitsUseCase> {
        self { GetActiveHabits(habitAnalyticsService: self.habitAnalyticsService(), userService: self.userService()) }
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
    
    var toggleHabitLog: Factory<ToggleHabitLog> {
        self { 
            ToggleHabitLog(
                getLogForDate: self.getLogForDate(),
                logHabit: self.logHabit(),
                deleteLog: self.deleteLog()
            )
        }
    }
    
    // MARK: - Profile Operations
    
    var loadProfile: Factory<LoadProfile> {
        self { LoadProfile(repo: self.profileRepository()) }
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
        self { CalculateCurrentStreak(streakCalculationService: self.streakCalculationService()) }
    }
    
    
    // MARK: - Service-based Use Cases
    
    var trackUserAction: Factory<TrackUserAction> {
        self { TrackUserAction(userActionTracker: self.userActionTracker()) }
    }
    
    var trackHabitLogged: Factory<TrackHabitLogged> {
        self { TrackHabitLogged(userActionTracker: self.userActionTracker()) }
    }
    
    var refreshWidget: Factory<RefreshWidget> {
        self { RefreshWidget(widgetRefreshService: self.widgetRefreshService()) }
    }
    
    var checkFeatureAccess: Factory<CheckFeatureAccess> {
        self { CheckFeatureAccess(featureGatingService: self.featureGatingService()) }
    }
    
    var getPaywallMessage: Factory<GetPaywallMessage> {
        self { GetPaywallMessage(featureGatingService: self.featureGatingService()) }
    }
}