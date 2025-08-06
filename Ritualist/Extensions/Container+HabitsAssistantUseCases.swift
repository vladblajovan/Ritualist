import Foundation
import FactoryKit

// MARK: - HabitsAssistant Use Cases Container Extensions

extension Container {
    
    // MARK: - HabitsAssistant Operations
    
    var getPredefinedCategoriesUseCase: Factory<GetPredefinedCategoriesUseCase> {
        self { GetPredefinedCategories(repo: self.categoryRepository()) }
    }
    
    var getHabitsFromSuggestionsUseCase: Factory<GetHabitsFromSuggestionsUseCase> {
        self { GetHabitsFromSuggestions() }
    }
}