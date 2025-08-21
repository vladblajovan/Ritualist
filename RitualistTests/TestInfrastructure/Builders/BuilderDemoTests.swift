//
//  BuilderDemoTests.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
import Testing
@testable import RitualistCore

/// Simple demonstration tests to verify builders work correctly
struct BuilderDemoTests {
    
    @Test("HabitBuilder creates valid habits")
    func testHabitBuilderBasic() throws {
        let habit = HabitBuilder()
            .withName("Test Habit")
            .withEmoji("⭐")
            .asDaily()
            .build()
        
        #expect(habit.name == "Test Habit")
        #expect(habit.emoji == "⭐")
        #expect(habit.schedule == .daily)
        #expect(habit.isActive == true)
    }
    
    @Test("HabitLogBuilder creates valid logs") 
    func testHabitLogBuilderBasic() throws {
        let habit = HabitBuilder().withName("Exercise").build()
        
        let log = HabitLogBuilder()
            .withHabit(habit)
            .forToday()
            .build()
        
        #expect(log.habitID == habit.id)
        #expect(Calendar.current.isDateInToday(log.date))
    }
    
    @Test("CategoryBuilder creates valid categories")
    func testCategoryBuilderBasic() throws {
        let category = CategoryBuilder()
            .withName("Health")
            .withEmoji("💪")
            .build()
        
        #expect(category.name == "Health")
        #expect(category.emoji == "💪")
        #expect(!category.id.isEmpty)
    }
    
    @Test("UserProfileBuilder creates valid profiles")
    func testUserProfileBuilderBasic() throws {
        let profile = UserProfileBuilder()
            .withName("Test User")
            .withFreeSubscription()
            .build()
        
        #expect(profile.name == "Test User")
        #expect(profile.subscriptionPlan == .free)
        #expect(!profile.hasActiveSubscription)
    }
    
    @Test("Predefined builders work")
    func testPredefinedBuilders() throws {
        let readingHabit = HabitBuilder.readingHabit().build()
        #expect(readingHabit.name == "Daily Reading")
        #expect(readingHabit.kind == .numeric)
        
        let healthCategory = CategoryBuilder.healthCategory().build()
        #expect(healthCategory.id == "health")
        #expect(healthCategory.isPredefined)
        
        let premiumUser = UserProfileBuilder.premiumAnnualUser().build()
        #expect(premiumUser.subscriptionPlan == .annual)
        #expect(premiumUser.hasActiveSubscription)
    }
    
    @Test("Test scenarios provide realistic data")
    func testScenarios() throws {
        let scenario = TestScenarios.newUserWithHabits()
        
        #expect(!scenario.user.name.isEmpty)
        #expect(scenario.habits.count >= 2)
        #expect(scenario.logs.count > 0)
        
        // Verify logs belong to habits
        let habitIds = Set(scenario.habits.map(\.id))
        for log in scenario.logs {
            #expect(habitIds.contains(log.habitID))
        }
    }
    
    @Test("Batch log creation works")
    func testBatchLogCreation() throws {
        let habit = HabitBuilder.waterIntakeHabit().build()
        let logs = HabitLogBuilder.createWeeklyLogs(for: habit, completionRate: 0.8)
        
        #expect(logs.count > 0)
        #expect(logs.count <= 7) // At most 7 days in a week
        #expect(logs.allSatisfy { $0.habitID == habit.id })
    }
}