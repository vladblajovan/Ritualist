# Test Fixtures Documentation

This directory contains specialized test fixtures that complement the Test Builders created in Task 2. These fixtures provide complex, multi-entity scenarios for comprehensive testing.

## Overview

The fixtures are organized into five specialized categories:

### 1. StreakTestFixtures.swift
**Purpose**: Complex streak calculation testing scenarios
- **intermittentLongStreaks()**: Multiple streak periods with gaps for testing longest streak calculation
- **perfectCurrentStreak(days:)**: Perfect consecutive streaks for current streak validation
- **weekendOnlyStreaks()**: Schedule-aware streak testing for daysOfWeek habits
- **timesPerWeekVariablePerformance()**: Weekly completion threshold testing
- **numericHabitPartialCompliance()**: Target-based streak testing for numeric habits
- **numericHabitEdgeCases()**: Zero, nil, and negative value handling
- **multiScheduleComparison()**: Cross-schedule type comparative testing
- **habitLifecycleBoundaries()**: Start/end date boundary testing

### 2. NotificationTestFixtures.swift
**Purpose**: Habit notification and reminder testing scenarios  
- **multipleReminderHabit()**: Single habit with multiple daily reminders
- **scheduleAwareReminders()**: Reminders only on scheduled days
- **boundaryTimeReminders()**: Early morning and late evening edge cases
- **overlappingReminders()**: Multiple habits with close reminder times
- **identicalReminderTimes()**: Notification consolidation testing
- **comprehensiveDailySchedule()**: Full day reminder distribution
- **weeklyPatternReminders()**: Various weekly reminder patterns
- **highVolumeNotifications(habitCount:)**: Performance testing with many habits

### 3. PerformanceTestFixtures.swift
**Purpose**: Large dataset performance validation
- **heavyUserScenario(habitCount:, daysOfHistory:)**: Realistic high-volume user data
- **extremeLoggingScenario(habitCount:, daysOfHistory:)**: Multiple daily entries stress testing
- **complexStreakPerformanceScenario()**: Intricate streak patterns for performance testing
- **memoryStressScenario()**: Large datasets for memory pressure testing
- **batchProcessingTestData(habitCount:)**: N+1 query prevention validation
- **longTermUserSimulation()**: Multi-year user evolution simulation

### 4. EdgeCaseFixtures.swift
**Purpose**: Boundary conditions and error scenario testing
- **leapYearBoundaries()**: February 29th date calculations
- **daylightSavingTransitions()**: DST change handling
- **yearBoundaryCrossing()**: Year rollover continuity
- **corruptedDataScenarios()**: Invalid/corrupted data resilience
- **extremeNumericValues()**: Numeric boundary and overflow testing
- **unicodeTextChallenges()**: Complex Unicode and special character handling
- **concurrencyStressTest()**: Race condition and thread safety testing
- **resourceExhaustionTest()**: Memory and resource limit testing

### 5. IntegrationTestFixtures.swift
**Purpose**: Cross-service integration testing
- **habitCreationToAnalyticsPipeline()**: End-to-end data flow testing
- **batchHabitOperations()**: Multi-habit bulk operations
- **streakCalculationIntegration()**: Cross-schedule streak calculation testing
- **notificationSchedulingIntegration()**: Notification and habit management integration
- **dataMigrationSyncIntegration()**: Data format migration and sync testing
- **userProfileHabitIntegration()**: User preferences and habit behavior integration
- **performanceScalabilityIntegration()**: Realistic load performance testing

## Key Design Principles

### 1. Complementary to Builders
- Fixtures create **scenarios**, builders create **entities**
- Fixtures provide **multi-step workflows**, builders provide **single entity creation**
- Fixtures include **expected outcomes**, builders provide **configurable inputs**

### 2. Scenario-Focused
- Each fixture represents a complete **testing scenario** rather than individual entities
- Includes **validation data** and **expected results** for comprehensive testing
- Provides **context and relationships** between multiple entities

### 3. Deterministic and Reproducible
- Uses **fixed dates and IDs** where needed for consistent results
- Generates **predictable patterns** for reliable test validation
- Includes **built-in validation** to ensure fixture integrity

