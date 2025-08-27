//
//  TestModelContainerTests.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Testing
import Foundation
import SwiftData
@testable import Ritualist
@testable import RitualistCore

/// Tests for TestModelContainer functionality
/// Verifies the testing infrastructure works correctly for all models
struct TestModelContainerTests {
    
    // MARK: - Container Creation Tests
    
    @Test("Creates in-memory container successfully")
    func createInMemoryContainerSuccess() throws {
        let container = try TestModelContainer.createInMemoryContainer()
        #expect(container.configurations.first?.isStoredInMemoryOnly == true)
    }
    
    @Test("Creates context from container successfully")
    func createContextFromContainer() throws {
        let container = try TestModelContainer.createInMemoryContainer()
        let context = TestModelContainer.createContext(from: container)
        #expect(context.container === container)
    }
    
    @Test("Creates container and context together")
    func createContainerAndContext() throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        #expect(container.configurations.first?.isStoredInMemoryOnly == true)
        #expect(context.container === container)
    }
    
    // MARK: - Model Registration Tests
    
    @Test("All models are properly registered")
    func allModelsRegistered() throws {
        let container = try TestModelContainer.createInMemoryContainer()
        try TestModelContainer.verifyContainerConfiguration(container)
        // If this doesn't throw, all models are properly registered
    }
    
    @Test("Can create and save models")
    func canCreateAndSaveModels() throws {
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        // Create a test category
        let category = HabitCategoryModel(
            id: "test",
            name: "test",
            displayName: "Test",
            emoji: "🧪",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context.insert(category)
        
        // Create a test habit
        let habit = HabitModel(
            id: UUID(),
            name: "Test Habit",
            colorHex: "#FF0000",
            emoji: "🎯",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([ReminderTime]()),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            category: category,
            suggestionId: nil
        )
        context.insert(habit)
        
        // Create a test log
        let log = HabitLogModel(
            id: UUID(),
            habitID: habit.id,
            habit: habit,
            date: Date(),
            value: 1.0
        )
        context.insert(log)
        
        // Save and verify
        try context.save()
        
        let habitCount = try context.fetch(FetchDescriptor<HabitModel>()).count
        let logCount = try context.fetch(FetchDescriptor<HabitLogModel>()).count
        let categoryCount = try context.fetch(FetchDescriptor<HabitCategoryModel>()).count
        
        #expect(habitCount == 1)
        #expect(logCount == 1)
        #expect(categoryCount == 1)
    }
    
    // MARK: - Data Population Tests
    
    @Test("Populates with test data successfully")
    func populateWithTestData() throws {
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        let fixture = try TestModelContainer.populateWithTestData(context: context)
        
        // Verify fixture has expected data
        #expect(fixture.allHabits.count == 2)
        #expect(fixture.allCategories.count == 2)
        #expect(fixture.allLogs.count == 6) // 3 exercise + 3 reading logs
        
        // Verify data was actually saved to context
        let habitCount = try context.fetch(FetchDescriptor<HabitModel>()).count
        let logCount = try context.fetch(FetchDescriptor<HabitLogModel>()).count
        let categoryCount = try context.fetch(FetchDescriptor<HabitCategoryModel>()).count
        let profileCount = try context.fetch(FetchDescriptor<UserProfileModel>()).count
        let onboardingCount = try context.fetch(FetchDescriptor<OnboardingStateModel>()).count
        
        #expect(habitCount == 2)
        #expect(logCount == 6)
        #expect(categoryCount == 2)
        #expect(profileCount == 1)
        #expect(onboardingCount == 1)
        
        // Verify relationships are properly set up
        let exerciseHabit = fixture.exerciseHabit
        #expect(exerciseHabit.category?.id == "health")
        #expect(exerciseHabit.logs.count == 3)
        
        let readingHabit = fixture.readingHabit
        #expect(readingHabit.category?.id == "productivity")
        #expect(readingHabit.logs.count == 3)
    }
    
    // MARK: - Data Cleanup Tests
    
    @Test("Cleans all data successfully")
    func cleanAllData() throws {
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        // First populate with test data
        try TestModelContainer.populateWithTestData(context: context)
        
        // Verify data exists
        let initialCount = try TestModelContainer.countAllObjects(in: context)
        #expect(initialCount > 0)
        
        // Clean all data
        try TestModelContainer.cleanAllData(in: context)
        
        // Verify all data is gone
        let finalCount = try TestModelContainer.countAllObjects(in: context)
        #expect(finalCount == 0)
        
        // Verify each model type is empty
        let habitCount = try context.fetch(FetchDescriptor<HabitModel>()).count
        let logCount = try context.fetch(FetchDescriptor<HabitLogModel>()).count
        let categoryCount = try context.fetch(FetchDescriptor<HabitCategoryModel>()).count
        let profileCount = try context.fetch(FetchDescriptor<UserProfileModel>()).count
        let onboardingCount = try context.fetch(FetchDescriptor<OnboardingStateModel>()).count
        let personalityCount = try context.fetch(FetchDescriptor<PersonalityAnalysisModel>()).count
        
        #expect(habitCount == 0)
        #expect(logCount == 0)
        #expect(categoryCount == 0)
        #expect(profileCount == 0)
        #expect(onboardingCount == 0)
        #expect(personalityCount == 0)
    }
    
    // MARK: - Threading Tests
    
    @Test("Background context works correctly")
    func backgroundContext() throws {
        let container = try TestModelContainer.createInMemoryContainer()
        let backgroundContext = TestModelContainer.createBackgroundContext(from: container)
        
        #expect(backgroundContext.container === container)
        
        // Test that we can perform operations on background context
        let category = HabitCategoryModel(
            id: "background-test",
            name: "background-test",
            displayName: "Background Test",
            emoji: "🔄",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        
        backgroundContext.insert(category)
        try backgroundContext.save()
        
        let count = try backgroundContext.fetch(FetchDescriptor<HabitCategoryModel>()).count
        #expect(count == 1)
    }
    
    // MARK: - Isolation Tests
    
    @Test("Contexts are isolated from each other")
    func contextIsolation() throws {
        let container1 = try TestModelContainer.createInMemoryContainer()
        let context1 = TestModelContainer.createContext(from: container1)
        
        let container2 = try TestModelContainer.createInMemoryContainer()
        let context2 = TestModelContainer.createContext(from: container2)
        
        // Add data to first context
        let category1 = HabitCategoryModel(
            id: "context1",
            name: "context1",
            displayName: "Context 1",
            emoji: "1️⃣",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context1.insert(category1)
        try context1.save()
        
        // Add data to second context
        let category2 = HabitCategoryModel(
            id: "context2",
            name: "context2",
            displayName: "Context 2",
            emoji: "2️⃣",
            order: 0,
            isActive: true,
            isPredefined: false
        )
        context2.insert(category2)
        try context2.save()
        
        // Verify isolation - each context should only see its own data
        let count1 = try context1.fetch(FetchDescriptor<HabitCategoryModel>()).count
        let count2 = try context2.fetch(FetchDescriptor<HabitCategoryModel>()).count
        
        #expect(count1 == 1)
        #expect(count2 == 1)
        
        // Verify specific data
        let categories1 = try context1.fetch(FetchDescriptor<HabitCategoryModel>())
        let categories2 = try context2.fetch(FetchDescriptor<HabitCategoryModel>())
        
        #expect(categories1.first?.id == "context1")
        #expect(categories2.first?.id == "context2")
    }
}