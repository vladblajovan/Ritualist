# Implementation Plan: Cache Sync with Migration-Aware Invalidation

**Date**: 2025-11-07
**Goal**: Fix memory leak by eliminating unnecessary database reloads while ensuring cache validity during migrations

---

## Overview

**Approach**: Cache Sync (NOT true optimistic updates)
1. ✅ Wait for database write to complete
2. ✅ Update in-memory cache with written data
3. ✅ Skip full database reload
4. ✅ **NEW**: Invalidate cache when migration completes

**Total Impact**:
- Lines added: ~120 lines
- Lines modified: ~12 lines
- Complexity: Low-Medium
- Risk: Low

---

## The Migration Problem (Critical Addition)

### Why Migrations Invalidate Cache

**Scenario**:
```
1. App launches, loads data into cache (SchemaV7)
2. User completes habit → cache updated
3. Migration starts (V7 → V8, adds new fields)
4. Migration completes
5. Cache structure is now STALE (missing new fields from V8)
6. User completes another habit → updateCachedLog() uses old structure
7. CRASH or data inconsistency
```

### Your Existing Migration System

**File**: `MigrationStatusService.swift`

```swift
@MainActor @Observable
public final class MigrationStatusService {
    public static let shared = MigrationStatusService()

    public private(set) var isMigrating: Bool = false
    public private(set) var migrationDetails: MigrationDetails?

    public func startMigration(from: String, to: String) {
        isMigrating = true
        migrationDetails = MigrationDetails(...)
    }

    public func completeMigration() {
        // Keeps modal visible for 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run {
                isMigrating = false  // ← We need to detect this!
                // ...
            }
        }
    }
}
```

**Key Insight**: `isMigrating` changes from `true` → `false` when migration completes.

---

## Solution: Migration-Aware Cache Invalidation

### Strategy

**Detect migration completion and force cache reload**:

1. Track previous `isMigrating` state in OverviewViewModel
2. On each operation, check if migration just completed
3. If yes, invalidate cache and force full reload
4. After reload, cache is fresh with new schema

### Implementation

**Add to OverviewViewModel**:

```swift
// MARK: - Cache Invalidation State

/// Track previous migration state to detect completion
@ObservationIgnored private var wasMigrating = false

/// Check if migration just completed and invalidate cache if needed
/// Returns true if cache was invalidated (caller should reload)
private func checkMigrationAndInvalidateCache() -> Bool {
    let currentlyMigrating = getMigrationStatus.isMigrating

    // Detect migration completion: was migrating, now not
    let justCompletedMigration = wasMigrating && !currentlyMigrating

    // Update tracking state
    wasMigrating = currentlyMigrating

    if justCompletedMigration {
        // Migration just completed - cache is STALE
        print("🔄 Migration completed - invalidating cache")
        overviewData = nil  // Force reload
        return true
    }

    return false
}
```

**Usage in Every Method That Touches Cache**:

```swift
public func completeHabit(_ habit: Habit) async {
    // BEFORE doing anything, check migration
    if checkMigrationAndInvalidateCache() {
        // Cache invalidated, do full reload
        await loadData()
    }

    // Now safe to use cache
    // ... rest of logic ...
}
```

---

## Complete Implementation Plan

### Phase 1: Add Helper Methods (~120 lines)

**Location**: `OverviewViewModel.swift` after `loadOverviewData()`

#### 1.1 Migration Detection (~20 lines)

```swift
// MARK: - Cache Invalidation State

/// Track previous migration state to detect completion
@ObservationIgnored private var wasMigrating = false

/// Check if migration just completed and invalidate cache if needed
/// Returns true if cache was invalidated (caller should reload)
private func checkMigrationAndInvalidateCache() -> Bool {
    let currentlyMigrating = getMigrationStatus.isMigrating

    // Detect migration completion: was migrating, now not
    let justCompletedMigration = wasMigrating && !currentlyMigrating

    // Update tracking state
    wasMigrating = currentlyMigrating

    if justCompletedMigration {
        // Migration just completed - cache is STALE
        print("🔄 Migration completed - invalidating cache")
        overviewData = nil  // Force reload
        return true
    }

    return false
}
```

#### 1.2 Cache Update Helpers (~100 lines)

