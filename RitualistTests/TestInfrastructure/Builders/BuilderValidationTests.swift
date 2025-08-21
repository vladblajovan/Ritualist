//
//  BuilderValidationTests.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import SwiftData
import Testing
@testable import Ritualist
@testable import RitualistCore

/// Comprehensive validation tests for all test builders
/// Ensures builders integrate correctly with TestModelContainer infrastructure
struct BuilderValidationTests {
    
    // MARK: - Basic Builder Validation Tests
    
    @Test("All builders can create valid entities")
    func testAllBuildersCreateValidEntities() throws {
        // Test HabitBuilder
        let habit = HabitBuilder()
            .withName("Test Habit")
            .build()
        
        #expect(!habit.name.isEmpty)
        #expect(habit.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        #expect(habit.isActive)
        
        // Test HabitLogBuilder
        let log = HabitLogBuilder()
            .withHabit(habit)
            .withDate(Date())
            .build()
        
        #expect(log.habitID == habit.id)
        #expect(log.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
        
        // Test CategoryBuilder
        let category = CategoryBuilder()
            .withName("Test Category")
            .build()
        
        #expect(!category.name.isEmpty)
        #expect(!category.id.isEmpty)
        #expect(!category.emoji.isEmpty)
        
        // Test UserProfileBuilder
        let userProfile = UserProfileBuilder()
            .withName("Test User")
            .build()
        
        #expect(!userProfile.name.isEmpty)
        #expect(userProfile.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000")!)
    }
    
    @Test("TestBuilders convenience methods work correctly")
    func testConvenienceMethods() throws {
        let habit = TestBuilders.simpleHabit(name: "Convenience Habit")
        let log = TestBuilders.simpleLog(for: habit, daysAgo: 1)
        let category = TestBuilders.simpleCategory(name: "Convenience Category")
        let user = TestBuilders.simpleUser(name: "Convenience User")
        
        #expect(habit.name == "Convenience Habit")
        #expect(log.habitID == habit.id)
        #expect(category.name == "Convenience Category")
        #expect(user.name == "Convenience User")
    }
    
    @Test("Builder validation utility works")
    func testBuilderValidation() throws {
        let isValid = TestBuilders.validateAllBuilders()
        #expect(isValid)
    }
    
    // MARK: - TestModelContainer Integration Tests
    
    @Test("Builders work with TestModelContainer")
    func testBuildersWithModelContainer() throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        
        // Clean any existing data
        try TestModelContainer.cleanAllData(in: context)
        
        // Create entities using builders
        let category = CategoryBuilder.healthCategory().build()
        let habit = HabitBuilder.workoutHabit()
            .withCategory(category)
            .build()
        let log = HabitLogBuilder()
            .withHabit(habit)
            .forToday()
            .build()
        let user = UserProfileBuilder.premiumAnnualUser().build()
        
        // Convert to SwiftData models and save
        let categoryModel = try HabitCategoryModel.fromEntity(category)
        let habitModel = try HabitModel.fromEntity(habit, context: context)
        let logModel = try HabitLogModel.fromEntity(log)
        let userModel = try UserProfileModel.fromEntity(user)
        
        context.insert(categoryModel)
        context.insert(habitModel)
        context.insert(logModel)
        context.insert(userModel)
        
        try context.save()
        
        // Verify data was saved correctly
        let habitDescriptor = FetchDescriptor<HabitModel>()
        let savedHabits = try context.fetch(habitDescriptor)
        
        #expect(savedHabits.count == 1)
        #expect(savedHabits.first?.name == "Morning Workout")
        #expect(savedHabits.first?.categoryId == "health")
        
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let savedLogs = try context.fetch(logDescriptor)
        
