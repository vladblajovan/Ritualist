//
//  HabitMaintenanceService.swift
//  RitualistCore
//
//  Created by Phase 2 Consolidation on 13.11.2025.
//

import Foundation
import SwiftData

/// Protocol for habit maintenance operations
/// Handles cleanup and maintenance tasks for habit data integrity
public protocol HabitMaintenanceServiceProtocol {
    /// Cleanup orphaned habits that reference non-existent categories
    /// Returns the count of habits deleted
    func cleanupOrphanedHabits() async throws -> Int
}

/// Service that handles habit maintenance operations
/// Extracted from HabitLocalDataSource for proper layer separation
/// Uses @ModelActor for background thread database operations
@ModelActor
public actor HabitMaintenanceService: HabitMaintenanceServiceProtocol {

    // Inline logger (cannot inject into @ModelActor - Swift Data limitation)
    private let logger = DebugLogger(subsystem: "com.ritualist.app", category: "data")

    /// Cleanup orphaned habits that reference non-existent categories
    /// This maintains data integrity by removing habits that point to deleted categories
    /// Returns the count of habits that were deleted
    public func cleanupOrphanedHabits() async throws -> Int {
        do {
            // Get all habits
            let habitDescriptor = FetchDescriptor<ActiveHabitModel>()
            let allHabits = try modelContext.fetch(habitDescriptor)

            // Get all existing category IDs
            let categoryDescriptor = FetchDescriptor<ActiveHabitCategoryModel>()
            let allCategories = try modelContext.fetch(categoryDescriptor)
            let existingCategoryIds = Set(allCategories.map { $0.id })

            // Find habits with invalid category references through relationship
            let orphanedHabits = allHabits.filter { habit in
                // Check if habit has a category relationship that points to a deleted category
                if let category = habit.category {
                    let isOrphaned = !existingCategoryIds.contains(category.id)
                    return isOrphaned
                }
                return false // Habits with nil category are fine
            }

            // Delete orphaned habits
            for habit in orphanedHabits {
                modelContext.delete(habit)
            }

            try modelContext.save()

            return orphanedHabits.count

        } catch {
            logger.log("Error during orphaned habits cleanup: \(error)", level: .error, category: .dataIntegrity)
            throw error
        }
    }
}