```swift
// MARK: - Cache Update Helpers (Memory Leak Fix)

/// Update cache after successful database write
/// This eliminates the need for full database reload
private func updateCachedLog(_ log: HabitLog) {
    guard var data = overviewData else { return }

    var habitLogs = data.habitLogs[log.habitID] ?? []

    // Check if log already exists (update scenario)
    if let existingIndex = habitLogs.firstIndex(where: { $0.id == log.id }) {
        habitLogs[existingIndex] = log
    } else {
        habitLogs.append(log)
    }

    var updatedHabitLogs = data.habitLogs
    updatedHabitLogs[log.habitID] = habitLogs

    let updatedData = OverviewData(
        habits: data.habits,
        habitLogs: updatedHabitLogs,
        dateRange: data.dateRange
    )

    refreshUIState(with: updatedData)
}

/// Remove logs from cache after successful database delete
private func removeCachedLogs(habitId: UUID, on date: Date) {
    guard var data = overviewData else { return }

    var habitLogs = data.habitLogs[habitId] ?? []
    habitLogs.removeAll { log in
        CalendarUtils.areSameDayUTC(log.date, date)
    }

    var updatedHabitLogs = data.habitLogs
    updatedHabitLogs[habitId] = habitLogs

    let updatedData = OverviewData(
        habits: data.habits,
        habitLogs: updatedHabitLogs,
        dateRange: data.dateRange
    )

    refreshUIState(with: updatedData)
}

/// Refresh all derived UI properties from OverviewData
/// Ensures consistency across all cards
private func refreshUIState(with data: OverviewData) {
    self.overviewData = data
    self.todaysSummary = extractTodaysSummary(from: data)
    self.activeStreaks = extractActiveStreaks(from: data)
    self.monthlyCompletionData = extractMonthlyData(from: data)
    self.smartInsights = extractSmartInsights(from: data)
    self.checkAndShowInspirationCard()
}

/// Check if date requires database reload (outside cached range)
private func needsReload(for date: Date) -> Bool {
    guard let data = overviewData else { return true }
    let dateStart = CalendarUtils.startOfDayUTC(for: date)
    return !data.dateRange.contains(dateStart)
}
```

---

### Phase 2: Modify Write Methods (3 changes)

**All write methods MUST check for migration first!**

#### 2.1 completeHabit() - Lines 202-233

```swift
public func completeHabit(_ habit: Habit) async {
    // MIGRATION CHECK: Invalidate cache if migration just completed
    if checkMigrationAndInvalidateCache() {
        await loadData()
    }

    do {
        if habit.kind == .numeric {
            await updateNumericHabit(habit, value: habit.dailyTarget ?? 1.0)
        } else {
            let log = HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: CalendarUtils.startOfDayUTC(for: viewingDate),
                value: 1.0,
                timezone: TimeZone.current.identifier
            )

            try await logHabit.execute(log)

            // CACHE SYNC: Update cache instead of full reload
            updateCachedLog(log)

            try? await Task.sleep(nanoseconds: 100_000_000)
            refreshWidget.execute(habitId: habit.id)
        }
    } catch {
        self.error = error
        print("Failed to complete habit: \(error)")
    }
}
```

#### 2.2 updateNumericHabit() - Lines 251-301

```swift
public func updateNumericHabit(_ habit: Habit, value: Double) async {
    // MIGRATION CHECK: Invalidate cache if migration just completed
    if checkMigrationAndInvalidateCache() {
        await loadData()
    }

    do {
        // Get existing logs FROM CACHE (not database)
        let existingLogsForDate = overviewData?.logs(for: habit.id, on: viewingDate) ?? []

        let log: HabitLog

        if existingLogsForDate.isEmpty {
            log = HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: CalendarUtils.startOfDayUTC(for: viewingDate),
                value: value,
                timezone: TimeZone.current.identifier
            )
            try await logHabit.execute(log)

        } else if existingLogsForDate.count == 1 {
            var updatedLog = existingLogsForDate[0]
            updatedLog.value = value
            log = updatedLog
            try await logHabit.execute(log)

        } else {
            // Multiple logs - delete all, create one
            for existingLog in existingLogsForDate {
                try await deleteLog.execute(id: existingLog.id)
            }

            log = HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: CalendarUtils.startOfDayUTC(for: viewingDate),
                value: value,
                timezone: TimeZone.current.identifier
            )
            try await logHabit.execute(log)
        }

        // CACHE SYNC: Update cache instead of full reload
        updateCachedLog(log)

        try? await Task.sleep(nanoseconds: 100_000_000)
        refreshWidget.execute(habitId: habit.id)

    } catch {
        self.error = error
        print("Failed to update numeric habit: \(error)")
    }
}
```

#### 2.3 deleteHabitLog() - Lines 408-431

