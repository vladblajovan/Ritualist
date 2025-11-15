import Foundation
import SwiftData
@testable import RitualistCore

/// In-memory SwiftData container for testing
///
/// **Purpose:** Provide fast, isolated test environment using SwiftData's in-memory store
///
/// **Key Features:**
/// - Uses SchemaV8 (latest schema)
/// - In-memory storage (no persistent files)
/// - Tests don't interfere with each other
/// - Fast setup/teardown
/// - Full SwiftData relationship support
///
/// **Usage:**
/// ```swift
/// @Test("Binary habit completion")
/// func testBinaryHabitCompletion() async throws {
///     let container = try TestModelContainer.create()
///     let context = ModelContext(container)
///
///     // Insert test data
///     let habit = HabitBuilder.binary()
///     context.insert(habit.toModel())
///
///     try context.save()
///
///     // Run test assertions...
/// }
/// ```
public enum TestModelContainer {

    // MARK: - Container Creation

    /// Create an in-memory model container with SchemaV8
    ///
    /// - Returns: In-memory ModelContainer configured for testing
    /// - Throws: If container creation fails
    public static func create() throws -> ModelContainer {
        let schema = Schema([
            ActiveHabitModel.self,
            ActiveHabitLogModel.self,
            ActiveHabitCategoryModel.self,
            ActiveUserProfileModel.self,
            ActiveOnboardingStateModel.self,
            ActivePersonalityAnalysisModel.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true  // KEY: In-memory for fast, isolated tests
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    // MARK: - Convenience Factories

    /// Create a container pre-populated with a single habit
    ///
    /// - Parameter habit: Habit to insert
    /// - Returns: Tuple of (container, context, habitModel)
    /// - Throws: If container creation or insertion fails
    public static func withHabit(_ habit: Habit) throws -> (container: ModelContainer, context: ModelContext, habitModel: ActiveHabitModel) {
        let container = try create()
        let context = ModelContext(container)

        let habitModel = habit.toModel()
        context.insert(habitModel)
        try context.save()

        return (container, context, habitModel)
    }

    /// Create a container pre-populated with a habit and logs
    ///
    /// - Parameters:
    ///   - habit: Habit to insert
    ///   - logs: Logs to insert
    /// - Returns: Tuple of (container, context, habitModel, logModels)
    /// - Throws: If container creation or insertion fails
    public static func withHabitAndLogs(
        _ habit: Habit,
        logs: [HabitLog]
    ) throws -> (container: ModelContainer, context: ModelContext, habitModel: ActiveHabitModel, logModels: [ActiveHabitLogModel]) {
        let container = try create()
        let context = ModelContext(container)

        let habitModel = habit.toModel()
        context.insert(habitModel)

        let logModels = logs.map { log in
            let logModel = log.toModel()
            logModel.habit = habitModel  // Establish relationship
            return logModel
        }

        logModels.forEach { context.insert($0) }
        try context.save()

        return (container, context, habitModel, logModels)
    }

    /// Create a container with multiple habits
    ///
    /// - Parameter habits: Habits to insert
    /// - Returns: Tuple of (container, context, habitModels)
    /// - Throws: If container creation or insertion fails
    public static func withHabits(
        _ habits: [Habit]
    ) throws -> (container: ModelContainer, context: ModelContext, habitModels: [ActiveHabitModel]) {
        let container = try create()
        let context = ModelContext(container)

        let habitModels = habits.map { $0.toModel() }
        habitModels.forEach { context.insert($0) }
        try context.save()

        return (container, context, habitModels)
    }

    /// Create a container with categories
    ///
    /// - Parameter categories: Categories to insert
    /// - Returns: Tuple of (container, context, categoryModels)
    /// - Throws: If container creation or insertion fails
    public static func withCategories(
        _ categories: [HabitCategory]
    ) throws -> (container: ModelContainer, context: ModelContext, categoryModels: [ActiveHabitCategoryModel]) {
        let container = try create()
        let context = ModelContext(container)

        let categoryModels = categories.map { $0.toModel() }
        categoryModels.forEach { context.insert($0) }
        try context.save()

        return (container, context, categoryModels)
    }

    // MARK: - Test Cleanup

    /// Clean up test data from a container
    ///
    /// **Note:** With in-memory storage, this is technically unnecessary
    /// since the container is discarded after the test, but it's provided
    /// for explicit cleanup if needed.
    ///
    /// - Parameter container: Container to clean up
    /// - Throws: If deletion fails
    public static func cleanup(_ container: ModelContainer) throws {
        let context = ModelContext(container)

        // Delete all habits (will cascade to logs due to delete rule)
        try context.delete(model: ActiveHabitModel.self)

        // Delete all categories
        try context.delete(model: ActiveHabitCategoryModel.self)

        // Delete all user profiles
        try context.delete(model: ActiveUserProfileModel.self)

        // Delete all onboarding states
        try context.delete(model: ActiveOnboardingStateModel.self)

        // Delete all personality analyses
        try context.delete(model: ActivePersonalityAnalysisModel.self)

        try context.save()
    }

    // MARK: - Query Helpers

    /// Fetch all habits from a context
    ///
    /// - Parameter context: Model context to query
    /// - Returns: Array of HabitModel instances
    /// - Throws: If fetch fails
    public static func fetchAllHabits(from context: ModelContext) throws -> [ActiveHabitModel] {
        let descriptor = FetchDescriptor<ActiveHabitModel>()
        return try context.fetch(descriptor)
    }

    /// Fetch all logs from a context
    ///
    /// - Parameter context: Model context to query
    /// - Returns: Array of HabitLogModel instances
    /// - Throws: If fetch fails
    public static func fetchAllLogs(from context: ModelContext) throws -> [ActiveHabitLogModel] {
        let descriptor = FetchDescriptor<ActiveHabitLogModel>()
        return try context.fetch(descriptor)
    }

    /// Fetch logs for a specific habit
    ///
    /// - Parameters:
    ///   - habitId: ID of the habit
    ///   - context: Model context to query
    /// - Returns: Array of HabitLogModel instances
    /// - Throws: If fetch fails
    public static func fetchLogs(
        for habitId: UUID,
        from context: ModelContext
    ) throws -> [ActiveHabitLogModel] {
        let descriptor = FetchDescriptor<ActiveHabitLogModel>(
            predicate: #Predicate { log in
                log.habitID == habitId
            }
        )
        return try context.fetch(descriptor)
    }

    /// Fetch all categories from a context
    ///
    /// - Parameter context: Model context to query
    /// - Returns: Array of HabitCategoryModel instances
    /// - Throws: If fetch fails
    public static func fetchAllCategories(from context: ModelContext) throws -> [ActiveHabitCategoryModel] {
        let descriptor = FetchDescriptor<ActiveHabitCategoryModel>()
        return try context.fetch(descriptor)
    }
}

// MARK: - Conversion Helpers

extension Habit {
    /// Convert domain Habit to ActiveHabitModel for testing
    func toModel() -> ActiveHabitModel {
        return ActiveHabitModel(
            id: self.id,
            name: self.name,
            colorHex: self.colorHex,
            emoji: self.emoji,
            kindRaw: self.kind == .binary ? 0 : 1,  // binary=0, numeric=1
            unitLabel: self.unitLabel,
            dailyTarget: self.dailyTarget,
            scheduleData: try! JSONEncoder().encode(self.schedule),
            remindersData: try! JSONEncoder().encode(self.reminders),
            startDate: self.startDate,
            endDate: self.endDate,
            isActive: self.isActive,
            displayOrder: self.displayOrder,
            category: nil,  // Categories loaded separately
            suggestionId: self.suggestionId,
            notes: self.notes,
            lastCompletedDate: self.lastCompletedDate,
            archivedDate: self.archivedDate,
            locationConfigData: self.locationConfiguration.flatMap { try? JSONEncoder().encode($0) },
            lastGeofenceTriggerDate: nil
        )
    }
}

extension HabitLog {
    /// Convert domain HabitLog to ActiveHabitLogModel for testing
    func toModel() -> ActiveHabitLogModel {
        return ActiveHabitLogModel(
            id: self.id,
            habitID: self.habitID,
            habit: nil,  // Relationship set separately
            date: self.date,
            value: self.value,
            timezone: self.timezone
        )
    }
}

extension HabitCategory {
    /// Convert domain HabitCategory to ActiveHabitCategoryModel for testing
    func toModel() -> ActiveHabitCategoryModel {
        return ActiveHabitCategoryModel(
            id: self.id,
            name: self.name,
            displayName: self.displayName,
            emoji: self.emoji,
            order: self.order,
            isActive: self.isActive,
            isPredefined: self.isPredefined
        )
    }
}
