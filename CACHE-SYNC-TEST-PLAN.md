# Cache Sync Testing Suite - Implementation Plan

**Date**: 2025-11-08
**Goal**: Comprehensive unit tests for cache sync with zero mocks
**Status**: 🚧 In Progress

---

## Testing Philosophy

### ✅ What We're Doing
- **Real entities** - Use actual Habit, HabitLog, OverviewData structs
- **Pure logic testing** - Test cache algorithms directly
- **In-memory only** - No database, no simulator, instant execution
- **Zero mocks** - Following project anti-mock principle
- **Same pattern** - Match existing ViewLogic test style

### ❌ What We're NOT Doing
- ❌ Mocking entities or services
- ❌ Database/persistence testing
- ❌ UI/Integration tests that launch app
- ❌ Simulator-dependent tests
- ❌ Async complexity

---

## Phase 1: Test Infrastructure

### Directory Structure
```
RitualistTests/
└── TestInfrastructure/          (NEW)
    ├── TestDataBuilders.swift   (NEW)
    └── TestHelpers.swift         (NEW)
```

### TestDataBuilders.swift
**Purpose**: Convenience constructors for real entities

**Components**:
```swift
struct HabitBuilder {
    static func binary(name: String = "Test Habit") -> Habit
    static func numeric(name: String = "Test Habit", target: Double = 10.0) -> Habit
}

struct HabitLogBuilder {
    static func binary(habitId: UUID, date: Date = Date()) -> HabitLog
    static func numeric(habitId: UUID, value: Double, date: Date = Date()) -> HabitLog
}

struct OverviewDataBuilder {
    static func empty() -> OverviewData
    static func withHabits(_ habits: [Habit]) -> OverviewData
    static func with(habits: [Habit], logs: [HabitLog]) -> OverviewData
}
```

### TestHelpers.swift
**Purpose**: Date utilities and test constants

**Components**:
```swift
enum TestDates {
    static let today: Date
    static let yesterday: Date
    static let tomorrow: Date
    static func daysAgo(_ days: Int) -> Date
    static func dateRange(days: Int) -> ClosedRange<Date>
}
```

**Estimated**: ~100 lines total

---

## Phase 2: Cache Logic Tests

### File Location
```
RitualistTests/
└── Features/
    └── Overview/
        └── Presentation/
            └── CacheSyncLogicTests.swift (NEW)
```

### Test Structure
```swift
@Suite("Cache Sync Logic Tests")
struct CacheSyncLogicTests {

    // MARK: - OverviewData Helper Tests
    @Test("logs(for:on:) returns logs for specific habit and date")
    @Test("logs(for:) returns all logs for date across habits")
    @Test("scheduledHabits returns only scheduled habits")

    // MARK: - Date Range Tests
    @Test("needsReload returns false when date is in cached range")
    @Test("needsReload returns true when date is before cached range")
    @Test("needsReload returns true when date is after cached range")
    @Test("30-day cache boundary - first day is valid")
    @Test("30-day cache boundary - last day is valid")
    @Test("30-day cache boundary - day 31 triggers reload")

    // MARK: - Cache Update Tests
    @Test("updateCachedLog adds new log to empty cache")
    @Test("updateCachedLog adds new log to existing habit logs")
    @Test("updateCachedLog updates existing log with same ID")
    @Test("updateCachedLog preserves other habit logs")

    // MARK: - Cache Removal Tests
    @Test("removeCachedLogs removes logs for specific date")
    @Test("removeCachedLogs preserves logs from other dates")
    @Test("removeCachedLogs handles empty cache gracefully")

    // MARK: - Migration Detection Tests
    @Test("checkMigration detects true→false transition")
    @Test("checkMigration ignores false→false (no change)")
    @Test("checkMigration ignores true→true (still migrating)")
    @Test("checkMigration handles false→true (migration starts)")
}
```

**Test Scenarios**:
1. OverviewData helper methods work correctly
2. Date range detection (30-day window boundaries)
3. Cache updates (add new, update existing, preserve others)
4. Cache removals (delete specific, preserve others)
5. Migration state transitions

**Estimated**: ~300 lines, 15-20 tests

---

## Phase 3: Navigation Cache Tests

### File Location
```
RitualistTests/
└── Features/
    └── Overview/
        └── Presentation/
            └── NavigationCacheTests.swift (NEW)
```