        #expect(savedLogs.count == 1)
        #expect(savedLogs.first?.habitID == habit.id)
    }
    
    @Test("Batch log creation works with TestModelContainer")
    func testBatchLogCreationWithContainer() throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        try TestModelContainer.cleanAllData(in: context)
        
        // Create habit using builder
        let habit = HabitBuilder.waterIntakeHabit().build()
        
        // Create batch logs using builder
        let logs = HabitLogBuilder.createWeeklyLogs(for: habit, completionRate: 0.7)
        
        // Convert and save to container
        let habitModel = try HabitModel.fromEntity(habit, context: context)
        context.insert(habitModel)
        
        for log in logs {
            let logModel = try HabitLogModel.fromEntity(log)
            context.insert(logModel)
        }
        
        try context.save()
        
        // Verify logs were created with realistic completion rate
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let savedLogs = try context.fetch(logDescriptor)
        
        #expect(savedLogs.count > 0)
        #expect(savedLogs.count <= 7) // At most 7 days in a week
        #expect(savedLogs.allSatisfy { $0.habitID == habit.id })
    }
    
    // MARK: - Test Scenario Integration Tests
    
    @Test("TestScenarios work with TestModelContainer")
    func testScenariosWithContainer() throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        try TestModelContainer.cleanAllData(in: context)
        
        // Use a test scenario
        let scenario = TestScenarios.newUserWithHabits()
        
        // Convert and save all entities
        let userModel = try UserProfileModel.fromEntity(scenario.user)
        context.insert(userModel)
        
        for habit in scenario.habits {
            let habitModel = try HabitModel.fromEntity(habit, context: context)
            context.insert(habitModel)
        }
        
        for log in scenario.logs {
            let logModel = try HabitLogModel.fromEntity(log)
            context.insert(logModel)
        }
        
        try context.save()
        
        // Verify scenario data was saved correctly
        let habitDescriptor = FetchDescriptor<HabitModel>()
        let savedHabits = try context.fetch(habitDescriptor)
        
        #expect(savedHabits.count == scenario.habits.count)
        #expect(savedHabits.contains { $0.name == "Daily Reading" })
        #expect(savedHabits.contains { $0.name == "Morning Workout" })
        
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let savedLogs = try context.fetch(logDescriptor)
        
        #expect(savedLogs.count == scenario.logs.count)
        #expect(savedLogs.allSatisfy { log in 
            scenario.habits.contains { $0.id == log.habitID }
        })
    }
    
    @Test("Advanced scenario with categories works")
    func testAdvancedScenarioWithCategories() throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        try TestModelContainer.cleanAllData(in: context)
        
        // Use advanced scenario with categories
        let scenario = TestScenarios.premiumUserWithAdvancedHabits()
        
        // Convert and save all entities
        let userModel = try UserProfileModel.fromEntity(scenario.user)
        context.insert(userModel)
        
        for category in scenario.categories {
            let categoryModel = try HabitCategoryModel.fromEntity(category)
            context.insert(categoryModel)
        }
        
        for habit in scenario.habits {
            let habitModel = try HabitModel.fromEntity(habit, context: context)
            context.insert(habitModel)
        }
        
        for log in scenario.logs {
            let logModel = try HabitLogModel.fromEntity(log)
            context.insert(logModel)
        }
        
        try context.save()
        
        // Verify advanced scenario works
        let categoryDescriptor = FetchDescriptor<HabitCategoryModel>()
        let savedCategories = try context.fetch(categoryDescriptor)
        
        #expect(savedCategories.count >= 4) // At least health, learning, mindfulness categories
        
        let habitDescriptor = FetchDescriptor<HabitModel>()
        let savedHabits = try context.fetch(habitDescriptor)
        
        #expect(savedHabits.count == 4) // Reading, workout, water, meditation
        #expect(savedHabits.allSatisfy { $0.categoryId != nil })
        
        // Verify relationships
        for habitModel in savedHabits {
            if let categoryId = habitModel.categoryId {
                let matchingCategory = savedCategories.first { $0.id == categoryId }
                #expect(matchingCategory != nil, "Habit should have matching category")
            }
        }
    }
    
    // MARK: - Builder Pattern Variations Tests
    
    @Test("HabitBuilder supports all schedule types")
    func testHabitBuilderScheduleTypes() throws {
        let dailyHabit = HabitBuilder().asDaily().build()
        #expect(dailyHabit.schedule == .daily)
        
        let weekdayHabit = HabitBuilder().forDaysOfWeek([1, 2, 3, 4, 5]).build()
        if case .daysOfWeek(let days) = weekdayHabit.schedule {
            #expect(days == Set([1, 2, 3, 4, 5]))
        } else {
            Issue.record("Expected daysOfWeek schedule")
        }
        
        let flexibleHabit = HabitBuilder().forTimesPerWeek(3).build()
        if case .timesPerWeek(let times) = flexibleHabit.schedule {
            #expect(times == 3)
        } else {
            Issue.record("Expected timesPerWeek schedule")
        }
    }
    
    @Test("HabitBuilder supports both habit types")
    func testHabitBuilderTypes() throws {
        let binaryHabit = HabitBuilder().asBinary().build()
        #expect(binaryHabit.kind == .binary)
        #expect(binaryHabit.dailyTarget == nil)
        #expect(binaryHabit.unitLabel == nil)
        
        let numericHabit = HabitBuilder().asNumeric(target: 5.0, unit: "cups").build()
        #expect(numericHabit.kind == .numeric)
        #expect(numericHabit.dailyTarget == 5.0)
        #expect(numericHabit.unitLabel == "cups")
    }
    
    @Test("HabitLogBuilder supports date utilities")
    func testHabitLogBuilderDateUtilities() throws {
        let habit = TestBuilders.simpleHabit()
        
        let todayLog = HabitLogBuilder().withHabit(habit).forToday().build()
        let today = Date()
        let calendar = Calendar.current
        
        #expect(calendar.isDate(todayLog.date, inSameDayAs: today))
        
        let pastLog = HabitLogBuilder().withHabit(habit).forDaysAgo(7).build()
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        
        #expect(calendar.isDate(pastLog.date, inSameDayAs: weekAgo))
        
        let futureLog = HabitLogBuilder().withHabit(habit).forDaysFromNow(3).build()
        let threeDaysFromNow = calendar.date(byAdding: .day, value: 3, to: today)!
        
        #expect(calendar.isDate(futureLog.date, inSameDayAs: threeDaysFromNow))
    }
    
    @Test("CategoryBuilder supports predefined categories")
    func testCategoryBuilderPredefined() throws {
        let healthCategory = CategoryBuilder.healthCategory().build()
        
        #expect(healthCategory.id == "health")
        #expect(healthCategory.name == "Health & Fitness")
        #expect(healthCategory.emoji == "🏃‍♂️")
        #expect(healthCategory.isPredefined)
        #expect(healthCategory.isActive)
        
        let customCategory = CategoryBuilder.customCategory(name: "My Custom Category").build()
        
        #expect(!customCategory.isPredefined)
        #expect(customCategory.name == "My Custom Category")
        #expect(customCategory.displayName == "My Custom Category")
    }
    
    @Test("UserProfileBuilder supports subscription states")
    func testUserProfileBuilderSubscriptions() throws {
        let freeUser = UserProfileBuilder().withFreeSubscription().build()
        #expect(freeUser.subscriptionPlan == .free)
        #expect(!freeUser.hasActiveSubscription)
        
        let premiumUser = UserProfileBuilder()
            .withMonthlySubscription()
            .withActiveSubscription()
            .build()
        
        #expect(premiumUser.subscriptionPlan == .monthly)
        #expect(premiumUser.hasActiveSubscription)
        #expect(premiumUser.isPremiumUser)
        
        let expiredUser = UserProfileBuilder()
            .withAnnualSubscription()
            .withExpiredSubscription()
            .build()
        
        #expect(expiredUser.subscriptionPlan == .annual)
        #expect(!expiredUser.hasActiveSubscription)
        #expect(!expiredUser.isPremiumUser)
    }
    
    // MARK: - Log Pattern Tests
    
    @Test("Log patterns create realistic data")
    func testLogPatterns() throws {
        let habit = TestBuilders.simpleHabit()
        
        // Test consistent pattern
        let consistentLogs = HabitLogBuilder.createMonthlyLogs(for: habit, pattern: .consistent)
        let consistentCount = consistentLogs.count
        #expect(consistentCount > 20) // Should have high completion rate
        
        // Test perfect pattern
        let perfectLogs = HabitLogBuilder.createMonthlyLogs(for: habit, pattern: .perfect)
        #expect(perfectLogs.count == 30) // Should have logs for every day
        
        // Test sporadic pattern
        let sporadicLogs = HabitLogBuilder.createMonthlyLogs(for: habit, pattern: .sporadic)
        #expect(sporadicLogs.count < consistentCount) // Should have fewer logs
        
        // Test weekends only pattern
        let weekendLogs = HabitLogBuilder.createMonthlyLogs(for: habit, pattern: .weekendsOnly)
        let calendar = Calendar.current
        
        for log in weekendLogs {
            let weekday = calendar.component(.weekday, from: log.date)
            #expect(weekday == 1 || weekday == 7) // Sunday (1) or Saturday (7)
        }
    }
    
    // MARK: - Performance Tests
    
    @Test("Batch operations perform well")
    func testBatchOperationPerformance() throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        try TestModelContainer.cleanAllData(in: context)
        
        let startTime = Date()
        
        // Create large batch of test data
        let habits = (0..<50).map { index in
            HabitBuilder()
                .withName("Habit \(index)")
                .withDisplayOrder(index)
                .build()
        }
        
        let logs = habits.flatMap { habit in
            HabitLogBuilder.createWeeklyLogs(for: habit, completionRate: 0.8)
        }
        
        // Save to container
        for habit in habits {
            let habitModel = try HabitModel.fromEntity(habit, context: context)
            context.insert(habitModel)
        }
        
        for log in logs {
            let logModel = try HabitLogModel.fromEntity(log)
            context.insert(logModel)
        }
        
        try context.save()
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust based on your performance requirements)
        #expect(duration < 5.0, "Batch operation took too long: \(duration) seconds")
        
        // Verify all data was saved
        let habitDescriptor = FetchDescriptor<HabitModel>()
        let savedHabits = try context.fetch(habitDescriptor)
        #expect(savedHabits.count == 50)
        
        let logDescriptor = FetchDescriptor<HabitLogModel>()
        let savedLogs = try context.fetch(logDescriptor)
        #expect(savedLogs.count == logs.count)
    }
}

// MARK: - Helper Extensions

// Note: fromEntity methods are implemented in the actual data model files