```swift
public func deleteHabitLog(_ habit: Habit) async {
    // MIGRATION CHECK: Invalidate cache if migration just completed
    if checkMigrationAndInvalidateCache() {
        await loadData()
    }

    do {
        // Get logs FROM CACHE (not database)
        let existingLogsForDate = overviewData?.logs(for: habit.id, on: viewingDate) ?? []

        // Delete from database
        for log in existingLogsForDate {
            try await deleteLog.execute(id: log.id)
        }

        // CACHE SYNC: Update cache instead of full reload
        removeCachedLogs(habitId: habit.id, on: viewingDate)

        try? await Task.sleep(nanoseconds: 100_000_000)
        refreshWidget.execute(habitId: habit.id)

    } catch {
        self.error = error
        print("Failed to delete habit log: \(error)")
    }
}
```

---

### Phase 3: Optimize Date Navigation (3 changes)

**Date navigation also needs migration check!**

#### 3.1 goToPreviousDay() - Line 433

```swift
public func goToPreviousDay() {
    guard canGoToPreviousDay else { return }

    viewingDate = CalendarUtils.previousDay(from: viewingDate)

    // MIGRATION CHECK: Invalidate cache if migration just completed
    if checkMigrationAndInvalidateCache() {
        Task { await loadData() }
        return
    }

    // SELECTIVE RELOAD: Only if date out of cached range
    if needsReload(for: viewingDate) {
        Task { await loadData() }
    } else {
        guard let data = overviewData else { return }
        refreshUIState(with: data)
    }
}
```

#### 3.2 goToNextDay() - Line 442

```swift
public func goToNextDay() {
    guard canGoToNextDay else { return }

    viewingDate = CalendarUtils.nextDay(from: viewingDate)

    // MIGRATION CHECK
    if checkMigrationAndInvalidateCache() {
        Task { await loadData() }
        return
    }

    // SELECTIVE RELOAD
    if needsReload(for: viewingDate) {
        Task { await loadData() }
    } else {
        guard let data = overviewData else { return }
        refreshUIState(with: data)
    }
}
```

#### 3.3 goToToday() - Line 451

```swift
public func goToToday() {
    viewingDate = CalendarUtils.startOfDayLocal(for: Date())

    // MIGRATION CHECK
    if checkMigrationAndInvalidateCache() {
        Task { await loadData() }
        return
    }

    // SELECTIVE RELOAD
    if needsReload(for: Date()) {
        Task { await loadData() }
    } else {
        guard let data = overviewData else { return }
        refreshUIState(with: data)
    }
}
```

---

## Migration Timeline Example

**To visualize how this works**:

```
Time 0s:   App launches, loadData() called
           ├─ overviewData = SchemaV7 data
           └─ wasMigrating = false

Time 1s:   User completes habit
           ├─ checkMigration() → false (no migration)
           └─ updateCachedLog() → works with V7

Time 5s:   Migration starts! (V7 → V8)
           └─ MigrationStatusService.isMigrating = true

Time 8s:   Migration completes
           └─ MigrationStatusService.isMigrating = false

Time 9s:   User completes another habit
           ├─ checkMigration() → wasMigrating=true, currently=false
           ├─ DETECTS migration completion!
           ├─ overviewData = nil (invalidate)
           ├─ loadData() → fresh V8 data
           └─ updateCachedLog() → works with V8 ✅

Time 10s:  User completes another habit
           ├─ checkMigration() → false (already detected)
           └─ updateCachedLog() → works with V8 ✅
```

**Key Points**:
1. Migration detection happens ONCE (when state changes)
2. First operation after migration does full reload
3. Subsequent operations use cache normally
4. Cache structure always matches current schema

---

## Edge Case Handling

### Edge Case 1: User Completes Habit DURING Migration

```
User taps "Complete" → Migration in progress
```

**Behavior**:
```swift
if checkMigrationAndInvalidateCache() {
    await loadData()  // Migration ongoing, load current data
}
```

**Result**: Full reload happens, user sees updated UI after migration

---

### Edge Case 2: Migration Fails

```
Migration starts → Migration fails → isMigrating = false
```

**Our code**:
```swift
if justCompletedMigration {  // true
    overviewData = nil
    return true
}
```

**Result**: Cache invalidated, full reload happens, safe

---

### Edge Case 3: Multiple ViewModels Exist

**Question**: What if HabitsViewModel also uses cache?

**Answer**: Each ViewModel independently tracks `wasMigrating`:
- OverviewViewModel detects migration completion → reloads
- HabitsViewModel detects migration completion → reloads
- Both get fresh data from new schema

**No coordination needed** - each ViewModel is self-contained.

---

## Testing Strategy

### 1. Migration Detection Test

