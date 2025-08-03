# Testing Strategy for Ritualist

## Overview

This document outlines the comprehensive testing strategy for the Ritualist iOS app, built with SwiftUI and following Clean Architecture principles.

## Testing Philosophy

### Core Principles
1. **Test Pyramid**: More unit tests, fewer integration tests, minimal UI tests
2. **Fast Feedback**: Tests should run quickly and provide immediate feedback
3. **Reliable**: Tests should be deterministic and not flaky
4. **Maintainable**: Tests should be easy to understand and modify
5. **Independent**: Each test should be isolated and not depend on others

### Test Types

#### 1. Unit Tests (Foundation Layer)
**Target**: Individual components in isolation
**Framework**: XCTest
**Coverage**: 80%+ for business logic

**What to Test:**
- **Domain Entities**: Business rules and validation logic
- **Use Cases**: Business logic and workflows  
- **Services**: Core business services (StreakEngine, DateProvider, etc.)
- **Utilities**: Helper functions and extensions
- **Mappers**: Data transformation logic

**What NOT to Test:**
- SwiftUI Views (test ViewModels instead)
- Simple property getters/setters
- Framework code

#### 2. Integration Tests (Component Layer)
**Target**: Multiple components working together
**Framework**: XCTest

**What to Test:**
- **Repository Implementations**: Data access with mock data sources
- **Use Case Orchestration**: Multiple use cases working together
- **Dependency Injection**: Container setup and service resolution

#### 3. UI Tests (Application Layer)
**Target**: End-to-end user workflows
**Framework**: XCUITest
**Coverage**: Critical user paths only

**What to Test:**
- **Core User Flows**: Habit creation, logging, navigation
- **Accessibility**: VoiceOver support, Dynamic Type
- **Critical Business Scenarios**: Streak calculations, target achievements

## Testing Architecture

### Mock Strategy
- **Protocol-Based Mocking**: All dependencies defined as protocols
- **Test Doubles**: Use mocks, stubs, and fakes appropriately
- **Dependency Injection**: All dependencies injected for easy testing

### Test Structure
```
RitualistTests/
├── Domain/
│   ├── Entities/
│   ├── UseCases/
│   └── Services/
├── Data/
│   ├── Repositories/
│   ├── DataSources/
│   └── Mappers/
├── Presentation/
│   └── ViewModels/
├── TestDoubles/
│   ├── Mocks/
│   ├── Stubs/
│   └── Fakes/
└── Helpers/
    └── TestHelpers.swift
```

## Unit Testing Guidelines

### Test Naming Convention
```swift
func test_methodName_whenCondition_thenExpectedBehavior()

// Examples:
func test_currentStreak_whenHabitCompletedToday_thenReturnsCorrectStreak()
func test_bestStreak_whenMultipleStreaks_thenReturnsLongest()
```

### Test Structure (AAA Pattern)
```swift
func test_example() {
    // Arrange - Set up test data and dependencies
    let mockDateProvider = MockDateProvider()
    let streakEngine = DefaultStreakEngine(dateProvider: mockDateProvider)
    let habit = createTestHabit()
    
    // Act - Execute the method under test
    let result = streakEngine.currentStreak(for: habit, logs: logs, asOf: today)
    
    // Assert - Verify the expected outcome
    XCTAssertEqual(result, expectedStreak)
}
```

### Mock Creation Guidelines
```swift
protocol DateProvider {
    func startOfDay(_ date: Date) -> Date
    func today() -> Date
}

class MockDateProvider: DateProvider {
    var todayReturnValue: Date = Date()
    var startOfDayReturnValue: Date?
    
    func today() -> Date {
        return todayReturnValue
    }
    
    func startOfDay(_ date: Date) -> Date {
        return startOfDayReturnValue ?? Calendar.current.startOfDay(for: date)
    }
}
```

## ViewModel Testing Strategy

### ViewModels as Business Logic Containers
- Test state changes and business logic
- Mock all dependencies (UseCases, Services)
- Verify async operations and error handling

### Example ViewModel Test
```swift
@MainActor
final class OverviewViewModelTests: XCTestCase {
    private var viewModel: OverviewViewModel!
    private var mockGetActiveHabits: MockGetActiveHabitsUseCase!
    private var mockStreakEngine: MockStreakEngine!
    
    override func setUp() {
        super.setUp()
        mockGetActiveHabits = MockGetActiveHabitsUseCase()
        mockStreakEngine = MockStreakEngine()
        
        viewModel = OverviewViewModel(
            getActiveHabits: mockGetActiveHabits,
            streakEngine: mockStreakEngine
            // ... other dependencies
        )
    }
    
    func test_load_whenHabitsExist_thenUpdatesState() async {
        // Arrange
        let expectedHabits = [createTestHabit()]
        mockGetActiveHabits.executeReturnValue = expectedHabits
        
        // Act
        await viewModel.load()
        
        // Assert
        XCTAssertEqual(viewModel.habits, expectedHabits)
        XCTAssertFalse(viewModel.isLoading)
    }
}
```

