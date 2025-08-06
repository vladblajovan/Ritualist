import Foundation
import FactoryKit

// MARK: - Overview Use Cases Container Extensions

extension Container {
    
    // MARK: - Habit Operations
    
    var getActiveHabits: Factory<GetActiveHabits> {
        self { GetActiveHabits(repo: self.habitRepository()) }
    }
    
    // MARK: - Log Operations
    
    var getLogs: Factory<GetLogs> {
        self { GetLogs(repo: self.logRepository()) }
    }
    
    var getLogForDate: Factory<GetLogForDate> {
        self { GetLogForDate(repo: self.logRepository()) }
    }
    
    var logHabit: Factory<LogHabit> {
        self { LogHabit(repo: self.logRepository()) }
    }
    
    var deleteLog: Factory<DeleteLog> {
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
    
    // MARK: - Calendar Utilities
    
    var generateCalendarDays: Factory<GenerateCalendarDays> {
        self { GenerateCalendarDays() }
    }
    
    var generateCalendarGrid: Factory<GenerateCalendarGrid> {
        self { GenerateCalendarGrid() }
    }
    
    var validateHabitSchedule: Factory<ValidateHabitSchedule> {
        self { ValidateHabitSchedule() }
    }
    
    var checkWeeklyTarget: Factory<CheckWeeklyTarget> {
        self { CheckWeeklyTarget() }
    }
    
    // MARK: - Streak Calculations
    
    var calculateCurrentStreak: Factory<CalculateCurrentStreak> {
        self { CalculateCurrentStreak() }
    }
    
    var calculateBestStreak: Factory<CalculateBestStreak> {
        self { CalculateBestStreak() }
    }
    
    // MARK: - Service-based Use Cases
    
    var getCurrentSlogan: Factory<GetCurrentSlogan> {
        self { GetCurrentSlogan(slogansService: self.slogansService()) }
    }
    
    var trackUserAction: Factory<TrackUserAction> {
        self { TrackUserAction(userActionTracker: self.userActionTracker()) }
    }
    
    var trackHabitLogged: Factory<TrackHabitLogged> {
        self { TrackHabitLogged(userActionTracker: self.userActionTracker()) }
    }
    
    @MainActor
    var checkFeatureAccess: Factory<CheckFeatureAccess> {
        self { @MainActor in CheckFeatureAccess(featureGatingService: self.featureGatingService()) }
    }
    
    @MainActor
    var getPaywallMessage: Factory<GetPaywallMessage> {
        self { @MainActor in GetPaywallMessage(featureGatingService: self.featureGatingService()) }
    }
}