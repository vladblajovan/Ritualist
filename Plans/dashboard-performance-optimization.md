# Dashboard Performance Optimization Plan

## Executive Summary

The Dashboard page suffers from severe performance issues, especially when switching to annual or all-time timeframes. Analysis reveals catastrophic N+1 query patterns resulting in **471+ database queries** for annual views with just 20 habits. This plan outlines a comprehensive optimization strategy to achieve **99.4% query reduction**.

## Current Performance Issues

### 1. Catastrophic N+1 Query Pattern in Chart Generation
**Location**: `GenerateProgressChartDataUseCase.execute()`
- Makes **1 database query per day** in the date range
- Annual timeframe: **365 queries**
- All-time (10 years): **3,650 queries**
- Each query calls `getHabitCompletionStats` which makes additional queries

### 2. N+1 Query in HabitAnalyticsService
**Location**: `HabitAnalyticsService.getHabitLogs()`
```swift
// Current problematic code
for habit in habits {
    let habitLogs = try await logRepository.logs(for: habit.id)
    // ... process logs
}
```
- Makes **1 query per habit**
- With 20 habits: 20 queries just for logs
- Called by EVERY use case (5 times total)

### 3. Redundant Data Loading
Each use case independently loads:
- Active habits: **6 times**
- Habit logs: **5 times**
- Categories: **1 time**

### 4. Performance Impact by Timeframe

| Timeframe | Days | Chart Queries | Log Queries | Total Queries | Estimated Load Time |
|-----------|------|---------------|-------------|---------------|-------------------|
| This Week | 7 | 7 | 100 | ~113 | 1-2s |
| This Month | 30 | 30 | 100 | ~136 | 2-3s |
| Last 6 Months | 180 | 180 | 100 | ~286 | 3-5s |
| Last Year | 365 | 365 | 100 | **~471** | **5-10s** |
| All Time (10y) | 3650 | 3650 | 100 | **~3756** | **30-60s** |

## Proposed Solution Architecture

### Phase 1: Unified Dashboard Data Model

Create a single source of truth for all dashboard calculations:

```swift
// File: /Features/Dashboard/Domain/Models/UnifiedDashboardData.swift
struct UnifiedDashboardData {
    let habits: [Habit]
    let categories: [Category]
    let habitLogs: [UUID: [HabitLog]]  // Indexed by habitId for O(1) access
    let dateRange: ClosedRange<Date>
    
    // Pre-calculated daily metrics for O(1) chart generation
    private var dailyCompletions: [Date: DayCompletion] = [:]
    
    struct DayCompletion {
        let date: Date
        let completedHabits: Set<UUID>
        let expectedHabits: Set<UUID>  // Based on schedule
        let completionRate: Double
        let totalCompleted: Int
        let totalExpected: Int
    }
    
    // Helper methods
    func completionRate(for date: Date) -> Double
    func habitsCompleted(on date: Date) -> [Habit]
    func streakData(for habitId: UUID) -> StreakInfo
    func weeklyPattern() -> WeeklyPattern
}
```

### Phase 2: Batch Data Loading

Replace multiple queries with single batch operation:

```swift
// File: /Features/Dashboard/Presentation/DashboardViewModel+UnifiedLoading.swift
extension DashboardViewModel {
    private func loadUnifiedDashboardData() async throws -> UnifiedDashboardData {
        let range = selectedTimePeriod.dateRange
        
        // 1. Single query for all habits
        let habits = try await habitRepository.fetchAllHabits()
            .filter { $0.isActive }
        
        // 2. Single query for all categories
        let categories = try await categoryRepository.getActiveCategories()
        
        // 3. Single batch query for ALL logs in date range
        let habitIds = habits.map(\.id)
        let logs = try await getBatchLogs.execute(
            for: habitIds,
            since: range.start,
            until: range.end
        )
        
        // 4. Pre-calculate all daily completions ONCE
        let dailyCompletions = calculateDailyCompletions(
            habits: habits,
            logs: logs,
            dateRange: range
        )
        
        return UnifiedDashboardData(
            habits: habits,
            categories: categories,
            habitLogs: logs,
            dateRange: range.start...range.end,
            dailyCompletions: dailyCompletions
        )
    }
}
```

### Phase 3: Fix HabitAnalyticsService N+1

```swift
// File: /Features/Dashboard/Domain/Services/HabitAnalyticsService.swift
public func getHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
    let habits = try await getActiveHabits(for: userId)
    
    // BEFORE: N+1 Query Pattern
    // for habit in habits {
    //     let habitLogs = try await logRepository.logs(for: habit.id)
    // }
    
    // AFTER: Batch Loading
    let habitIds = habits.map(\.id)
    let logsByHabitId = try await getBatchLogs.execute(
        for: habitIds,
        since: startDate,
        until: endDate
    )
    
    return logsByHabitId.values.flatMap { $0 }
}
```

### Phase 4: Optimize Chart Generation

```swift
// File: /Features/Dashboard/Domain/UseCases/GenerateProgressChartDataUseCase.swift
public func execute(from unifiedData: UnifiedDashboardData) -> [ProgressChartDataPoint] {
    // BEFORE: 365 queries for annual
    // while currentDate <= endDate {
    //     let dayStats = try await habitAnalyticsService.getHabitCompletionStats(...)
    // }
    
    // AFTER: Zero queries - use pre-calculated data
    return unifiedData.dailyCompletions.map { date, completion in
        ProgressChartDataPoint(
            date: date,
            completionRate: completion.completionRate
        )
    }.sorted { $0.date < $1.date }
}
```

