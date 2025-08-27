//
//  TestModelContainerExample.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Testing
import Foundation
import SwiftData
@testable import Ritualist
@testable import RitualistCore

/// Example demonstrating how to use TestModelContainer for repository testing
/// This shows common patterns for testing data layer components
struct TestModelContainerExample {
    
    // MARK: - Basic Usage Pattern
    
    @Test("Basic TestModelContainer usage example")
    func basicUsageExample() throws {
        // Create in-memory container and context
        let (container, context) = try TestModelContainer.createContainerAndContext()
        
        // Your test logic here using the context
        let habits = try context.fetch(FetchDescriptor<HabitModel>())
        #expect(habits.isEmpty)
        
        // Container is automatically cleaned up when test completes
    }
    
    // MARK: - Repository Testing Pattern
    
    @Test("Repository testing with TestModelContainer")
    func repositoryTestingExample() throws {
        // Setup: Create test environment
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        // Populate with test data
        let fixture = try TestModelContainer.populateWithTestData(context: context)
        
        // Test your repository operations
        let habits = try context.fetch(FetchDescriptor<HabitModel>())
        #expect(habits.count == 2)
        
        // Verify specific test data
        let exerciseHabit = fixture.exerciseHabit
        #expect(exerciseHabit.name == "Exercise")
        #expect(exerciseHabit.kindRaw == 0) // binary
        
        let readingHabit = fixture.readingHabit
        #expect(readingHabit.name == "Read Pages")
        #expect(readingHabit.kindRaw == 1) // numeric
        #expect(readingHabit.dailyTarget == 20.0)
    }
    
    // MARK: - Multiple Test Isolation Pattern
    
    @Test("Test isolation example - multiple contexts")
    func testIsolationExample() throws {
        // Each test gets its own isolated container
        let (_, context1) = try TestModelContainer.createContainerAndContext()
        let (_, context2) = try TestModelContainer.createContainerAndContext()
        
        // Add data to first context
        let habit1 = HabitModel(
            id: UUID(),
            name: "Context 1 Habit",
            colorHex: "#FF0000",
            emoji: "1️⃣",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([ReminderTime]()),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            category: nil,
            suggestionId: nil
        )
        context1.insert(habit1)
        try context1.save()
        
        // Add different data to second context
        let habit2 = HabitModel(
            id: UUID(),
            name: "Context 2 Habit",
            colorHex: "#00FF00",
            emoji: "2️⃣",
            kindRaw: 0,
            unitLabel: nil,
            dailyTarget: nil,
            scheduleData: try JSONEncoder().encode(HabitSchedule.daily),
            remindersData: try JSONEncoder().encode([ReminderTime]()),
            startDate: Date(),
            endDate: nil,
            isActive: true,
            displayOrder: 0,
            category: nil,
            suggestionId: nil
        )
        context2.insert(habit2)
        try context2.save()
        
        // Verify isolation - each context only sees its own data
        let habits1 = try context1.fetch(FetchDescriptor<HabitModel>())
        let habits2 = try context2.fetch(FetchDescriptor<HabitModel>())
        
        #expect(habits1.count == 1)
        #expect(habits2.count == 1)
        #expect(habits1.first?.name == "Context 1 Habit")
        #expect(habits2.first?.name == "Context 2 Habit")
    }
    
    // MARK: - Data Cleanup Pattern
    
    @Test("Data cleanup for test reuse")
    func dataCleanupExample() throws {
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        // Setup test data
        try TestModelContainer.populateWithTestData(context: context)
        
        // Verify data exists
        let initialCount = try TestModelContainer.countAllObjects(in: context)
        #expect(initialCount > 0)
        
        // Your test operations here...
        
        // Clean up for next test phase (if needed)
        try TestModelContainer.cleanAllData(in: context)
        
        // Verify cleanup
        let finalCount = try TestModelContainer.countAllObjects(in: context)
        #expect(finalCount == 0)
        
        // Can now start fresh for additional test scenarios
    }
    
    // MARK: - Relationship Testing Pattern
    
    @Test("Testing SwiftData relationships")
    func relationshipTestingExample() throws {
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        // Use test fixture to verify relationships work correctly
        let fixture = try TestModelContainer.populateWithTestData(context: context)
        
        // Test habit-category relationship
        let exerciseHabit = fixture.exerciseHabit
        #expect(exerciseHabit.category != nil)
        #expect(exerciseHabit.category?.id == "health")
        // categoryId removed - using relationship only
        
        // Test habit-log relationship
        #expect(exerciseHabit.logs.count == 3)
        
        // Test category-habits inverse relationship
        let healthCategory = fixture.healthCategory
        #expect(healthCategory.habits.contains(exerciseHabit))
        
        // Test log-habit relationship
        let firstLog = fixture.exerciseLogs.first!
        #expect(firstLog.habit === exerciseHabit)
        #expect(firstLog.habitID == exerciseHabit.id)
    }
    
    // MARK: - Error Handling Pattern
    
    @Test("Error handling in repository tests")
    func errorHandlingExample() throws {
        let (_, context) = try TestModelContainer.createContainerAndContext()
        
        // Test error conditions safely
        do {
            // This should work fine
            try TestModelContainer.verifyContainerConfiguration(context.container)
            
            // This might throw in actual repository code
            let invalidDescriptor = FetchDescriptor<HabitModel>(predicate: #Predicate { _ in false })
            let results = try context.fetch(invalidDescriptor)
            #expect(results.isEmpty)
            
        } catch {
            // Handle specific errors in your repository tests
            #expect(false, "Unexpected error: \(error)")
        }
    }
}

// MARK: - Usage Guidelines

/*
 TESTMODELCONTAINER USAGE PATTERNS:
 
 1. BASIC SETUP:
    - Use createContainerAndContext() for simple tests
    - Container is automatically in-memory and isolated
 
 2. WITH TEST DATA:
    - Use populateWithTestData() for consistent fixtures
    - Access specific objects via TestDataFixture properties
 
 3. CUSTOM DATA:
    - Create your own models using the context
    - Use proper SwiftData relationships
 
 4. CLEANUP:
    - Usually not needed (in-memory container discarded)
    - Use cleanAllData() if reusing context within same test
 
 5. ISOLATION:
    - Each createContainerAndContext() call creates separate database
    - Perfect for testing different scenarios independently
 
 6. REPOSITORY INTEGRATION:
    - Pass the context to your repository implementations
    - Test repository methods with known test data
 
 7. PERFORMANCE:
    - In-memory storage is fast for tests
    - No file I/O overhead
    - Perfect for unit test suites
*/