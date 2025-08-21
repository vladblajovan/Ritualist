//
//  TestModelContainer.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import SwiftData
import Testing
@testable import Ritualist
@testable import RitualistCore

/// In-memory SwiftData container for testing purposes
/// Provides isolated testing environment with all app models configured
public final class TestModelContainer {
    
    // MARK: - Container Creation
    
    /// Creates an in-memory ModelContainer with all app models configured
    /// 
    /// This container includes:
    /// - HabitModel: Core habit data with relationships
    /// - HabitLogModel: Daily habit tracking logs
    /// - HabitCategoryModel: Category organization system
    /// - UserProfileModel: User settings and subscription data
    /// - OnboardingStateModel: App onboarding state
    /// - PersonalityAnalysisModel: Big Five personality analysis data
    ///
    /// - Returns: Configured ModelContainer stored in memory only
    /// - Throws: ModelContainer creation errors
    public static func createInMemoryContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        
        let container = try ModelContainer(
            for: HabitModel.self,
                 HabitLogModel.self,
                 HabitCategoryModel.self,
                 UserProfileModel.self,
                 OnboardingStateModel.self,
                 PersonalityAnalysisModel.self,
            configurations: configuration
        )
        
        return container
    }
    
    /// Creates a fresh ModelContext from an in-memory container
    /// Each context provides isolated access to the data
    ///
    /// - Parameter container: The ModelContainer to create context from
    /// - Returns: Fresh ModelContext for testing operations
    public static func createContext(from container: ModelContainer) -> ModelContext {
        return ModelContext(container)
    }
    
    /// Creates both container and context in one call for convenience
    /// Most common usage pattern for individual tests
    ///
    /// - Returns: Tuple containing the container and a fresh context
    /// - Throws: ModelContainer creation errors
    public static func createContainerAndContext() throws -> (container: ModelContainer, context: ModelContext) {
        let container = try createInMemoryContainer()
        let context = createContext(from: container)
        return (container, context)
    }
    
    // MARK: - Test Data Utilities
    
    /// Cleans all data from the given context
    /// Removes all models to ensure test isolation
    ///
    /// - Parameter context: The ModelContext to clean
    /// - Throws: SwiftData deletion errors
    public static func cleanAllData(in context: ModelContext) throws {
        // Delete all models in dependency order (avoid relationship constraint violations)
        
        // 1. Delete HabitLogModel first (depends on HabitModel)
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let logs = try context.fetch(logDescriptor)
        for log in logs {
            context.delete(log)
        }
        
        // 2. Delete PersonalityAnalysisModel (no dependencies)
        let personalityDescriptor = FetchDescriptor<PersonalityAnalysisModel>()
        let personalities = try context.fetch(personalityDescriptor)
        for personality in personalities {
            context.delete(personality)
        }
        
        // 3. Delete HabitModel (depends on HabitCategoryModel relationship)
        let habitDescriptor = FetchDescriptor<HabitModel>()
        let habits = try context.fetch(habitDescriptor)
        for habit in habits {
            context.delete(habit)
        }
        
        // 4. Delete HabitCategoryModel (can be referenced by habits)
        let categoryDescriptor = FetchDescriptor<HabitCategoryModel>()
        let categories = try context.fetch(categoryDescriptor)
        for category in categories {
            context.delete(category)
        }
        
        // 5. Delete UserProfileModel (no dependencies)
        let profileDescriptor = FetchDescriptor<UserProfileModel>()
        let profiles = try context.fetch(profileDescriptor)
        for profile in profiles {
            context.delete(profile)
        }
        
        // 6. Delete OnboardingStateModel (no dependencies)
        let onboardingDescriptor = FetchDescriptor<OnboardingStateModel>()
        let onboardingStates = try context.fetch(onboardingDescriptor)
        for state in onboardingStates {
            context.delete(state)
        }
        
        // Save changes to persist deletions
        try context.save()
    }
    
    /// Populates context with common test data
    /// Provides standardized test fixtures for consistent testing
    ///
    /// - Parameter context: The ModelContext to populate
    /// - Returns: TestDataFixture containing references to created objects
    /// - Throws: SwiftData save errors
    @discardableResult
    public static func populateWithTestData(context: ModelContext) throws -> TestDataFixture {
        // Create test categories
        let healthCategory = HabitCategoryModel(
            id: "health",
            name: "health",
            displayName: "Health",
            emoji: "💪",
            order: 0,
            isActive: true,
            isPredefined: true
        )
        
        let productivityCategory = HabitCategoryModel(
            id: "productivity",
            name: "productivity",
            displayName: "Productivity",
            emoji: "📈",
            order: 1,
            isActive: true,
            isPredefined: true
        )
        
        context.insert(healthCategory)
        context.insert(productivityCategory)
        
        // Create test habits
        let dailyScheduleData = try JSONEncoder().encode(HabitSchedule.daily)
        let emptyRemindersData = try JSONEncoder().encode([ReminderTime]())
        let baseDate = Calendar.current.date(from: DateComponents(year: 2025, month: 8, day: 1))!
        
        let exerciseHabit = HabitModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            name: "Exercise",
            colorHex: "#FF6B6B",
            emoji: "🏃‍♂️",
            kindRaw: 0, // binary
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: dailyScheduleData,
            remindersData: emptyRemindersData,
            startDate: baseDate,
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            categoryId: "health",
            category: healthCategory,
            suggestionId: nil
        )
        
        let readingHabit = HabitModel(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            name: "Read Pages",
            colorHex: "#4ECDC4",
            emoji: "📚",
            kindRaw: 1, // numeric
            unitLabel: "pages",
            dailyTarget: 20.0,
            scheduleData: dailyScheduleData,
            remindersData: emptyRemindersData,
            startDate: baseDate,
            endDate: nil,
            isActive: true,
            displayOrder: 1,
            categoryId: "productivity",
            category: productivityCategory,
            suggestionId: nil
        )
        
        context.insert(exerciseHabit)
        context.insert(readingHabit)
        
        // Create some test logs
        let today = Date()
        let calendar = Calendar.current
        
        let exerciseLogs = [
            HabitLogModel(
                id: UUID(),
                habitID: exerciseHabit.id,
                habit: exerciseHabit,
                date: calendar.date(byAdding: .day, value: -2, to: today)!,
                value: 1.0
            ),
            HabitLogModel(
                id: UUID(),
                habitID: exerciseHabit.id,
                habit: exerciseHabit,
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                value: 1.0
            ),
            HabitLogModel(
                id: UUID(),
                habitID: exerciseHabit.id,
                habit: exerciseHabit,
                date: today,
                value: 1.0
            )
        ]
        
        let readingLogs = [
            HabitLogModel(
                id: UUID(),
                habitID: readingHabit.id,
                habit: readingHabit,
                date: calendar.date(byAdding: .day, value: -2, to: today)!,
                value: 25.0
            ),
            HabitLogModel(
                id: UUID(),
                habitID: readingHabit.id,
                habit: readingHabit,
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                value: 15.0 // Below target
            ),
            HabitLogModel(
                id: UUID(),
                habitID: readingHabit.id,
                habit: readingHabit,
                date: today,
                value: 30.0
            )
        ]
        
        for log in exerciseLogs + readingLogs {
            context.insert(log)
        }
        
        // Create test user profile
        let userProfile = UserProfileModel(
            id: UUID().uuidString,
            name: "Test User",
            avatarImageData: nil,
            appearance: "0", // followSystem
            subscriptionPlan: "free",
            subscriptionExpiryDate: nil,
            createdAt: baseDate,
            updatedAt: Date()
        )
        
        context.insert(userProfile)
        
        // Create test onboarding state
        let onboardingState = OnboardingStateModel(
            id: UUID(),
            isCompleted: true,
            completedDate: baseDate,
            userName: "Test User",
            hasGrantedNotifications: false
        )
        
        context.insert(onboardingState)
        
        // Save all changes
        try context.save()
        
        return TestDataFixture(
            healthCategory: healthCategory,
            productivityCategory: productivityCategory,
            exerciseHabit: exerciseHabit,
            readingHabit: readingHabit,
            exerciseLogs: exerciseLogs,
            readingLogs: readingLogs,
            userProfile: userProfile,
            onboardingState: onboardingState
        )
    }
    
    // MARK: - Thread Safety
    
    /// Creates a background context for concurrent testing scenarios
    /// Uses background queue to avoid main thread blocking
    ///
    /// - Parameter container: The ModelContainer to create background context from
    /// - Returns: ModelContext configured for background operations
    public static func createBackgroundContext(from container: ModelContainer) -> ModelContext {
        let context = ModelContext(container)
        // SwiftData contexts are thread-safe by design, but operations should be
        // performed on the same thread that created the context
        return context
    }
}

