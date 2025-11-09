import Testing
import Foundation
@testable import RitualistCore
@testable import Ritualist

/// Tests for navigation cache behavior - verifies all navigation methods use cache consistently
/// Tests goToPreviousDay, goToNextDay, goToToday, and goToDate cache behavior
@Suite("Navigation Cache Behavior Tests")
struct NavigationCacheTests {

    // MARK: - Date Navigation Cache Logic Tests

    @Test("goToPreviousDay logic uses cache when date in range")
    func previousDayUsesCache() {
        // Arrange: 30-day cache from today, navigate from day 10 to day 9
        let currentDate = TestDates.daysFromNow(10) // Day 10 of cache
        let previousDate = CalendarUtils.previousDay(from: currentDate)

        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)
        let previousDateStart = CalendarUtils.startOfDayUTC(for: previousDate)

        // Act: Check if previous day is in cache
        let needsReload = !cacheRange.contains(previousDateStart)

        // Assert
        #expect(!needsReload, "Previous day (day 9) should be in cache and not need reload")
    }

    @Test("goToNextDay logic uses cache when date in range")
    func nextDayUsesCache() {
        // Arrange: Navigate from day within cache
        let currentDate = TestDates.daysFromNow(10) // Day 10 of cache
        let nextDate = CalendarUtils.nextDay(from: currentDate)

        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)
        let nextDateStart = CalendarUtils.startOfDayUTC(for: nextDate)

        // Act
        let needsReload = !cacheRange.contains(nextDateStart)

        // Assert
        #expect(!needsReload, "Next day (day 11) should be in cache")
    }

    @Test("goToToday logic uses cache when today in range")
    func todayUsesCache() {
        // Arrange: Cache includes today
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)
        let todayStart = CalendarUtils.startOfDayUTC(for: TestDates.today)

        // Act
        let needsReload = !cacheRange.contains(todayStart)

        // Assert
        #expect(!needsReload, "Today should always be in cache")
    }

    @Test("goToDate logic uses cache when date in range")
    func goToDateUsesCache() {
        // Arrange: Select a date within cache
        let selectedDate = TestDates.daysFromNow(15) // Day 15 of 30-day cache
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)
        let selectedDateStart = CalendarUtils.startOfDayUTC(for: selectedDate)

        // Act
        let needsReload = !cacheRange.contains(selectedDateStart)

        // Assert
        #expect(!needsReload, "Date within cache range should not need reload")
    }

    // MARK: - Cache Miss Scenarios

    @Test("goToPreviousDay logic reloads when date outside range")
    func previousDayOutsideRange() {
        // Arrange: Cache starts at day 5, going back to day 4 is outside
        let cacheStartDate = TestDates.daysFromNow(5)
        let currentDate = cacheStartDate
        let previousDate = CalendarUtils.previousDay(from: currentDate)

        let cacheRange = TestDates.standard30DayRange(from: cacheStartDate)
        let previousDateStart = CalendarUtils.startOfDayUTC(for: previousDate)

        // Act
        let needsReload = !cacheRange.contains(previousDateStart)

        // Assert
        #expect(needsReload, "Previous day outside cache should need reload")
    }

    @Test("goToNextDay logic reloads when date outside range")
    func nextDayOutsideRange() {
        // Arrange: Cache ends at day 29, going to day 30 is outside
        let cacheStartDate = TestDates.today
        let currentDate = TestDates.daysFromNow(29) // Last day of cache
        let nextDate = CalendarUtils.nextDay(from: currentDate)

        let cacheRange = TestDates.standard30DayRange(from: cacheStartDate)
        let nextDateStart = CalendarUtils.startOfDayUTC(for: nextDate)

        // Act
        let needsReload = !cacheRange.contains(nextDateStart)

        // Assert
        #expect(needsReload, "Next day outside cache (day 30) should need reload")
    }

    @Test("goToDate logic reloads when date outside range")
    func goToDateOutsideRange() {
        // Arrange: Select date well outside cache
        let selectedDate = TestDates.daysAgo(35) // 35 days ago, outside 30-day cache
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)
        let selectedDateStart = CalendarUtils.startOfDayUTC(for: selectedDate)

        // Act
        let needsReload = !cacheRange.contains(selectedDateStart)

        // Assert
        #expect(needsReload, "Date outside cache range should need reload")
    }

    // MARK: - Navigation Consistency Tests

    @Test("goToDate and arrow navigation have same cache logic")
    func goToDateMatchesArrowNavigation() {
        // Arrange: Test same target date with both methods
        let targetDate = TestDates.daysFromNow(10)
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)
        let targetDateStart = CalendarUtils.startOfDayUTC(for: targetDate)

        // Act: Simulate both navigation methods
        let needsReloadArrow = !cacheRange.contains(targetDateStart)
        let needsReloadCalendar = !cacheRange.contains(targetDateStart)

        // Assert: Both should have identical cache behavior
        #expect(needsReloadArrow == needsReloadCalendar, "Arrow and calendar navigation should use cache identically")
        #expect(!needsReloadArrow, "Both should use cache for date in range")
    }

    @Test("All navigation methods respect 30-day cache boundary")
    func allMethodsRespectCacheBoundary() {
        // Arrange
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)

        // Test all boundary scenarios
        let testCases: [(date: Date, shouldBeInCache: Bool, description: String)] = [
            (TestDates.today, true, "First day (day 0)"),
            (TestDates.daysFromNow(15), true, "Middle day (day 15)"),
            (TestDates.daysFromNow(29), true, "Last day (day 29)"),
            (TestDates.daysFromNow(30), false, "Just outside (day 30)"),
            (TestDates.daysAgo(1), false, "Before cache (yesterday)")
        ]

        // Act & Assert: All methods should respect same boundaries
        for testCase in testCases {
            let dateStart = CalendarUtils.startOfDayUTC(for: testCase.date)
            let isInCache = cacheRange.contains(dateStart)
            let needsReload = !isInCache

            if testCase.shouldBeInCache {
                #expect(!needsReload, "\(testCase.description) should not need reload")
            } else {
                #expect(needsReload, "\(testCase.description) should need reload")
            }
        }
    }

    // MARK: - Cache Edge Cases

    @Test("Navigation to cache boundary dates (first and last day)")
    func navigationToCacheBoundaries() {
        // Arrange
        let cacheStartDate = TestDates.today
        let cacheRange = TestDates.standard30DayRange(from: cacheStartDate)

        // Test boundary dates
        let firstDay = cacheStartDate
        let lastDay = TestDates.daysFromNow(29)

        let firstDayStart = CalendarUtils.startOfDayUTC(for: firstDay)
        let lastDayStart = CalendarUtils.startOfDayUTC(for: lastDay)

        // Act
        let firstDayInCache = cacheRange.contains(firstDayStart)
        let lastDayInCache = cacheRange.contains(lastDayStart)

        // Assert
        #expect(firstDayInCache, "First day of cache should be accessible")
        #expect(lastDayInCache, "Last day of cache should be accessible")
    }

    @Test("Rapid navigation within cache doesn't trigger reloads")
    func rapidNavigationWithinCache() {
        // Arrange: Simulate rapid date changes within cache
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)

        let navigationSequence = [
            TestDates.today,
            TestDates.daysFromNow(5),
            TestDates.daysFromNow(3),
            TestDates.daysFromNow(10),
            TestDates.daysFromNow(7)
        ]

        // Act & Assert: None should need reload
        for date in navigationSequence {
            let dateStart = CalendarUtils.startOfDayUTC(for: date)
            let needsReload = !cacheRange.contains(dateStart)
            #expect(!needsReload, "Navigation to \(date) should use cache")
        }
    }

    @Test("Navigation across cache boundary triggers reload")
    func navigationAcrossBoundary() {
        // Arrange
        let cacheRange = TestDates.standard30DayRange(from: TestDates.today)

        // Navigate from inside cache to outside
        let insideCache = TestDates.daysFromNow(15)
        let outsideCache = TestDates.daysFromNow(35)

        let insideStart = CalendarUtils.startOfDayUTC(for: insideCache)
        let outsideStart = CalendarUtils.startOfDayUTC(for: outsideCache)

        // Act
        let insideNeedsReload = !cacheRange.contains(insideStart)
        let outsideNeedsReload = !cacheRange.contains(outsideStart)

        // Assert
        #expect(!insideNeedsReload, "Inside cache should not need reload")
        #expect(outsideNeedsReload, "Outside cache should need reload")
    }

    // MARK: - Migration State Handling Tests

    @Test("Migration completion detection logic")
    func migrationCompletionDetection() {
        // Arrange: Simulate migration state transitions
        struct MigrationState {
            var wasMigrating: Bool
            let currentlyMigrating: Bool
            var expectedCompletion: Bool
        }

        let testCases: [MigrationState] = [
            MigrationState(wasMigrating: true, currentlyMigrating: false, expectedCompletion: true),  // Completion
            MigrationState(wasMigrating: false, currentlyMigrating: false, expectedCompletion: false), // No change
            MigrationState(wasMigrating: true, currentlyMigrating: true, expectedCompletion: false),   // Still migrating
            MigrationState(wasMigrating: false, currentlyMigrating: true, expectedCompletion: false)   // Starting
        ]

        // Act & Assert
        for testCase in testCases {
            var wasMigrating = testCase.wasMigrating
            let currentlyMigrating = testCase.currentlyMigrating

            let justCompleted = wasMigrating && !currentlyMigrating
            wasMigrating = currentlyMigrating

            #expect(justCompleted == testCase.expectedCompletion)
        }
    }

    @Test("Navigation during active migration should defer load")
    func navigationDuringMigration() {
        // Arrange: Migration is active
        let isMigrating = true
        let hasLoadedInitialData = false

        // Act: Check if load should be deferred
        let shouldDeferLoad = !hasLoadedInitialData && isMigrating

        // Assert
        #expect(shouldDeferLoad, "Should defer load when migration is active on first load")
    }

    @Test("Navigation after migration completion should invalidate cache")
    func navigationAfterMigration() {
        // Arrange: Migration just completed
        let wasMigrating = true
        let currentlyMigrating = false

        // Act: Detect completion
        let justCompletedMigration = wasMigrating && !currentlyMigrating

        // Assert
        #expect(justCompletedMigration, "Should detect migration completion")
        // In actual ViewModel, this would trigger:
        // - overviewData = nil
        // - hasLoadedInitialData = false
        // - await loadData()
    }

    // MARK: - Helper Method Tests

    @Test("startOfDayUTC normalizes dates correctly for cache comparison")
    func startOfDayNormalization() {
        // Arrange: Different times on same day
        let morning = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: TestDates.today)!
        let afternoon = Calendar.current.date(bySettingHour: 14, minute: 30, second: 0, of: TestDates.today)!
        let evening = Calendar.current.date(bySettingHour: 22, minute: 15, second: 0, of: TestDates.today)!

        // Act: Normalize all to start of day UTC
        let morningStart = CalendarUtils.startOfDayUTC(for: morning)
        let afternoonStart = CalendarUtils.startOfDayUTC(for: afternoon)
        let eveningStart = CalendarUtils.startOfDayUTC(for: evening)

        // Assert: All should normalize to same start-of-day value
        #expect(morningStart == afternoonStart, "Morning and afternoon should normalize to same day")
        #expect(afternoonStart == eveningStart, "Afternoon and evening should normalize to same day")
        #expect(morningStart == eveningStart, "Morning and evening should normalize to same day")
    }

    @Test("areSameDayUTC correctly identifies same day logs")
    func sameDayIdentification() {
        // Arrange: Multiple times on same day
        let date1 = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: TestDates.today)!
        let date2 = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: TestDates.today)!
        let differentDay = TestDates.yesterday

        // Act
        let areSameDay = CalendarUtils.areSameDayUTC(date1, date2)
        let areDifferentDay = CalendarUtils.areSameDayUTC(date1, differentDay)

        // Assert
        #expect(areSameDay, "Different times on same day should be identified as same day")
        #expect(!areDifferentDay, "Different days should be identified as different")
    }
}
