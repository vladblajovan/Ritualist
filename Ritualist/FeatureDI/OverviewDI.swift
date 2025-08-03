import Foundation

public struct OverviewFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    @MainActor public func makeViewModel() -> OverviewViewModel {
        let getActiveHabits = GetActiveHabits(repo: container.habitRepository)
        let getLogForDate = GetLogForDate(repo: container.logRepository)
        let logHabit = LogHabit(repo: container.logRepository)
        let deleteLog = DeleteLog(repo: container.logRepository)
        let getLogs = GetLogs(repo: container.logRepository)
        let loadProfile = LoadProfile(repo: container.profileRepository)
        let generateCalendarDays = GenerateCalendarDays()
        let generateCalendarGrid = GenerateCalendarGrid()
        let toggleHabitLog = ToggleHabitLog(
            getLogForDate: getLogForDate,
            logHabit: logHabit,
            deleteLog: deleteLog
        )
        let getCurrentSlogan = GetCurrentSlogan(slogansService: container.slogansService)
        let trackUserAction = TrackUserAction(userActionTracker: container.userActionTracker)
        let trackHabitLogged = TrackHabitLogged(userActionTracker: container.userActionTracker)
        let checkFeatureAccess = CheckFeatureAccess(featureGatingService: container.featureGatingService)
        let checkHabitCreationLimit = CheckHabitCreationLimit(featureGatingService: container.featureGatingService)
        let getPaywallMessage = GetPaywallMessage(featureGatingService: container.featureGatingService)
        let validateHabitSchedule = ValidateHabitSchedule()
        let checkWeeklyTarget = CheckWeeklyTarget()
        
        return OverviewViewModel(
            getActiveHabits: getActiveHabits,
            getLogs: getLogs,
            getLogForDate: getLogForDate,
            streakEngine: container.streakEngine,
            loadProfile: loadProfile,
            generateCalendarDays: generateCalendarDays,
            generateCalendarGrid: generateCalendarGrid,
            toggleHabitLog: toggleHabitLog,
            getCurrentSlogan: getCurrentSlogan,
            trackUserAction: trackUserAction,
            trackHabitLogged: trackHabitLogged,
            checkFeatureAccess: checkFeatureAccess,
            checkHabitCreationLimit: checkHabitCreationLimit,
            getPaywallMessage: getPaywallMessage,
            validateHabitSchedule: validateHabitSchedule,
            checkWeeklyTarget: checkWeeklyTarget
        )
    }
}