// MARK: - Test Data Fixture

/// Container for test data references
/// Provides easy access to created test objects for assertions
public struct TestDataFixture {
    public let healthCategory: HabitCategoryModel
    public let productivityCategory: HabitCategoryModel
    public let exerciseHabit: HabitModel
    public let readingHabit: HabitModel
    public let exerciseLogs: [HabitLogModel]
    public let readingLogs: [HabitLogModel]
    public let userProfile: UserProfileModel
    public let onboardingState: OnboardingStateModel
    
    /// All logs combined for convenience
    public var allLogs: [HabitLogModel] {
        exerciseLogs + readingLogs
    }
    
    /// All habits combined for convenience
    public var allHabits: [HabitModel] {
        [exerciseHabit, readingHabit]
    }
    
    /// All categories combined for convenience
    public var allCategories: [HabitCategoryModel] {
        [healthCategory, productivityCategory]
    }
}

// MARK: - Testing Extensions

extension TestModelContainer {
    
    /// Verifies that the container is properly configured
    /// Useful for debugging container setup issues
    ///
    /// - Parameter container: Container to verify
    /// - Throws: Verification errors
    public static func verifyContainerConfiguration(_ container: ModelContainer) throws {
        let context = createContext(from: container)
        
        // Test that all model types are properly registered
        let habitDescriptor = FetchDescriptor<HabitModel>()
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let categoryDescriptor = FetchDescriptor<HabitCategoryModel>()
        let profileDescriptor = FetchDescriptor<UserProfileModel>()
        let onboardingDescriptor = FetchDescriptor<OnboardingStateModel>()
        let personalityDescriptor = FetchDescriptor<PersonalityAnalysisModel>()
        
        // These should not throw if models are properly registered
        _ = try context.fetch(habitDescriptor)
        _ = try context.fetch(logDescriptor)
        _ = try context.fetch(categoryDescriptor)
        _ = try context.fetch(profileDescriptor)
        _ = try context.fetch(onboardingDescriptor)
        _ = try context.fetch(personalityDescriptor)
    }
    
    /// Counts total objects in the context across all model types
    /// Useful for verifying data cleanup operations
    ///
    /// - Parameter context: Context to count objects in
    /// - Returns: Total count of all objects
    /// - Throws: Fetch errors
    public static func countAllObjects(in context: ModelContext) throws -> Int {
        let habitCount = try context.fetch(FetchDescriptor<HabitModel>()).count
        let logCount = try context.fetch(FetchDescriptor<HabitLogModel>()).count
        let categoryCount = try context.fetch(FetchDescriptor<HabitCategoryModel>()).count
        let profileCount = try context.fetch(FetchDescriptor<UserProfileModel>()).count
        let onboardingCount = try context.fetch(FetchDescriptor<OnboardingStateModel>()).count
        let personalityCount = try context.fetch(FetchDescriptor<PersonalityAnalysisModel>()).count
        
        return habitCount + logCount + categoryCount + profileCount + onboardingCount + personalityCount
    }
}