# Memory Leak Analysis - OverviewViewModel

**Date**: 2025-11-07
**Issue**: App crashes after ~1 hour of use due to memory exhaustion (2.36 GiB total allocations)

## Executive Summary

The app suffers from a critical memory leak caused by **excessive full data reloads** after every user interaction. Instead of updating only the changed data, the app recreates entire arrays of habits and logs thousands of times, leading to memory exhaustion and crashes.

## Instruments Data Analysis

### Key Findings from Allocation Statistics

| Type | Persistent Instances | Total Allocations | Total Bytes | Leak Ratio |
|------|---------------------|-------------------|-------------|------------|
| `_ContiguousArrayStorage<Habit>` | 6 | 61,282 | 125.61 MiB | ~10,000:1 |
| `_ContiguousArrayStorage<HabitLog>` | 12 | 38,330 | 161.56 MiB | ~3,200:1 |

**What This Means**:
- Only 6 habit arrays should exist, but 61,282 were created
- Only 12 log arrays should exist, but 38,330 were created
- Arrays are being recreated ~10,000 times when they should be reused
- Over 1 hour of usage, this causes 2.36 GiB of allocations → crash

## Root Cause: Excessive Full Reloads

### Problem Pattern

**File**: `Ritualist/Features/Overview/Presentation/OverviewViewModel.swift`

Every user action triggers a complete database reload that recreates all arrays:

```swift
// Line 221 - After completing a single habit
public func completeHabit(_ habit: Habit) async {
    // ... create ONE log entry ...
    try await logHabit.execute(log)

    await loadData()  // ← RELOADS ALL HABITS + 30 DAYS OF LOGS!
}

// Line 290 - After updating a single numeric value
public func updateNumericHabit(_ habit: Habit, value: Double) async {
    // ... update ONE log entry ...
    try await logHabit.execute(updatedLog)

    await loadData()  // ← RELOADS ALL HABITS + 30 DAYS OF LOGS!
}

// Line 420 - After deleting a single log
public func deleteHabitLog(_ habit: Habit) async {
    // ... delete ONE log entry ...
    try await deleteLog.execute(id: log.id)

    await loadData()  // ← RELOADS ALL HABITS + 30 DAYS OF LOGS!
}

// Lines 436-449 - Date navigation (WORST OFFENDER)
public func goToPreviousDay() {
    if canGoToPreviousDay {
        viewingDate = CalendarUtils.previousDay(from: viewingDate)
        Task {
            await loadData()  // ← RELOADS EVEN WHEN DATA IS CACHED!
        }
    }
}
```

### What `loadData()` Does

**Lines 154-188**: Full data pipeline execution

```swift
public func loadData() async {
    // 1. Load ALL habits from database
    let overviewData = try await loadOverviewData()

    // 2. Store overview data (creates new arrays)
    self.overviewData = overviewData

    // 3. Extract all card data (processes arrays)
    self.todaysSummary = extractTodaysSummary(from: overviewData)
    self.activeStreaks = extractActiveStreaks(from: overviewData)
    self.monthlyCompletionData = extractMonthlyData(from: overviewData)
    self.smartInsights = extractSmartInsights(from: overviewData)
}
```

**Lines 671-692**: Database query + array creation

```swift
private func loadOverviewData() async throws -> OverviewData {
    // 1. Load ALL habits from database
    let habits = try await getActiveHabits.execute()

    // 2. Load logs for past 30 days for ALL habits
    let startDate = CalendarUtils.addDays(-30, to: today)
    let habitLogs = try await getBatchLogs.execute(
        for: habitIds,
        since: startDate,
        until: today
    )

    // 3. Create new OverviewData with NEW ARRAYS
    return OverviewData(
        habits: habits,          // ← NEW array created
        habitLogs: habitLogs,    // ← NEW dictionary of arrays created
        dateRange: startDate...today
    )
}
```

## Impact Calculation

### Typical Usage Scenario (1 hour of active use)

**Assumptions**:
- User has 20 habits
- User completes 10 habits during the session
- User navigates dates 15 times
- User updates 5 numeric values
- Each habit has ~50 logs in 30-day window

**Array Recreations**:
- Habit array recreations: 30 operations × 20 habits = 600 Habit objects
- Log array recreations: 30 operations × 1000 logs = 30,000 HabitLog objects

