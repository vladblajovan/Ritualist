import Foundation

/// Domain service responsible for performance analysis and calculations
public protocol PerformanceAnalysisService {
    
    /// Calculate habit performance results from habits and logs
    func calculateHabitPerformance(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [HabitPerformanceResult]
    
    /// Generate progress chart data from completion stats over time
    func generateProgressChartData(
        completionStats: [Date: HabitCompletionStats]
    ) -> [ProgressChartDataPoint]
    
    /// Analyze weekly patterns from habits and logs
    func analyzeWeeklyPatterns(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> WeeklyPatternsResult
    
    /// Calculate streak analysis from habits and logs
    func calculateStreakAnalysis(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> StreakAnalysisResult
    
    /// Aggregate category performance from habits, categories, and logs
    func aggregateCategoryPerformance(
        habits: [Habit], 
        categories: [HabitCategory], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [CategoryPerformanceResult]
}

private struct PerfectDayStreakResult {
    let currentStreak: Int
    let longestStreak: Int
    let streakTrend: String
    let daysWithFullCompletion: Int
    let consistencyScore: Double
}

/// Implementation of performance analysis service for dashboard metrics.
///
/// **CRITICAL BUG FIX (Commit: edceada):**
/// This service previously counted log existence instead of validating completion criteria.
/// For numeric habits with targets (e.g., "drink 8 glasses of water"), partial progress
/// (e.g., 3/8 glasses) was incorrectly counted as complete, causing dashboard to show zeros
/// despite having data.
///
/// **Fixed Methods:**
/// - `calculateHabitPerformance`: Now validates log completion before counting
/// - `analyzeWeeklyPatterns`: Now validates log completion for day-of-week analysis
/// - `calculatePerfectDayStreak`: Now validates log completion for streak calculation
/// - `calculateCategoryCompletionRate`: Now validates log completion for category performance
///
/// All methods now use `HabitLogCompletionValidator.isLogCompleted()` to ensure logs meet
/// completion criteria before counting them as completed.
///
/// **Regression Test Recommendation:**
/// Add tests verifying that partial progress (logValue < target) is NOT counted as complete:
/// - Test habit with target=8, log with value=3 → should NOT count as complete
/// - Test habit with target=5, log with value=5 → should count as complete
/// - Test binary habit with value=1.0 → should count as complete
/// - Test binary habit with value=0.0 → should NOT count as complete
public final class PerformanceAnalysisServiceImpl: PerformanceAnalysisService {

    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let streakCalculationService: StreakCalculationService
    private let logger: DebugLogger

    public init(
        scheduleAnalyzer: HabitScheduleAnalyzerProtocol,
        streakCalculationService: StreakCalculationService,
        logger: DebugLogger = DebugLogger(subsystem: "com.ritualist.app", category: "performance")
    ) {
        self.scheduleAnalyzer = scheduleAnalyzer
        self.streakCalculationService = streakCalculationService
        self.logger = logger
    }
    
    public func calculateHabitPerformance(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [HabitPerformanceResult] {
        
        let activeHabits = habits.filter { $0.isActive }
        var results: [HabitPerformanceResult] = []
        
        for habit in activeHabits {
            let habitLogs = logs.filter { $0.habitID == habit.id }
            let logsInRange = habitLogs.filter { log in
                log.date >= startDate && log.date <= endDate
            }
            
            // For retroactive logging support: calculate expected days from the earliest relevant date
            // This ensures that if user logs retroactively, we account for those periods in expected days
            let earliestLogDate = logsInRange.map { $0.date }.min()
            let effectiveStartDate = min(habit.startDate, earliestLogDate ?? habit.startDate)
            let calculationStartDate = max(startDate, effectiveStartDate)
            
            let expectedDays = scheduleAnalyzer.calculateExpectedDays(
                for: habit,
                from: calculationStartDate,
                to: endDate,
                timezone: .current
            )

            // Count only logs that meet completion criteria
            let completedDays = logsInRange.filter { log in
                HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit)
            }.count

            let completionRate = expectedDays > 0 ? Double(completedDays) / Double(expectedDays) : 0.0

            let result = HabitPerformanceResult(
                habitId: habit.id,
                habitName: habit.name,
                emoji: habit.emoji ?? "📊",
                completionRate: min(completionRate, 1.0),
                completedDays: completedDays,
                expectedDays: expectedDays
            )
            
            results.append(result)
        }
        
        return results.sorted { $0.completionRate > $1.completionRate }
    }
    
    public func generateProgressChartData(
        completionStats: [Date: HabitCompletionStats]
    ) -> [ProgressChartDataPoint] {
        
        return completionStats
            .sorted { $0.key < $1.key }
            .map { date, stats in
                ProgressChartDataPoint(
                    date: date,
                    completionRate: stats.completionRate
                )
            }
    }
    
    public func analyzeWeeklyPatterns(
        habits: [Habit],
        logs: [HabitLog],
        from startDate: Date,
        to endDate: Date
    ) -> WeeklyPatternsResult {
        let timezone = TimeZone.current

        // Initialize day performance tracking
        var dayPerformance: [Int: (total: Int, completed: Int)] = [:]
        for weekday in 1...7 {
            dayPerformance[weekday] = (0, 0)
        }

        // Analyze each day in the range
        var currentDate = startDate
        while currentDate <= endDate {
            let weekday = CalendarUtils.weekdayComponentLocal(from: currentDate, timezone: timezone)

            for habit in habits where habit.isActive {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate, timezone: timezone) {
                    dayPerformance[weekday]?.total += 1

                    // Use timezone-aware log matching (consistent with streak calculations)
                    let matchingLog = findLogForDay(
                        habitId: habit.id,
                        date: currentDate,
                        logs: logs,
                        queryTimezone: timezone
                    )

                    if let habitLog = matchingLog,
                       HabitLogCompletionValidator.isLogCompleted(log: habitLog, habit: habit) {
                        dayPerformance[weekday]?.completed += 1
                    }
                }
            }

            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        // Calculate day of week performance results using proper week ordering
        let dayOfWeekResults = dayPerformance.map { weekday, performance in
            let dayName = DateFormatter().weekdaySymbols[weekday - 1]
            let completionRate = performance.total > 0 ? Double(performance.completed) / Double(performance.total) : 0.0
            let averageCompleted = performance.total > 0 ? performance.completed / getDayCount(weekday: weekday, from: startDate, to: endDate) : 0
            
            return DayOfWeekPerformanceResult(
                dayName: dayName,
                completionRate: completionRate,
                averageHabitsCompleted: averageCompleted
            )
        }.sorted { $0.completionRate > $1.completionRate }
        
        let bestDay = dayOfWeekResults.first?.dayName ?? ""
        let worstDay = dayOfWeekResults.last?.dayName ?? ""
        let averageWeeklyCompletion = dayOfWeekResults.reduce(0.0) { $0 + $1.completionRate } / Double(dayOfWeekResults.count)
        
        return WeeklyPatternsResult(
            dayOfWeekPerformance: dayOfWeekResults,
            bestDay: bestDay,
            worstDay: worstDay,
            averageWeeklyCompletion: averageWeeklyCompletion
        )
    }
    
    public func calculateStreakAnalysis(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> StreakAnalysisResult {
        
        let activeHabits = habits.filter { $0.isActive }
        
        // Calculate "perfect day" streaks (where ALL habits are completed)
        // This is different from individual habit streaks and remains useful for overall performance analysis
        let perfectDayAnalysis = calculatePerfectDayStreak(
            habits: activeHabits,
            logs: logs,
            from: startDate,
            to: endDate
        )
        
        return StreakAnalysisResult(
            currentStreak: perfectDayAnalysis.currentStreak,
            longestStreak: perfectDayAnalysis.longestStreak,
            streakTrend: perfectDayAnalysis.streakTrend,
            daysWithFullCompletion: perfectDayAnalysis.daysWithFullCompletion,
            consistencyScore: perfectDayAnalysis.consistencyScore
        )
    }
    
    /// Calculate "perfect day" streaks where ALL active habits are completed
    /// This is different from individual habit streaks - it tracks overall consistency
    private func calculatePerfectDayStreak(
        habits: [Habit],
        logs: [HabitLog],
        from startDate: Date,
        to endDate: Date
    ) -> PerfectDayStreakResult {
        let timezone = TimeZone.current

        var activeStreak = 0  // Active streak ending today (going backwards from today)
        var tempStreak = 0    // Temporary streak while scanning backwards
        var longestStreak = 0
        var daysWithFullCompletion = 0
        var isActiveStreakSet = false  // Track if we've captured the active streak yet

        let today = CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)
        var currentDate = today
        let start = CalendarUtils.startOfDayLocal(for: startDate, timezone: timezone)

        while currentDate >= start {
            var dayCompleted = true
            var expectedHabitsCount = 0

            for habit in habits {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate, timezone: timezone) {
                    expectedHabitsCount += 1

                    // Use timezone-aware log matching: find log that matches this calendar day
                    // considering the log's stored timezone (consistent with HabitCompletionService)
                    let matchingLog = findLogForDay(
                        habitId: habit.id,
                        date: currentDate,
                        logs: logs,
                        queryTimezone: timezone
                    )

                    if let habitLog = matchingLog {
                        if !HabitLogCompletionValidator.isLogCompleted(log: habitLog, habit: habit) {
                            dayCompleted = false
                            break
                        }
                    } else {
                        // No log found for this expected habit
                        dayCompleted = false
                        break
                    }
                }
            }

            if expectedHabitsCount > 0 && dayCompleted {
                tempStreak += 1
                daysWithFullCompletion += 1
            } else if expectedHabitsCount > 0 {
                // Break streak - save it if it's the longest so far
                longestStreak = max(longestStreak, tempStreak)

                // If this is the first break we hit (coming from today), capture active streak
                if !isActiveStreakSet {
                    activeStreak = tempStreak
                    isActiveStreakSet = true
                }

                tempStreak = 0
            }

            currentDate = CalendarUtils.addDays(-1, to: currentDate)
        }

        // End of period - check if we have a final streak to save
        longestStreak = max(longestStreak, tempStreak)

        // If we never hit a break (perfect streak entire period), active streak = temp streak
        if !isActiveStreakSet {
            activeStreak = tempStreak
        }

        // Calculate consistency based on analysis period
        // Add 1 to convert from "difference" to "count" (3 days = difference of 2)
        let totalDays = CalendarUtils.daysBetweenLocal(start, today) + 1
        let consistencyScore = totalDays > 0 ? Double(daysWithFullCompletion) / Double(totalDays) : 0.0

        let streakTrend: String
        if activeStreak > Int(Double(longestStreak) * 0.8) {
            streakTrend = "improving"
        } else if activeStreak < Int(Double(longestStreak) * 0.5) {
            streakTrend = "declining"
        } else {
            streakTrend = "stable"
        }

        return PerfectDayStreakResult(
            currentStreak: activeStreak,  // Return active streak (ending today)
            longestStreak: longestStreak,
            streakTrend: streakTrend,
            daysWithFullCompletion: daysWithFullCompletion,
            consistencyScore: consistencyScore
        )
    }
    
    public func aggregateCategoryPerformance(
        habits: [Habit], 
        categories: [HabitCategory], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> [CategoryPerformanceResult] {
        
        // Group habits by category
        let habitsByCategory = Dictionary(grouping: habits) { habit in
            if let categoryId = habit.categoryId, categories.contains(where: { $0.id == categoryId }) {
                return categoryId
            } else if habit.suggestionId != nil {
                return "suggestion-unknown"
            } else {
                return "uncategorized"
            }
        }
        
        var categoryPerformance: [CategoryPerformanceResult] = []
        
        for (categoryId, categoryHabits) in habitsByCategory {
            // Skip the suggestion-unknown group as it indicates a data issue
            if categoryId == "suggestion-unknown" {
                logger.log("Found habits from suggestions with invalid categoryId", level: .warning, category: .dataIntegrity)
                continue
            }
            
            // Find category info
            let category = categories.first { $0.id == categoryId }
            let categoryName = category?.displayName ?? "Uncategorized"
            let categoryColor = "#007AFF" // Default color since Category doesn't have colorHex
            let categoryEmoji = category?.emoji
            
            // Calculate completion rate for this category
            let completionRate = calculateCategoryCompletionRate(
                habits: categoryHabits,
                logs: logs,
                from: startDate,
                to: endDate
            )
            
            let performance = CategoryPerformanceResult(
                categoryId: categoryId,
                categoryName: categoryName,
                completionRate: completionRate,
                habitCount: categoryHabits.count,
                color: categoryColor,
                emoji: categoryEmoji
            )
            
            categoryPerformance.append(performance)
        }
        
        return categoryPerformance.sorted { $0.completionRate > $1.completionRate }
    }
    
    // MARK: - Private Helpers
    
    private func getDayCount(weekday: Int, from startDate: Date, to endDate: Date) -> Int {
        var count = 0
        var currentDate = startDate

        while currentDate <= endDate {
            if CalendarUtils.weekdayComponentLocal(from: currentDate) == weekday {
                count += 1
            }
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        return max(count, 1) // Avoid division by zero
    }
    
    private func calculateCategoryCompletionRate(
        habits: [Habit], 
        logs: [HabitLog], 
        from startDate: Date, 
        to endDate: Date
    ) -> Double {
        guard !habits.isEmpty else { return 0.0 }
        
        let categoryLogs = logs.filter { log in
            habits.contains { $0.id == log.habitID }
        }
        
        var totalExpectedDays = 0
        var totalCompletedDays = 0
        
        for habit in habits {
            let habitLogs = categoryLogs.filter { $0.habitID == habit.id }

            let expectedDays = scheduleAnalyzer.calculateExpectedDays(
                for: habit,
                from: startDate,
                to: endDate,
                timezone: .current
            )

            // Count only logs that meet completion criteria
            let completedDays = habitLogs.filter { log in
                HabitLogCompletionValidator.isLogCompleted(log: log, habit: habit)
            }.count

            totalExpectedDays += expectedDays
            totalCompletedDays += completedDays
        }
        
        return totalExpectedDays > 0 ? min(Double(totalCompletedDays) / Double(totalExpectedDays), 1.0) : 0.0
    }

    /// Find a log for a specific habit on a specific calendar day using timezone-aware comparison.
    /// Uses CalendarUtils.areSameDayAcrossTimezones for consistent behavior across the codebase.
    private func findLogForDay(
        habitId: UUID,
        date: Date,
        logs: [HabitLog],
        queryTimezone: TimeZone
    ) -> HabitLog? {
        return logs.first { log in
            guard log.habitID == habitId else { return false }

            // Resolve log timezone with fallback and debug logging
            let logTimezone: TimeZone
            if let tz = TimeZone(identifier: log.timezone) {
                logTimezone = tz
            } else {
                #if DEBUG
                print("⚠️ Invalid timezone identifier '\(log.timezone)' for log \(log.id). Falling back to \(queryTimezone.identifier)")
                #endif
                logTimezone = queryTimezone
            }

            // Use shared utility for cross-timezone day comparison
            return CalendarUtils.areSameDayAcrossTimezones(
                log.date,
                timezone1: logTimezone,
                date,
                timezone2: queryTimezone
            )
        }
    }
}
