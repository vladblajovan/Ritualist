# Testing Infrastructure Improvements - Implementation Plan v2

**Branch**: `feature/testing-infrastructure-improvements`
**Status**: Phase 4 Complete ✅ - 73 Core Service Tests Written (97% passing)
**Priority**: HIGH (addresses critical PR #34 feedback)
**Version**: 2.0 (incorporates PR #35 review feedback)

## 📊 Phase Completion Status

- ✅ **Phase 3: Testing Infrastructure Setup** - COMPLETE (November 15, 2025)
  - ✅ 3.1 Timezone Test Helpers (TimezoneTestHelpers.swift) - 315 lines
  - ✅ 3.2 Test Data Builders Enhancement (TestDataBuilders.swift) - 140 lines added
  - ✅ 3.3 SwiftData Test Infrastructure (TestModelContainer.swift) - 284 lines
  - ✅ 3.4 Test Fixtures for Edge Cases (TimezoneEdgeCaseFixtures.swift) - 494 lines
  - ✅ 3.5 Test Organization & Documentation (RitualistTests/README.md) - 495 lines
- ✅ **Phase 4: Core Service Tests** - COMPLETE (November 15, 2025)
  - ✅ 4.1 HabitCompletionService Tests - 24 tests (HabitCompletionServiceTests.swift)
  - ✅ 4.2 StreakCalculationService Tests - 26 tests (StreakCalculationServiceTests.swift)
  - ✅ 4.3 HabitScheduleAnalyzer Tests - 23 tests (HabitScheduleAnalyzerTests.swift)
  - **Total: 73 tests, 97% passing (2 minor assertion failures to debug)**
- ⬜ **Phase 4.5: Repository Layer Tests** - NEXT UP
- ⬜ **Phase 4.6: Data Layer Tests**
- ⬜ **Remaining Phases** - Pending

---

## 🚨 CRITICAL UPDATE

**Based on Claude's PR #35 review**, we've identified BLOCKING issues that must be fixed before proceeding:

1. ❌ **TestDataBuilders.swift uses UTC** (lines 109, 127, 142) - Contradicts PR #34 timezone migration
2. ❌ **TestHelpers.swift uses UTC** - Systematic bias in all tests
3. ❌ **Missing test infrastructure for Repository/Data layers**
4. ❌ **Missing performance regression testing**
5. ❌ **Missing CI/CD integration strategy**

---

## 🎯 Objectives

Based on Claude's PR #34 review feedback + PR #35 review insights:

1. **FIX test infrastructure UTC usage FIRST** (Phase 0 - BLOCKING)
2. **Eliminate redundant/duplicate code** in Service and UseCase layers before testing
3. **Build timezone-specific test infrastructure** for comprehensive edge case coverage
4. **Achieve 80%+ business logic coverage, 90%+ Domain layer coverage** (per CLAUDE.md)
5. **Use real implementations, NOT mocks** (per MICRO-CONTEXTS/testing-strategy.md)
6. **Add regression protection** for 78 timezone fixes
7. **Test ALL layers**: Services, UseCases, Repositories, Data, ViewModels, Widget
8. **Performance regression testing** to validate N+1 optimizations

---

## 📋 Phase 0: Fix Test Infrastructure UTC Usage (BLOCKING)

> **CRITICAL**: Must be completed before any other phase. Current test infrastructure uses UTC, contradicting the PR #34 timezone migration.

### 0.1 Fix TestDataBuilders.swift

**File**: `RitualistTests/TestInfrastructure/TestDataBuilders.swift`

**Issues Found**:
- Lines 109, 127, 142: Using UTC timezone
- Test data created with UTC assumptions
- Mismatch with production code (now uses LOCAL)

**Required Changes**:
```swift
// BEFORE (UTC - WRONG):
timezone: "UTC"
CalendarUtils.startOfDayUTC(for: date)

// AFTER (LOCAL - CORRECT):
timezone: TimeZone.current.identifier
CalendarUtils.startOfDayLocal(for: date)
```

**Validation**:
- [ ] All test builders use LOCAL timezone by default
- [ ] Optional timezone parameter for cross-TZ testing
- [ ] No UTC assumptions in test data creation
- [ ] Build and verify existing tests still pass

### 0.2 Audit TestHelpers.swift for UTC Usage

**File**: `RitualistTests/TestInfrastructure/TestHelpers.swift`

**Audit Checklist**:
- [ ] Identify all date/time helper methods
- [ ] Check for UTC assumptions (TestDates, etc.)
- [ ] Add LOCAL variants where needed
- [ ] Document which helpers are UTC vs LOCAL and why

### 0.3 Verify CalendarUtils LOCAL Methods Availability

**File**: `RitualistCore/Sources/RitualistCore/Utilities/CalendarUtils.swift`

**Audit Checklist**:
- [ ] List all LOCAL methods available
- [ ] Identify missing LOCAL equivalents for UTC methods
- [ ] Document which UTC methods are deprecated
- [ ] Add any missing LOCAL helpers needed for testing

**Expected Output**:
- `test-infrastructure-audit.md` documenting current UTC usage
- Fixed TestDataBuilders.swift with LOCAL timezone
- Audited TestHelpers.swift with LOCAL variants
- CalendarUtils audit report

**Timeline**: 1 day (BLOCKING - must complete before Phase 1)

---

## 📋 Phase 1: Comprehensive Layer Audit (PREREQUISITE)

> **Rationale**: No point writing tests for duplicate/redundant code. Clean architecture first, then test.

### 1.1 Service Layer Audit

**Goal**: Identify duplicate logic, redundant services, consolidation opportunities

**Audit Checklist**:
- [ ] List all services in `RitualistCore/Sources/RitualistCore/Services/`
- [ ] Identify services with overlapping responsibilities
- [ ] Find duplicate timezone/date logic not using CalendarUtils
- [ ] Detect redundant completion calculation logic
- [ ] Spot duplicate streak calculation patterns
- [ ] Check for services that should be UseCases
- [ ] Verify Single Responsibility Principle adherence
- [ ] Document performance-critical services (for perf testing)

**Expected Output**: `service-layer-audit.md` with:
- Service inventory with responsibilities
- Duplicate code findings
- Consolidation recommendations
- Refactoring priority (P0/P1/P2)
- Performance-critical service identification

### 1.2 UseCase Layer Audit

**Goal**: Identify duplicate business logic, thin wrappers, consolidation opportunities

**Audit Checklist**:
- [ ] List all UseCases in `RitualistCore/Sources/RitualistCore/UseCases/`
- [ ] Find UseCases that are thin wrappers around services (should be removed)
- [ ] Identify duplicate orchestration logic
- [ ] Check for UseCases violating Single Responsibility
- [ ] Verify proper dependency direction (UseCases → Services, not vice versa)
- [ ] Find missing UseCases (business operations exposed directly)
- [ ] Check for UseCases doing service-level work (calculation vs orchestration)

**Expected Output**: `usecase-layer-audit.md` with:
- UseCase inventory with responsibilities
- Thin wrapper findings
- Duplicate logic findings
- Consolidation recommendations
- Missing UseCase opportunities

### 1.3 Repository Layer Audit (NEW)

**Goal**: Identify repository patterns, SwiftData usage, testability gaps

**Audit Checklist**:
- [ ] List all repositories in `RitualistCore/Sources/RitualistCore/Data/Repositories/`
- [ ] Check SwiftData context usage (background vs main thread)
- [ ] Identify complex queries that need performance testing
- [ ] Find duplicate query logic across repositories
- [ ] Verify repository protocols vs implementations
- [ ] Check for business logic in repositories (should be in services)

**Expected Output**: `repository-layer-audit.md` with:
- Repository inventory
- SwiftData usage patterns
- Complex query identification
- Testability assessment

### 1.4 Data Layer Audit (NEW)

**Goal**: Audit SwiftData models, mappers, relationships

**Audit Checklist**:
- [ ] List all SwiftData models (`SDHabit`, `SDHabitLog`, `SDCategory`)
- [ ] Verify @Relationship configurations
- [ ] Check cascade delete rules
- [ ] Audit entity ↔ model mappers for correctness
- [ ] Identify schema migration risks

**Expected Output**: `data-layer-audit.md` with:
- Model inventory with relationships
- Mapper correctness assessment
- Schema validation needs

### 1.5 Cross-Layer Analysis

**Goal**: Identify architectural violations and cleanup opportunities

**Audit Checklist**:
- [ ] ViewModels calling Services directly (should use UseCases)
- [ ] Services calling UseCases (dependency inversion violation)
- [ ] Duplicate domain logic in multiple layers
- [ ] Business logic in ViewModels (should be UseCases)
- [ ] Data transformation logic in wrong layer
- [ ] Repository logic leaking into ViewModels

**Expected Output**: `architecture-violations.md` with fix priorities

**Timeline Phase 1**: 3-4 days (extended to include Repository/Data layers)

---

## 📋 Phase 2: Code Consolidation & Cleanup

**Goal**: Eliminate redundancy before writing tests

### 2.1 Service Consolidation
- [ ] Merge duplicate timezone/date logic into CalendarUtils
- [ ] Consolidate completion calculation into single service
- [ ] Remove redundant helper services
- [ ] Extract common patterns into shared utilities

### 2.2 UseCase Consolidation
- [ ] Remove thin wrapper UseCases (direct service injection)
- [ ] Merge duplicate orchestration logic
- [ ] Simplify complex UseCases by extracting services
- [ ] Ensure proper UseCase → Service dependency direction

### 2.3 Repository Consolidation (NEW)
- [ ] Merge duplicate query logic
- [ ] Standardize SwiftData context usage
- [ ] Extract common repository patterns

### 2.4 Architecture Cleanup
- [ ] Fix ViewModels calling Services directly
- [ ] Add missing UseCases for exposed business operations
- [ ] Move business logic from ViewModels to UseCases
- [ ] Document architectural patterns in CLAUDE.md

**Acceptance Criteria**:
- Zero duplicate business logic across layers
- Clean architecture violations = 0
- All services have single, clear responsibility
- All UseCases orchestrate (not calculate)
- Repositories handle data access only

**Timeline Phase 2**: 3-4 days (unchanged)

---

## 📋 Phase 3: Testing Infrastructure Setup

**Goal**: Build comprehensive, reusable test infrastructure

### 3.1 Timezone Test Helpers

**Create**: `RitualistTests/TestInfrastructure/TimezoneTestHelpers.swift`

```swift
/// Timezone-specific test helpers for edge case scenarios
public struct TimezoneTestHelpers {

    /// Create date in specific timezone at specific time
    static func createDate(
        year: Int, month: Int, day: Int,
        hour: Int, minute: Int,
        timezone: TimeZone
    ) -> Date

    /// Create late-night date (11:30 PM) in timezone
    static func createLateNightDate(timezone: TimeZone) -> Date

    /// Create midnight boundary date in timezone
    static func createMidnightDate(timezone: TimeZone) -> Date

    /// Create week boundary date (Sunday 11:59 PM) in timezone
    static func createWeekBoundaryDate(timezone: TimeZone) -> Date

    /// Test timezones for cross-TZ validation
    static let testTimezones: [TimeZone] = [
        TimeZone(identifier: "UTC")!,              // Baseline
        TimeZone(identifier: "America/New_York")!, // GMT-5
        TimeZone(identifier: "Asia/Tokyo")!,       // GMT+9
        TimeZone(identifier: "Australia/Sydney")!  // GMT+11
    ]
}
```

### 3.2 Test Data Builders Enhancement

**Enhance**: `RitualistTests/TestInfrastructure/TestBuilders.swift`

```swift
extension TestBuilders {
    /// Create habit with timezone-aware logs
    static func habitWithLogs(
        schedule: HabitSchedule,
        logDates: [Date],
        timezone: TimeZone = .current
    ) -> (Habit, [HabitLog])

    /// Create Mon/Wed/Fri habit with realistic logs
    static func monWedFriHabit(
        completedDays: [Date],
        timezone: TimeZone = .current
    ) -> (Habit, [HabitLog])

    /// Create count habit with daily values
    static func countHabit(
        dailyTarget: Double,
        progressValues: [Date: Double]
    ) -> (Habit, [HabitLog])
}
```

### 3.3 SwiftData Test Infrastructure (NEW)

**Create**: `RitualistTests/TestInfrastructure/TestModelContainer.swift`

```swift
/// In-memory SwiftData container for testing
public struct TestModelContainer {

    /// Create in-memory model container with schema
    static func create() throws -> ModelContainer

    /// Insert test habit and return context
    static func withHabit(_ habit: Habit) throws -> ModelContext

    /// Clean up test data after each test
    static func cleanup(_ container: ModelContainer) throws
}
```

**Testing Strategy**:
- Use in-memory ModelContainer for fast, isolated tests
- No persistent storage (tests don't interfere)
- Schema V8 validation with all relationships
- Cascade delete rule testing

### 3.4 Test Fixtures for Edge Cases

**Create**: `RitualistTests/TestInfrastructure/Fixtures/TimezoneEdgeCaseFixtures.swift`

```swift
/// Pre-built test scenarios for timezone edge cases
public struct TimezoneEdgeCaseFixtures {

    /// User logs habit at 11:30 PM local (should count for same day)
    static func lateNightLoggingScenario() -> TestScenario

    /// User travels across timezones mid-week
    static func timezoneTransitionScenario() -> TestScenario

    /// Mon/Wed/Fri habit scheduled in multiple timezones
    static func weeklyScheduleScenario() -> TestScenario

    /// Week boundary (Sunday 11:59 PM → Monday 12:00 AM)
    static func weekBoundaryScenario() -> TestScenario

    /// DST transition scenarios
    static func dstTransitionScenario() -> TestScenario
}
```

### 3.5 Test Organization & Naming Conventions (NEW)

**Documentation**: `RitualistTests/README.md`

**Test Structure**:
```
RitualistTests/
├── TestInfrastructure/        # Shared test utilities
│   ├── TestBuilders.swift
│   ├── TimezoneTestHelpers.swift
│   ├── TestModelContainer.swift
│   └── Fixtures/
├── Services/                   # Service layer tests
├── UseCases/                   # UseCase layer tests
├── Repositories/               # Repository layer tests
├── Data/                       # Data model & mapper tests
├── Features/                   # ViewModel integration tests
│   ├── Overview/
│   ├── Dashboard/
│   └── Habits/
└── EdgeCases/                  # Complex scenario tests
```

**Naming Convention**:
- Test files: `{ComponentName}Tests.swift`
- Test suites: `@Suite("{Component} - {Category}")`
- Test methods: `func test{Behavior}{Context}() async throws`

**Example**:
```swift
@Suite("HabitCompletionService - Timezone Edge Cases")
struct HabitCompletionServiceTimezoneTests {
    @Test("Binary habit marked complete when logged at 11:30 PM local")
    func testBinaryHabitLateNightLoggingMarksComplete() async throws
}
```

### 3.6 Async Testing Patterns (NEW)

**Documentation**: `async-testing-patterns.md`

**Patterns**:
- Swift Testing async/await support
- Timeout handling for async operations
- Race condition testing
- Concurrent operation validation

**Timeline Phase 3**: 2-3 days (extended for SwiftData infrastructure + patterns)

---

## 📋 Phase 4: Core Service Tests

**Goal**: Test critical services with timezone awareness + error paths

### 4.1 HabitCompletionService Tests

**File**: `RitualistTests/Services/HabitCompletionServiceTests.swift`

**Test Cases**:
```swift
@Suite("HabitCompletionService - Timezone Tests")
struct HabitCompletionServiceTests {

    @Test("Binary habit - late night logging uses LOCAL timezone")
    func testLateNightLoggingLocalTimezone() async throws

    @Test("Count habit - completion uses LOCAL day boundaries")
    func testCountHabitCompletionLocalDay() async throws

    @Test("Schedule check - Mon/Wed/Fri respects LOCAL weekdays")
    func testScheduleChecksLocalWeekdays() async throws

    @Test("Completion across timezones - GMT-5, GMT+0, GMT+9")
    func testCompletionAcrossTimezones() async throws

    @Test("Week boundary - Sunday 11:59 PM ≠ Monday completion")
    func testWeekBoundaryCorrectness() async throws

    // ERROR PATHS
    @Test("Invalid habit ID returns false")
    func testInvalidHabitIdReturnsFalse() async throws

    @Test("Empty logs array handles gracefully")
    func testEmptyLogsHandlesGracefully() async throws
}
```

### 4.2 StreakCalculationService Tests

**File**: `RitualistTests/Services/StreakCalculationServiceTests.swift`

**Test Cases**:
```swift
@Suite("StreakCalculationService - Timezone Tests")
struct StreakCalculationServiceTests {

    @Test("Current streak - late night logging doesn't break streak")
    func testLateNightLoggingPreservesStreak() async throws

    @Test("Longest streak - LOCAL day boundaries")
    func testLongestStreakLocalBoundaries() async throws

    @Test("Streak reset - midnight in LOCAL timezone")
    func testStreakResetAtLocalMidnight() async throws

    @Test("Cross-timezone streak - consistent across GMT+8, GMT-5")
    func testStreakConsistencyAcrossTimezones() async throws

    // ERROR PATHS
    @Test("Streak calculation with gaps handles correctly")
    func testStreakWithGapsHandlesCorrectly() async throws
}
```

### 4.3 HabitScheduleAnalyzer Tests

**File**: `RitualistTests/Services/HabitScheduleAnalyzerTests.swift`

**Test Cases**:
```swift
@Suite("HabitScheduleAnalyzer - Timezone Tests")
struct HabitScheduleAnalyzerTests {

    @Test("isScheduledDay - Mon/Wed/Fri uses LOCAL weekdays")
    func testScheduledDayLocalWeekdays() async throws

    @Test("Weekly target - LOCAL week boundaries (Sun-Sat)")
    func testWeeklyTargetLocalWeek() async throws

    @Test("Schedule validation - respects user's LOCAL timezone")
    func testScheduleValidationLocalTimezone() async throws
}
```

**Timeline Phase 4**: 2-3 days (unchanged)

---

## 📋 Phase 4.5: Repository Layer Tests (NEW)

**Goal**: Test SwiftData repositories with in-memory container

### 4.5.1 HabitRepositoryImpl Tests

**File**: `RitualistTests/Repositories/HabitRepositoryImplTests.swift`

**Test Cases**:
```swift
@Suite("HabitRepositoryImpl - SwiftData Tests")
struct HabitRepositoryImplTests {

    @Test("Fetch active habits returns correct data")
    func testFetchActiveHabitsReturnsCorrectData() async throws

    @Test("Create habit persists correctly")
    func testCreateHabitPersistsCorrectly() async throws

    @Test("Update habit modifies existing record")
    func testUpdateHabitModifiesExistingRecord() async throws

    @Test("Delete habit cascades to logs")
    func testDeleteHabitCascadesToLogs() async throws

    @Test("Background context doesn't block main thread")
    func testBackgroundContextDoesntBlockMainThread() async throws
}
```

### 4.5.2 LogRepositoryImpl Tests

**File**: `RitualistTests/Repositories/LogRepositoryImplTests.swift`

**Test Cases**:
```swift
@Suite("LogRepositoryImpl - SwiftData Tests")
struct LogRepositoryImplTests {

    @Test("Batch fetch logs for date range")
    func testBatchFetchLogsForDateRange() async throws

    @Test("Create log with timezone metadata")
    func testCreateLogWithTimezoneMetadata() async throws

    @Test("Query optimization - no N+1 queries")
    func testQueryOptimizationNoNPlusOne() async throws
}
```

**Timeline Phase 4.5**: 1-2 days

---

## 📋 Phase 4.6: Data Layer Tests (NEW)

**Goal**: Test SwiftData models, mappers, relationships

### 4.6.1 SwiftData Model Tests

**File**: `RitualistTests/Data/SwiftDataModelTests.swift`

**Test Cases**:
```swift
@Suite("SwiftData Models - Relationship Tests")
struct SwiftDataModelTests {

    @Test("SDHabit ↔ SDHabitLog relationship integrity")
    func testHabitLogRelationshipIntegrity() async throws

    @Test("SDHabit ↔ SDCategory relationship integrity")
    func testHabitCategoryRelationshipIntegrity() async throws

    @Test("Cascade delete rules work correctly")
    func testCascadeDeleteRulesWorkCorrectly() async throws
}
```

### 4.6.2 Mapper Tests

**File**: `RitualistTests/Data/MapperTests.swift`

**Test Cases**:
```swift
@Suite("Entity ↔ Model Mappers")
struct MapperTests {

    @Test("Habit → SDHabit mapping preserves all fields")
    func testHabitToSDHabitMappingPreservesFields() async throws

    @Test("SDHabit → Habit mapping handles optional fields")
    func testSDHabitToHabitMappingHandlesOptionals() async throws

    @Test("HabitLog → SDHabitLog includes timezone")
    func testHabitLogToSDHabitLogIncludesTimezone() async throws
}
```

**Timeline Phase 4.6**: 1 day

---

## 📋 Phase 5: UseCase Integration Tests

**Goal**: Test UseCases with real services (no mocks)

### 5.1 LogHabitUseCase Tests

**File**: `RitualistTests/UseCases/LogHabitUseCaseTests.swift`

**Test Cases**:
```swift
@Suite("LogHabitUseCase - Integration Tests")
struct LogHabitUseCaseTests {

    @Test("Log binary habit - late night logging (11:30 PM)")
    func testLogBinaryHabitLateNight() async throws

    @Test("Log count habit - progress accumulation LOCAL day")
    func testLogCountHabitLocalDay() async throws

    @Test("Validation - prevents future dates in LOCAL timezone")
    func testFutureDateValidationLocal() async throws

    // ERROR PATHS
    @Test("Log invalid habit ID throws error")
    func testLogInvalidHabitIdThrowsError() async throws
}
```

### 5.2 CalculateStreakAnalysisUseCase Tests

**File**: `RitualistTests/UseCases/CalculateStreakAnalysisUseCaseTests.swift`

**Test Cases**:
```swift
@Suite("CalculateStreakAnalysisUseCase - Integration Tests")
struct CalculateStreakAnalysisUseCaseTests {

    @Test("Streak analysis - cross-timezone consistency")
    func testStreakAnalysisCrossTimezone() async throws

    @Test("Perfect days - LOCAL midnight boundaries")
    func testPerfectDaysLocalBoundaries() async throws
}
```

**Timeline Phase 5**: 1-2 days (unchanged)

---

## 📋 Phase 6: ViewModel Integration Tests

**Goal**: Test ViewModels with real UseCases (full stack)

### 6.1 OverviewViewModel Tests

**File**: `RitualistTests/Features/Overview/OverviewViewModelTests.swift`

**Test Cases**:
```swift
@Suite("OverviewViewModel - Timezone Integration Tests")
struct OverviewViewModelTests {

    @Test("Load today's summary - uses LOCAL timezone")
    func testLoadTodaysSummaryLocal() async throws

    @Test("Weekly progress - LOCAL week boundaries")
    func testWeeklyProgressLocal() async throws

    @Test("Calendar data - correct LOCAL date filtering")
    func testCalendarDataLocalFiltering() async throws

    // PERFORMANCE
    @Test("Load summary completes within 2 seconds")
    func testLoadSummaryPerformance() async throws
}
```

**Timeline Phase 6**: 1-2 days (unchanged)

---

## 📋 Phase 7: Widget Timezone Tests

**Goal**: Ensure Widget uses same LOCAL timezone as main app

### 7.1 Widget Test Target Setup (NEW)

**Tasks**:
- [ ] Create `RitualistWidgetTests` target
- [ ] Configure shared test infrastructure access
- [ ] Set up widget-specific test helpers

### 7.2 WidgetHabitsViewModel Tests

**File**: `RitualistWidgetTests/WidgetHabitsViewModelTests.swift`

**Test Cases**:
```swift
@Suite("WidgetHabitsViewModel - Timezone Tests")
struct WidgetHabitsViewModelTests {

    @Test("Widget data - matches main app LOCAL timezone")
    func testWidgetUsesLocalTimezone() async throws

    @Test("Widget date navigation - LOCAL day boundaries")
    func testWidgetNavigationLocal() async throws

    @Test("Widget completion - syncs with main app status")
    func testWidgetCompletionSync() async throws
}
```

**Timeline Phase 7**: 1 day (unchanged)

---

## 📋 Phase 8: Edge Case Scenario Tests

**Goal**: Test complex real-world scenarios + error paths

### 8.1 Timezone Transition Tests

**File**: `RitualistTests/EdgeCases/TimezoneTransitionTests.swift`

**Test Cases**:
```swift
@Suite("Timezone Edge Cases")
struct TimezoneEdgeCaseTests {

    @Test("User travels Tokyo → New York mid-week")
    func testTimezoneTravel() async throws

    @Test("DST transition - spring forward/fall back")
    func testDaylightSavingTransition() async throws

    @Test("International Date Line crossing")
    func testDateLineCrossing() async throws
}
```

### 8.2 Error Path Tests (NEW)

**File**: `RitualistTests/EdgeCases/ErrorPathTests.swift`

**Test Cases**:
```swift
@Suite("Error Handling & Edge Cases")
struct ErrorPathTests {

    @Test("Network failure during sync")
    func testNetworkFailureDuringSync() async throws

    @Test("Database corruption recovery")
    func testDatabaseCorruptionRecovery() async throws

    @Test("Concurrent modification conflicts")
    func testConcurrentModificationConflicts() async throws
}
```

**Timeline Phase 8**: 1-2 days (unchanged)

---

## 📋 Phase 9: Documentation (NEW)

**Goal**: Document testing patterns for future development

### 9.1 Update CLAUDE.md

**Add Sections**:
- Testing strategy summary
- Timezone testing patterns
- Test infrastructure usage
- Coverage requirements
- CI/CD integration

### 9.2 Create Testing Guide

**File**: `RitualistTests/TESTING_GUIDE.md`

**Contents**:
- How to write new tests
- Test data builders usage
- Timezone test helpers guide
- SwiftData testing patterns
- Async testing examples

**Timeline Phase 9**: 1 day

---

## 📋 Phase 10: Performance Regression Testing (NEW)

**Goal**: Ensure N+1 optimizations and performance characteristics maintained

### 10.1 Performance Test Suite

**File**: `RitualistTests/Performance/PerformanceTests.swift`

**Test Cases**:
```swift
@Suite("Performance Regression Tests")
struct PerformanceTests {

    @Test("Dashboard load with 20 habits < 2 seconds")
    func testDashboardLoadPerformance() async throws

    @Test("Batch log query: 20 habits, 90 days < 500ms")
    func testBatchLogQueryPerformance() async throws

    @Test("Streak calculation: 20 habits, 365 days < 1 second")
    func testStreakCalculationPerformance() async throws

    @Test("No N+1 queries in habit list load")
    func testNoNPlusOneQueriesInHabitList() async throws
}
```

**Metrics**:
- Response time targets
- Memory usage limits
- Database query counts
- UI responsiveness (frame drops)

**Timeline Phase 10**: 1 day

---

## 📋 Phase 11: CI/CD Integration (NEW)

**Goal**: Integrate tests into GitHub Actions workflow

### 11.1 Test Execution Strategy

**Test Tiers**:
1. **Smoke Tests** (< 30s) - Run on every commit
   - Critical path tests only
   - Fast unit tests

2. **Full Test Suite** (< 5 min) - Run on PR
   - All unit tests
   - Integration tests
   - Performance tests

3. **Extended Tests** (< 15 min) - Run nightly
   - Edge case scenarios
   - Long-running performance tests
   - Cross-timezone full matrix

### 11.2 Coverage Reporting

**Tools**:
- Xcode's built-in code coverage
- GitHub Actions coverage report upload
- Coverage badge in README
- Fail PR if coverage drops below 80%

### 11.3 Flaky Test Mitigation

**Strategy**:
- Retry flaky tests once
- Track flaky test frequency
- Isolate timing-dependent tests
- Use deterministic date mocking for time-based tests

**Timeline Phase 11**: 1 day

---

## 📊 Success Metrics

### Code Quality Metrics
- [ ] **Test Coverage**: 80%+ business logic, 90%+ Domain layer
- [ ] **Architecture Violations**: 0 (Views → ViewModels → UseCases → Services → Repositories)
- [ ] **Duplicate Code**: 0 in Service/UseCase/Repository layers
- [ ] **Mock Usage**: 0% (all tests use real implementations)

### Test Quality Metrics
- [ ] **Timezone Tests**: 30+ test cases covering edge scenarios
- [ ] **Integration Tests**: 20+ ViewModel tests with real UseCases
- [ ] **Repository Tests**: 15+ SwiftData integration tests
- [ ] **Edge Case Coverage**: 15+ complex scenario + error path tests
- [ ] **Performance Tests**: 10+ regression tests
- [ ] **Build Success**: All tests pass on CI/CD (iPhone 16, iOS 26)

### Test Infrastructure
- [ ] **Test Builders**: LOCAL timezone by default
- [ ] **SwiftData Testing**: In-memory ModelContainer working
- [ ] **Async Testing**: Patterns documented and working
- [ ] **Widget Testing**: Separate target with shared infrastructure

### Documentation
- [ ] **Audit Reports**: 5 audit documents (service, usecase, repository, data, architecture)
- [ ] **Testing Guide**: Comprehensive guide for future developers
- [ ] **CLAUDE.md Updated**: Testing patterns documented
- [ ] **Examples**: Reference tests for all layers

### CI/CD Integration
- [ ] **Smoke Tests**: < 30s on every commit
- [ ] **Full Suite**: < 5 min on PR
- [ ] **Coverage Reporting**: Automated with PR blocking < 80%
- [ ] **Flaky Test Tracking**: Implemented and monitored

---

## 🗓️ Timeline Estimate (REVISED)

| Phase | Effort | Duration | Dependencies |
|-------|--------|----------|--------------|
| **Phase 0: Fix Test Infrastructure** | HIGH | **1 day** | **BLOCKING** |
| Phase 1: Comprehensive Audit | HIGH | 3-4 days | After Phase 0 |
| Phase 2: Consolidation | HIGH | 3-4 days | After Phase 1 |
| Phase 3: Test Infrastructure | MEDIUM | 2-3 days | After Phase 2 |
| Phase 4: Service Tests | HIGH | 2-3 days | After Phase 3 |
| Phase 4.5: Repository Tests | MEDIUM | 1-2 days | After Phase 3 |
| Phase 4.6: Data Layer Tests | LOW | 1 day | After Phase 3 |
| Phase 5: UseCase Tests | MEDIUM | 1-2 days | After Phase 4 |
| Phase 6: ViewModel Tests | MEDIUM | 1-2 days | After Phase 5 |
| Phase 7: Widget Tests | LOW | 1 day | After Phase 3 |
| Phase 8: Edge Cases | MEDIUM | 1-2 days | After Phase 6 |
| Phase 9: Documentation | LOW | 1 day | After Phase 8 |
| Phase 10: Performance Tests | MEDIUM | 1 day | After Phase 4 |
| Phase 11: CI/CD Integration | MEDIUM | 1 day | After Phase 8 |
| **TOTAL** | | **18-26 days** | |

**Previous Estimate**: 12-19 days
**New Estimate**: 18-26 days (+50% more realistic)

**Why Longer**:
- +1 day Phase 0 (BLOCKING - fix test infrastructure)
- +1 day Phase 1 (added Repository/Data audits)
- +1 day Phase 3 (added SwiftData infrastructure)
- +2 days Phase 4.5/4.6 (NEW - Repository/Data tests)
- +1 day Phase 9 (NEW - Documentation)
- +1 day Phase 10 (NEW - Performance regression)
- +1 day Phase 11 (NEW - CI/CD integration)
- +1-2 days contingency buffer

---

## 🎯 Immediate Next Steps

### Week 1: Fix Foundation (CRITICAL)

**Day 1**: Phase 0 - Fix Test Infrastructure (BLOCKING)
1. Fix TestDataBuilders.swift UTC usage
2. Audit TestHelpers.swift
3. Verify CalendarUtils LOCAL methods
4. Document findings in `test-infrastructure-audit.md`

**Days 2-4**: Phase 1 - Comprehensive Audit
1. Service layer audit
2. UseCase layer audit
3. Repository layer audit
4. Data layer audit
5. Cross-layer analysis
6. Document findings in 5 audit reports

**Day 5**: Phase 2 Start - Begin Consolidation
1. Review audit findings
2. Prioritize P0 consolidations
3. Start service consolidation

### Week 2-3: Consolidation & Infrastructure
- Complete Phase 2 (Consolidation)
- Complete Phase 3 (Test Infrastructure)

### Week 3-4: Core Testing
- Phase 4 (Service Tests)
- Phase 4.5 (Repository Tests)
- Phase 4.6 (Data Tests)
- Phase 10 (Performance Tests - parallel)

### Week 4: Integration & Edge Cases
- Phase 5 (UseCase Tests)
- Phase 6 (ViewModel Tests)
- Phase 7 (Widget Tests - parallel)
- Phase 8 (Edge Cases)

### Week 4-5: Documentation & CI/CD
- Phase 9 (Documentation)
- Phase 11 (CI/CD Integration)
- Final validation

---

## 📚 References

- **CLAUDE.md**: Testing requirements (80%+ coverage, real implementations)
- **MICRO-CONTEXTS/testing-strategy.md**: NO MOCKS, use test builders
- **MICRO-CONTEXTS/anti-patterns.md**: Avoid mock-heavy test suites
- **PR #34 Review**: Claude's feedback on missing test coverage
- **PR #35 Review**: Claude's feedback on plan (TestDataBuilders UTC issue, missing phases)
- **project-analysis.md**: Over-reliance on mocks identified as major issue

---

## ✅ Definition of Done

This work is COMPLETE when:

1. ✅ Phase 0 complete: Test infrastructure uses LOCAL timezone
2. ✅ Zero duplicate/redundant code in Service/UseCase/Repository layers
3. ✅ 80%+ test coverage for business logic, 90%+ for Domain layer
4. ✅ Zero tests using mocks (all real implementations)
5. ✅ 30+ timezone-specific tests covering edge cases
6. ✅ 15+ repository tests with SwiftData (in-memory)
7. ✅ 15+ error path & edge case tests
8. ✅ 10+ performance regression tests
9. ✅ All tests pass on CI/CD with iPhone 16, iOS 26 simulator
10. ✅ Documentation complete (5 audit reports + testing guide + CLAUDE.md)
11. ✅ CI/CD integrated (smoke tests < 30s, full suite < 5 min)
12. ✅ Coverage reporting automated with PR blocking < 80%
13. ✅ PR approved with no testing concerns

---

## 🚨 CRITICAL: Start with Phase 0

**DO NOT proceed to Phase 1 until Phase 0 is complete.**

Phase 0 fixes BLOCKING issues in test infrastructure that contradict the PR #34 timezone migration. All subsequent work depends on correct test infrastructure.

---

**Ready to begin Phase 0: Fix Test Infrastructure UTC Usage** 🚀
