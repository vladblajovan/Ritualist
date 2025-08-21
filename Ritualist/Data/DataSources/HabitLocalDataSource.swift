import Foundation
import SwiftData
import RitualistCore

/// @ModelActor implementation of HabitLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor HabitLocalDataSource: HabitLocalDataSourceProtocol {
    
    /// Fetch all habits from background thread, return Domain models
    public func fetchAll() async throws -> [Habit] {
        do {
            let descriptor = FetchDescriptor<HabitModel>(
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
            let descriptor = FetchDescriptor<HabitModel>(
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
            let descriptor = FetchDescriptor<HabitModel>(
                predicate: #Predicate { $0.id == habit.id }
            )
            
            if let existing = try modelContext.fetch(descriptor).first {
                // Update existing habit properties
                existing.name = habit.name
                existing.colorHex = habit.colorHex
                existing.emoji = habit.emoji
            existing.kindRaw = (habit.kind == .binary) ? 0 : 1
            existing.unitLabel = habit.unitLabel
            existing.dailyTarget = habit.dailyTarget
            existing.scheduleData = try JSONEncoder().encode(habit.schedule)
            existing.remindersData = try JSONEncoder().encode(habit.reminders)
            existing.startDate = habit.startDate
            existing.endDate = habit.endDate
            existing.isActive = habit.isActive
            existing.displayOrder = habit.displayOrder
            existing.categoryId = habit.categoryId
            existing.suggestionId = habit.suggestionId
        } else {
            // Create new habit in this ModelContext
            let habitModel = try HabitModel.fromEntity(habit, context: modelContext)
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
            let descriptor = FetchDescriptor<HabitModel>(predicate: #Predicate { $0.id == id })
            let habits = try modelContext.fetch(descriptor)
            
            for habit in habits {
                modelContext.delete(habit)
            }
            
            try modelContext.save()
            
            // Verify deletion worked
            let verifyDescriptor = FetchDescriptor<HabitModel>(predicate: #Predicate { $0.id == id })
            let remainingHabits = try modelContext.fetch(verifyDescriptor)
        } catch {
            // TODO: Add error handler integration when DI allows it
            throw error
        }
    }
    
    /// Cleanup orphaned habits that reference non-existent categories
    public func cleanupOrphanedHabits() async throws -> Int {
        do {
            // Get all habits
            let habitDescriptor = FetchDescriptor<HabitModel>()
            let allHabits = try modelContext.fetch(habitDescriptor)
            
            // Get all existing category IDs
            let categoryDescriptor = FetchDescriptor<HabitCategoryModel>()
            let allCategories = try modelContext.fetch(categoryDescriptor)
            let existingCategoryIds = Set(allCategories.map { $0.id })
            
            
            // Find habits with invalid category references
            let orphanedHabits = allHabits.filter { habit in
                if let categoryId = habit.categoryId, !categoryId.isEmpty {
                    let isOrphaned = !existingCategoryIds.contains(categoryId)
                    return isOrphaned
                }
                return false // Habits with nil categoryId are fine
            }
        
            // Delete orphaned habits
            for habit in orphanedHabits {
                modelContext.delete(habit)
            }
            
            try modelContext.save()
            
            return orphanedHabits.count
            
        } catch {
            print("🧹 [DEBUG] Error during orphaned habits cleanup: \(error)")
            throw error
        }
    }
}
