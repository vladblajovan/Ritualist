# Ritualist Test Suite

Comprehensive test suite for the Ritualist habit tracking app, built with Swift Testing framework and SwiftData.

## 📁 Test Organization

```
RitualistTests/
├── README.md (you are here)
├── TestInfrastructure/
│   ├── TestHelpers.swift           # Date helpers, test constants
│   ├── TestDataBuilders.swift      # HabitBuilder, HabitLogBuilder, OverviewDataBuilder
│   ├── TimezoneTestHelpers.swift   # Timezone-specific test utilities
│   ├── TestModelContainer.swift    # SwiftData in-memory container for testing
│   └── Fixtures/
│       └── TimezoneEdgeCaseFixtures.swift  # Pre-built test scenarios
│
├── CoreServices/                    # Tests for core business logic
│   ├── HabitCompletionServiceTests.swift
│   ├── StreakCalculationServiceTests.swift
│   └── ...
│
├── Repositories/                    # Tests for data layer
│   ├── HabitRepositoryTests.swift
│   └── ...
│
├── ViewModels/                      # Tests for presentation layer
│   ├── DashboardViewModelTests.swift
│   └── ...
│
└── Integration/                     # End-to-end integration tests
    └── ...
```

## 🎯 Testing Philosophy

### NO MOCKS
We use **real domain entities** and **in-memory SwiftData containers** instead of mocks:
- ✅ **Real:** `HabitBuilder.binary()` creates a real `Habit` instance
- ✅ **Real:** `TestModelContainer.create()` creates a real SwiftData container (in-memory)
- ❌ **No Mock:** We don't use mocking frameworks or fake objects

**Why?**
1. Tests are closer to production behavior
2. SwiftData's in-memory store is fast enough for tests
3. Refactoring doesn't break mocks
4. Tests verify real object relationships

## 🛠️ Test Infrastructure

### 1. TestHelpers.swift
Fixed test dates and date manipulation utilities.

```swift
import RitualistTests

// Fixed dates for consistent testing
let today = TestDates.today
let yesterday = TestDates.yesterday
let tomorrow = TestDates.tomorrow

// Date manipulation
let nextWeek = TestDates.addDays(7, to: today)
let lastMonth = TestDates.addMonths(-1, to: today)
```

### 2. TestDataBuilders.swift
Fluent builders for creating test entities.

```swift
// Binary habit with defaults
let habit = HabitBuilder.binary()

// Numeric habit with custom values
let waterHabit = HabitBuilder.numeric(
    name: "Drink Water",
    target: 8.0,
    unit: "glasses"
)

// Multiple habits
let habits = HabitBuilder.multipleBinary(count: 5)

// Habit with logs
let (habit, logs) = HabitBuilder.habitWithLogs(
    schedule: .daily,
    logDates: [today, yesterday],
    timezone: .current
)

// Logs for a habit
let logs = HabitLogBuilder.multipleLogs(
    habitId: habit.id,
    dates: [today, yesterday, twoDaysAgo]
)
```

### 3. TimezoneTestHelpers.swift
Timezone-specific helpers for edge case testing.

```swift
// Common timezones
let tokyo = TimezoneTestHelpers.tokyo
let newYork = TimezoneTestHelpers.newYork
let sydney = TimezoneTestHelpers.sydney

// Create date in specific timezone
let lateNight = TimezoneTestHelpers.createDate(
    year: 2025, month: 11, day: 8,
    hour: 23, minute: 30,
    timezone: tokyo
)

// Edge case scenarios
let lateNightDate = TimezoneTestHelpers.createLateNightDate(timezone: tokyo)
let midnightBoundary = TimezoneTestHelpers.createMidnightBoundaryDate(timezone: newYork)
let dstTransition = TimezoneTestHelpers.dstSpringForwardDate()
```

### 4. TestModelContainer.swift
SwiftData in-memory containers for isolated testing.

```swift
// Basic container
let container = try TestModelContainer.create()
let context = ModelContext(container)

// Container with pre-populated habit
let (container, context, habitModel) = try TestModelContainer.withHabit(habit)

// Container with habit and logs
let (container, context, habitModel, logModels) = try TestModelContainer.withHabitAndLogs(
    habit,
    logs: logs
)

// Query helpers
let allHabits = try TestModelContainer.fetchAllHabits(from: context)
let habitLogs = try TestModelContainer.fetchLogs(for: habitId, from: context)
```

### 5. TimezoneEdgeCaseFixtures.swift
Pre-built test scenarios for common edge cases.