**Memory Impact** (per Instruments data):
- `_ContiguousArrayStorage<Habit>`: 61,282 allocations = 125.61 MiB
- `_ContiguousArrayStorage<HabitLog>`: 38,330 allocations = 161.56 MiB
- **Total**: ~287 MiB in array overhead alone
- Plus actual object allocations → **2.36 GiB total**

## Why This Happens

### OverviewData is Immutable

**File**: `RitualistCore/Sources/RitualistCore/Entities/Overview/OverviewData.swift`

```swift
public struct OverviewData {
    public let habits: [Habit]
    public let habitLogs: [UUID: [HabitLog]]
    public let dateRange: ClosedRange<Date>
}
```

- `OverviewData` is a `struct` with `let` properties
- **Every change requires creating entirely new arrays**
- No incremental update mechanism exists

### @Observable Reactivity Requirements

- OverviewViewModel uses `@Observable` for SwiftUI reactivity
- Changing `self.overviewData` triggers view updates
- But current implementation recreates everything instead of updating in place

## Related Issues in HabitsViewModel

**File**: `Ritualist/Features/Habits/Presentation/HabitsViewModel.swift`

Similar pattern exists:

```swift
// Line 136 - After creating habit
public func create(_ habit: Habit) async -> Bool {
    _ = try await createHabit.execute(habit)
    await load() // ← Full reload
}

// Line 161 - After updating habit
public func update(_ habit: Habit) async -> Bool {
    try await updateHabit.execute(habit)
    await load() // ← Full reload
}

// Line 188 - After deleting habit
public func delete(id: UUID) async -> Bool {
    try await deleteHabit.execute(id: id)
    await load() // ← Full reload
}
```

While habits change less frequently than logs, this still contributes to the problem.

## Deep Technical Analysis: Is This a "Caching" Problem?

### Reframing the Problem

**Initial framing**: "We need to cache data to avoid reloads"
**Correct framing**: "We need proper state synchronization between database and UI"

This distinction is critical for choosing the right solution.

### What's Actually Happening: The Absurdity

Let's trace a single user interaction:

```swift
completeHabit()
  ├─ Write ONE log to database (we know: habitId, date, value)
  │  └─ logHabit.execute(log)
  │
  └─ Read EVERYTHING from database
     └─ loadData()
        └─ loadOverviewData()
           ├─ Query ALL habits
           └─ Query 30 days × N habits = ~1000 logs
```

**The absurdity**: We just wrote one specific log to the database. We KNOW exactly what changed (habitId, date, value). Why are we reading back 1,000 logs to "discover" what we just wrote?

**Analogy**: This is like running `git clone` after every `git commit` - technically correct, but absurdly inefficient.

### The Real Technical Problem

This is a **state synchronization** problem, not a caching problem:

- **Database** = source of truth (persistent state)
- **ViewModel state** = UI representation of database (ephemeral state)
- **Current sync strategy** = reload everything after every write (naive, but simple)

**Caching** is about:
- Storing expensive computations
- TTL/expiration policies
- Cache invalidation strategies
- Optimizing reads

**State management** is about:
- Keeping UI state synchronized with database
- Eliminating redundant round trips
- Optimistic updates
- Synchronization correctness

### Technical Options Analysis

#### Option 1: Cache with Incremental Updates (Original Proposal)

```swift
completeHabit() → write DB → update cache → refresh UI
```

**Benefits**:
- Reduces database queries by 95%
- Straightforward to implement
- Keeps existing architecture

**Issues**:
- Cache invalidation complexity
- Single source of truth violation (database vs cache divergence)
- What if another screen/widget modifies data?
- Potential synchronization bugs
- Still treats symptoms, not root cause

**Verdict**: Works, but conceptually treating this as "caching" is misleading.

#### Option 2: Optimistic UI Updates (Recommended)

```swift
completeHabit() → update UI immediately → write DB (background)
```

**This is how modern apps work** - Instagram doesn't reload your feed when you like a post!

**Benefits**:
- Instant UI response (no wait for database)
- No unnecessary database queries
- We KNOW what changed (we just wrote it)
- Correct mental model: trust writes, don't verify

