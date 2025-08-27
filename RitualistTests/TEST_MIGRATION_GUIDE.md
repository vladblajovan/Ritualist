# 🔄 Test Migration Guide

## Overview

This guide provides step-by-step instructions for migrating existing mock-based tests to the clean testing pattern established in Phase 0. Use this alongside `TESTING_GUIDELINES.md` for complete migration workflow.

## Migration Strategy

### **Phase Timeline**
- **Phase 1A** (Current): Mark tests as deprecated, create migration infrastructure
- **Phases 2-4A**: Keep tests running but **DO NOT FIX** mock tests
- **Phase 1B+4B**: Complete migration to clean pattern

### **Migration Approach**
1. **Keep Good Tests Running** - Repository integration tests, utility tests
2. **Mark Mock Tests as Deprecated** - Add deprecation warnings with migration notes
3. **Let Mock Tests Fail During Refactoring** - Don't spend time fixing them
4. **Complete Migration at End** - Rewrite with clean pattern in Phase 1B+4B

## Test Categories Analysis

### **✅ Keep As-Is (Good Tests)**
```swift
// These tests already follow clean patterns:
- NumberUtilsTests.swift ✅
- DateUtilsTests.swift ✅
- HabitRepositoryImplTests.swift ✅ (uses TestModelContainer)
- OverviewViewModelSimpleTests.swift ✅ (Phase 0 clean example)
- NotificationUseCaseCleanTests.swift ✅ (Phase 0 clean example)
```

### **🔄 Mark for Migration (Mock-Heavy)**
```swift
// These tests use mocks and need complete rewrite:
- PersonalityAnalysisServiceTests.swift ❌ (MockRepository pattern)
- ViewModelTrackingIntegrationTests.swift ❌ (MockUseCases pattern)  
- HabitCompletionServiceTests.swift ❌ (Mock dependencies)
- NotificationUseCaseTests.swift ❌ (MockHabitRepository, MockLogRepository)
- [8 other mock-heavy test files identified in analysis]
```

### **🗑️ Delete/Replace (Obsolete)**
```swift
// These should be deleted:
- OverviewViewModelMocks.swift ❌ (Mock implementations - already removed)
- Tests for deleted code/features
- Tests that can't be salvaged from mock pattern
```

## Step-by-Step Migration Process

### **Step 1: Analysis (5 minutes per file)**

**Before migrating any test file:**

```swift
// 1. Identify what the test is actually testing
grep -n "func test" TestFile.swift

// 2. Check for mock usage patterns
grep -n "Mock\|Stub\|fake\|spy" TestFile.swift

// 3. Identify business logic vs system boundaries
grep -n "Service\|Repository\|UseCase" TestFile.swift
```

### **Step 2: Clean Pattern Implementation**

**Template for UseCase Test Migration:**

```swift
// ❌ OLD: Mock-based pattern
@Suite("ExampleUseCase Tests")
final class ExampleUseCaseTests {
    
    func testSomething() {
        // Arrange
        let mockRepo = MockHabitRepository()
        mockRepo.stubbedHabits = [TestHabit.sample()]
        let useCase = ExampleUseCase(repository: mockRepo)
        
        // Act
        let result = useCase.execute()
        
        // Assert
        XCTAssertEqual(result.count, 1) // Testing mock behavior!
    }
}

// ✅ NEW: Clean pattern
@Suite("ExampleUseCase Clean Tests")
@MainActor
final class ExampleUseCaseCleanTests {
    
    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    
    init() async throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        testContainer = container
        testContext = context
    }
    
    @Test("should execute business logic correctly")
    func testBusinessLogic() async throws {
        // Arrange: Set up REAL data
        let habit = HabitModelBuilder()
            .with(name: "Test Habit")
            .with(schedule: .daily)
            .build()
        
        testContext.insert(habit)
        try testContext.save()
        
        // Create REAL UseCase with REAL repository
        let useCase = ExampleUseCase(
            repository: HabitRepositoryImpl(context: testContext)
        )
        
        // Act: Execute REAL business logic
        let result = try await useCase.execute()
        
        // Assert: Verify REAL calculations
        #expect(result.count == 1)
        #expect(result.first?.name == "Test Habit")
    }
}
```

