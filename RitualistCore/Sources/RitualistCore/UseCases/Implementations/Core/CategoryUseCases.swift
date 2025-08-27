import Foundation

// MARK: - Category Use Case Implementations

public final class GetAllCategories: GetAllCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getAllCategories() }
}

public final class GetCategoryById: GetCategoryByIdUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(id: String) async throws -> HabitCategory? { try await repo.getCategory(by: id) }
}

public final class GetActiveCategories: GetActiveCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getActiveCategories() }
}

public final class GetPredefinedCategories: GetPredefinedCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getPredefinedCategories() }
}

public final class GetCustomCategories: GetCustomCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getCustomCategories() }
}

public final class CreateCustomCategory: CreateCustomCategoryUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(_ category: HabitCategory) async throws {
        // Business logic: Validate category doesn't already exist
        let existsByName = try await repo.categoryExists(name: category.name)
        let existsById = try await repo.categoryExists(id: category.id)
        
        guard !existsByName && !existsById else {
            throw CategoryError.categoryAlreadyExists
        }
        
        try await repo.createCustomCategory(category)
    }
}

public final class UpdateCategory: UpdateCategoryUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(_ category: HabitCategory) async throws {
        try await repo.updateCategory(category)
    }
}

public final class DeleteCategory: DeleteCategoryUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(id: String) async throws {
        try await repo.deleteCategory(id: id)
    }
}

public final class ValidateCategoryName: ValidateCategoryNameUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(name: String) async throws -> Bool {
        // Business logic: Check if category name is unique
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        let exists = try await repo.categoryExists(name: trimmedName)
        return !exists
    }
}

public final class LoadHabitsData: LoadHabitsDataUseCase {
    private let habitRepo: HabitRepository
    private let categoryRepo: CategoryRepository
    
    public init(habitRepo: HabitRepository, categoryRepo: CategoryRepository) {
        self.habitRepo = habitRepo
        self.categoryRepo = categoryRepo
    }
    
    public func execute() async throws -> HabitsData {
        // Batch load both habits and categories concurrently for performance
        async let habitsResult = habitRepo.fetchAllHabits()
        async let categoriesResult = categoryRepo.getActiveCategories()
        
        do {
            let habits = try await habitsResult.sorted { $0.displayOrder < $1.displayOrder }
            let categories = try await categoriesResult
            
            return HabitsData(habits: habits, categories: categories)
        } catch {
            throw error
        }
    }
}