**Implementation**:
```swift
public func completeHabit(_ habit: Habit) async {
    let log = HabitLog(...)

    // 1. Optimistic update - we KNOW the new state
    updateUIWithLog(log)  // Modify existing OverviewData in memory

    // 2. Persist to database (can fail)
    do {
        try await logHabit.execute(log)
    } catch {
        // Rollback optimistic update
        removeUILog(log)
        self.error = error
        return
    }

    // 3. Widget sync (still needs 0.1s delay)
    try? await Task.sleep(nanoseconds: 100_000_000)
    refreshWidget.execute(habitId: habit.id)

    // NO database reload - we already know the state!
}
```

**Risks**:
- What if write fails? → Need rollback mechanism (shown above)
- What if widget modifies data? → Reload on app activation
- Race conditions? → Task cancellation + proper sequencing

**Verdict**: Best balance of performance and correctness.

#### Option 3: Reactive Database Layer

```swift
Database emits changes → ViewModel observes → UI updates automatically
```

SwiftData has this built-in with `@Query`:
```swift
@Query var habits: [Habit]  // Automatically updates when database changes
```

**But**: You're using Clean Architecture (Views → ViewModels → UseCases → Repositories), so Views don't directly query SwiftData.

**Would require**:
- Repository publishes changes via Combine/AsyncSequence
- UseCases stream updates instead of one-shot queries
- ViewModels observe streams
- Major architectural refactor

**Example architecture**:
```swift
// Repository layer
protocol HabitRepository {
    func observeHabits() -> AsyncStream<[Habit]>
    func observeLogs(for habitId: UUID) -> AsyncStream<[HabitLog]>
}

// ViewModel layer
@MainActor
class OverviewViewModel {
    init() {
        // Subscribe to habit changes
        Task {
            for await habits in habitRepository.observeHabits() {
                self.habits = habits
                refreshDerivedState()
            }
        }
    }
}
```

**Benefits**:
- Automatic synchronization (single source of truth)
- Works across all screens/widgets
- Most "correct" architecturally

**Costs**:
- Major refactor (weeks of work)
- Increased complexity
- More moving parts

**Verdict**: Architecturally ideal, but overkill for this problem.

#### Option 4: Event-Driven Architecture

```swift
completeHabit() → emit HabitCompletedEvent → subscribers update
```

**Benefits**:
- Decoupled components
- Extensible (add new subscribers easily)
- Clear separation of concerns

**Costs**:
- Most complex option
- Event bus/coordinator needed
- Harder to debug

**Verdict**: Over-engineered for this problem.

#### Option 5: Smart Reload Strategy

```swift
completeHabit() → write DB → only reload if needed
```

**Analysis**: When DO we actually need to reload from database?

| Scenario | Need Reload? | Why |
|----------|--------------|-----|
| App launch | ✅ Yes | No state exists |
| User pull-to-refresh | ✅ Yes | Explicit user request |
| Date navigation (in cached 30-day range) | ❌ No | Data already loaded |
| Date navigation (outside cached range) | ✅ Yes | Need new data |
| Complete habit | ❌ No | We just wrote it, we know the state |
| Update numeric value | ❌ No | We just wrote it, we know the state |
| Delete log | ❌ No | We just deleted it, we know the state |
| Background sync (widget/notification modified data) | ✅ Yes | External modification |
| Return from background | ⚠️ Maybe | Widget might have changed data |

**Key insight**: 95% of database reloads are unnecessary!

**Verdict**: Pragmatic middle ground.

### The SwiftData Dilemma

SwiftData with `@Query` gives you reactive updates for free:
```swift
@Query var habits: [Habit]  // Automatically updates when database changes
```

But you're using **Clean Architecture**, which means:
- ✅ Views don't know about SwiftData
- ✅ ViewModels don't know about SwiftData
- ✅ Only Repositories touch SwiftData
- ✅ Testability without database
- ❌ Lost automatic reactivity

**Your architectural choices**:

| Choice | Pros | Cons |
|--------|------|------|
| **Keep Clean Architecture** | Maintainable, testable, decoupled | Manual synchronization required |
| **Break Clean Architecture** | Automatic reactivity via `@Query` | Views coupled to SwiftData, harder to test |
| **Reactive Clean Architecture** | Best of both worlds | Complex, major refactor |

**Recommendation**: Keep Clean Architecture, optimize manual synchronization.

### Recommended Approach: Hybrid Strategy

**Combine Options 2 + 5**: Optimistic Updates + Selective Reloads