```swift
func testMigrationInvalidatesCache() async {
    let vm = OverviewViewModel()
    await vm.loadData()

    let initialData = vm.overviewData
    XCTAssertNotNil(initialData)

    // Simulate migration
    MigrationStatusService.shared.startMigration(from: "7.0.0", to: "8.0.0")
    await Task.sleep(nanoseconds: 100_000_000)

    // Complete migration
    MigrationStatusService.shared.completeMigration()
    await Task.sleep(nanoseconds: 100_000_000)

    // Next operation should detect migration
    await vm.completeHabit(mockHabit)

    // Verify cache was reloaded (different object)
    XCTAssertNotEqual(vm.overviewData, initialData)
}
```

### 2. Cache Sync Test (No Migration)

```swift
func testCacheSyncWithoutMigration() async {
    let vm = OverviewViewModel()
    await vm.loadData()

    let queryCounter = DatabaseQueryCounter()
    queryCounter.reset()

    // Complete 10 habits
    for habit in vm.habits.prefix(10) {
        await vm.completeHabit(habit)
    }

    // Should have 10 writes, 0 reads (no migration)
    XCTAssertEqual(queryCounter.writeCount, 10)
    XCTAssertEqual(queryCounter.readCount, 0)
}
```

### 3. Migration Mid-Session Test

```swift
func testMigrationMidSessionReloads() async {
    let vm = OverviewViewModel()
    await vm.loadData()

    // Complete habit normally
    await vm.completeHabit(habit1)
    XCTAssertNotNil(vm.overviewData)  // Cache used

    // Trigger migration
    MigrationStatusService.shared.startMigration(from: "7.0.0", to: "8.0.0")
    await Task.sleep(nanoseconds: 1_000_000_000)
    MigrationStatusService.shared.completeMigration()

    // Complete another habit
    await vm.completeHabit(habit2)

    // Should have reloaded due to migration
    XCTAssertNotNil(vm.overviewData)
    // Verify both habits are complete
    XCTAssertTrue(vm.completedHabits.contains(habit1))
    XCTAssertTrue(vm.completedHabits.contains(habit2))
}
```

---

## Summary of Changes

### Files Modified
- `OverviewViewModel.swift` only

### Lines Added
- Migration detection: ~20 lines
- Cache helpers: ~100 lines
- **Total**: ~120 lines

### Lines Modified
- `completeHabit()`: +2 lines (migration check)
- `updateNumericHabit()`: +2 lines (migration check)
- `deleteHabitLog()`: +2 lines (migration check)
- `goToPreviousDay()`: +4 lines (migration check + selective reload)
- `goToNextDay()`: +4 lines (migration check + selective reload)
- `goToToday()`: +4 lines (migration check + selective reload)
- **Total**: ~18 lines modified

### Complexity
- **Low-Medium**: Migration detection is straightforward state tracking
- **Risk**: Low - migration detection is passive (only reads state)

---

## Implementation Checklist

### Pre-Implementation
- [ ] Review current migration flow in `PersistenceContainer.swift`
- [ ] Verify `MigrationStatusService` is accessible via DI
- [ ] Document current schema version

### Phase 1: Migration Detection
- [ ] Add `wasMigrating` state variable
- [ ] Implement `checkMigrationAndInvalidateCache()`
- [ ] Add logging for migration detection

### Phase 2: Cache Helpers
- [ ] Implement `updateCachedLog()`
- [ ] Implement `removeCachedLogs()`
- [ ] Implement `refreshUIState()`
- [ ] Implement `needsReload()`

### Phase 3: Modify Write Methods
- [ ] Update `completeHabit()` with migration check
- [ ] Update `updateNumericHabit()` with migration check
- [ ] Update `deleteHabitLog()` with migration check

### Phase 4: Optimize Navigation
- [ ] Update `goToPreviousDay()`
- [ ] Update `goToNextDay()`
- [ ] Update `goToToday()`

### Testing
- [ ] Write migration detection test
- [ ] Write cache sync test (no migration)
- [ ] Write mid-session migration test
- [ ] Run existing test suite
- [ ] Manual testing with simulated migration

### Validation
- [ ] Profile with Instruments (verify query reduction)
- [ ] Test with real migration (V7 → V8 if available)
- [ ] Monitor logs for migration detection messages

---

## Success Criteria

- ✅ Cache invalidates when migration completes
- ✅ First operation after migration does full reload
- ✅ Subsequent operations use cache normally
- ✅ 95%+ reduction in database queries (no migration scenario)
- ✅ No data corruption or crashes during/after migration
- ✅ All existing tests pass
- ✅ UI remains responsive

---

**Status**: Plan complete, ready for review and implementation
**Next Action**: Review plan with team, approve, then implement
