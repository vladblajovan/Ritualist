# Testing Improvements Plan

**Created:** 2025-11-20
**Branch:** `feature/testing-improvements`
**Status:** 🟡 Planning

---

## 📋 Executive Summary

This plan outlines a comprehensive testing improvement initiative to strengthen test coverage for critical business logic, timezone handling, and notification services in the Ritualist iOS app. The focus is on untested services with high business impact and clear testing requirements.

**Current State:**
- ✅ 20 test files, 337 test cases, 8,143 lines of test code
- ✅ Excellent test infrastructure (Swift Testing, builders, fixtures)
- ❌ 10+ critical services untested
- ❌ No UI/ViewModel tests
- ❌ No CI/CD test automation

**Goals:**
- Add 135-175 new test cases across 10+ services
- Address code comments requesting regression tests (PerformanceAnalysisService)
- Strengthen notification reliability testing
- Improve timezone edge case coverage

---

## 🎯 Testing Priorities

### **🔴 HIGH PRIORITY - Critical Business Logic**

#### 1. HistoricalDateValidationService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/HistoricalDateValidationService.swift:82`
**Why Critical:** Validates date boundaries for historical logging (30-day limit)
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐⭐

**Test Cases to Add:**
```swift
@Suite("HistoricalDateValidationService Tests")
struct HistoricalDateValidationServiceTests {

    // Boundary Tests
    @Test("Date within bounds is valid")
    @Test("Future date throws futureDate error")
    @Test("Date beyond history limit throws beyondHistoryLimit error")
    @Test("Invalid date string throws invalidDateFormat error")

    // Edge Cases
    @Test("Date exactly at boundary (today) is valid")
    @Test("Date exactly at boundary (30 days ago) is valid")
    @Test("Date 31 days ago is invalid")

    // API Tests
    @Test("isDateWithinBounds returns correct boolean")
    @Test("getEarliestAllowedDate returns correct date")

    // Configuration Tests
    @Test("Custom maxHistoryDays configuration works")
}
```

**Estimated Effort:** 1-2 hours
**Estimated Test Cases:** 10-12

---

#### 2. PerformanceAnalysisService Tests ⚠️ REGRESSION RISK
**File:** `RitualistCore/Sources/RitualistCore/Services/PerformanceAnalysisService.swift:76`
**Why Critical:** Powers Dashboard metrics; code explicitly requests regression tests
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐⭐

**📝 Code Comment (Line 70-75):**
> "**Regression Test Recommendation:**
> Add tests verifying that partial progress (logValue < target) is NOT counted as complete"

**Test Cases to Add:**
```swift
@Suite("PerformanceAnalysisService Tests")
struct PerformanceAnalysisServiceTests {

    // CRITICAL BUG REGRESSION TESTS (requested in code)
    @Test("Partial numeric progress is NOT counted as complete")
    // Test: target=8, value=3 → should NOT count

    @Test("Full numeric progress IS counted as complete")
    // Test: target=5, value=5 → should count

    @Test("Binary habit with value 1.0 is counted as complete")
    @Test("Binary habit with value 0.0 is NOT counted as complete")

    // Habit Performance Calculations
    @Test("calculateHabitPerformance with no logs returns 0%")
    @Test("calculateHabitPerformance with all days completed returns 100%")
    @Test("calculateHabitPerformance handles retroactive logging")
    @Test("calculateHabitPerformance respects habit schedules")
    @Test("calculateHabitPerformance sorts by completion rate descending")

    // Weekly Patterns
    @Test("analyzeWeeklyPatterns identifies best day")
    @Test("analyzeWeeklyPatterns identifies worst day")
    @Test("analyzeWeeklyPatterns with no data returns zero averages")
    @Test("analyzeWeeklyPatterns calculates average weekly completion")

    // Perfect Day Streaks
    @Test("calculateStreakAnalysis finds current streak")
    @Test("calculateStreakAnalysis finds longest streak")
    @Test("Perfect day streak requires ALL habits completed")
    @Test("Streak broken when one habit incomplete")
    @Test("Streak trend is 'improving' when near longest")
    @Test("Streak trend is 'declining' when below 50% of longest")

    // Progress Chart Data
    @Test("generateProgressChartData sorts by date")
    @Test("generateProgressChartData maps completion stats correctly")

    // Category Performance
    @Test("aggregateCategoryPerformance groups habits correctly")
    @Test("aggregateCategoryPerformance handles uncategorized habits")
    @Test("aggregateCategoryPerformance skips suggestion-unknown group")
    @Test("aggregateCategoryPerformance sorts by completion rate")
}
```