### Phase 5: Update Dashboard ViewModel

```swift
// File: /Features/Dashboard/Presentation/DashboardViewModel.swift
public func loadData() async {
    guard !isLoading else { return }
    
    isLoading = true
    error = nil
    
    do {
        // Single unified data load
        let unifiedData = try await loadUnifiedDashboardData()
        
        // Extract all metrics from single source (no additional queries)
        self.completionStats = extractCompletionStats(from: unifiedData)
        self.habitPerformanceData = extractHabitPerformance(from: unifiedData)
        self.progressChartData = extractChartData(from: unifiedData)
        self.weeklyPatterns = extractWeeklyPatterns(from: unifiedData)
        self.streakAnalysis = extractStreakAnalysis(from: unifiedData)
        self.categoryBreakdown = extractCategoryBreakdown(from: unifiedData)
        
    } catch {
        self.error = error
        print("Failed to load dashboard data: \(error)")
    }
    
    self.isLoading = false
}
```

## Implementation Plan

### Step 1: Create Data Structures (30 min)
- [ ] Create `UnifiedDashboardData.swift`
- [ ] Define `DayCompletion` struct
- [ ] Add helper methods for data access

### Step 2: Implement Batch Loading (45 min)
- [ ] Create `GetBatchHabitLogsUseCase` if not exists
- [ ] Update `HabitAnalyticsService.getHabitLogs()`
- [ ] Remove N+1 query pattern

### Step 3: Add Unified Loading (1 hour)
- [ ] Implement `loadUnifiedDashboardData()`
- [ ] Add `calculateDailyCompletions()` method
- [ ] Create date range iteration helper

### Step 4: Create Extraction Methods (2 hours)
- [ ] `extractCompletionStats(from:)`
- [ ] `extractHabitPerformance(from:)`
- [ ] `extractChartData(from:)`
- [ ] `extractWeeklyPatterns(from:)`
- [ ] `extractStreakAnalysis(from:)`
- [ ] `extractCategoryBreakdown(from:)`

### Step 5: Update Use Cases (1 hour)
- [ ] Modify `GenerateProgressChartDataUseCase`
- [ ] Update `CalculateHabitPerformanceUseCase`
- [ ] Update `AnalyzeWeeklyPatternsUseCase`
- [ ] Update `CalculateStreakAnalysisUseCase`
- [ ] Update `AggregateCategoryPerformanceUseCase`

### Step 6: Testing (1 hour)
- [ ] Test with minimal data (5 habits, 1 week)
- [ ] Test with moderate data (20 habits, 1 month)
- [ ] Test with large data (50 habits, 1 year)
- [ ] Verify all metrics display correctly
- [ ] Measure actual query counts

### Step 7: Cleanup (30 min)
- [ ] Remove old individual loading methods
- [ ] Update documentation
- [ ] Add performance logging

## Expected Performance Improvements

### Query Reduction

| Scenario | Before | After | Reduction |
|----------|--------|-------|-----------|
| Annual (20 habits) | ~471 queries | 3 queries | **99.4%** |
| All-time (20 habits) | ~3,756 queries | 3 queries | **99.9%** |
| Monthly (50 habits) | ~180 queries | 3 queries | **98.3%** |

### Load Time Improvements

| Timeframe | Current | Optimized | Improvement |
|-----------|---------|-----------|-------------|
| This Week | 1-2s | <100ms | 95% faster |
| This Month | 2-3s | <200ms | 93% faster |
| Last Year | 5-10s | <500ms | **95% faster** |
| All Time | 30-60s | <1s | **98% faster** |

### Memory Optimization
- **Before**: 6 separate data structures, redundant copies
- **After**: 1 unified structure, shared references
- **Reduction**: ~85% memory usage

## Risk Mitigation

### Potential Risks
1. **Large dataset memory usage**: Pre-calculating 10 years of daily data
   - **Mitigation**: Implement pagination for all-time view
   - **Alternative**: Cache only visible range + buffer

2. **Initial load time for first fetch**
   - **Mitigation**: Show progressive loading
   - **Alternative**: Load current month first, then expand

3. **Data consistency during updates**
   - **Mitigation**: Immutable data structures
   - **Alternative**: Copy-on-write semantics

## Success Metrics

- [ ] Dashboard loads in <500ms for annual view
- [ ] Database queries reduced to ≤3 per load
- [ ] Memory usage reduced by >80%
- [ ] No UI freezing during timeframe switches
- [ ] All existing functionality preserved

## Alternative Approaches Considered

1. **Caching Layer**: Add Redis/in-memory cache
   - **Pros**: Even faster subsequent loads
   - **Cons**: Additional complexity, cache invalidation

2. **Background Pre-loading**: Load all timeframes on app start
   - **Pros**: Instant switching
   - **Cons**: High initial memory usage

3. **Pagination**: Load data in chunks
   - **Pros**: Consistent performance regardless of range
   - **Cons**: Complex implementation, multiple requests

## Conclusion

This optimization will transform the Dashboard from the slowest feature in the app to one of the fastest. The 99.4% reduction in database queries will make timeframe switching essentially instant, dramatically improving user experience.

**Estimated Total Implementation Time**: 6 hours
**Estimated Performance Gain**: 95-98% faster load times
**Risk Level**: Low (preserves all functionality)
**Priority**: CRITICAL (current performance is unacceptable)