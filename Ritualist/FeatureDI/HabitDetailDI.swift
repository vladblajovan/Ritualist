import Foundation

public struct HabitDetailFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }

    @MainActor public func makeViewModel(for habit: Habit?) -> HabitDetailViewModel {
        let createHabit = CreateHabit(repo: container.habitRepository)
        let updateHabit = UpdateHabit(repo: container.habitRepository)
        let deleteHabit = DeleteHabit(repo: container.habitRepository)
        let toggleHabitActiveStatus = ToggleHabitActiveStatus(repo: container.habitRepository)

        return HabitDetailViewModel(
            createHabit: createHabit,
            updateHabit: updateHabit,
            deleteHabit: deleteHabit,
            toggleHabitActiveStatus: toggleHabitActiveStatus,
            habit: habit
        )
    }
}
