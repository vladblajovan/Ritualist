# Integration Testing Plan - OverviewV2ViewModel Cache Sync

**Date**: 2025-11-08
**Status**: 📋 Planning Document (Not Yet Implemented)
**Purpose**: Future implementation guide for testing ACTUAL ViewModel cache methods

---

## ⚠️ Current Testing Limitations

### What We Have Now (Unit Tests)
✅ **CACHE-SYNC-TEST-PLAN.md** - 38 unit tests covering:
- Utility functions (`CalendarUtils.previousDay`, `CalendarUtils.startOfDayUTC`)
- Helper methods (`OverviewData.logs(for:on:)`)
- Algorithm logic (date range checking, 30-day boundaries)
- **Value**: Tests small pieces in isolation, validates utilities work

### What We DON'T Have (Integration Tests)
❌ **Tests for actual ViewModel cache methods**:
- `updateCachedLog()` - Does it actually update the cache correctly?
- `removeCachedLogs(for:)` - Does it actually remove logs from cache?
- `goToPreviousDay()` / `goToNextDay()` - Do they use cache or reload?
- `goToDate()` - Does it check cache range correctly?
- `checkMigrationAndInvalidateCache()` - Does it invalidate on completion?

**The Gap**: We test the ingredients, but not the recipe execution.

---

## 🎯 Integration Testing Goals

Test the ACTUAL cache sync orchestration in `OverviewV2ViewModel`:

1. **Cache Updates**: When logging a habit, does `updateCachedLog()` update `overviewData` correctly?
2. **Cache Removals**: When deleting a log, does `removeCachedLogs()` remove from `overviewData`?
3. **Navigation Cache Hits**: When navigating within 30-day range, does it use cache (no reload)?
4. **Navigation Cache Misses**: When navigating outside range, does it trigger `loadData()`?
5. **Migration Invalidation**: Does cache get cleared when migration completes?

---

## 🚧 Key Challenges & Solutions

### Challenge 1: ViewModel Has 21 Dependencies

**The Problem**:
```swift
@MainActor
@Observable
final class OverviewV2ViewModel {
    @ObservationIgnored @Injected(\.getActiveHabitsUseCase) private var getActiveHabitsUseCase
    @ObservationIgnored @Injected(\.getBatchHabitLogsUseCase) private var getBatchHabitLogsUseCase
    @ObservationIgnored @Injected(\.completeHabitUseCase) private var completeHabitUseCase
    // ... 18 more dependencies
}
```

**Solution Options**:

**Option A: Use Real Dependencies (Recommended)**
- Use actual UseCases with in-memory TestModelContainer
- Tests become true integration tests
- Example:
```swift
@Test
@MainActor
func testUpdateCachedLog() async throws {
    // Arrange: Real dependencies with in-memory container
    let container = TestModelContainer.inMemory()

    // Create ViewModel with real dependencies (Factory will provide them)
    let vm = OverviewV2ViewModel()
    await vm.loadData()

    let habit = vm.overviewData!.habits.first!
    let initialLogCount = vm.overviewData!.habitLogs[habit.id]?.count ?? 0

    // Act: Log a habit (triggers updateCachedLog internally)
    await vm.logHabit(habit, value: 1.0)

    // Assert: Cache was updated
    let newLogCount = vm.overviewData!.habitLogs[habit.id]?.count ?? 0
    #expect(newLogCount == initialLogCount + 1)
}
```

**Option B: Mock Dependencies (NOT Recommended - Project Anti-Pattern)**
- Goes against project's zero-mock philosophy
- User explicitly rejected this approach
- Tests mock behavior instead of real logic

**Recommended**: Option A with TestModelContainer

---

### Challenge 2: @MainActor Isolation

**The Problem**:
```swift
@MainActor
@Observable
final class OverviewV2ViewModel {
    // All methods must run on MainActor
}
```

**Solution**:
```swift
@Test
@MainActor  // ← Mark test as @MainActor
func testCacheUpdate() async throws {  // ← Use async
    let vm = OverviewV2ViewModel()
    await vm.loadData()  // ← await async methods

    // Test cache operations...
}
```

**Key Points**:
- All test methods must be marked `@MainActor`
- All test methods must be `async throws`
- Use `await` for all ViewModel method calls

---

### Challenge 3: Async Operations

**The Problem**:
```swift
func updateCachedLog(_ log: HabitLog) async {
    // Async operation
}

func loadData() async {
    // Complex async data loading
}
```

