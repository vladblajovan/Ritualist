import Foundation

// HabitCompletionService protocol moved to Services/HabitCompletionService.swift

/// Single source of truth data structure for Dashboard analytics
/// Replaces multiple independent data loading methods to eliminate N+1 queries
/// Expected to reduce database queries from 471+ to 3 for annual views
public struct DashboardData {
    public let habits: [Habit]
    public let categories: [HabitCategory]
    public let habitLogs: [UUID: [HabitLog]]  // Indexed by habitId for O(1) access
    public let dateRange: ClosedRange<Date>   // Date range we have data for
    
    // Pre-calculated daily metrics for O(1) chart generation
    private let dailyCompletions: [Date: DayCompletion]
    
    public struct DayCompletion {
        public let date: Date
        public let completedHabits: Set<UUID>
        public let expectedHabits: Set<UUID>  // Based on schedule
        public let completionRate: Double
        public let totalCompleted: Int
        public let totalExpected: Int
        
        public init(date: Date, completedHabits: Set<UUID>, expectedHabits: Set<UUID>, completionRate: Double, totalCompleted: Int, totalExpected: Int) {
            self.date = date
            self.completedHabits = completedHabits
            self.expectedHabits = expectedHabits
            self.completionRate = completionRate
            self.totalCompleted = totalCompleted
            self.totalExpected = totalExpected
        }
    }
    
    public init(habits: [Habit], categories: [HabitCategory], habitLogs: [UUID: [HabitLog]], dateRange: ClosedRange<Date>, isHabitCompleted: IsHabitCompletedUseCase, calculateDailyProgress: CalculateDailyProgressUseCase, isScheduledDay: IsScheduledDayUseCase) {
        self.habits = habits
        self.categories = categories
        self.habitLogs = habitLogs
        self.dateRange = dateRange
        
        // Pre-calculate all daily completions during initialization using UseCases
        self.dailyCompletions = Self.calculateDailyCompletions(
            habits: habits,
            habitLogs: habitLogs,
            dateRange: dateRange,
            isHabitCompleted: isHabitCompleted,
            calculateDailyProgress: calculateDailyProgress,
            isScheduledDay: isScheduledDay
        )
    }
    
    // MARK: - Helper Methods for O(1) Data Access
    
    /// Get completion rate for a specific date (0.0 to 1.0)
    /// O(1) lookup - no database queries
    public func completionRate(for date: Date) -> Double {
        let startOfDay = CalendarUtils.startOfDayLocal(for: date)
        return dailyCompletions[startOfDay]?.completionRate ?? 0.0
    }
    
    /// Get habits completed on a specific date
    /// O(1) lookup for habit IDs, then O(n) filtering where n is small
    public func habitsCompleted(on date: Date) -> [Habit] {
        let startOfDay = CalendarUtils.startOfDayLocal(for: date)
        
        guard let dayCompletion = dailyCompletions[startOfDay] else { return [] }
        
        return habits.filter { dayCompletion.completedHabits.contains($0.id) }
    }
    
    /// Get completed habit IDs for a specific date
    /// O(1) lookup - no database queries
    public func completedHabits(for date: Date) -> Set<UUID> {
        let startOfDay = CalendarUtils.startOfDayLocal(for: date)
        return dailyCompletions[startOfDay]?.completedHabits ?? []
    }
    
    /// Get habits scheduled for a specific date
    /// Only includes habits that have started (date >= habit.startDate) and are scheduled for that day
    public func scheduledHabits(for date: Date) -> [Habit] {
        return habits.filter { $0.isScheduledOn(date: date) }
    }
    
    /// Get streak data for a specific habit using proper UseCase
    /// Uses pre-loaded logs without additional queries
    public func streakData(for habitId: UUID, using calculateCurrentStreak: CalculateCurrentStreakUseCase) -> StreakInfo? {
        guard let habit = habits.first(where: { $0.id == habitId }),
              let logs = habitLogs[habitId] else { return nil }
        
        // Use proper streak calculation UseCase that handles schedules and compliance
        let currentStreak = calculateCurrentStreak.execute(habit: habit, logs: logs, asOf: Date())
        
        return StreakInfo(
            id: habit.id.uuidString,
            habitName: habit.name,
            emoji: habit.emoji ?? "📊",
            currentStreak: currentStreak,
            isActive: currentStreak > 0
        )
    }
    
