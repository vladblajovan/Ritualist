import Foundation
import SwiftData
import RitualistCore

/// @ModelActor implementation of HabitLocalDataSource
/// Runs database operations on background actor thread for optimal performance
@ModelActor
public actor HabitLocalDataSource: HabitLocalDataSourceProtocol {
    
    /// Fetch all habits from background thread, return Domain models
    public func fetchAll() async throws -> [Habit] {
        let descriptor = FetchDescriptor<SDHabit>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        let sdHabits = try modelContext.fetch(descriptor)
        return try sdHabits.map { try HabitMapper.fromSD($0) }
    }
    
    /// Insert or update habit on background thread - accepts Domain model
    public func upsert(_ habit: Habit) async throws {
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
    }
    
    /// Delete habit by ID on background thread
    public func delete(id: UUID) async throws {
        let descriptor = FetchDescriptor<SDHabit>(predicate: #Predicate { $0.id == id })
        let habits = try modelContext.fetch(descriptor)
        
        for habit in habits {
            modelContext.delete(habit)
        }
        try modelContext.save()
    }
}