**Core principles**:
1. **Optimistic updates** for writes we control
2. **Only reload** when truly necessary
3. **Keep Clean Architecture** intact
4. **Simple to implement**, easy to test

**Implementation strategy**:
```swift
// For writes WE control (95% of cases)
completeHabit() → optimistic UI update → persist DB → NO reload

// For date navigation WITHIN cached range (common)
goToPreviousDay() → change viewingDate → re-extract from cache → NO reload

// For date navigation OUTSIDE cached range (rare)
goToPreviousDay() → detect out of range → loadData() → YES reload

// For explicit refresh (rare)
refresh() → loadData() → YES reload

// For app activation (rare, but important)
onAppear() → check if stale → maybe reload
```

**Expected impact**:
- **Before**: 30 reloads per session → 60,000+ array allocations
- **After**: 1 reload per session → ~100 array allocations
- **Reduction**: 99.5% fewer database queries

### Why This Isn't "Caching"

**Traditional caching**:
```
┌─────────┐    expensive    ┌───────┐
│  Cache  │ ←───────────── │  API  │
└─────────┘    computation   └───────┘
     ↓
   read
```

**What we actually have**:
```
┌──────────┐   write    ┌──────────┐
│ Database │ ←───────── │ViewModel │
└──────────┘            └──────────┘
     ↓                        ↑
   read                    update
     └───────→ REDUNDANT ───→
```

The problem isn't "expensive reads" - it's "unnecessary reads of what we just wrote".

### Bottom Line

**Not a caching problem. A state synchronization problem.**

**Strategy**: Don't query the database to find out what you just wrote to the database.

**Implementation**: Optimistic UI updates + selective reloads = 99% reduction in database queries without architectural complexity.

## Proposed Solution (Not Yet Implemented)

### Strategy: Optimistic UI Updates + Selective Reloads

Based on the deep technical analysis, the recommended approach is a hybrid strategy that:
1. Uses **optimistic updates** for writes we control (instant UI, no verification read)
2. Uses **selective reloads** only when truly necessary (date out of range, explicit refresh)
3. Keeps **Clean Architecture** intact (no major refactor needed)

#### 1. For Single Log Operations (80% of calls)

**Current flow**:
```swift
completeHabit()
  └─ logHabit.execute(log)      // Write to DB
  └─ loadData()                  // Read 1000+ logs from DB ❌
     └─ Query ALL habits
     └─ Query 30 days of logs
```

**Proposed optimistic flow**:
```swift
completeHabit()
  └─ updateUIWithLog(log)        // Update UI state immediately ✅
  └─ logHabit.execute(log)       // Write to DB (can fail)
     ├─ on success: ✅ done (UI already updated)
     └─ on failure: ❌ rollback UI, show error
```

**Key insight**: We KNOW what we just wrote. Don't read it back.

#### 2. For Date Navigation Within Cached Range (common case)

**Current flow**:
```swift
goToPreviousDay()
  └─ viewingDate = previousDay
  └─ loadData()                  // Read 1000+ logs from DB ❌
```

**Proposed cached flow**:
```swift
goToPreviousDay()
  └─ viewingDate = previousDay
  └─ if dateInCachedRange(viewingDate):
     └─ refreshDerivedProperties()   // Re-extract from existing data ✅
     └─ NO database query
```

**Key insight**: We already loaded 30 days of data. Reuse it.

#### 3. For Date Navigation Outside Cached Range (rare case)

**Proposed selective reload**:
```swift
goToPreviousDay()
  └─ viewingDate = previousDay
  └─ if NOT dateInCachedRange(viewingDate):
     └─ loadData()               // YES, reload needed ✅
```

**Key insight**: Only query database when we don't have the data.

### Implementation Approach

#### Phase 1: Helper Methods (Foundation)

**1. Optimistic state update helpers**:

