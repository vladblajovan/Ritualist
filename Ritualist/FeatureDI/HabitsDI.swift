import Foundation

public struct HabitsFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }
    @MainActor public func makeViewModel() -> HabitsViewModel {
        let getAllHabits = GetAllHabits(repo: container.habitRepository)
        let createHabit = CreateHabit(repo: container.habitRepository)
        let updateHabit = UpdateHabit(repo: container.habitRepository)
        let deleteHabit = DeleteHabit(repo: container.habitRepository)
        let toggleHabitActiveStatus = ToggleHabitActiveStatus(repo: container.habitRepository)
        
        return HabitsViewModel(
            getAllHabits: getAllHabits,
            createHabit: createHabit,
            updateHabit: updateHabit,
            deleteHabit: deleteHabit,
            toggleHabitActiveStatus: toggleHabitActiveStatus,
            refreshTrigger: container.refreshTrigger,
            featureGatingService: container.featureGatingService
        )
    }
}