**Solution**:
```swift
@Test
@MainActor
func testAsyncCacheUpdate() async throws {
    let vm = OverviewV2ViewModel()

    // Load initial data
    await vm.loadData()
    #expect(vm.overviewData != nil, "Initial load should succeed")

    // Perform cache operation
    let habit = vm.overviewData!.habits.first!
    await vm.logHabit(habit, value: 1.0)

    // Verify cache was updated synchronously
    #expect(vm.overviewData!.logs(for: habit.id, on: Date()).count > 0)
}
```

**Key Points**:
- Use `await` for all async operations
- Verify state changes after `await` completes
- Cache updates should be synchronous (immediate after async DB write)

---

### Challenge 4: Complex State Management

**The Problem**:
```swift
@Published var overviewData: OverviewData?
@Published var selectedDate: Date
@Published var isLoading: Bool
private var hasLoadedInitialData = false
private var wasMigrating = false
```

**Solution - Test State Transitions**:
```swift
@Test
@MainActor
func testNavigationCacheHit() async throws {
    let vm = OverviewV2ViewModel()

    // Arrange: Load initial 30-day cache (today → day 29)
    await vm.loadData()
    let initialCacheRange = vm.overviewData!.dateRange

    // Act: Navigate to day 10 (within cache)
    let day10 = CalendarUtils.addDays(10, to: Date())
    await vm.goToDate(day10)

    // Assert: Cache range didn't change (no reload)
    #expect(vm.overviewData!.dateRange == initialCacheRange,
            "Cache range should not change for in-range navigation")
    #expect(vm.selectedDate == CalendarUtils.startOfDayUTC(for: day10))
}

@Test
@MainActor
func testNavigationCacheMiss() async throws {
    let vm = OverviewV2ViewModel()

    // Arrange: Load initial cache
    await vm.loadData()
    let initialCacheStart = vm.overviewData!.dateRange.lowerBound

    // Act: Navigate to 60 days from now (outside 30-day cache)
    let day60 = CalendarUtils.addDays(60, to: Date())
    await vm.goToDate(day60)

    // Assert: Cache was reloaded (new range)
    #expect(vm.overviewData!.dateRange.lowerBound != initialCacheStart,
            "Cache should reload for out-of-range navigation")
    #expect(vm.overviewData!.dateRange.contains(CalendarUtils.startOfDayUTC(for: day60)),
            "New cache should include target date")
}
```

---

### Challenge 5: TestModelContainer Setup

**The Problem**:
Need in-memory SwiftData for real UseCases without simulator persistence.

**Solution - Use Existing TestModelContainer**:
```swift
@Test
@MainActor
func testRealCacheIntegration() async throws {
    // Setup: In-memory container
    let container = try TestModelContainer.inMemory()

    // Create test data in container
    let context = ModelContext(container.container)

    let habit = SDHabit(
        id: UUID(),
        name: "Test Habit",
        colorHex: "#2DA9E3",
        emoji: "🎯",
        kind: .binary,
        // ... other params
    )
    context.insert(habit)
    try context.save()

    // Create ViewModel (Factory will use in-memory container)
    let vm = OverviewV2ViewModel()
    await vm.loadData()

    // Verify cache loaded real data
    #expect(vm.overviewData?.habits.count == 1)
    #expect(vm.overviewData?.habits.first?.name == "Test Habit")
}
```

**Key Points**:
- Use `TestModelContainer.inMemory()` from existing test infrastructure
- Insert test data before ViewModel creation
- ViewModel will use real repositories with in-memory data

---

### Challenge 6: Factory DI in Tests

**The Problem**:
How to inject test container into Factory-based DI?

**Solution - Use Factory Test Scopes**:
```swift
import Factory

@Test
@MainAactor
func testWithFactoryScope() async throws {
    // Setup test scope
    Container.shared.manager.push()
    defer { Container.shared.manager.pop() }

    // Override dependencies for this test
    Container.shared.modelContainer.register {
        try! TestModelContainer.inMemory().container
    }

    // Create ViewModel - will use test container
    let vm = OverviewV2ViewModel()
    await vm.loadData()

    // Test cache behavior...
}
```

**Reference**: Check Factory documentation for `ContainerManager.push()/pop()` pattern

---

## 📋 Recommended Test Suite Structure

### File Location
```
RitualistTests/
└── Features/
    └── Overview/
        └── Presentation/
            └── OverviewV2ViewModelIntegrationTests.swift  (NEW)
```