**Estimated Effort:** 3-4 hours
**Estimated Test Cases:** 25-30

---

#### 3. HabitCompletionCheckService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/HabitCompletionCheckService.swift:36`
**Why Critical:** Orchestrates notification decisions; fail-safe logic critical
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐

**📝 Note:** This is different from `HabitCompletionService` (which already has 25 test cases).
`HabitCompletionService` handles pure completion logic, while `HabitCompletionCheckService`
orchestrates multiple services (repositories, timezone, completion) for notification decisions.

**Test Cases to Add (Focus on Orchestration & Integration):**
```swift
@Suite("HabitCompletionCheckService Tests")
struct HabitCompletionCheckServiceTests {

    // NOTE: These tests focus on orchestration logic, NOT core completion logic
    // (Core completion logic is already tested in HabitCompletionServiceTests)

    // Lifecycle Validations (not in HabitCompletionService)
    @Test("shouldShowNotification returns false for inactive habit")
    @Test("shouldShowNotification returns false before habit start date")
    @Test("shouldShowNotification returns false after habit end date")
    @Test("shouldShowNotification returns false on habit end date boundary")

    // Repository Integration (async fetching)
    @Test("shouldShowNotification fetches habit from repository")
    @Test("shouldShowNotification fetches logs from repository")
    @Test("shouldShowNotification fails safe when habit not found (returns true)")

    // Timezone Service Integration
    @Test("shouldShowNotification uses display timezone from TimezoneService")
    @Test("shouldShowNotification falls back to current timezone on fetch error")

    // Error Handling (Fail-Safe Behavior)
    @Test("shouldShowNotification fails safe on repository error (returns true)")
    @Test("shouldShowNotification fails safe on completion check error (returns true)")

    // Schedule-Aware Logic (delegates to HabitCompletionService)
    @Test("shouldShowNotification returns false for daysOfWeek habit on non-scheduled day")
    @Test("shouldShowNotification returns true for daysOfWeek habit on scheduled day when incomplete")
}
```

**Estimated Effort:** 2-3 hours
**Estimated Test Cases:** 12-15 (reduced - focuses on orchestration, not core logic)

---

#### 4. TimezoneService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/TimezoneService.swift:144`
**Why Critical:** Manages three-timezone model (Current/Home/Display); complex logic
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐⭐

**Test Cases to Add:**
```swift
@Suite("TimezoneService Tests")
struct TimezoneServiceTests {

    // Getters
    @Test("getCurrentTimezone returns device timezone")
    @Test("getHomeTimezone returns stored home timezone")
    @Test("getHomeTimezone falls back to current on invalid identifier")
    @Test("getDisplayTimezoneMode returns stored display mode")
    @Test("getDisplayTimezone resolves based on mode - current")
    @Test("getDisplayTimezone resolves based on mode - home")
    @Test("getDisplayTimezone resolves based on mode - custom")
    @Test("getDisplayTimezone falls back to current on invalid identifier")

    // Setters
    @Test("updateHomeTimezone updates profile")
    @Test("updateHomeTimezone logs timezone change")
    @Test("updateHomeTimezone throws on invalid identifier")
    @Test("updateHomeTimezone updates timestamps")
    @Test("updateDisplayTimezoneMode updates profile")
    @Test("updateDisplayTimezoneMode logs change when mode changes")
    @Test("updateDisplayTimezoneMode does not log when mode unchanged")

    // History Management
    @Test("Timezone change history is trimmed to 100 entries")
    @Test("Timezone change history preserves most recent entries")

    // Detection
    @Test("detectTimezoneChange returns nil when no change")
    @Test("detectTimezoneChange detects device timezone change")
    @Test("detectTimezoneChange returns correct previous and new timezones")
    @Test("detectTravelStatus returns nil when not traveling")
    @Test("detectTravelStatus detects travel (Current ≠ Home)")
    @Test("detectTravelStatus sets isTravel flag correctly")

    // Update Operations
    @Test("updateCurrentTimezone updates device timezone")
    @Test("updateCurrentTimezone logs timezone change")
    @Test("updateCurrentTimezone skips update if unchanged")
}
```

