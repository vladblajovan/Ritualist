import Foundation
import SwiftData

/// @ModelActor implementation of HabitLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor HabitLocalDataSource: HabitLocalDataSourceProtocol {
    
    /// Fetch all habits from background thread, return Domain models
    public func fetchAll() async throws -> [Habit] {
        do {
            let descriptor = FetchDescriptor<ActiveHabitModel>(
                sortBy: [SortDescriptor(\.displayOrder)]
            )
            let habits = try modelContext.fetch(descriptor)
            return try habits.compactMap { try $0.toEntity() }
        } catch {
            // TODO: Add error handler integration when DI allows it
            // For now, just re-throw the error
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
            return try habits.first?.toEntity()
        } catch {
            // TODO: Add error handler integration when DI allows it
            // For now, just re-throw the error
            throw error
        }
    }
    
    /// Insert or update habit on background thread - accepts Domain model
    public func upsert(_ habit: Habit) async throws {
        do {
            // Check if habit already exists
            let descriptor = FetchDescriptor<ActiveHabitModel>(
                predicate: #Predicate { $0.id == habit.id }
            )

            if let existing = try modelContext.fetch(descriptor).first {
                // Update existing habit using shared mapping logic
                // Local logger: @ModelActor cannot use DI injection (SwiftData limitation)
                let logger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "data")
                try existing.updateFromEntity(habit, context: modelContext, logger: logger)
        } else {
            // Create new habit in this ModelContext
            let habitModel = try ActiveHabitModel.fromEntity(habit, context: modelContext)
            modelContext.insert(habitModel)
        }

        try modelContext.save()
        } catch {
            // TODO: Add error handler integration when DI allows it
            throw error
        }
    }
    
    /// Delete habit by ID on background thread
    public func delete(id: UUID) async throws {
        do {
            let descriptor = FetchDescriptor<ActiveHabitModel>(predicate: #Predicate { $0.id == id })
            let habits = try modelContext.fetch(descriptor)

            for habit in habits {
                modelContext.delete(habit)
            }

            try modelContext.save()

            // Verify deletion worked
            let verifyDescriptor = FetchDescriptor<ActiveHabitModel>(predicate: #Predicate { $0.id == id })
            let remainingHabits = try modelContext.fetch(verifyDescriptor)
        } catch {
            // TODO: Add error handler integration when DI allows it
            throw error
        }
    }
    
    /// Cleanup orphaned habits that reference non-existent categories
    /// Delegates to HabitMaintenanceService for proper layer separation
    public func cleanupOrphanedHabits() async throws -> Int {
        let maintenanceService = HabitMaintenanceService(modelContainer: modelContainer)
        return try await maintenanceService.cleanupOrphanedHabits()
    }
}
