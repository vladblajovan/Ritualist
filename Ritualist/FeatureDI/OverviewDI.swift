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
        
        return OverviewViewModel(
            getActiveHabits: getActiveHabits,
            getLogForDate: getLogForDate,
            logHabit: logHabit,
            deleteLog: deleteLog,
            getLogs: getLogs,
            streakEngine: container.streakEngine,
            profileRepository: container.profileRepository,
            userActionTracker: container.userActionTracker
        )
    }
}
