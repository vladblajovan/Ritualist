import Foundation
import SwiftData

/// @ModelActor implementation of CategoryLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor CategoryLocalDataSource: CategoryLocalDataSourceProtocol {

    /// Local logger instance - @ModelActor cannot use DI injection (SwiftData limitation)
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "data")

    private let categoryDefinitionsService: CategoryDefinitionsServiceProtocol = CategoryDefinitionsService()

    private var predefinedCategories: [HabitCategory] {
        categoryDefinitionsService.getPredefinedCategories()
    }

    private func getStoredCategories() async throws -> [HabitCategory] {
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
        let categories = try modelContext.fetch(descriptor)
        return categories.map { $0.toEntity() }
    }

    public func getAllCategories() async throws -> [HabitCategory] {
        do {
            // After seeding, all categories (predefined + custom) are in the database
            // Just fetch from database to avoid duplicates
            let categories = try await getStoredCategories().sorted { $0.order < $1.order }
            return categories
        } catch {
            logger.log(
                "Failed to fetch all categories",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }

    public func getCategory(by id: String) async throws -> HabitCategory? {
        do {
            // After seeding, all categories are in the database - fetch from there
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.id == id }
            )
            return try modelContext.fetch(descriptor).first?.toEntity()
        } catch {
            logger.log(
                "Failed to fetch category by ID",
                level: .error,
                category: .dataIntegrity,
                metadata: ["category_id": id, "error": error.localizedDescription]
            )
            throw error
        }
    }

    public func getActiveCategories() async throws -> [HabitCategory] {
        do {
            // After seeding, all categories are in the database - fetch active ones from there
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.isActive == true }
            )
            return try modelContext.fetch(descriptor).map { $0.toEntity() }.sorted { $0.order < $1.order }
        } catch {
            logger.log(
                "Failed to fetch active categories",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }

    public func getPredefinedCategories() async throws -> [HabitCategory] {
        do {
            // After seeding, predefined categories are in the database
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.isPredefined == true && $0.isActive == true }
            )
            return try modelContext.fetch(descriptor).map { $0.toEntity() }
        } catch {
            logger.log(
                "Failed to fetch predefined categories",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }

    public func getCustomCategories() async throws -> [HabitCategory] {
        do {
            // Custom categories are those created by user (not predefined)
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.isPredefined == false && $0.isActive == true }
            )
            return try modelContext.fetch(descriptor).map { $0.toEntity() }
        } catch {
            logger.log(
                "Failed to fetch custom categories",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }

    public func createCustomCategory(_ category: HabitCategory) async throws {
        // Validate category ID is not empty
        guard !category.id.isEmpty else {
            logger.log(
                "Attempted to create category with empty ID",
                level: .error,
                category: .dataIntegrity
            )
            throw CategoryDataSourceError.invalidCategoryId
        }

        do {
            let categoryModel = ActiveHabitCategoryModel.fromEntity(category)
            modelContext.insert(categoryModel)
            try modelContext.save()

            logger.log(
                "Created custom category",
                level: .debug,
                category: .dataIntegrity,
                metadata: ["category_id": category.id, "name": category.name]
            )
        } catch {
            logger.log(
                "Failed to create custom category",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "category_id": category.id,
                    "name": category.name,
                    "error": error.localizedDescription
                ]
            )
            throw error
        }
    }

    public func updateCategory(_ category: HabitCategory) async throws {
        // Validate category ID is not empty
        guard !category.id.isEmpty else {
            logger.log(
                "Attempted to update category with empty ID",
                level: .error,
                category: .dataIntegrity
            )
            throw CategoryDataSourceError.invalidCategoryId
        }

        do {
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.id == category.id }
            )

            if let existingCategory = try modelContext.fetch(descriptor).first {
                // Update existing category
                existingCategory.name = category.name
                existingCategory.displayName = category.displayName
                existingCategory.emoji = category.emoji
                existingCategory.order = category.order
                existingCategory.isActive = category.isActive
                existingCategory.isPredefined = category.isPredefined
                try modelContext.save()

                logger.log(
                    "Updated existing category",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["category_id": category.id, "name": category.name]
                )
            } else {
                // Create new category if it doesn't exist
                let categoryModel = ActiveHabitCategoryModel.fromEntity(category)
                modelContext.insert(categoryModel)
                try modelContext.save()

                logger.log(
                    "Created category (did not exist for update)",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["category_id": category.id, "name": category.name]
                )
            }
        } catch {
            logger.log(
                "Failed to update category",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "category_id": category.id,
                    "name": category.name,
                    "error": error.localizedDescription
                ]
            )
            throw error
        }
    }

    public func deleteCategory(id: String) async throws {
        do {
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.id == id }
            )

            let categories = try modelContext.fetch(descriptor)
            let deletedCount = categories.count

            for category in categories {
                modelContext.delete(category)
            }
            try modelContext.save()

            logger.log(
                "Deleted category",
                level: .debug,
                category: .dataIntegrity,
                metadata: ["category_id": id, "deleted_count": deletedCount]
            )
        } catch {
            logger.log(
                "Failed to delete category",
                level: .error,
                category: .dataIntegrity,
                metadata: ["category_id": id, "error": error.localizedDescription]
            )
            throw error
        }
    }

    public func categoryExists(id: String) async throws -> Bool {
        do {
            // Only check database - predefined categories need to be persisted too
            let descriptor = FetchDescriptor<ActiveHabitCategoryModel>(
                predicate: #Predicate { $0.id == id }
            )
            return try !modelContext.fetch(descriptor).isEmpty
        } catch {
            logger.log(
                "Failed to check category existence by ID",
                level: .error,
                category: .dataIntegrity,
                metadata: ["category_id": id, "error": error.localizedDescription]
            )
            throw error
        }
    }

    public func categoryExists(name: String) async throws -> Bool {
        do {
            let lowercasedName = name.lowercased()

            // After seeding, all categories are in the database - check there
            // Note: SwiftData doesn't support case-insensitive predicates directly,
            // so we fetch just the names and compare in memory
            var descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
            descriptor.propertiesToFetch = [\.name] // Only fetch name field, not full models
            let storedCategories = try modelContext.fetch(descriptor)
            return storedCategories.contains { $0.name.lowercased() == lowercasedName }
        } catch {
            logger.log(
                "Failed to check category existence by name",
                level: .error,
                category: .dataIntegrity,
                metadata: ["name": name, "error": error.localizedDescription]
            )
            throw error
        }
    }
}
