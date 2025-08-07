import SwiftUI
import Foundation
import FactoryKit

// swiftlint:disable type_body_length
@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var selectedTimePeriod: TimePeriod = .thisMonth {
        didSet {
            if oldValue != selectedTimePeriod {
                Task {
                    await loadData()
                }
            }
        }
    }
    @Published public var completionStats: HabitCompletionStats?
    @Published public var habitPerformanceData: [HabitPerformance]?
    @Published public var progressChartData: [ChartDataPoint]?
    @Published public var weeklyPatterns: WeeklyPatterns?
    @Published public var streakAnalysis: StreakAnalysis?
    @Published public var categoryBreakdown: [CategoryPerformance]?
    @Published public var isLoading = false
    @Published public var error: Error?
    
    @Injected(\.personalityAnalysisRepository) private var repository
    @Injected(\.categoryRepository) private var categoryRepository
    
    private let userId = UUID() // For now, using a default UUID
    
    public init() {}
    
    // MARK: - Data Models
    
    public enum TimePeriod: CaseIterable {
        case thisWeek
        case thisMonth
        case last6Months
        case lastYear
        case allTime
        
        public var displayName: String {
            switch self {
            case .thisWeek: return Strings.Dashboard.thisWeek
            case .thisMonth: return Strings.Dashboard.thisMonth
            case .last6Months: return Strings.Dashboard.last6Months
            case .lastYear: return Strings.Dashboard.lastYear
            case .allTime: return Strings.Dashboard.allTime
            }
        }
        
        public var dateRange: (start: Date, end: Date) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .thisWeek:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
                return (start: startOfWeek, end: now)
                
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
                return (start: startOfMonth, end: now)
                
            case .last6Months:
                let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now) ?? now
                return (start: sixMonthsAgo, end: now)
                
            case .lastYear:
                let oneYearAgo = calendar.date(byAdding: .year, value: -1, to: now) ?? now
                return (start: oneYearAgo, end: now)
                
            case .allTime:
                // Use a date far in the past to capture all available data
                let allTimeStart = calendar.date(byAdding: .year, value: -10, to: now) ?? now
                return (start: allTimeStart, end: now)
            }
        }
    }
    
    public struct HabitPerformance: Identifiable {
        public let id: String
        public let habitName: String
        public let emoji: String
        public let completionRate: Double
        
        public init(habitName: String, emoji: String, completionRate: Double) {
            self.id = habitName
            self.habitName = habitName
            self.emoji = emoji
            self.completionRate = completionRate
        }
    }
    
    public struct ChartDataPoint: Identifiable {
        public let id = UUID()
        public let date: Date
        public let completionRate: Double
        
        public init(date: Date, completionRate: Double) {
            self.date = date
            self.completionRate = completionRate
        }
    }
    
    public struct WeeklyPatterns {
        public let dayOfWeekPerformance: [DayOfWeekPerformance]
        public let bestDay: String
        public let worstDay: String
        public let averageWeeklyCompletion: Double
        
        public init(dayOfWeekPerformance: [DayOfWeekPerformance], bestDay: String, worstDay: String, averageWeeklyCompletion: Double) {
            self.dayOfWeekPerformance = dayOfWeekPerformance
            self.bestDay = bestDay
            self.worstDay = worstDay
            self.averageWeeklyCompletion = averageWeeklyCompletion
        }
    }
    
    public struct DayOfWeekPerformance: Identifiable {
        public let id: String
        public let dayName: String
        public let completionRate: Double
        public let averageHabitsCompleted: Int
        
        public init(dayName: String, completionRate: Double, averageHabitsCompleted: Int) {
            self.id = dayName
            self.dayName = dayName
            self.completionRate = completionRate
            self.averageHabitsCompleted = averageHabitsCompleted
        }
    }
    
    public struct StreakAnalysis {
        public let currentStreak: Int
        public let longestStreak: Int
        public let streakTrend: String // "improving", "declining", "stable"
        public let daysWithFullCompletion: Int
        public let consistencyScore: Double // 0-1
        
        public init(currentStreak: Int, longestStreak: Int, streakTrend: String, daysWithFullCompletion: Int, consistencyScore: Double) {
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.streakTrend = streakTrend
            self.daysWithFullCompletion = daysWithFullCompletion
            self.consistencyScore = consistencyScore
        }
    }
    
    public struct CategoryPerformance: Identifiable {
        public let id: String
        public let categoryName: String
        public let completionRate: Double
        public let habitCount: Int
        public let color: String
        public let emoji: String?
        
        public init(categoryName: String, completionRate: Double, habitCount: Int, color: String, emoji: String? = nil) {
            self.id = categoryName
            self.categoryName = categoryName
            self.completionRate = completionRate
            self.habitCount = habitCount
            self.color = color
            self.emoji = emoji
        }
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            // Load completion statistics
            let range = selectedTimePeriod.dateRange
            let stats = try await repository.getHabitCompletionStats(
                for: userId,
                from: range.start,
                to: range.end
            )
            
            await MainActor.run {
                self.completionStats = stats
            }
            
            // Load additional data if stats are available
            if stats.totalHabits > 0 {
                await loadHabitPerformanceData()
                await loadProgressChartData()
                await loadWeeklyPatterns()
                await loadStreakAnalysis()
                await loadCategoryBreakdown()
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                print("Failed to load dashboard data: \(error)")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    public func refresh() async {
        await loadData()
    }
    
    // MARK: - Private Methods
    
    private func loadHabitPerformanceData() async {
        do {
            // Get all habits to analyze individual performance
            let habits = try await repository.getUserHabits(for: userId)
            let range = selectedTimePeriod.dateRange
            
            var performanceData: [HabitPerformance] = []
            
            for habit in habits {
                // Calculate individual habit completion rate
                _ = try await repository.getHabitCompletionStats(
                    for: userId,
                    from: range.start,
                    to: range.end
                )
                
                // For individual habit analysis, we would need a different method
                // For now, we'll simulate with some mock data based on the habit
                let completionRate = Double.random(in: 0.3...0.95) // Mock data
                
                let performance = HabitPerformance(
                    habitName: habit.name,
                    emoji: habit.emoji ?? "📊",
                    completionRate: completionRate
                )
                
                performanceData.append(performance)
            }
            
            // Sort by completion rate (highest first)
            performanceData.sort { $0.completionRate > $1.completionRate }
            
            await MainActor.run {
                self.habitPerformanceData = performanceData
            }
            
        } catch {
            print("Failed to load habit performance data: \(error)")
        }
    }
    
    private func loadProgressChartData() async {
        do {
            let range = selectedTimePeriod.dateRange
            let calendar = Calendar.current
            
            var chartData: [ChartDataPoint] = []
            var currentDate = range.start
            
            // Generate daily completion rates for the chart
            while currentDate <= range.end {
                let dayEnd = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                
                let dayStats = try await repository.getHabitCompletionStats(
                    for: userId,
                    from: currentDate,
                    to: dayEnd
                )
                
                let dataPoint = ChartDataPoint(
                    date: currentDate,
                    completionRate: dayStats.completionRate
                )
                
                chartData.append(dataPoint)
                
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            }
            
            await MainActor.run {
                self.progressChartData = chartData
            }
            
        } catch {
            print("Failed to load progress chart data: \(error)")
        }
    }
    
    private func loadWeeklyPatterns() async {
        do {
            let range = selectedTimePeriod.dateRange
            let habits = try await repository.getUserHabits(for: userId)
            let logs = try await repository.getUserHabitLogs(for: userId, from: range.start, to: range.end)
            
            let calendar = Calendar.current
            
            // Group logs by day of week
            var dayPerformance: [String: (completed: Int, total: Int)] = [
                "Sunday": (0, 0),
                "Monday": (0, 0),
                "Tuesday": (0, 0),
                "Wednesday": (0, 0),
                "Thursday": (0, 0),
                "Friday": (0, 0),
                "Saturday": (0, 0)
            ]
            
            let logsByDate = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
            
            for (date, dayLogs) in logsByDate {
                let dayName = DateFormatter().weekdaySymbols[calendar.component(.weekday, from: date) - 1]
                
                // Calculate completion for this day
                let habitsForDay = habits.count
                let completedForDay = dayLogs.count // Simplified - in reality would need proper completion logic
                
                dayPerformance[dayName]?.completed += completedForDay
                dayPerformance[dayName]?.total += habitsForDay
            }
            
            // Create day of week performance array
            let dayOfWeekPerformance = dayPerformance.map { (dayName, performance) in
                let completionRate = performance.total > 0 ? Double(performance.completed) / Double(performance.total) : 0.0
                return DayOfWeekPerformance(
                    dayName: dayName,
                    completionRate: completionRate,
                    averageHabitsCompleted: performance.total > 0 ? performance.completed / max(1, performance.total / habits.count) : 0
                )
            }.sorted { $0.completionRate > $1.completionRate }
            
            let bestDay = dayOfWeekPerformance.first?.dayName ?? "Monday"
            let worstDay = dayOfWeekPerformance.last?.dayName ?? "Monday"
            let averageCompletion = dayOfWeekPerformance.map { $0.completionRate }.reduce(0, +) / Double(dayOfWeekPerformance.count)
            
            let weeklyPatterns = WeeklyPatterns(
                dayOfWeekPerformance: dayOfWeekPerformance,
                bestDay: bestDay,
                worstDay: worstDay,
                averageWeeklyCompletion: averageCompletion
            )
            
            await MainActor.run {
                self.weeklyPatterns = weeklyPatterns
            }
            
        } catch {
            print("Failed to load weekly patterns: \(error)")
        }
    }
    
    private func loadStreakAnalysis() async {
        do {
            let range = selectedTimePeriod.dateRange
            let logs = try await repository.getUserHabitLogs(for: userId, from: range.start, to: range.end)
            
            let calendar = Calendar.current
            let logsByDate = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
            
            // Calculate streaks and consistency
            var currentStreak = 0
            var longestStreak = 0
            var tempStreak = 0
            var daysWithFullCompletion = 0
            
            let sortedDates = logsByDate.keys.sorted()
            
            for (index, date) in sortedDates.enumerated() {
                let dayLogs = logsByDate[date] ?? []
                
                // Consider a day "complete" if there are any logs (simplified)
                if !dayLogs.isEmpty {
                    tempStreak += 1
                    longestStreak = max(longestStreak, tempStreak)
                    
                    // Assume full completion if 80% of expected logs (simplified)
                    if dayLogs.count >= 4 { // Mock threshold
                        daysWithFullCompletion += 1
                    }
                    
                    // If this is the last day or yesterday, it counts toward current streak
                    let isRecent = calendar.dateComponents([.day], from: date, to: Date()).day ?? 0 <= 1
                    if isRecent {
                        currentStreak = tempStreak
                    }
                } else {
                    tempStreak = 0
                }
            }
            
            // Determine trend (simplified)
            let totalDays = max(1, calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 1)
            let consistencyScore = Double(daysWithFullCompletion) / Double(totalDays)
            
            let trend = consistencyScore > 0.7 ? "improving" : consistencyScore > 0.4 ? "stable" : "declining"
            
            let streakAnalysis = StreakAnalysis(
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                streakTrend: trend,
                daysWithFullCompletion: daysWithFullCompletion,
                consistencyScore: consistencyScore
            )
            
            await MainActor.run {
                self.streakAnalysis = streakAnalysis
            }
            
        } catch {
            print("Failed to load streak analysis: \(error)")
        }
    }
    
    private func loadCategoryBreakdown() async {
        do {
            let habits = try await repository.getUserHabits(for: userId)
            let categories = try await categoryRepository.getActiveCategories()
            let range = selectedTimePeriod.dateRange
            
            // Group habits by category, handling suggestions properly
            let habitsByCategory = Dictionary(grouping: habits) { habit in
                // For habits from suggestions, use the actual categoryId
                // For custom habits, use categoryId or "uncategorized"
                if let categoryId = habit.categoryId, categories.contains(where: { $0.id == categoryId }) {
                    return categoryId
                } else if habit.suggestionId != nil {
                    // This is a habit from suggestion but categoryId doesn't match a real category
                    // This shouldn't happen, but if it does, group as "suggestion-unknown"
                    return "suggestion-unknown"
                } else {
                    return "uncategorized"
                }
            }
            
            var categoryPerformance: [CategoryPerformance] = []
            
            for (categoryId, categoryHabits) in habitsByCategory {
                // Skip the suggestion-unknown group as it indicates a data issue
                if categoryId == "suggestion-unknown" {
                    print("WARNING: Found habits from suggestions with invalid categoryId")
                    continue
                }
                
                // Find category info
                let category = categories.first { $0.id == categoryId }
                let categoryName = category?.displayName ?? "Uncategorized"
                let categoryColor = "#007AFF" // Default color since Category doesn't have colorHex
                let categoryEmoji = category?.emoji
                
                // Calculate completion rate for this category (simplified)
                let completionRate = Double.random(in: 0.4...0.95) // Mock data for now
                
                let performance = CategoryPerformance(
                    categoryName: categoryName,
                    completionRate: completionRate,
                    habitCount: categoryHabits.count,
                    color: categoryColor,
                    emoji: categoryEmoji
                )
                
                categoryPerformance.append(performance)
            }
            
            // Sort by completion rate
            categoryPerformance.sort { $0.completionRate > $1.completionRate }
            
            await MainActor.run {
                self.categoryBreakdown = categoryPerformance
            }
        } catch {
            print("Failed to load category breakdown: \(error)")
        }
    }
}
// swiftlint:enable type_body_length