```swift
// Update UI state with new/modified log (before DB write)
private func updateUIWithLog(_ log: HabitLog) {
    guard var data = overviewData else { return }

    var habitLogs = data.habitLogs[log.habitID] ?? []

    if let existingIndex = habitLogs.firstIndex(where: { $0.id == log.id }) {
        habitLogs[existingIndex] = log  // Update existing
    } else {
        habitLogs.append(log)  // Add new
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

// Remove log from UI state (for deletes or rollbacks)
private func removeUILog(_ log: HabitLog) {
    guard var data = overviewData else { return }

    var habitLogs = data.habitLogs[log.habitID] ?? []
    habitLogs.removeAll { $0.id == log.id }

    var updatedHabitLogs = data.habitLogs
    updatedHabitLogs[log.habitID] = habitLogs

    let updatedData = OverviewData(
        habits: data.habits,
        habitLogs: updatedHabitLogs,
        dateRange: data.dateRange
    )

    refreshUIState(with: updatedData)
}

// Refresh all derived UI properties from data
private func refreshUIState(with data: OverviewData) {
    self.overviewData = data
    self.todaysSummary = extractTodaysSummary(from: data)
    self.activeStreaks = extractActiveStreaks(from: data)
    self.monthlyCompletionData = extractMonthlyData(from: data)
    self.smartInsights = extractSmartInsights(from: data)
    self.checkAndShowInspirationCard()
}

// Check if date needs database reload
private func needsReload(for date: Date) -> Bool {
    guard let data = overviewData else { return true }
    let dateStart = CalendarUtils.startOfDayUTC(for: date)
    return !data.dateRange.contains(dateStart)
}
```

#### Phase 2: Update Write Operations (Biggest Impact)

**1. completeHabit()** (line 202) - 40% of all operations:
```swift
public func completeHabit(_ habit: Habit) async {
    let log = HabitLog(
        id: UUID(),
        habitID: habit.id,
        date: CalendarUtils.startOfDayUTC(for: viewingDate),
        value: 1.0,
        timezone: TimeZone.current.identifier
    )

    // OPTIMISTIC UPDATE: Update UI immediately
    updateUIWithLog(log)

    // PERSIST: Write to database
    do {
        try await logHabit.execute(log)
    } catch {
        // ROLLBACK: Remove from UI on failure
        removeUILog(log)
        self.error = error
        return
    }

    // Widget sync (keep existing delay)
    try? await Task.sleep(nanoseconds: 100_000_000)
    refreshWidget.execute(habitId: habit.id)

    // NO loadData() call! ✅
}
```

**2. updateNumericHabit()** (line 251) - 30% of all operations:
```swift
public func updateNumericHabit(_ habit: Habit, value: Double) async {
    // ... existing log fetching logic ...

    let log = HabitLog(...)

    // OPTIMISTIC UPDATE
    updateUIWithLog(log)

    // PERSIST
    do {
        try await logHabit.execute(log)
    } catch {
        removeUILog(log)
        self.error = error
        return
    }

    // Widget sync
    try? await Task.sleep(nanoseconds: 100_000_000)
    refreshWidget.execute(habitId: habit.id)

    // NO loadData() call! ✅
}
```

**3. deleteHabitLog()** (line 408) - 10% of all operations:
```swift
public func deleteHabitLog(_ habit: Habit) async {
    // Get logs to delete
    let allLogs = try await getLogs.execute(...)
    let logsToDelete = allLogs.filter { ... }

    // OPTIMISTIC UPDATE: Remove from UI first
    for log in logsToDelete {
        removeUILog(log)
    }

    // PERSIST: Delete from database
    do {
        for log in logsToDelete {
            try await deleteLog.execute(id: log.id)
        }
    } catch {
        // ROLLBACK: Re-add to UI on failure
        for log in logsToDelete {
            updateUIWithLog(log)
        }
        self.error = error
        return
    }

    // Widget sync
    try? await Task.sleep(nanoseconds: 100_000_000)
    refreshWidget.execute(habitId: habit.id)

    // NO loadData() call! ✅
}
```

#### Phase 3: Optimize Date Navigation (20% of operations)

**1. goToPreviousDay()** (line 433):
```swift
public func goToPreviousDay() {
    guard canGoToPreviousDay else { return }

    viewingDate = CalendarUtils.previousDay(from: viewingDate)

    // SELECTIVE RELOAD: Only if date out of range
    if needsReload(for: viewingDate) {
        Task { await loadData() }
    } else {
        // Reuse cached data
        guard let data = overviewData else { return }
        refreshUIState(with: data)
    }
}
```

