import Foundation
import Observation
import FactoryKit
import RitualistCore

@MainActor
@Observable
public final class CategoryManagementViewModel {
    
    // MARK: - Dependencies
    private let getAllCategoriesUseCase: GetAllCategoriesUseCase
    private let createCustomCategoryUseCase: CreateCustomCategoryUseCase
    private let updateCategoryUseCase: UpdateCategoryUseCase
    private let deleteCategoryUseCase: DeleteCategoryUseCase
    private let getHabitsByCategoryUseCase: GetHabitsByCategoryUseCase
    private let orphanHabitsFromCategoryUseCase: OrphanHabitsFromCategoryUseCase
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    
    // MARK: - State
    public private(set) var categories: [HabitCategory] = []
    public private(set) var isLoading = false
    public private(set) var error: Error?
    
    
    // MARK: - Computed Properties
    public var customCategories: [HabitCategory] {
        categories.filter { !$0.isPredefined }
    }
    
    public var predefinedCategories: [HabitCategory] {
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
    
    public func trackCategoryManagementOpened() {
        userActionTracker.track(.categoryManagementOpened)
    }
    
    public func createCategory(_ category: HabitCategory) async {
        error = nil
        
        do {
            try await createCustomCategoryUseCase.execute(category)
            await load() // Refresh the list
            
            // Track category creation
            userActionTracker.track(.categoryCreated(
                categoryId: category.id,
                categoryName: category.displayName,
                emoji: category.emoji
            ))
        } catch {
            self.error = error
        }
    }
    
    public func createCustomCategory(name: String, emoji: String) async -> Bool {
        error = nil
        
        let category = HabitCategory(
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
            
            // Track category creation
            userActionTracker.track(.categoryCreated(
                categoryId: category.id,
                categoryName: category.displayName,
                emoji: category.emoji
            ))
            
            return true
        } catch {
            self.error = error
            return false
        }
    }
    
    public func updateCategory(_ category: HabitCategory) async {
        error = nil
        
        do {
            try await updateCategoryUseCase.execute(category)
            await load() // Refresh the list
            
            // Track category update
            userActionTracker.track(.categoryUpdated(
                categoryId: category.id,
                categoryName: category.displayName
            ))
        } catch {
            self.error = error
        }
    }
    
    public func deleteCategories(at offsets: IndexSet) async {
        error = nil
        
        // Only allow deletion of custom categories
        let categoriesToDelete: [HabitCategory] = offsets.compactMap { index in
            guard index < categories.count else { return nil }
            let category = categories[index]
            return category.isPredefined ? nil : category
        }
        
        guard !categoriesToDelete.isEmpty else { return }
        
        do {
            for category in categoriesToDelete {
                // Get habits count before deletion for tracking
                let habitsCount = await getHabitsCount(for: category.id)
                
                // Handle cascading deletion - orphan habits first
                try await orphanHabitsFromCategoryUseCase.execute(categoryId: category.id)
                
                // Then delete the category
                try await deleteCategoryUseCase.execute(id: category.id)
                
                // Track category deletion
                userActionTracker.track(.categoryDeleted(
                    categoryId: category.id,
                    categoryName: category.displayName,
                    habitsCount: habitsCount
                ))
            }
            await load() // Refresh the list
        } catch {
            self.error = error
        }
    }
    
    public func getHabitsCount(for categoryId: String) async -> Int {
        do {
            let habits = try await getHabitsByCategoryUseCase.execute(categoryId: categoryId)
            return habits.count
        } catch {
            return 0
        }
    }
    
    public func toggleActiveStatus(id: String) async {
        guard let category = categories.first(where: { $0.id == id }) else { return }
        
        let updatedCategory = HabitCategory(
            id: category.id,
            name: category.name,
            displayName: category.displayName,
            emoji: category.emoji,
            order: category.order,
            isActive: !category.isActive,  // Toggle the status
            isPredefined: category.isPredefined,
            personalityWeights: category.personalityWeights
        )
        
        await updateCategory(updatedCategory)
    }
    
    public func moveCategories(from source: IndexSet, to destination: Int) async {
        error = nil
        
        var updatedCategories = categories
        updatedCategories.move(fromOffsets: source, toOffset: destination)
        
        // Update order values and track reordering
        for (index, category) in updatedCategories.enumerated() {
            let oldOrder = category.order
            updatedCategories[index] = HabitCategory(
                id: category.id,
                name: category.name,
                displayName: category.displayName,
                emoji: category.emoji,
                order: index,
                isActive: category.isActive,
                isPredefined: category.isPredefined
            )
            
            // Track reordering if order changed
            if oldOrder != index {
                userActionTracker.track(.categoryReordered(
                    categoryId: category.id,
                    fromOrder: oldOrder,
                    toOrder: index
                ))
            }
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
    
    public func deleteCategory(_ categoryId: String) async {
        error = nil
        
        guard let category = categories.first(where: { $0.id == categoryId }),
              !category.isPredefined else {
            return
        }
        
        do {
            // Get habits count before deletion for tracking
            let habitsCount = await getHabitsCount(for: categoryId)
            
            // Handle cascading deletion - orphan habits from this category
            try await orphanHabitsFromCategoryUseCase.execute(categoryId: categoryId)
            
            // Delete the category
            try await deleteCategoryUseCase.execute(id: categoryId)
            
            // Track category deletion
            userActionTracker.track(.categoryDeleted(
                categoryId: category.id,
                categoryName: category.displayName,
                habitsCount: habitsCount
            ))
            
            // Refresh the list
            await load()
        } catch {
            self.error = error
        }
    }
}