    /// Get all chart data points for the date range
    /// O(n) where n is number of days - no database queries
    public func chartDataPoints() -> [ProgressChartDataPoint] {
        var dataPoints: [ProgressChartDataPoint] = []

        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let startOfDay = CalendarUtils.startOfDayLocal(for: currentDate)
            let completionRate = dailyCompletions[startOfDay]?.completionRate ?? 0.0
            
            dataPoints.append(ProgressChartDataPoint(
                date: startOfDay,
                completionRate: completionRate
            ))

            currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: .current)
        }
        
        return dataPoints.sorted { $0.date < $1.date }
    }
    
    /// Get habit performance data for all habits using proper schedule calculation
    /// Uses pre-loaded logs and calculated completions with schedule analyzer
    public func habitPerformanceData(using scheduleAnalyzer: HabitScheduleAnalyzerProtocol) -> [HabitPerformanceResult] {
        return habits.map { habit in
            // Count completed days for this habit
            var completedDays = 0
            var expectedDays = 0
            
            for (_, dayCompletion) in dailyCompletions {
                if dayCompletion.expectedHabits.contains(habit.id) {
                    expectedDays += 1
                    if dayCompletion.completedHabits.contains(habit.id) {
                        completedDays += 1
                    }
                }
            }
            
            let completionRate = expectedDays > 0 ? Double(completedDays) / Double(expectedDays) : 0.0
            
            return HabitPerformanceResult(
                habitId: habit.id,
                habitName: habit.name,
                emoji: habit.emoji ?? "📊",
                completionRate: min(completionRate, 1.0), // Cap at 100%
                completedDays: completedDays,
                expectedDays: expectedDays
            )
        }.sorted { $0.completionRate > $1.completionRate }
    }
    
    // TODO: Remove this method - replaced by PerformanceAnalysisService.aggregateCategoryPerformance()
    // Dashboard now uses extractCategoryBreakdown() which calls the service directly.
    // Keeping for now in case other code references it. Safe to delete once confirmed unused.
    /// Get category performance breakdown
    public func categoryPerformanceData() -> [CategoryPerformanceResult] {
        let habitsByCategory = Dictionary(grouping: habits) { $0.categoryId ?? "default" }

        return categories.compactMap { category -> CategoryPerformanceResult? in
            let categoryHabits = habitsByCategory[String(describing: category.id)] ?? []
            guard !categoryHabits.isEmpty else { return nil }

            let totalCompletions = categoryHabits.reduce(0) { total, habit in
                let habitCompletions = dailyCompletions.values.reduce(0) { sum, dayCompletion in
                    return sum + (dayCompletion.completedHabits.contains(habit.id) ? 1 : 0)
                }
                return total + habitCompletions
            }

            let totalPossibleCompletions = categoryHabits.reduce(0) { total, habit in
                let habitExpected = dailyCompletions.values.reduce(0) { sum, dayCompletion in
                    return sum + (dayCompletion.expectedHabits.contains(habit.id) ? 1 : 0)
                }
                return total + habitExpected
            }

            let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0

            return CategoryPerformanceResult(
                categoryId: String(describing: category.id),
                categoryName: category.displayName,
                completionRate: completionRate,
                habitCount: categoryHabits.count,
                color: "#007AFF", // Default iOS blue color
                emoji: category.emoji ?? "📂"
            )
        }.sorted { $0.completionRate > $1.completionRate }
    }
    
    // MARK: - Private Calculation Methods
    
    /// Pre-calculate daily completions for the entire date range using UseCases
    /// This eliminates the need for per-day database queries and ensures single source of truth
    private static func calculateDailyCompletions(habits: [Habit], habitLogs: [UUID: [HabitLog]], dateRange: ClosedRange<Date>, isHabitCompleted: IsHabitCompletedUseCase, calculateDailyProgress: CalculateDailyProgressUseCase, isScheduledDay: IsScheduledDayUseCase) -> [Date: DayCompletion] {
        var dailyCompletions: [Date: DayCompletion] = [:]


        var currentDate = dateRange.lowerBound
        while currentDate <= dateRange.upperBound {
            let startOfDay = CalendarUtils.startOfDayLocal(for: currentDate)

            // Get habits scheduled for this date (must have started AND be scheduled)
            let scheduledHabits = habits.filter { $0.isScheduledOn(date: startOfDay) }
            let expectedHabits = Set(scheduledHabits.map(\.id))
            
            // Find completed habits for this date
            var completedHabits: Set<UUID> = []
            
            for habit in scheduledHabits {
                if let logs = habitLogs[habit.id] {
                    // Use IsHabitCompletedUseCase for single source of truth completion logic
                    let isCompleted = isHabitCompleted.execute(habit: habit, on: startOfDay, logs: logs)
                    
                    if isCompleted {
                        completedHabits.insert(habit.id)
                    }
                }
            }
            
            let completionRate = expectedHabits.isEmpty ? 0.0 : Double(completedHabits.count) / Double(expectedHabits.count)
            
            dailyCompletions[startOfDay] = DayCompletion(
                date: startOfDay,
                completedHabits: completedHabits,
                expectedHabits: expectedHabits,
                completionRate: completionRate,
                totalCompleted: completedHabits.count,
                totalExpected: expectedHabits.count
            )

            currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: .current)
        }
        
        return dailyCompletions
    }
}