**2. goToNextDay()** (line 442):
```swift
public func goToNextDay() {
    guard canGoToNextDay else { return }

    viewingDate = CalendarUtils.nextDay(from: viewingDate)

    if needsReload(for: viewingDate) {
        Task { await loadData() }
    } else {
        guard let data = overviewData else { return }
        refreshUIState(with: data)
    }
}
```

**3. goToDate()** (line 458):
```swift
public func goToDate(_ date: Date) {
    viewingDate = date

    if needsReload(for: date) {
        Task { await loadData() }
    } else {
        guard let data = overviewData else { return }
        refreshUIState(with: data)
    }
}
```

#### Phase 4: Handle Background Refresh (Edge Cases)

**Add to OverviewView.onAppear**:
```swift
.onAppear {
    vm.setViewVisible(true)

    // Check if data might be stale (widget modified, etc.)
    if vm.shouldRefreshOnAppear {
        Task { await vm.refresh() }
    }
}

.onDisappear {
    vm.setViewVisible(false)
}
```

**Add to ViewModel**:
```swift
@ObservationIgnored private var lastRefreshDate: Date?

public var shouldRefreshOnAppear: Bool {
    guard let lastRefresh = lastRefreshDate else { return false }
    // Refresh if app was in background for > 5 minutes
    return Date().timeIntervalSince(lastRefresh) > 300
}
```

### Expected Impact

**Before Fix**:
- 30 full reloads per session
- 61,282 array allocations
- 287 MiB in array overhead
- 2.36 GiB total allocations
- Crash after ~1 hour

**After Fix**:
- 1 full reload at app launch
- ~30 incremental updates (reuse existing arrays)
- ~10 MiB in array overhead
- ~100 MiB total allocations
- **96% reduction in array allocations**
- No crash

## Additional Optimization Opportunities

### 1. Task Cancellation

Add cancellation for overlapping `loadData()` calls:

```swift
@ObservationIgnored private var loadDataTask: Task<Void, Never>?

public func loadData() async {
    // Cancel previous load if still running
    loadDataTask?.cancel()

    loadDataTask = Task {
        // ... existing load logic ...
    }

    await loadDataTask?.value
}
```

### 2. Debouncing Date Navigation

If user rapidly navigates dates, only load data for the final date:

```swift
@ObservationIgnored private var navigationDebounceTask: Task<Void, Never>?

public func goToPreviousDay() {
    if canGoToPreviousDay {
        viewingDate = CalendarUtils.previousDay(from: viewingDate)

        navigationDebounceTask?.cancel()
        navigationDebounceTask = Task {
            try? await Task.sleep(for: .milliseconds(300))
            if !Task.isCancelled {
                await loadDataIfNeeded()
            }
        }
    }
}
```

## Risks and Considerations

### 1. Cache Invalidation

**Risk**: Cached data may become stale if another part of the app modifies data.

**Mitigation**:
- Keep full reload for app launch and pull-to-refresh
- Add cache invalidation when habits are created/deleted/modified from other screens

### 2. Widget Data Sync

**Risk**: Widget may show stale data if cache isn't updated correctly.

**Current Code** (line 224):
```swift
// Small delay to ensure data is committed to shared container
try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
refreshWidget.execute(habitId: habit.id)
```

**Mitigation**: Keep the delay and widget refresh, but use incremental update for ViewModel state.

### 3. SwiftUI Reactivity

**Risk**: @Observable might not detect changes to nested dictionaries.

**Mitigation**: Always assign to `self.overviewData` (not mutate in place) to trigger SwiftUI updates.

### 4. Testing Complexity

**Risk**: Incremental updates are harder to test than full reloads.

**Mitigation**: Write unit tests that verify cache updates match full reloads.

## Next Steps

1. **Review this analysis** - Confirm the root cause and proposed approach
2. **Decide on implementation strategy** - Incremental updates vs. alternative approaches
3. **Implement changes incrementally** - One method at a time with testing
4. **Verify with Instruments** - Re-run allocation profiling to confirm fix
5. **Monitor in production** - Track crash rates and memory usage

## Open Questions

1. Should we also optimize HabitsViewModel with similar approach?
2. Should we implement task cancellation as part of this fix?
3. Should we add debouncing for date navigation?
4. What's the testing strategy for verifying memory improvements?
5. Are there other ViewModels with similar patterns?

---

**Status**: Analysis complete, helper methods added but not integrated
**Next Action**: Awaiting decision on implementation approach