```swift
// Late-night logging (11:30 PM should count for same day)
let scenario = TimezoneEdgeCaseFixtures.lateNightLoggingScenario()
let habit = scenario.habit
let logs = scenario.logs
let metadata = scenario.metadata

// Other scenarios
let travelScenario = TimezoneEdgeCaseFixtures.timezoneTransitionScenario()
let weeklyScenario = TimezoneEdgeCaseFixtures.weeklyScheduleScenario()
let dstScenario = TimezoneEdgeCaseFixtures.dstTransitionScenario()
let midnightScenario = TimezoneEdgeCaseFixtures.midnightBoundaryScenario()
```

## 📝 Naming Conventions

### Test Files
Follow the pattern: `<ComponentName>Tests.swift`

```
✅ HabitCompletionServiceTests.swift
✅ StreakCalculationServiceTests.swift
✅ DashboardViewModelTests.swift

❌ TestHabitCompletion.swift
❌ HabitTests.swift (too vague)
```

### Test Functions
Use descriptive names that explain WHAT is being tested and WHAT the expected outcome is.

```swift
// ✅ Good: Describes behavior and expected outcome
@Test("Binary habit marked as completed when logged")
func binaryHabitCompletionWhenLogged() async throws { ... }

@Test("Numeric habit completed when value meets or exceeds target")
func numericHabitCompletionWhenTargetMet() async throws { ... }

@Test("Late-night logging counts for same day, not next day")
func lateNightLoggingCountsForSameDay() async throws { ... }

// ❌ Bad: Vague or unclear
@Test("Test completion")
func testCompletion() async throws { ... }

@Test("Check habit")
func checkHabit() async throws { ... }
```

### Test Suites
Group related tests using `@Suite`

```swift
@Suite("Habit Completion Service")
struct HabitCompletionServiceTests {

    @Test("Binary habit completion")
    func binaryHabitCompletion() async throws { ... }

    @Test("Numeric habit completion")
    func numericHabitCompletion() async throws { ... }

    @Suite("Timezone Edge Cases")
    struct TimezoneTests {
        @Test("Late-night logging")
        func lateNightLogging() async throws { ... }

        @Test("Timezone transition")
        func timezoneTransition() async throws { ... }
    }
}
```

## 🧪 Common Test Patterns

### Pattern 1: Testing Core Services

```swift
@Test("Habit marked as completed when logged")
func habitCompletionWhenLogged() async throws {
    // Arrange: Create test data
    let habit = HabitBuilder.binary()
    let log = HabitLogBuilder.binary(
        habitId: habit.id,
        date: TestDates.today
    )

    // Arrange: Set up SwiftData container
    let (container, context, habitModel, logModels) = try TestModelContainer.withHabitAndLogs(
        habit,
        logs: [log]
    )

    // Act: Call the service method
    let service = HabitCompletionService(context: context)
    let isCompleted = service.isCompleted(habitId: habit.id, on: TestDates.today)

    // Assert: Verify expected behavior
    #expect(isCompleted == true)
}
```

### Pattern 2: Testing with Timezone Edge Cases

```swift
@Test("Late-night logging counts for same day")
func lateNightLoggingCountsForSameDay() async throws {
    // Arrange: Use pre-built scenario
    let scenario = TimezoneEdgeCaseFixtures.lateNightLoggingScenario(
        timezone: TimezoneTestHelpers.tokyo
    )

    // Arrange: Set up container
    let (container, context, habitModel, logModels) = try TestModelContainer.withHabitAndLogs(
        scenario.habit,
        logs: scenario.logs
    )

    // Act & Assert: Verify logs count for correct days
    let service = HabitCompletionService(context: context)

    // Log at 11:30 PM on Nov 8 should count for Nov 8 (not Nov 9)
    let nov8Completed = service.isCompleted(
        habitId: scenario.habit.id,
        on: TimezoneTestHelpers.createDate(
            year: 2025, month: 11, day: 8,
            hour: 12, minute: 0,
            timezone: TimezoneTestHelpers.tokyo
        )
    )
    #expect(nov8Completed == true)
}
```

### Pattern 3: Testing with Multiple Scenarios

```swift
@Test("Habit completion across different schedules", arguments: [
    HabitSchedule.daily,
    HabitSchedule.daysOfWeek([1, 3, 5]),
    HabitSchedule.weekends
])
func habitCompletionAcrossSchedules(schedule: HabitSchedule) async throws {
    // Arrange
    let habit = HabitBuilder.binary(schedule: schedule)
    let log = HabitLogBuilder.binary(habitId: habit.id)

    // Act & Assert
    let (container, context, _, _) = try TestModelContainer.withHabitAndLogs(
        habit,
        logs: [log]
    )

    let service = HabitCompletionService(context: context)
    let isCompleted = service.isCompleted(habitId: habit.id, on: log.date)

    #expect(isCompleted == true)
}
```

### Pattern 4: Testing Repositories

