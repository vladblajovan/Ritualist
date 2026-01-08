import Foundation
import SwiftData

/// @ModelActor implementation of HabitLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor HabitLocalDataSource: HabitLocalDataSourceProtocol {

    /// Local logger instance - @ModelActor cannot use DI injection (SwiftData limitation)
    private let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "data")

    /// Fetch all habits from background thread, return Domain models
    public func fetchAll() async throws -> [Habit] {
        do {
            let descriptor = FetchDescriptor<ActiveHabitModel>(
                sortBy: [SortDescriptor(\.displayOrder)]
            )
            let habits = try modelContext.fetch(descriptor)
            let entities = try habits.compactMap { try $0.toEntity() }

            logger.log(
                "Fetched all habits",
                level: .debug,
                category: .dataIntegrity,
                metadata: ["count": habits.count, "converted": entities.count]
            )

            return entities
        } catch {
            logger.log(
                "Failed to fetch all habits",
                level: .error,
                category: .dataIntegrity,
                metadata: ["error": error.localizedDescription]
            )
            throw error
        }
    }

    /// Fetch a single habit by ID from background thread, return Domain model
    public func fetch(by id: UUID) async throws -> Habit? {
        do {
            let descriptor = FetchDescriptor<ActiveHabitModel>(
                predicate: #Predicate { $0.id == id }
            )
            let habits = try modelContext.fetch(descriptor)
            let entity = try habits.first?.toEntity()

            if entity == nil {
                logger.log(
                    "Habit not found",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["habit_id": id.uuidString]
                )
            }

            return entity
        } catch {
            logger.log(
                "Failed to fetch habit by ID",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": id.uuidString, "error": error.localizedDescription]
            )
            throw error
        }
    }

    /// Insert or update habit on background thread - accepts Domain model
    public func upsert(_ habit: Habit) async throws {
        // Validate habit ID is not empty (UUID zero is technically valid but suspicious)
        let habitIdString = habit.id.uuidString
        guard !habitIdString.isEmpty else {
            logger.log(
                "Attempted to upsert habit with empty ID",
                level: .error,
                category: .dataIntegrity
            )
            throw HabitDataSourceError.invalidHabitId
        }

        do {
            // Check if habit already exists
            let descriptor = FetchDescriptor<ActiveHabitModel>(
                predicate: #Predicate { $0.id == habit.id }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                // Update existing habit using shared mapping logic
                try existing.updateFromEntity(habit, context: modelContext, logger: logger)

                logger.log(
                    "Updated existing habit",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["habit_id": habitIdString, "name": habit.name]
                )
            } else {
                // Create new habit in this ModelContext
                let habitModel = try ActiveHabitModel.fromEntity(habit, context: modelContext)
                modelContext.insert(habitModel)

                logger.log(
                    "Created new habit",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["habit_id": habitIdString, "name": habit.name]
                )
            }

            try modelContext.save()
        } catch {
            logger.log(
                "Failed to upsert habit",
                level: .error,
                category: .dataIntegrity,
                metadata: [
                    "habit_id": habitIdString,
                    "name": habit.name,
                    "error": error.localizedDescription
                ]
            )
            throw error
        }
    }

    /// Delete habit by ID on background thread
    public func delete(id: UUID) async throws {
        do {
            let descriptor = FetchDescriptor<ActiveHabitModel>(predicate: #Predicate { $0.id == id })
            let habits = try modelContext.fetch(descriptor)

            let deletedCount = habits.count
            for habit in habits {
                modelContext.delete(habit)
            }

            try modelContext.save()

            // Verify deletion worked
            let verifyDescriptor = FetchDescriptor<ActiveHabitModel>(predicate: #Predicate { $0.id == id })
            let remainingHabits = try modelContext.fetch(verifyDescriptor)

            if remainingHabits.isEmpty {
                logger.log(
                    "Deleted habit successfully",
                    level: .debug,
                    category: .dataIntegrity,
                    metadata: ["habit_id": id.uuidString, "deleted_count": deletedCount]
                )
            } else {
                logger.log(
                    "Habit deletion may have failed - records still exist",
                    level: .warning,
                    category: .dataIntegrity,
                    metadata: ["habit_id": id.uuidString, "remaining_count": remainingHabits.count]
                )
            }
        } catch {
            logger.log(
                "Failed to delete habit",
                level: .error,
                category: .dataIntegrity,
                metadata: ["habit_id": id.uuidString, "error": error.localizedDescription]
            )
            throw error
        }
    }

    /// Cleanup orphaned habits that reference non-existent categories
    /// Delegates to HabitMaintenanceService for proper layer separation
    public func cleanupOrphanedHabits() async throws -> Int {
        let maintenanceService = HabitMaintenanceService(modelContainer: modelContainer)
        let cleanedCount = try await maintenanceService.cleanupOrphanedHabits()

        if cleanedCount > 0 {
            logger.log(
                "Cleaned up orphaned habits",
                level: .info,
                category: .dataIntegrity,
                metadata: ["cleaned_count": cleanedCount]
            )
        }

        return cleanedCount
    }
}

// MARK: - Habit Data Source Errors

public enum HabitDataSourceError: LocalizedError {
    case invalidHabitId

    public var errorDescription: String? {
        switch self {
        case .invalidHabitId:
            return "Cannot save habit with empty or invalid ID"
        }
    }
}
