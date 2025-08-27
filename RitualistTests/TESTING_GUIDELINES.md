# 🧪 Ritualist Testing Guidelines

## Overview

This document establishes the testing patterns and guidelines for the Ritualist project, based on the clean architecture principles established in **Phase 0** and the testing infrastructure setup in **Phase 1A**.

## Core Testing Philosophy

### ✅ **The Clean Pattern (USE THIS)**
- **Real implementations** with **real data**
- **TestModelContainer** for in-memory database
- **Test actual business logic**, not mock behavior
- **Integration-style tests** that verify end-to-end functionality

### ❌ **Anti-Pattern (AVOID)**
- Mock-heavy tests that test mock behavior
- Stub methods returning hardcoded values (0, nil, empty arrays)
- Testing implementation details instead of behavior
- Isolated unit tests that don't test real interactions

## Architecture Compliance

### **Clean Architecture Flow**
```
Views → ViewModels → UseCases → Services/Repositories → Data
```

### **Testing Flow**
```
Test → ViewModel (real) → UseCase (real) → Repository (real) → TestModelContainer
```

**NEVER bypass this flow with mocks in business logic tests!**

## Testing Patterns

### 1. **ViewModel Testing Pattern**

```swift
// ✅ CORRECT: Clean ViewModel Test
import Testing
import Foundation
import SwiftData
@testable import Ritualist
@testable import RitualistCore

@Suite("ViewModel Clean Tests")
@MainActor
final class ExampleViewModelTests {
    
    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    
    init() async throws {
        // Set up real database infrastructure
        let (container, context) = try TestModelContainer.createContainerAndContext()
        testContainer = container
        testContext = context
    }
    
    private func createViewModel() -> ExampleViewModel {
        // Use real ViewModel with real UseCase implementations
        return ExampleViewModel()
    }
    
    private func setupTestData() async throws {
        // Use builders to create real test data in the database
        let habit = HabitModelBuilder()
            .with(name: "Test Habit")
            .with(schedule: .daily)
            .build()
        
        testContext.insert(habit)
        try testContext.save()
    }
    
    @Test("should load data correctly")
    func testDataLoading() async throws {
        // Arrange: Set up real test data
        try await setupTestData()
        let vm = createViewModel()
        
        // Act: Trigger real business operation
        await vm.load()
        
        // Assert: Verify real results
        #expect(vm.habits.count == 1)
        #expect(vm.habits.first?.name == "Test Habit")
    }
}
```

### 2. **UseCase Testing Pattern**

```swift
// ✅ CORRECT: Clean UseCase Test
@Suite("UseCase Clean Tests")
@MainActor
final class ExampleUseCaseTests {
    
    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    
    init() async throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        testContainer = container
        testContext = context
    }
    
    @Test("should execute business logic correctly")
    func testBusinessLogic() async throws {
        // Arrange: Set up real data with builders
        let habit = TestHabit.readingHabit().build()
        // Insert real data into test database...
        
        // Create real UseCase with real repository
        let useCase = GetActiveHabits(
            habitAnalyticsService: Container.shared.habitAnalyticsService(),
            userService: Container.shared.userService()
        )
        
        // Act: Execute real business logic
        let result = try await useCase.execute()
        
        // Assert: Verify real calculations
        #expect(result.count == 1)
        #expect(result.first?.isActive == true)
    }
}
```

### 3. **Service Testing Pattern**

```swift
// ✅ CORRECT: Service Utility Test
@Suite("Service Utility Tests")
final class ExampleServiceTests {
    
    @Test("should calculate correctly")
    func testCalculation() {
        // Arrange: Set up real inputs
        let service = HabitCompletionCalculatorService()
        let habit = TestHabit.dailyHabit().build()
        let logs = [TestHabitLog.completed().build()]
        
        // Act: Test real calculation
        let result = service.calculateProgress(habit: habit, logs: logs)
        
        // Assert: Verify real calculation
        #expect(result == 1.0)
    }
}
```

## Test Data Management

### **Use Builders, Not Hardcoded Data**

```swift
// ✅ CORRECT: Use builders
let habit = TestHabit.readingHabit()
    .withName("Custom Reading")
    .withSchedule(.daily)
    .withReminders([ReminderTime(hour: 9, minute: 0)])
    .build()

// ❌ WRONG: Hardcoded data
let habit = Habit(
    id: UUID(),
    name: "Reading",
    // ... 20 more parameters
)
```

