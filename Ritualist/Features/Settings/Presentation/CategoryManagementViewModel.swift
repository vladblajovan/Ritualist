import Foundation
import Observation

@Observable
public final class CategoryManagementViewModel {
    
    // MARK: - Dependencies
    private let getAllCategoriesUseCase: GetAllCategoriesUseCase
    private let createCustomCategoryUseCase: CreateCustomCategoryUseCase
    private let updateCategoryUseCase: UpdateCategoryUseCase
    private let deleteCategoryUseCase: DeleteCategoryUseCase
    private let getHabitsByCategoryUseCase: GetHabitsByCategoryUseCase
    private let orphanHabitsFromCategoryUseCase: OrphanHabitsFromCategoryUseCase
    
    // MARK: - State
    public private(set) var categories: [Category] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    
    
    // MARK: - Computed Properties
    public var customCategories: [Category] {
        categories.filter { !$0.isPredefined }
    }
    
    public var predefinedCategories: [Category] {
        categories.filter { $0.isPredefined }
    }
    
    // MARK: - Initialization
    public init(
        getAllCategoriesUseCase: GetAllCategoriesUseCase,
        createCustomCategoryUseCase: CreateCustomCategoryUseCase,
        updateCategoryUseCase: UpdateCategoryUseCase,
        deleteCategoryUseCase: DeleteCategoryUseCase,
        getHabitsByCategoryUseCase: GetHabitsByCategoryUseCase,
        orphanHabitsFromCategoryUseCase: OrphanHabitsFromCategoryUseCase
    ) {
        self.getAllCategoriesUseCase = getAllCategoriesUseCase
        self.createCustomCategoryUseCase = createCustomCategoryUseCase
        self.updateCategoryUseCase = updateCategoryUseCase
        self.deleteCategoryUseCase = deleteCategoryUseCase
        self.getHabitsByCategoryUseCase = getHabitsByCategoryUseCase
        self.orphanHabitsFromCategoryUseCase = orphanHabitsFromCategoryUseCase
    }
    
    // MARK: - Public Methods
    
    @MainActor
    public func load() async {
        isLoading = true
        error = nil
        
        do {
            categories = try await getAllCategoriesUseCase.execute()
        } catch {
            self.error = error
        }
        
        isLoading = false
    }
    
    @MainActor
    public func createCategory(_ category: Category) async {
        error = nil
        
        do {
            try await createCustomCategoryUseCase.execute(category)
            await load() // Refresh the list
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    public func createCustomCategory(name: String, emoji: String) async -> Bool {
        error = nil
        
        let category = Category(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            displayName: name.trimmingCharacters(in: .whitespacesAndNewlines),
            emoji: emoji.trimmingCharacters(in: .whitespacesAndNewlines),
            order: categories.count,
            isActive: true,
            isPredefined: false
        )
        
        do {
            try await createCustomCategoryUseCase.execute(category)
            await load() // Refresh the list
            return true
        } catch {
            self.error = error
            return false
        }
    }
    
    @MainActor
    public func updateCategory(_ category: Category) async {
        error = nil
        
        do {
            try await updateCategoryUseCase.execute(category)
            await load() // Refresh the list
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    public func deleteCategories(at offsets: IndexSet) async {
        error = nil
        
        // Only allow deletion of custom categories
        let categoriesToDelete: [Category] = offsets.compactMap { index in
            guard index < categories.count else { return nil }
            let category = categories[index]
            return category.isPredefined ? nil : category
        }
        
        guard !categoriesToDelete.isEmpty else { return }
        
        do {
            for category in categoriesToDelete {
                // Handle cascading deletion - orphan habits first
                try await orphanHabitsFromCategoryUseCase.execute(categoryId: category.id)
                
                // Then delete the category
                try await deleteCategoryUseCase.execute(id: category.id)
            }
            await load() // Refresh the list
        } catch {
            self.error = error
        }
    }
    
    @MainActor
    public func getHabitsCount(for categoryId: String) async -> Int {
        do {
            let habits = try await getHabitsByCategoryUseCase.execute(categoryId: categoryId)
            return habits.count
        } catch {
            return 0
        }
    }
    
    @MainActor
    public func moveCategories(from source: IndexSet, to destination: Int) async {
        error = nil
        
        var updatedCategories = categories
        updatedCategories.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for (index, category) in updatedCategories.enumerated() {
            updatedCategories[index] = Category(
                id: category.id,
                name: category.name,
                displayName: category.displayName,
                emoji: category.emoji,
                order: index,
                isActive: category.isActive,
                isPredefined: category.isPredefined
            )
        }
        
        // Save only custom categories (predefined categories maintain their original order)
        let customCategoriesToUpdate = updatedCategories.filter { !$0.isPredefined }
        
        do {
            for category in customCategoriesToUpdate {
                try await updateCategoryUseCase.execute(category)
            }
            await load() // Refresh the list
        } catch {
            self.error = error
        }
    }
    
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
    
    @MainActor
    public func deleteCategory(_ categoryId: String) async {
        error = nil
        
        guard let category = categories.first(where: { $0.id == categoryId }),
              !category.isPredefined else {
            return
        }
        
        do {
            // Handle cascading deletion - orphan habits from this category
            try await orphanHabitsFromCategoryUseCase.execute(categoryId: categoryId)
            
            // Delete the category
            try await deleteCategoryUseCase.execute(id: categoryId)
            
            // Refresh the list
            await load()
        } catch {
            self.error = error
        }
    }
}