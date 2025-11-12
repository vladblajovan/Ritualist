# Testing Infrastructure Improvements - Implementation Plan

**Branch**: `feature/testing-infrastructure-improvements`
**Status**: Planning Phase
**Priority**: HIGH (addresses critical PR feedback)

---

## 🎯 Objectives

Based on Claude's PR #34 review feedback:

1. **Eliminate redundant/duplicate code** in Service and UseCase layers before testing
2. **Build timezone-specific test infrastructure** for comprehensive edge case coverage
3. **Achieve 80%+ business logic coverage, 90%+ Domain layer coverage** (per CLAUDE.md)
4. **Use real implementations, NOT mocks** (per MICRO-CONTEXTS/testing-strategy.md)
5. **Add regression protection** for 78 timezone fixes

---

## 📋 Phase 1: Service & UseCase Layer Audit (PREREQUISITE)

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

**Expected Output**: `service-layer-audit.md` with:
- Service inventory with responsibilities
- Duplicate code findings
- Consolidation recommendations
- Refactoring priority (P0/P1/P2)

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

### 1.3 Cross-Layer Analysis

**Goal**: Identify architectural violations and cleanup opportunities

**Audit Checklist**:
- [ ] ViewModels calling Services directly (should use UseCases)
- [ ] Services calling UseCases (dependency inversion violation)
- [ ] Duplicate domain logic in multiple layers
- [ ] Business logic in ViewModels (should be UseCases)
- [ ] Data transformation logic in wrong layer

**Expected Output**: `architecture-violations.md` with fix priorities

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

### 2.3 Architecture Cleanup
- [ ] Fix ViewModels calling Services directly
- [ ] Add missing UseCases for exposed business operations
- [ ] Move business logic from ViewModels to UseCases
- [ ] Document architectural patterns in CLAUDE.md

**Acceptance Criteria**:
- Zero duplicate business logic across layers
- Clean architecture violations = 0
- All services have single, clear responsibility
- All UseCases orchestrate (not calculate)

---

## 📋 Phase 3: Testing Infrastructure Setup

**Goal**: Build reusable test infrastructure before writing tests

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
        TimeZone(identifier: "UTC")!,
        TimeZone(identifier: "America/New_York")!,  // GMT-5
        TimeZone(identifier: "Asia/Tokyo")!,        // GMT+9
        TimeZone(identifier: "Australia/Sydney")!   // GMT+11
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

### 3.3 Test Fixtures for Edge Cases

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
}
```

---

## 📋 Phase 4: Core Service Tests

**Goal**: Test critical services with timezone awareness

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
}
```

---

## 📋 Phase 7: Widget Timezone Tests

**Goal**: Ensure Widget uses same LOCAL timezone as main app

### 7.1 WidgetHabitsViewModel Tests

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

---

## 📋 Phase 8: Edge Case Scenario Tests

**Goal**: Test complex real-world scenarios

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

---

## 📊 Success Metrics

### Code Quality Metrics
- [ ] **Test Coverage**: 80%+ business logic, 90%+ Domain layer
- [ ] **Architecture Violations**: 0 (Views → ViewModels → UseCases → Services)
- [ ] **Duplicate Code**: 0 in Service/UseCase layers
- [ ] **Mock Usage**: 0% (all tests use real implementations)

### Test Quality Metrics
- [ ] **Timezone Tests**: 30+ test cases covering edge scenarios
- [ ] **Integration Tests**: 15+ ViewModel tests with real UseCases
- [ ] **Edge Case Coverage**: 10+ complex scenario tests
- [ ] **Build Success**: All tests pass on CI/CD

### Documentation
- [ ] **Audit Reports**: service-layer-audit.md, usecase-layer-audit.md, architecture-violations.md
- [ ] **Test Documentation**: Testing patterns documented in CLAUDE.md
- [ ] **Examples**: Reference tests for future development

---

## 🗓️ Timeline Estimate

| Phase | Effort | Duration |
|-------|--------|----------|
| Phase 1: Audit | High | 2-3 days |
| Phase 2: Consolidation | High | 3-4 days |
| Phase 3: Test Infrastructure | Medium | 1-2 days |
| Phase 4: Service Tests | High | 2-3 days |
| Phase 5: UseCase Tests | Medium | 1-2 days |
| Phase 6: ViewModel Tests | Medium | 1-2 days |
| Phase 7: Widget Tests | Low | 1 day |
| Phase 8: Edge Cases | Medium | 1-2 days |
| **TOTAL** | | **12-19 days** |

---

## 🎯 Immediate Next Steps

1. **START**: Phase 1.1 - Service Layer Audit
   - Run comprehensive service inventory
   - Identify duplicate/redundant logic
   - Document consolidation opportunities

2. **Document findings** in `service-layer-audit.md`

3. **Review with team** before proceeding to consolidation

4. **Iterate** through phases sequentially (no skipping)

---

## 📚 References

- **CLAUDE.md**: Testing requirements (80%+ coverage, real implementations)
- **MICRO-CONTEXTS/testing-strategy.md**: NO MOCKS, use test builders
- **MICRO-CONTEXTS/anti-patterns.md**: Avoid mock-heavy test suites
- **PR #34 Review**: Claude's feedback on missing test coverage
- **project-analysis.md**: Over-reliance on mocks identified as major issue

---

## ✅ Definition of Done

This work is COMPLETE when:

1. ✅ Zero duplicate/redundant code in Service/UseCase layers
2. ✅ 80%+ test coverage for business logic, 90%+ for Domain layer
3. ✅ Zero tests using mocks (all real implementations)
4. ✅ 30+ timezone-specific tests covering edge cases
5. ✅ All tests pass on CI/CD with iPhone 16, iOS 26 simulator
6. ✅ Documentation complete (audit reports + test patterns in CLAUDE.md)
7. ✅ PR approved with no testing concerns

---

**Ready to begin Phase 1: Service & UseCase Layer Audit** 🚀
