import Foundation

// MARK: - Habit Use Case Implementations

public final class CreateHabit: CreateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws -> Habit { 
        // Business logic: Set display order to be last
        let existingHabits = try await repo.fetchAllHabits()
        let maxOrder = existingHabits.map(\.displayOrder).max() ?? -1
        
        let habitWithOrder = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: habit.endDate,
            isActive: habit.isActive,
            displayOrder: maxOrder + 1,
            categoryId: habit.categoryId,
            suggestionId: habit.suggestionId,
            locationConfiguration: habit.locationConfiguration
        )
        
        try await repo.update(habitWithOrder)
        return habitWithOrder
    }
}

public final class GetAllHabits: GetAllHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] { 
        let habits = try await repo.fetchAllHabits()
        return habits.sorted { $0.displayOrder < $1.displayOrder }
    }
}

public final class UpdateHabit: UpdateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws { try await repo.update(habit) }
}

public final class DeleteHabit: DeleteHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws { 
        // SwiftData cascade delete will automatically remove associated logs
        try await repo.delete(id: id) 
    }
}

public final class ToggleHabitActiveStatus: ToggleHabitActiveStatusUseCase {
    private let repo: HabitRepository
    private let locationMonitoringService: LocationMonitoringService?

    public init(repo: HabitRepository, locationMonitoringService: LocationMonitoringService? = nil) {
        self.repo = repo
        self.locationMonitoringService = locationMonitoringService
    }

    public func execute(id: UUID) async throws -> Habit {
        let allHabits = try await repo.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == id }) else {
            throw HabitError.habitNotFound(id: id)
        }

        let newActiveStatus = !habit.isActive

        let updatedHabit = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: habit.endDate,
            isActive: newActiveStatus,
            displayOrder: habit.displayOrder,
            categoryId: habit.categoryId,
            suggestionId: habit.suggestionId,
            locationConfiguration: habit.locationConfiguration
        )

        try await repo.update(updatedHabit)

        // Handle location monitoring based on active status
        if let locationService = locationMonitoringService,
           let locationConfig = habit.locationConfiguration,
           locationConfig.isEnabled {
            if newActiveStatus {
                // Reactivating habit - restore location monitoring
                try await locationService.startMonitoring(habitId: id, configuration: locationConfig)
            } else {
                // Deactivating habit - stop location monitoring (but keep config)
                await locationService.stopMonitoring(habitId: id)
            }
        }

        return updatedHabit
    }
}

public final class ReorderHabits: ReorderHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habits: [Habit]) async throws {
        // Business logic: Update display order for each habit
        var updatedHabits: [Habit] = []
        for (index, habit) in habits.enumerated() {
            let updatedHabit = Habit(
                id: habit.id,
                name: habit.name,
                colorHex: habit.colorHex,
                emoji: habit.emoji,
                kind: habit.kind,
                unitLabel: habit.unitLabel,
                dailyTarget: habit.dailyTarget,
                schedule: habit.schedule,
                reminders: habit.reminders,
                startDate: habit.startDate,
                endDate: habit.endDate,
                isActive: habit.isActive,
                displayOrder: index,
                categoryId: habit.categoryId,
                suggestionId: habit.suggestionId,
                locationConfiguration: habit.locationConfiguration
            )
            updatedHabits.append(updatedHabit)
        }
        
        // Update all habits with new order
        for habit in updatedHabits {
            try await repo.update(habit)
        }
    }
}

public final class ValidateHabitUniqueness: ValidateHabitUniquenessUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute(name: String, categoryId: String?, excludeId: UUID?) async throws -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allHabits = try await repo.fetchAllHabits()
        
        // Check for duplicate: same name AND same categoryId
        let isDuplicate = allHabits.contains { habit in
            // Skip the habit being edited (if any)
            if let excludeId = excludeId, habit.id == excludeId {
                return false
            }
            
            // Check if name matches
            let nameMatches = habit.name.lowercased() == trimmedName
            
            // Check if category matches (both nil, or both have same value)
            let categoryMatches = (habit.categoryId == categoryId)
            
            return nameMatches && categoryMatches
        }
        
        return !isDuplicate  // Return true if unique (no duplicate found)
    }
}

public final class GetHabitsByCategory: GetHabitsByCategoryUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute(categoryId: String) async throws -> [Habit] {
        let allHabits = try await repo.fetchAllHabits()
        return allHabits.filter { $0.categoryId == categoryId }
    }
}

public final class OrphanHabitsFromCategory: OrphanHabitsFromCategoryUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute(categoryId: String) async throws {
        let habitsInCategory = try await GetHabitsByCategory(repo: repo).execute(categoryId: categoryId)
        
        // Set categoryId to nil for all habits in the deleted category
        for habit in habitsInCategory {
            let orphanedHabit = Habit(
                id: habit.id,
                name: habit.name,
                colorHex: habit.colorHex,
                emoji: habit.emoji,
                kind: habit.kind,
                unitLabel: habit.unitLabel,
                dailyTarget: habit.dailyTarget,
                schedule: habit.schedule,
                reminders: habit.reminders,
                startDate: habit.startDate,
                endDate: habit.endDate,
                isActive: habit.isActive,
                displayOrder: habit.displayOrder,
                categoryId: nil,  // Remove category association
                suggestionId: habit.suggestionId,
                locationConfiguration: habit.locationConfiguration
            )
            
            try await repo.update(orphanedHabit)
        }
    }
}

public final class CleanupOrphanedHabits: CleanupOrphanedHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute() async throws -> Int {
        // Business logic: Find habits with non-nil categoryId that don't reference existing categories
        let allHabits = try await repo.fetchAllHabits()
        let habitsWithCategories = allHabits.filter { $0.categoryId != nil }
        
        // For now, just return count since we need category repository to validate
        // In a real implementation, we'd check against existing categories
        // This is a placeholder that could be enhanced with category validation
        return 0
    }
}

public final class GetActiveHabits: GetActiveHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute() async throws -> [Habit] {
        let allHabits = try await repo.fetchAllHabits()
        return allHabits.filter { $0.isActive }.sorted { $0.displayOrder < $1.displayOrder }
    }
}

public final class GetHabitCount: GetHabitCountUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute() async -> Int {
        do {
            let habits = try await repo.fetchAllHabits()
            return habits.count
        } catch {
            return 0
        }
    }
}