## Data Layer Testing

### Repository Testing
- Test with mock data sources
- Verify data transformation (Entity ↔ Model mapping)
- Test error handling and edge cases

### Example Repository Test
```swift
final class HabitRepositoryTests: XCTestCase {
    private var repository: HabitRepositoryImpl!
    private var mockDataSource: MockHabitDataSource!
    private var mockMapper: MockHabitMapper!
    
    override func setUp() {
        super.setUp()
        mockDataSource = MockHabitDataSource()
        mockMapper = MockHabitMapper()
        repository = HabitRepositoryImpl(
            dataSource: mockDataSource,
            mapper: mockMapper
        )
    }
    
    func test_getActiveHabits_whenDataExists_thenReturnsHabits() async throws {
        // Arrange
        let mockModels = [createSDHabit()]
        let expectedEntities = [createHabit()]
        mockDataSource.getActiveHabitsReturnValue = mockModels
        mockMapper.toEntityReturnValue = expectedEntities[0]
        
        // Act
        let result = try await repository.getActiveHabits()
        
        // Assert
        XCTAssertEqual(result, expectedEntities)
    }
}
```

## Test Data Builders

### Builder Pattern for Test Data
```swift
class TestDataBuilder {
    static func habit() -> HabitBuilder {
        return HabitBuilder()
    }
    
    static func habitLog() -> HabitLogBuilder {
        return HabitLogBuilder()
    }
}

class HabitBuilder {
    private var habit = Habit(
        id: UUID(),
        name: "Test Habit",
        kind: .binary,
        schedule: .daily,
        dailyTarget: nil,
        colorHex: "#FF0000"
    )
    
    func withName(_ name: String) -> HabitBuilder {
        habit = habit.copy(name: name)
        return self
    }
    
    func withKind(_ kind: Habit.Kind) -> HabitBuilder {
        habit = habit.copy(kind: kind)
        return self
    }
    
    func withDailyTarget(_ target: Double) -> HabitBuilder {
        habit = habit.copy(dailyTarget: target)
        return self
    }
    
    func build() -> Habit {
        return habit
    }
}
```

## Performance Testing

### Load Testing
- Test with large datasets (1000+ habits, logs)
- Verify memory usage and performance
- Test scroll performance in lists

### Example Performance Test
```swift
func test_streakCalculation_withLargeDataset_performsInReasonableTime() {
    let habits = (0..<1000).map { _ in createTestHabit() }
    let logs = (0..<10000).map { _ in createTestLog() }
    
    measure {
        for habit in habits {
            _ = streakEngine.currentStreak(for: habit, logs: logs, asOf: Date())
        }
    }
}
```

## Test Configuration

### Test Schemes
- **Unit Tests**: Fast, isolated tests
- **Integration Tests**: Component interaction tests  
- **UI Tests**: End-to-end workflow tests

### CI/CD Integration
- All tests must pass before merge
- Code coverage reports generated
- Performance regression detection

## Common Testing Patterns

### Date Testing
```swift
// Use fixed dates for consistent testing
let calendar = Calendar(identifier: .gregorian)
let testDate = calendar.date(from: DateComponents(year: 2025, month: 1, day: 15))!

// Mock DateProvider for consistent results
mockDateProvider.todayReturnValue = testDate
```

### Async Testing
```swift
func test_asyncOperation() async {
    let expectation = XCTestExpectation(description: "Async operation completes")
    
    await viewModel.performAsyncOperation()
    
    XCTAssertTrue(viewModel.operationCompleted)
    expectation.fulfill()
}
```

### Error Testing
```swift
func test_operation_whenErrorOccurs_thenHandlesGracefully() async {
    // Arrange
    mockRepository.shouldThrowError = true
    
    // Act
    await viewModel.loadData()
    
    // Assert
    XCTAssertNotNil(viewModel.error)
    XCTAssertFalse(viewModel.isLoading)
}
```

## Test Maintenance

### Regular Review
- Review test coverage monthly
- Remove obsolete tests
- Update tests when requirements change
- Refactor test code for maintainability

### Documentation
- Document complex test scenarios
- Maintain this testing strategy document
- Share testing best practices with team

## Tools and Frameworks

### Core Testing
- **XCTest**: Primary testing framework
- **XCUITest**: UI automation testing
- **SwiftUI Testing**: View testing utilities (iOS 17+)

### Additional Tools
- **Code Coverage**: Built-in Xcode coverage tools
- **Performance Testing**: XCTest measure blocks
- **Memory Testing**: Instruments integration

## Success Metrics

### Coverage Targets
- **Domain Layer**: 90%+ coverage
- **Data Layer**: 85%+ coverage  
- **Presentation Layer**: 70%+ coverage (ViewModels)
- **Overall**: 80%+ coverage

### Quality Metrics
- All tests pass consistently
- Test execution time < 30 seconds for unit tests
- No flaky tests (>99% success rate)
- New features include comprehensive tests

This testing strategy ensures high code quality, rapid development cycles, and confident releases of the Ritualist app.