### Test Structure
```swift
@Suite("Navigation Cache Behavior Tests")
struct NavigationCacheTests {

    // MARK: - Arrow Navigation - Cache Hits
    @Test("goToPreviousDay uses cache when date in range")
    @Test("goToNextDay uses cache when date in range")
    @Test("goToToday uses cache when date in range")

    // MARK: - Arrow Navigation - Cache Misses
    @Test("goToPreviousDay reloads when date outside range")
    @Test("goToNextDay reloads when date outside range")
    @Test("goToToday reloads when date outside range")

    // MARK: - Calendar Navigation
    @Test("goToDate uses cache when date in range")
    @Test("goToDate reloads when date outside range")

    // MARK: - Migration Checks
    @Test("all navigation methods check migration state")
    @Test("navigation during migration defers load")
    @Test("navigation after migration invalidates cache")

    // MARK: - Consistency Tests
    @Test("goToDate behaves identically to arrow navigation")
    @Test("all methods call checkMigrationAndInvalidateCache")
}
```

**Test Scenarios**:
1. Arrow navigation (previous/next/today) uses cache correctly
2. Calendar navigation (goToDate) uses cache correctly
3. All methods handle out-of-range dates
4. All methods check migration state
5. Consistency between navigation methods

**Estimated**: ~200 lines, 10-15 tests

---

## Implementation Order

### Step 1: Phase 1 (Infrastructure)
1. Create `RitualistTests/TestInfrastructure/` directory
2. Implement `TestDataBuilders.swift`
3. Implement `TestHelpers.swift`
4. Verify builders create valid entities

### Step 2: Phase 2 (Cache Logic)
1. Create `CacheSyncLogicTests.swift`
2. Implement OverviewData helper tests
3. Implement date range detection tests
4. Implement cache update tests
5. Implement cache removal tests
6. Implement migration detection tests
7. Run tests, verify all pass

### Step 3: Phase 3 (Navigation)
1. Create `NavigationCacheTests.swift`
2. Implement arrow navigation tests
3. Implement calendar navigation tests
4. Implement migration check tests
5. Implement consistency tests
6. Run tests, verify all pass

---

## Test Execution

### Running Tests
```bash
# Run all cache tests
xcodebuild test -scheme Ritualist-AllFeatures \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:RitualistTests/CacheSyncLogicTests

xcodebuild test -scheme Ritualist-AllFeatures \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -only-testing:RitualistTests/NavigationCacheTests
```

### Expected Results
- ✅ All tests pass (green)
- ✅ Instant execution (< 1 second total)
- ✅ Zero simulator persistence
- ✅ Zero test interference

---

## Coverage Goals

| Component | Target | Tests |
|-----------|--------|-------|
| OverviewData methods | 100% | 3-4 tests |
| Date range detection | 100% | 6 tests |
| Cache updates | 100% | 4 tests |
| Cache removals | 100% | 3 tests |
| Migration detection | 90% | 4 tests |
| Navigation methods | 80% | 12 tests |
| **TOTAL** | **90%+** | **~32 tests** |

---

## Success Criteria

### Code Quality
- ✅ Zero mocks - all real entities
- ✅ Clear test names describing behavior
- ✅ AAA pattern (Arrange, Act, Assert)
- ✅ Matches existing ViewLogic test style
- ✅ Fast execution (< 1 second)

### Coverage
- ✅ All cache update scenarios tested
- ✅ All date range edge cases covered
- ✅ Migration state transitions verified
- ✅ Navigation consistency validated

### Documentation
- ✅ Test plan documented (this file)
- ✅ Each test has clear description
- ✅ Complex logic has explanatory comments

---

## Benefits

### For Development
1. ✅ **Confidence** - Cache logic correctness verified
2. ✅ **Regression prevention** - Catches future breaks
3. ✅ **Documentation** - Tests show how cache works
4. ✅ **Fast feedback** - Instant test runs

### For Maintenance
1. ✅ **Refactoring safety** - Tests catch breaks
2. ✅ **Clear expectations** - Tests document behavior
3. ✅ **Easy debugging** - Isolated test failures
4. ✅ **No mocks to maintain** - Tests use real code

---

## Current Status

- [x] Plan created
- [ ] Phase 1: Test Infrastructure
- [ ] Phase 2: Cache Logic Tests
- [ ] Phase 3: Navigation Cache Tests
- [ ] All tests passing

**Next**: Implement Phase 1 (Test Infrastructure)
