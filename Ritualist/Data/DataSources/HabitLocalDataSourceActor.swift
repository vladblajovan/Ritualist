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
            let descriptor = FetchDescriptor<SDHabit>(
                sortBy: [SortDescriptor(\.displayOrder)]
            )
            let sdHabits = try modelContext.fetch(descriptor)
            return try sdHabits.map { try HabitMapper.fromSD($0) }
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
            let descriptor = FetchDescriptor<SDHabit>(
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
            let sdHabit = try HabitMapper.toSD(habit, context: modelContext)
            modelContext.insert(sdHabit)
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
            print("🗑️ [DEBUG] Attempting to delete habit with ID: \(id)")
            
            let descriptor = FetchDescriptor<SDHabit>(predicate: #Predicate { $0.id == id })
            let habits = try modelContext.fetch(descriptor)
            
            print("🗑️ [DEBUG] Found \(habits.count) habits to delete")
            
            for habit in habits {
                print("🗑️ [DEBUG] Deleting habit: \(habit.name) (ID: \(habit.id))")
                modelContext.delete(habit)
            }
            
            try modelContext.save()
            print("🗑️ [DEBUG] Successfully saved deletion to database")
            
            // Verify deletion worked
            let verifyDescriptor = FetchDescriptor<SDHabit>(predicate: #Predicate { $0.id == id })
            let remainingHabits = try modelContext.fetch(verifyDescriptor)
            print("🗑️ [DEBUG] After deletion, found \(remainingHabits.count) habits with that ID (should be 0)")
            
        } catch {
            print("🗑️ [DEBUG] Error during habit deletion: \(error)")
            // TODO: Add error handler integration when DI allows it
            throw error
        }
    }
    
    /// Cleanup orphaned habits that reference non-existent categories
    public func cleanupOrphanedHabits() async throws -> Int {
        do {
            print("🧹 [DEBUG] Starting cleanup of orphaned habits...")
            
            // Get all habits
            let habitDescriptor = FetchDescriptor<SDHabit>()
            let allHabits = try modelContext.fetch(habitDescriptor)
            
            // Get all existing category IDs
            let categoryDescriptor = FetchDescriptor<SDCategory>()
            let allCategories = try modelContext.fetch(categoryDescriptor)
            let existingCategoryIds = Set(allCategories.map { $0.id })
            
            print("🧹 [DEBUG] Found \(allHabits.count) habits and \(allCategories.count) categories")
            print("🧹 [DEBUG] Existing category IDs: \(existingCategoryIds)")
            
            // Find habits with invalid category references
            let orphanedHabits = allHabits.filter { habit in
                if let categoryId = habit.categoryId, !categoryId.isEmpty {
                    let isOrphaned = !existingCategoryIds.contains(categoryId)
                    if isOrphaned {
                        print("🧹 [DEBUG] ORPHANED: \(habit.name) references non-existent category: \(categoryId)")
                    }
                    return isOrphaned
                }
                return false // Habits with nil categoryId are fine
            }
            
            print("🧹 [DEBUG] Found \(orphanedHabits.count) orphaned habits to delete")
            
            // Delete orphaned habits
            for habit in orphanedHabits {
                print("🧹 [DEBUG] Deleting orphaned habit: \(habit.name) (ID: \(habit.id), categoryId: \(habit.categoryId ?? "nil"))")
                modelContext.delete(habit)
            }
            
            try modelContext.save()
            print("🧹 [DEBUG] Successfully cleaned up \(orphanedHabits.count) orphaned habits")
            
            return orphanedHabits.count
            
        } catch {
            print("🧹 [DEBUG] Error during orphaned habits cleanup: \(error)")
            throw error
        }
    }
}