### Test Structure
```swift
@Suite("OverviewV2ViewModel Integration Tests")
struct OverviewV2ViewModelIntegrationTests {

    // MARK: - Cache Update Integration

    @Test("updateCachedLog updates cache after logging habit")
    @MainActor
    func updateCachedLogIntegration() async throws {
        // Test actual cache update flow
    }

    @Test("updateCachedLog preserves other habit logs")
    @MainActor
    func updatePreservesOtherLogs() async throws {
        // Test cache isolation
    }

    // MARK: - Cache Removal Integration

    @Test("removeCachedLogs removes logs from cache")
    @MainActor
    func removeCachedLogsIntegration() async throws {
        // Test actual removal flow
    }

    @Test("removeCachedLogs removes only specified date")
    @MainActor
    func removalIsolation() async throws {
        // Test removal doesn't affect other dates
    }

    // MARK: - Navigation Cache Hits

    @Test("goToPreviousDay uses cache when in range")
    @MainActor
    func previousDayCacheHit() async throws {
        // Verify no reload for in-range navigation
    }

    @Test("goToNextDay uses cache when in range")
    @MainActor
    func nextDayCacheHit() async throws {
        // Verify cache reuse
    }

    @Test("goToDate uses cache when in range")
    @MainActor
    func goToDateCacheHit() async throws {
        // Verify calendar navigation uses cache
    }

    // MARK: - Navigation Cache Misses

    @Test("goToPreviousDay reloads when outside range")
    @MainActor
    func previousDayCacheMiss() async throws {
        // Verify reload triggers for out-of-range
    }

    @Test("goToDate reloads when outside range")
    @MainActor
    func goToDateCacheMiss() async throws {
        // Verify reload for distant dates
    }

    // MARK: - Migration Invalidation

    @Test("cache invalidates on migration completion")
    @MainActor
    func migrationInvalidation() async throws {
        // Verify cache clears when migration completes
    }

    @Test("navigation defers during active migration")
    @MainActor
    func navigationDuringMigration() async throws {
        // Verify load is deferred when migrating
    }

    // MARK: - Cache Consistency

    @Test("all navigation methods respect same cache boundaries")
    @MainActor
    func cacheConsistency() async throws {
        // Verify goToPreviousDay, goToNextDay, goToDate use same logic
    }

    @Test("cache updates are immediately visible")
    @MainActor
    func cacheUpdateVisibility() async throws {
        // Verify cache changes don't require reload
    }
}
```

**Estimated**: 15-20 integration tests, ~500 lines

---

## 🎯 Implementation Steps

### Step 1: Setup Test Infrastructure
1. Research Factory test scope pattern (`Container.shared.manager.push()/pop()`)
2. Verify TestModelContainer works with Factory DI
3. Create helper for ViewModel setup with test container
4. Test basic ViewModel instantiation in test

### Step 2: Test Cache Updates
1. Write test for `logHabit()` → `updateCachedLog()` flow
2. Verify cache has new log after completion
3. Test cache preserves other habits/dates
4. Test numeric vs binary habit logging

### Step 3: Test Cache Removals
1. Write test for `deleteLog()` → `removeCachedLogs()` flow
2. Verify log removed from cache
3. Test removal preserves other dates
4. Test removal from empty cache (graceful handling)

### Step 4: Test Navigation Cache Hits
1. Test `goToPreviousDay()` within 30-day range
2. Test `goToNextDay()` within range
3. Test `goToDate()` within range
4. Verify cache range doesn't change (no reload)

### Step 5: Test Navigation Cache Misses
1. Test navigation to dates before cache start
2. Test navigation to dates after cache end (day 30+)
3. Verify cache range changes (reload occurred)
4. Verify new cache includes target date

### Step 6: Test Migration Handling
1. Simulate migration completion (true → false)
2. Verify cache gets cleared (`overviewData = nil`)
3. Verify `hasLoadedInitialData` reset
4. Test navigation during migration (should defer)

---

## 🔍 Debugging Integration Tests

### Common Issues & Solutions

**Issue 1: ViewModel Has No Data**
```swift
// Problem: loadData() not called
let vm = OverviewV2ViewModel()
#expect(vm.overviewData == nil)  // ← Always nil, never loaded

// Solution: Always call loadData() first
await vm.loadData()
#expect(vm.overviewData != nil)
```

**Issue 2: Factory Not Using Test Container**
```swift
// Problem: Container override not working
Container.shared.modelContainer.register { testContainer }  // Wrong way

// Solution: Use Container.shared.manager scoping
Container.shared.manager.push()
defer { Container.shared.manager.pop() }
Container.shared.modelContainer.register { testContainer }  // Now isolated
```

