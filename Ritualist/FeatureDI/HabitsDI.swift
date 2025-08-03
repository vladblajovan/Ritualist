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
        let reorderHabits = ReorderHabits(repo: container.habitRepository)
        let checkHabitCreationLimit = CheckHabitCreationLimit(featureGatingService: container.featureGatingService)
        let getActiveCategories = GetActiveCategories(repo: container.categoryRepository)
        
        return HabitsViewModel(
            getAllHabits: getAllHabits,
            createHabit: createHabit,
            updateHabit: updateHabit,
            deleteHabit: deleteHabit,
            toggleHabitActiveStatus: toggleHabitActiveStatus,
            reorderHabits: reorderHabits,
            checkHabitCreationLimit: checkHabitCreationLimit,
            createHabitFromSuggestionUseCase: container.createHabitFromSuggestionUseCase,
            getActiveCategories: getActiveCategories,
            habitDetailFactory: container.habitDetailFactory,
            paywallFactory: container.paywallFactory,
            habitsAssistantViewModel: container.habitsAssistantViewModel,
            habitSuggestionsService: container.habitSuggestionsService,
            userActionTracker: container.userActionTracker
        )
    }
}