```swift
@Test("Repository creates habit with correct attributes")
func repositoryCreatesHabitCorrectly() async throws {
    // Arrange
    let container = try TestModelContainer.create()
    let context = ModelContext(container)
    let repository = HabitRepository(context: context)

    let habitInput = HabitBuilder.binary(name: "Test Habit", emoji: "🎯")

    // Act
    try await repository.create(habitInput)

    // Assert
    let habits = try TestModelContainer.fetchAllHabits(from: context)
    #expect(habits.count == 1)
    #expect(habits.first?.name == "Test Habit")
    #expect(habits.first?.emoji == "🎯")
}
```

### Pattern 5: Testing ViewModels

```swift
@Test("Dashboard shows correct completion percentage")
func dashboardCompletionPercentage() async throws {
    // Arrange: Create 3 habits, complete 2 of them
    let habit1 = HabitBuilder.binary(name: "Habit 1")
    let habit2 = HabitBuilder.binary(name: "Habit 2")
    let habit3 = HabitBuilder.binary(name: "Habit 3")

    let log1 = HabitLogBuilder.binary(habitId: habit1.id)
    let log2 = HabitLogBuilder.binary(habitId: habit2.id)

    let (container, context, _, _) = try TestModelContainer.withHabits([
        habit1, habit2, habit3
    ])

    [log1, log2].forEach { log in
        context.insert(log.toModel())
    }
    try context.save()

    // Act
    let viewModel = DashboardViewModel(context: context)
    await viewModel.loadData()

    // Assert
    #expect(viewModel.completionPercentage == 66.67) // 2 of 3 completed
}
```

## ⚠️ Common Pitfalls

### 1. Timezone Pitfalls
```swift
// ❌ Bad: Using Date() creates different times based on test runner's timezone
let log = HabitLogBuilder.binary(habitId: habit.id, date: Date())

// ✅ Good: Use fixed test dates or explicit timezone
let log = HabitLogBuilder.binary(habitId: habit.id, date: TestDates.today)
```

### 2. Date Comparison Pitfalls
```swift
// ❌ Bad: Comparing dates without considering timezone
#expect(log.date == TestDates.today)

// ✅ Good: Use CalendarUtils for day-level comparisons
#expect(CalendarUtils.isSameDay(log.date, as: TestDates.today))
```

### 3. SwiftData Relationship Pitfalls
```swift
// ❌ Bad: Not establishing relationships
let habitModel = habit.toModel()
let logModel = log.toModel()
context.insert(habitModel)
context.insert(logModel)
// logModel.habit is nil!

// ✅ Good: Establish relationships before inserting
let logModel = log.toModel()
logModel.habit = habitModel
context.insert(logModel)
```

### 4. Async/Await Pitfalls
```swift
// ❌ Bad: Not awaiting async operations
@Test("Load dashboard data")
func loadDashboardData() async throws {
    viewModel.loadData() // Missing await!
    #expect(viewModel.habits.count > 0)
}

// ✅ Good: Always await async operations
@Test("Load dashboard data")
func loadDashboardData() async throws {
    await viewModel.loadData()
    #expect(viewModel.habits.count > 0)
}
```

## 🚀 Running Tests

### Run All Tests
```bash
# Via Xcode
Cmd + U

# Via xcodebuild
xcodebuild test -scheme Ritualist -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run Specific Test Suite
```bash
xcodebuild test -scheme Ritualist -only-testing:RitualistTests/HabitCompletionServiceTests
```

### Run Specific Test
```bash
xcodebuild test -scheme Ritualist -only-testing:RitualistTests/HabitCompletionServiceTests/binaryHabitCompletion
```

## 📊 Test Coverage Goals

- **Core Services:** 90%+ coverage (these are critical for correctness)
- **Repositories:** 85%+ coverage (data layer must be reliable)
- **ViewModels:** 75%+ coverage (UI logic should be tested)
- **Utilities:** 80%+ coverage (CalendarUtils, etc.)

## 🔄 Test Lifecycle

1. **Before Each Test:**
   - New in-memory SwiftData container is created
   - Container is isolated from other tests

2. **During Test:**
   - Test data is inserted into in-memory container
   - Service/ViewModel operates on test data

3. **After Each Test:**
   - In-memory container is automatically discarded
   - No cleanup needed (automatic garbage collection)

## 📚 Additional Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [SwiftData Testing Guide](https://developer.apple.com/documentation/swiftdata)
- [Testing Infrastructure Plan](../plans/testing-infrastructure/testing-infrastructure-plan.md)
- [Phase 2 Execution Plan](../plans/testing-infrastructure/PHASE-2-EXECUTION-PLAN.md)

## 🤝 Contributing

When adding new tests:
1. Follow the naming conventions above
2. Use TestDataBuilders instead of manual object creation
3. Use TestModelContainer for SwiftData setup
4. Add timezone edge case tests when applicable
5. Document complex test scenarios with comments
6. Keep tests focused and single-purpose

---

**Built with ❤️ using Swift Testing and SwiftData**
