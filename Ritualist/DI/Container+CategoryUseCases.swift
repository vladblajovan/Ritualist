import Foundation
import FactoryKit
import RitualistCore

// MARK: - Category Use Cases Container Extensions

extension Container {
    
    // MARK: - Category Operations
    
    var getAllCategories: Factory<GetAllCategories> {
        self { GetAllCategories(repo: self.categoryRepository()) }
    }
    
    var getActiveCategories: Factory<GetActiveCategories> {
        self { GetActiveCategories(repo: self.categoryRepository()) }
    }
    
    var createCustomCategory: Factory<CreateCustomCategory> {
        self { CreateCustomCategory(repo: self.categoryRepository()) }
    }
    
    var updateCategory: Factory<UpdateCategory> {
        self { UpdateCategory(repo: self.categoryRepository()) }
    }
    
    var deleteCategory: Factory<DeleteCategory> {
        self { DeleteCategory(repo: self.categoryRepository()) }
    }
    
    var validateCategoryName: Factory<ValidateCategoryName> {
        self { ValidateCategoryName(repo: self.categoryRepository()) }
    }

    var seedPredefinedCategories: Factory<SeedPredefinedCategoriesUseCase> {
        self {
            SeedPredefinedCategories(
                categoryRepository: self.categoryRepository(),
                categoryDefinitionsService: self.categoryDefinitionsService(),
                habitRepository: self.habitRepository(),
                habitSuggestionsService: self.habitSuggestionsService(),
                logger: self.debugLogger()
            )
        }
    }

    // MARK: - Habit-Category Relations
    
    var getHabitsByCategory: Factory<GetHabitsByCategory> {
        self { GetHabitsByCategory(repo: self.habitRepository()) }
    }
    
    var orphanHabitsFromCategory: Factory<OrphanHabitsFromCategory> {
        self { OrphanHabitsFromCategory(repo: self.habitRepository()) }
    }
}