**Template for ViewModel Test Migration:**

```swift
// ❌ OLD: Mock-based ViewModel test
final class ExampleViewModelTests {
    func testLoading() {
        let mockUseCase = MockGetHabitsUseCase()
        mockUseCase.stubbedResult = [TestHabit.sample()]
        let vm = ExampleViewModel(getHabits: mockUseCase)
        
        vm.load()
        
        XCTAssertEqual(vm.habits.count, 1) // Testing mock return!
    }
}

// ✅ NEW: Clean ViewModel test
@Suite("ExampleViewModel Clean Tests")
@MainActor
final class ExampleViewModelCleanTests {
    
    private var testContainer: ModelContainer!
    private var testContext: ModelContext!
    
    init() async throws {
        let (container, context) = try TestModelContainer.createContainerAndContext()
        testContainer = container
        testContext = context
    }
    
    private func createViewModel() -> ExampleViewModel {
        // Use REAL ViewModel with REAL UseCase implementations
        return ExampleViewModel()
    }
    
    @Test("should load real data correctly")
    func testDataLoading() async throws {
        // Arrange: Create REAL test data
        let habit = HabitModelBuilder()
            .with(name: "Real Habit")
            .with(schedule: .daily)
            .build()
        
        testContext.insert(habit)
        try testContext.save()
        
        let vm = createViewModel()
        
        // Act: Trigger REAL business operation
        await vm.load()
        
        // Assert: Verify REAL results
        #expect(vm.habits.count == 1)
        #expect(vm.habits.first?.name == "Real Habit")
    }
}
```

### **Step 3: Service Test Migration (Utilities Only)**

```swift
// ✅ Services should only contain utility functions
@Suite("HabitCompletionCalculator Tests")
final class HabitCompletionCalculatorTests {
    
    @Test("should calculate completion percentage correctly")
    func testCompletionCalculation() {
        // Arrange: Real inputs
        let calculator = HabitCompletionCalculatorService()
        let habit = TestHabit.dailyHabit().build()
        let logs = [
            TestHabitLog.completed().with(date: Date()).build(),
            TestHabitLog.completed().with(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!).build()
        ]
        
        // Act: Test real calculation
        let result = calculator.calculateProgress(habit: habit, logs: logs)
        
        // Assert: Verify real calculation (not mock return)
        #expect(result == 1.0) // 2 logs, 2 days = 100%
    }
}
```

## Common Migration Patterns

### **1. Replace MockRepository with Real Repository + TestModelContainer**

```swift
// ❌ Before
let mockRepo = MockHabitRepository()
mockRepo.stubbedHabits = [habit1, habit2]

// ✅ After  
let realRepo = HabitRepositoryImpl(context: testContext)
// Insert actual data into test database
testContext.insert(habitModel1)
testContext.insert(habitModel2)
try testContext.save()
```

### **2. Replace MockUseCase with Real UseCase + Real Dependencies**

```swift
// ❌ Before
let mockUseCase = MockGetActiveHabitsUseCase()
mockUseCase.stubbedResult = [activeHabit]

// ✅ After
let realUseCase = GetActiveHabits(
    habitAnalyticsService: Container.shared.habitAnalyticsService(),
    userService: Container.shared.userService()
)
// Test will execute real business logic
```

### **3. System Boundaries: When Mocks ARE Appropriate**

```swift
// ✅ System boundaries can be mocked
let mockNotificationService = TestNotificationService() // External system
let mockAnalyticsService = TestAnalyticsService() // External tracking
let mockNetworkService = TestNetworkService() // External API

// ❌ Business logic should NOT be mocked
let mockHabitRepository = MockHabitRepository() // Internal business data
let mockUseCase = MockCalculateProgressUseCase() // Internal business logic
```

## Migration Checklist