**Estimated Effort:** 3-4 hours
**Estimated Test Cases:** 28-30

---

### **🟡 MEDIUM PRIORITY - Important Features**

#### 5. DailyNotificationSchedulerService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/DailyNotificationSchedulerService.swift:18`
**Why Important:** Daily notification rescheduling reliability
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐⭐
**Challenge:** Requires mocking `UNUserNotificationCenter`

**Test Cases to Add:**
```swift
@Suite("DailyNotificationSchedulerService Tests")
struct DailyNotificationSchedulerServiceTests {

    @Test("rescheduleAllHabitNotifications fetches active habits")
    @Test("rescheduleAllHabitNotifications filters habits with reminders")
    @Test("rescheduleAllHabitNotifications clears existing habit notifications")
    @Test("rescheduleAllHabitNotifications preserves non-habit notifications")
    @Test("rescheduleAllHabitNotifications identifies habit notifications by prefix")
    @Test("rescheduleAllHabitNotifications schedules for active habits with reminders")
    @Test("rescheduleAllHabitNotifications skips inactive habits")
    @Test("rescheduleAllHabitNotifications skips habits without reminders")
    @Test("rescheduleAllHabitNotifications handles scheduling errors gracefully")
    @Test("rescheduleAllHabitNotifications logs scheduling metrics")
}
```

**Estimated Effort:** 4-5 hours (mocking complexity)
**Estimated Test Cases:** 10-12

---

#### 6. HabitSuggestionsService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/HabitSuggestionsService.swift:25`
**Why Important:** Onboarding UX depends on suggestions
**Current Coverage:** ❌ None
**Test Value:** ⭐⭐⭐

**Test Cases to Add:**
```swift
@Suite("HabitSuggestionsService Tests")
struct HabitSuggestionsServiceTests {

    @Test("getSuggestions returns all suggestions")
    @Test("getSuggestions returns non-empty array")
    @Test("getSuggestions(for categoryId) filters by category")
    @Test("getSuggestions(for categoryId) returns only matching category")
    @Test("getSuggestions(for categoryId) returns empty for invalid category")
    @Test("getSuggestion(by id) returns specific suggestion")
    @Test("getSuggestion(by id) returns correct suggestion properties")
    @Test("getSuggestion(by id) returns nil for invalid id")
}
```

**Estimated Effort:** 1 hour
**Estimated Test Cases:** 8-10

---

#### 7. View Logic Tests - Additional Edge Cases
**Current Coverage:** ✅ 5 files tested
**Opportunity:** Add edge cases to existing tests

**Additional Tests for `ProgressColorViewLogicTests`:**
```swift
@Test("Color transitions smoothly across thresholds")
@Test("Edge case: exactly 0% completion")
@Test("Edge case: exactly 100% completion")
@Test("Edge case: negative completion (defensive)")
@Test("Edge case: completion > 100% (defensive)")
```

**Estimated Effort:** 1 hour
**Estimated Test Cases:** 5 per view logic file = 25 total

---

### **🟢 LOWER PRIORITY - Nice to Have**

#### 8. URLValidationService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/URLValidationService.swift`
**Why:** Simple validation logic, good for completeness
**Test Value:** ⭐⭐
**Estimated Effort:** 30 minutes