### **Available Test Builders**

- `TestHabit` / `HabitBuilder` - For creating habit test data
- `TestHabitLog` / `HabitLogBuilder` - For creating log test data  
- `TestCategory` / `CategoryBuilder` - For creating category test data
- `TestUserProfile` / `UserProfileBuilder` - For creating user test data

### **Test Scenarios**

Use predefined scenarios for common testing needs:

```swift
// Complete user with habits and logs
let scenario = TestScenarios.newUserWithHabits()
let user = scenario.user
let habits = scenario.habits
let logs = scenario.logs

// Premium user with advanced features
let premiumScenario = TestScenarios.premiumUserWithAdvancedHabits()
```

## TestModelContainer Usage

### **Basic Setup**

```swift
private var testContainer: ModelContainer!
private var testContext: ModelContext!

init() async throws {
    let (container, context) = try TestModelContainer.createContainerAndContext()
    testContainer = container
    testContext = context
}
```

### **Data Insertion**

```swift
private func setupTestData() async throws {
    let habit = HabitModelBuilder().with(name: "Test").build()
    testContext.insert(habit)
    try testContext.save()
}
```

### **Data Cleanup**

Cleanup is handled automatically by TestModelContainer - each test gets a fresh in-memory database.

## Examples from Codebase

### **✅ Good Examples to Follow**

1. **OverviewViewModelSimpleTests.swift** - Perfect example of clean ViewModel testing
2. **NotificationUseCaseCleanTests.swift** - Good UseCase testing pattern
3. **HabitRepositoryImplTests.swift** - Repository integration testing
4. **NumberUtilsTests.swift** - Simple utility testing

### **❌ Bad Examples (Marked for Migration)**

1. **PersonalityAnalysisServiceTests.swift** - Uses MockRepository
2. **ViewModelTrackingIntegrationTests.swift** - Uses MockUseCases
3. **HabitCompletionServiceTests.swift** - Has mock dependencies

These will be migrated to clean patterns in Phase 1B+4B.

## Test Categories

### **Tests to Keep Running (Good Tests)**
- Utility tests (NumberUtilsTests, DateUtilsTests, etc.)
- Repository integration tests (already use TestModelContainer)
- Clean examples from Phase 0

### **Tests Marked for Migration (Mock-Heavy)**
- Tests with `@available(*, deprecated)` annotation
- Will be completely rewritten in Phase 1B+4B
- **DO NOT fix these during Phases 2-4A** - let them fail

### **Tests to Delete**
- Obsolete test patterns
- Tests for deleted code
- Mock-heavy tests that can't be salvaged

## Performance Considerations

### **Test Execution Speed**
- TestModelContainer is fast (in-memory)
- Avoid unnecessary async/await in simple tests
- Use builders to minimize test setup time

### **Memory Usage**
- Each test gets a fresh database - no memory leaks
- Builders reuse common patterns efficiently
- Avoid creating large datasets unless testing performance

## Migration Strategy

### **Phase 1A** (Current)
- Document patterns ✅
- Mark mock tests as deprecated
- Don't write extensive new tests

### **Phases 2-4A** 
- Keep good tests running
- **Ignore failures in deprecated tests** - don't fix them
- Focus on architecture cleanup

### **Phase 1B+4B**
- Migrate all tests to clean pattern
- Delete all mock-based tests  
- Write comprehensive test suite for clean architecture

## Dos and Don'ts

### **✅ DO**
- Use real implementations with TestModelContainer
- Test actual business logic and calculations
- Use builders for consistent test data
- Follow the established clean patterns
- Write integration-style tests

### **❌ DON'T**
- Use mocks for business logic testing
- Return hardcoded values from stubs (0, nil, [])
- Test mock behavior instead of real behavior
- Bypass the Clean Architecture flow
- Fix deprecated mock tests during refactoring phases

## Getting Help

- **Reference**: Look at `OverviewViewModelSimpleTests.swift` for patterns
- **Builders**: Check `TestBuilders.swift` for available test data builders
- **Scenarios**: Use `TestScenarios` for common test setups
- **Infrastructure**: See `TestModelContainer.swift` for database setup

## Summary

The key principle: **Test real behavior with real data**. Our Phase 0 success in achieving zero architecture violations was enabled by this approach. Let's maintain this standard throughout all future development.

---

*This document will be updated as testing patterns evolve through the remaining phases.*