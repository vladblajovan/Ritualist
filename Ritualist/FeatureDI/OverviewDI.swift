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
            userActionTracker: container.userActionTracker,
            refreshTrigger: container.refreshTrigger
        )
    }
}