### 4. Performance Optimized
- **Efficient creation** of large test datasets
- **Memory-conscious** data generation patterns
- **Configurable scale** for different testing needs

## Usage Patterns

### Basic Fixture Usage
```swift
// Use a complete scenario
let scenario = StreakTestFixtures.perfectCurrentStreak(days: 15)
let service = StreakCalculationService()

let currentStreak = service.calculateCurrentStreak(
    habit: scenario.habit,
    logs: scenario.logs,
    asOf: Date()
)

#expect(currentStreak == scenario.expectedCurrentStreak)
```

### Combining Fixtures with Builders
```swift
// Extend a fixture scenario with custom data
let baseScenario = IntegrationTestFixtures.batchHabitOperations()
let customHabit = TestHabit.readingHabit().withName("Custom Test Habit").build()

let allHabits = baseScenario.habits + [customHabit]
```

### Performance Testing
```swift
let scenario = PerformanceTestFixtures.heavyUserScenario(habitCount: 100, daysOfHistory: 365)

let (result, timeInterval) = PerformanceTestFixtures.measure {
    return service.processAllHabits(scenario.habits, logs: scenario.logs)
}

#expect(timeInterval < 1.0) // Performance threshold
```

### Edge Case Validation
```swift
let scenario = EdgeCaseFixtures.corruptedDataScenarios()
let report = EdgeCaseFixtures.validateDataIntegrity(scenario)

// Test that service handles corrupted data gracefully
let result = service.processHabits(scenario.habits)
#expect(result.hasErrors == false) // Should handle gracefully
```

## Integration with Existing Infrastructure

### TestModelContainer Integration
All fixtures work seamlessly with the existing `TestModelContainer`:

```swift
@Test func testWithFixtures() async throws {
    let container = TestModelContainer.shared
    let scenario = StreakTestFixtures.perfectCurrentStreak(days: 10)
    
    // Add scenario data to test container
    try await container.addHabits(scenario.habits)
    try await container.addLogs(scenario.logs)
    
    // Run tests with containerized data
}
```

### Builder Compatibility
Fixtures complement builders without duplication:

```swift
// Builders for single entities
let habit = TestHabit.readingHabit().build()

// Fixtures for complex scenarios
let scenario = StreakTestFixtures.multiScheduleComparison()
```

## Quality Assurance

### Built-in Validation
Most fixtures include validation methods:
- **Data integrity checks**: Orphaned records, invalid dates, corrupt data
- **Expected outcome validation**: Ensures fixtures produce expected test conditions
- **Performance benchmarks**: Fixture creation time monitoring

### Comprehensive Coverage
The fixtures provide comprehensive coverage for:
- **All habit schedule types**: Daily, daysOfWeek, timesPerWeek
- **All habit kinds**: Binary and numeric with various targets
- **All time boundaries**: Leap years, DST, year rollover
- **All error conditions**: Unicode, corruption, resource limits
- **All integration paths**: Service coordination, data flow, UI integration

## Best Practices

### When to Use Fixtures vs Builders
- **Use Builders**: Simple entity creation, basic unit tests, isolated component testing
- **Use Fixtures**: Complex scenarios, integration testing, performance testing, edge case validation

### Fixture Customization
Most fixtures accept parameters for customization:
```swift
// Scalable fixtures
let smallScenario = PerformanceTestFixtures.heavyUserScenario(habitCount: 10, daysOfHistory: 30)
let largeScenario = PerformanceTestFixtures.heavyUserScenario(habitCount: 500, daysOfHistory: 1095)
```

### Performance Considerations
- Fixtures are optimized for **creation speed**
- Large datasets are **lazily generated** where possible
- **Memory usage** is monitored and optimized
- **Deterministic randomness** ensures reproducible results

## Future Extensions

The fixture system is designed to be easily extensible:
- Add new scenarios to existing fixture files
- Create new specialized fixture files for new testing domains
- Extend existing scenarios with additional parameters
- Add new validation utilities as needed

For examples of usage, see `FixturesIntegrationDemo.swift` which demonstrates proper usage patterns for all fixture types.