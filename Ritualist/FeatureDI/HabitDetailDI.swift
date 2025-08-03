import Foundation

public struct HabitDetailFactory {
    private let container: AppContainer
    public init(container: AppContainer) { self.container = container }

    @MainActor public func makeViewModel(for habit: Habit?) -> HabitDetailViewModel {
        let createHabit = CreateHabit(repo: container.habitRepository)
        let updateHabit = UpdateHabit(repo: container.habitRepository)
        let deleteHabit = DeleteHabit(repo: container.habitRepository)
        let toggleHabitActiveStatus = ToggleHabitActiveStatus(repo: container.habitRepository)
        let getActiveCategories = GetActiveCategories(repo: container.categoryRepository)
        let createCustomCategory = CreateCustomCategory(repo: container.categoryRepository)
        let validateCategoryName = ValidateCategoryName(repo: container.categoryRepository)
        let validateHabitUniqueness = ValidateHabitUniqueness(repo: container.habitRepository)

        return HabitDetailViewModel(
            createHabit: createHabit,
            updateHabit: updateHabit,
            deleteHabit: deleteHabit,
            toggleHabitActiveStatus: toggleHabitActiveStatus,
            getActiveCategories: getActiveCategories,
            createCustomCategory: createCustomCategory,
            validateCategoryName: validateCategoryName,
            validateHabitUniqueness: validateHabitUniqueness,
            habit: habit
        )
    }
}