#### 9. CalculateConsecutiveTrackingDaysService Tests
**File:** `RitualistCore/Sources/RitualistCore/Services/CalculateConsecutiveTrackingDaysService.swift`
**Why:** Untested service for tracking consecutive days
**Test Value:** ⭐⭐⭐
**Estimated Effort:** 1-2 hours

#### 10. Location Services Tests
**Files:** `LocationMonitoringService.swift`, `LocationPermissionService.swift`
**Why:** Location-based features
**Test Value:** ⭐⭐
**Challenge:** Requires mocking CoreLocation
**Estimated Effort:** 3-4 hours

---

## 📅 Implementation Roadmap

### **Phase 1: Critical Business Logic** (Week 1)
**Focus:** High-impact, pure logic tests

| Service | Effort | Test Cases | Priority |
|---------|--------|------------|----------|
| HistoricalDateValidationService | 1-2 hours | 10-12 | 🔴 High |
| PerformanceAnalysisService | 3-4 hours | 25-30 | 🔴 High |
| HabitCompletionCheckService | 2-3 hours | 12-15 | 🔴 High |

**Total Phase 1:** 6-9 hours, 47-57 test cases

**Success Criteria:**
- ✅ All high-priority services have test coverage
- ✅ Regression tests for PerformanceAnalysisService bug (commit edceada)
- ✅ Notification logic validated with edge cases

---

### **Phase 2: Timezone & Notification Logic** (Week 2)
**Focus:** Complex timezone handling and notification reliability

| Service | Effort | Test Cases | Priority |
|---------|--------|------------|----------|
| TimezoneService | 3-4 hours | 28-30 | 🔴 High |
| DailyNotificationSchedulerService | 4-5 hours | 10-12 | 🟡 Medium |

**Total Phase 2:** 7-9 hours, 38-42 test cases

**Success Criteria:**
- ✅ Three-timezone model fully tested
- ✅ Travel detection validated
- ✅ Notification scheduling logic covered

---

### **Phase 3: Feature Completeness** (Week 3)
**Focus:** Round out coverage with medium/low priority services

| Service | Effort | Test Cases | Priority |
|---------|--------|------------|----------|
| HabitSuggestionsService | 1 hour | 8-10 | 🟡 Medium |
| View Logic Edge Cases | 1 hour | 25 | 🟡 Medium |
| URLValidationService | 30 min | 5-8 | 🟢 Low |
| CalculateConsecutiveTrackingDaysService | 1-2 hours | 10-12 | 🟢 Low |

**Total Phase 3:** 3.5-4.5 hours, 48-55 test cases

**Success Criteria:**
- ✅ All medium-priority services covered
- ✅ Edge cases added to existing view logic tests
- ✅ Validation services tested

---

## 📊 Expected Outcomes

### **Test Coverage Metrics**

| Metric | Current | Target | Change |
|--------|---------|--------|--------|
| Test Files | 20 | 27-30 | +35-50% |
| Test Cases | 337 | 475-495 | +40-47% |
| Lines of Test Code | 8,143 | 12,000-13,000 | +47-60% |
| Services Tested | 9 | 17-19 | +89-111% |

### **Coverage by Layer**

| Layer | Current | Target |
|-------|---------|--------|
| Core Services | 9 files | 15-17 files |
| View Logic | 5 files | 5-6 files |
| Integration Tests | 2 files | 3-4 files |
| UI Tests | 0 files | 0 files (future) |

---

## 🛠️ Testing Infrastructure

### **Existing Strengths to Leverage**
- ✅ **TestDataBuilders** - `HabitBuilder`, `HabitLogBuilder`, `OverviewDataBuilder`
- ✅ **TestModelContainer** - In-memory SwiftData containers
- ✅ **TimezoneTestHelpers** - Timezone fixtures and edge cases
- ✅ **Swift Testing Framework** - Modern `@Test` and `#expect()` syntax
- ✅ **No Mocks Philosophy** - Real domain entities ensure production-like tests

### **New Infrastructure Needed**

#### 1. Notification Test Helpers
**Purpose:** Mock `UNUserNotificationCenter` for notification tests
**Location:** `RitualistTests/TestInfrastructure/NotificationTestHelpers.swift`