### **Before Starting Migration:**
- [ ] Read `TESTING_GUIDELINES.md` for patterns
- [ ] Analyze what the test is actually testing (business logic vs system boundaries)
- [ ] Identify all mock usage in the file
- [ ] Determine if test can be salvaged or needs complete rewrite

### **During Migration:**
- [ ] Set up TestModelContainer infrastructure
- [ ] Create real test data using builders
- [ ] Use real UseCase/Repository implementations
- [ ] Test actual business calculations/logic
- [ ] Only mock system boundaries (notifications, analytics, network)

### **After Migration:**
- [ ] Verify test actually tests business logic, not mock behavior
- [ ] Ensure test uses Swift Testing patterns (`#expect`, `@Test`)
- [ ] Confirm test follows AAA pattern (Arrange, Act, Assert)
- [ ] Run test to ensure it passes with real implementations
- [ ] Delete old mock-based version

## Common Pitfalls

### **❌ Don't Do This:**
```swift
// Testing mock return values instead of business logic
mockService.stubbedValue = 5
let result = useCase.execute()
#expect(result == 5) // This tests the mock, not the UseCase!
```

### **✅ Do This Instead:**
```swift
// Test actual business calculation
let habit = TestHabit.dailyHabit().build()
let logs = TestHabitLog.completedSequence(days: 5).build()
let result = useCase.calculateStreak(habit: habit, logs: logs)
#expect(result == 5) // This tests real streak calculation!
```

### **❌ Don't Do This:**
```swift
// Stubbing with placeholder values
mockRepo.stubbedHabits = [] // Empty stub
mockRepo.stubbedProgress = 0.0 // Hardcoded stub
```

### **✅ Do This Instead:**
```swift
// Create meaningful test data
let habits = [
    TestHabit.readingHabit().build(),
    TestHabit.exerciseHabit().build()
]
// Insert into real database for integration testing
```

## File-by-File Migration Notes

### **PersonalityAnalysisServiceTests.swift**
- **Issue**: Uses MockRepository pattern
- **Strategy**: Replace with real repository + test data
- **Business Logic**: Personality calculation algorithms
- **Timeline**: Phase 1B+4B

### **ViewModelTrackingIntegrationTests.swift**  
- **Issue**: Uses MockUseCases pattern
- **Strategy**: Use real UseCases with TestModelContainer
- **Business Logic**: ViewModel state management and data flow
- **Timeline**: Phase 1B+4B

### **HabitCompletionServiceTests.swift**
- **Issue**: Has mock dependencies
- **Strategy**: Test utility calculations directly
- **Business Logic**: Completion percentage, streak calculations
- **Timeline**: Phase 1B+4B

### **NotificationUseCaseTests.swift** ✅
- **Status**: Already migrated to NotificationUseCaseCleanTests.swift
- **Pattern**: Example of successful migration
- **Reference**: Use as template for other UseCase migrations

## Success Criteria

A test is successfully migrated when:

1. **✅ Zero Mock Usage**: No mocks for business logic (system boundaries OK)
2. **✅ Real Data**: Uses TestModelContainer and test builders
3. **✅ Real Logic**: Tests actual calculations/business operations
4. **✅ Integration Style**: Tests end-to-end flow through Clean Architecture
5. **✅ Swift Testing**: Uses `@Test` and `#expect` patterns
6. **✅ Maintainable**: Clear, readable, and follows established patterns

## Timeline

- **Phase 1A**: Document patterns, mark deprecated ✅
- **Phases 2-4A**: Ignore failing mock tests, focus on architecture
- **Phase 1B+4B**: Complete migration of all 8+ mock-heavy test files

## Getting Help

- **Clean Examples**: `OverviewViewModelSimpleTests.swift`, `NotificationUseCaseCleanTests.swift`
- **Test Builders**: `TestBuilders.swift` for consistent test data
- **Infrastructure**: `TestModelContainer.swift` for database setup
- **Guidelines**: `TESTING_GUIDELINES.md` for complete patterns

---

*This guide will be updated as migration patterns evolve through Phase 1B+4B implementation.*