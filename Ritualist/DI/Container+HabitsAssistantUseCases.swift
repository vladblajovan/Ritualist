import Foundation
import FactoryKit
import RitualistCore

// MARK: - HabitsAssistant Use Cases Container Extensions

extension Container {
    
    // MARK: - HabitsAssistant Operations
    
    var getPredefinedCategoriesUseCase: Factory<GetPredefinedCategoriesUseCase> {
        self { GetPredefinedCategories(repo: self.categoryRepository()) }
    }
    
    var getHabitsFromSuggestionsUseCase: Factory<GetHabitsFromSuggestionsUseCase> {
        self { GetHabitsFromSuggestions() }
    }

    var getSuggestionsUseCase: Factory<GetSuggestionsUseCase> {
        self { GetSuggestions(suggestionsService: self.habitSuggestionsService()) }
    }
}