**Issue 3: Cache Not Updating**
```swift
// Problem: Checking cache before async operation completes
vm.logHabit(habit, value: 1.0)  // Missing await
#expect(vm.overviewData!.logs.count > 0)  // ← Checks too early

// Solution: Always await async operations
await vm.logHabit(habit, value: 1.0)
#expect(vm.overviewData!.logs.count > 0)  // ← Correct
```

**Issue 4: Test Data Not Persisting**
```swift
// Problem: Context not saved
context.insert(habit)
// Missing: try context.save()

// Solution: Always save context
context.insert(habit)
try context.save()
```

---

## 📊 Success Criteria

### Code Quality
- ✅ Tests call ACTUAL ViewModel methods (not utilities)
- ✅ Tests use REAL dependencies (no mocks)
- ✅ Tests are @MainActor async
- ✅ Tests use TestModelContainer (in-memory)
- ✅ Tests are isolated (no cross-test pollution)

### Coverage
- ✅ Cache update flows tested (logHabit → updateCachedLog)
- ✅ Cache removal flows tested (deleteLog → removeCachedLogs)
- ✅ Navigation cache hits tested (all methods)
- ✅ Navigation cache misses tested (all methods)
- ✅ Migration invalidation tested

### Validation
- ✅ Tests actually fail when cache logic is broken
- ✅ Tests pass with current implementation
- ✅ Tests run fast (< 2 seconds total)
- ✅ Tests don't leave simulator data

---

## 🆚 Unit Tests vs Integration Tests

### Current Unit Tests (CACHE-SYNC-TEST-PLAN.md)
**What They Test**:
- ✅ Utility functions (`CalendarUtils`)
- ✅ Helper methods (`OverviewData.logs()`)
- ✅ Algorithm correctness (date range logic)

**Value**:
- Fast (< 0.001s per test)
- Test building blocks in isolation
- Catch utility bugs early

**Limitations**:
- Don't test ViewModel orchestration
- Don't test async flows
- Don't test real integration

### Future Integration Tests (This Document)
**What They'll Test**:
- ✅ ViewModel cache methods (`updateCachedLog()`, `removeCachedLogs()`)
- ✅ Navigation methods (`goToPreviousDay()`, `goToDate()`)
- ✅ Async orchestration
- ✅ Real dependency integration

**Value**:
- Test actual cache sync behavior
- Catch orchestration bugs
- Validate end-to-end flows

**Trade-offs**:
- Slower (async operations)
- More complex setup (Factory scoping)
- More comprehensive coverage

### Recommendation
**Keep BOTH**:
- Unit tests for fast feedback on utilities
- Integration tests for confidence in actual behavior
- Together = comprehensive coverage

---

## 📚 References

### Project Patterns
- **Existing Tests**: `RitualistTests/Features/Overview/Presentation/ProgressColorViewLogicTests.swift`
- **Test Builders**: `RitualistTests/TestInfrastructure/TestDataBuilders.swift`
- **Test Container**: `RitualistTests/TestInfrastructure/TestModelContainer.swift`

### ViewModel Under Test
- **File**: `Ritualist/Features/Overview/Presentation/OverviewV2ViewModel.swift`
- **Methods**: `updateCachedLog()`, `removeCachedLogs()`, `goToPreviousDay()`, `goToNextDay()`, `goToDate()`
- **State**: `overviewData`, `selectedDate`, `hasLoadedInitialData`, `wasMigrating`

### Factory DI
- **Documentation**: Factory framework for Swift
- **Pattern**: Container scoping with `push()/pop()`
- **Registration**: `Container.shared.dependency.register { ... }`

---

## 🎬 Next Steps

**When Ready to Implement**:
1. Read this document thoroughly
2. Research Factory test scoping pattern
3. Create basic ViewModel integration test (just instantiation)
4. Implement cache update tests (highest value)
5. Implement navigation tests (cache hit/miss scenarios)
6. Implement migration tests
7. Run full suite, ensure all pass

**Estimated Effort**: 4-6 hours for complete integration test suite

---

## ✅ Current Status

- [x] Unit tests implemented (38 tests, 100% pass rate)
- [ ] Integration testing plan documented (this file)
- [ ] Integration tests NOT YET IMPLEMENTED
- [ ] Factory test scoping research needed
- [ ] TestModelContainer + Factory integration verified

**This is a PLANNING document** - implementation is future work.