```swift
final class MockNotificationCenter {
    var pendingRequests: [UNNotificationRequest] = []
    var removedIdentifiers: [String] = []

    func add(_ request: UNNotificationRequest) async throws
    func getPendingNotificationRequests() async -> [UNNotificationRequest]
    func removePendingNotificationRequests(withIdentifiers: [String])
}
```

#### 2. UserProfile Test Builder
**Purpose:** Simplify creating test user profiles with timezones
**Location:** `RitualistTests/TestInfrastructure/TestDataBuilders.swift`

```swift
enum UserProfileBuilder {
    static func standard() -> UserProfile
    static func traveling() -> UserProfile
    static func withTimezone(_ timezone: TimeZone) -> UserProfile
    static func withDisplayMode(_ mode: DisplayTimezoneMode) -> UserProfile
}
```

---

## ⚠️ Risks & Mitigation

### **Risk 1: Notification Testing Complexity**
**Impact:** Medium
**Mitigation:** Create reusable `MockNotificationCenter` infrastructure before Phase 2

### **Risk 2: Timezone Test Flakiness**
**Impact:** Medium
**Mitigation:** Use existing `TimezoneTestHelpers` and fixed reference dates

### **Risk 3: Time Investment**
**Impact:** Low
**Mitigation:** Phased approach allows stopping after high-priority tests

---

## 🎓 Testing Best Practices

### **Patterns to Follow**
1. **Arrange-Act-Assert** structure
2. **Use TestDataBuilders** for consistent test data
3. **Fixed reference dates** (avoid `Date()` in tests)
4. **Real domain entities** (avoid mocks when possible)
5. **In-memory containers** for SwiftData tests
6. **Descriptive test names** (`@Test("Behavior description")`)

### **Patterns to Avoid**
1. ❌ Using `Date()` (creates timezone-dependent tests)
2. ❌ Manual entity construction (use builders)
3. ❌ Shared test state across tests
4. ❌ Testing implementation details instead of behavior
5. ❌ Overly complex test setup

---

## 📈 Success Metrics

### **Quantitative Metrics**
- ✅ 140-180 new test cases added
- ✅ 10+ previously untested services now covered
- ✅ Test suite execution time < 30 seconds
- ✅ 0 flaky tests (deterministic test suite)

### **Qualitative Metrics**
- ✅ Regression tests address code comments (PerformanceAnalysisService)
- ✅ Notification reliability validated
- ✅ Timezone edge cases comprehensively tested
- ✅ Test infrastructure reusable for future features

---

## 🚀 Future Improvements (Post-Plan)

### **Not Included in This Plan (Future Work)**

1. **UI/SwiftUI Testing**
   - ViewInspector integration
   - Snapshot testing
   - 13 untested ViewModels

2. **CI/CD Integration**
   - GitHub Actions workflow for test execution
   - Test coverage reporting
   - Automated test runs on PR

3. **Performance Testing**
   - Benchmark tests for performance-critical code
   - Memory leak detection
   - Launch time testing

4. **Integration Testing**
   - Real StoreKit integration tests
   - Network layer integration tests
   - Widget extension tests

---

## 📝 Notes

- This plan focuses on **unit and service layer tests** with high ROI
- **UI testing** is explicitly excluded (requires different infrastructure)
- **ViewModel testing** is deferred (requires view testing strategy)
- Tests should run **fast** (< 30s total) to maintain developer productivity
- All new tests must use **Swift Testing framework** (not XCTest)

---

## ✅ Definition of Done

A test suite is considered complete when:

1. ✅ All test cases outlined in this plan are implemented
2. ✅ Tests pass consistently (no flakiness)
3. ✅ Test execution time remains < 30 seconds
4. ✅ Code coverage for tested services > 80%
5. ✅ Test infrastructure documented in `RitualistTests/README.md`
6. ✅ Pull request includes test execution screenshot
7. ✅ All tests follow established patterns from existing test suite

---

**Last Updated:** 2025-11-20
**Document Version:** 1.0
**Author:** Claude Code
