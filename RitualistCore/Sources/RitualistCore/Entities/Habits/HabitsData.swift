//
//  HabitsData.swift
//  RitualistCore
//
//  Created for Habits architecture unification on 15.08.2025.
//

import Foundation

/// Single source of truth data structure for HabitsView
/// Replaces separate habits/categories loading to ensure consistency and eliminate N+1 patterns
/// Follows OverviewData/DashboardData reactive architecture patterns
public struct HabitsData {
    public let habits: [Habit]
    public let categories: [Category]
    
    public init(habits: [Habit], categories: [Category]) {
        self.habits = habits
        self.categories = categories
    }
    
    // MARK: - Helper Methods for Category Filtering
    
    /// Get all habits filtered by category and active status
    /// Returns habits from active categories only, plus uncategorized habits
    public func filteredHabits(for selectedCategory: Category?) -> [Habit] {
        let activeCategoryIds = Set(categories.map { $0.id })
        
        // First filter to only habits from active categories or habits with no category
        let habitsFromActiveCategories = habits.filter { habit in
            // Include habits with no category or habits from active categories
            habit.categoryId == nil || activeCategoryIds.contains(habit.categoryId ?? "")
        }
        
        // Then apply category filter if one is selected
        guard let selectedCategory = selectedCategory else {
            return habitsFromActiveCategories
        }
        
        return habitsFromActiveCategories.filter { habit in
            habit.categoryId == selectedCategory.id
        }
    }
    
    /// Get all active habits (not filtered by category)
    public var activeHabits: [Habit] {
        habits.filter { $0.isActive }
    }
    
    /// Get all inactive habits (not filtered by category)
    public var inactiveHabits: [Habit] {
        habits.filter { !$0.isActive }
    }
    
    /// Get habits for a specific category
    public func habits(in categoryId: String?) -> [Habit] {
        habits.filter { $0.categoryId == categoryId }
    }
    
    /// Get habits that have no category assigned
    public var uncategorizedHabits: [Habit] {
        habits.filter { $0.categoryId == nil }
    }
    
    /// Get category by ID
    public func category(withId id: String) -> Category? {
        categories.first { $0.id == id }
    }
    
    /// Get all habit IDs for performance operations
    public var habitIds: Set<UUID> {
        Set(habits.map(\.id))
    }
    
    /// Get all category IDs for performance operations  
    public var categoryIds: Set<String> {
        Set(categories.map(\.id))
    }
    
    /// Check if a habit belongs to an active category
    public func isHabitInActiveCategory(_ habit: Habit) -> Bool {
        guard let categoryId = habit.categoryId else { return true } // Uncategorized habits are always included
        return categoryIds.contains(categoryId)
    }
    
    /// Get habits count by category for analytics
    public var habitCountByCategory: [String: Int] {
        var counts: [String: Int] = [:]
        
        for habit in habits {
            let categoryKey = habit.categoryId ?? "uncategorized"
            counts[categoryKey, default: 0] += 1
        }
        
        return counts
    }
    
    /// Get active habits count (for paywall logic)
    public var activeHabitsCount: Int {
        habits.filter { $0.isActive }.count
    }
    
    /// Get total habits count
    public var totalHabitsCount: Int {
        habits.count
    }
    
    /// Get categories count
    public var categoriesCount: Int {
        categories.count
    }
}