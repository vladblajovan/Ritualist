import Foundation

public struct HabitsAssistantFactory {
    private let container: AppContainer
    
    public init(container: AppContainer) { 
        self.container = container 
    }
    
    public func makeDeleteHabitUseCase() -> DeleteHabitUseCase {
        return DeleteHabit(repo: container.habitRepository)
    }
    
    @MainActor
    public func makeViewModel() -> HabitsAssistantViewModel {
        let getPredefinedCategoriesUseCase = GetPredefinedCategories(repo: container.categoryRepository)
        let getHabitsFromSuggestionsUseCase = GetHabitsFromSuggestions()
        
        return HabitsAssistantViewModel(
            getPredefinedCategoriesUseCase: getPredefinedCategoriesUseCase,
            getHabitsFromSuggestionsUseCase: getHabitsFromSuggestionsUseCase,
            suggestionsService: container.habitSuggestionsService,
            userActionTracker: container.userActionTracker
        )
    }
}