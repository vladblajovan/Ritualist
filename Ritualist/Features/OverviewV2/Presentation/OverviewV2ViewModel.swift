import SwiftUI
import Foundation
import FactoryKit

// MARK: - Data Models

public struct TodaysSummary {
    public let completedHabits: Int
    public let totalHabits: Int
    public let completionPercentage: Double
    public let motivationalMessage: String
    public let incompleteHabits: [Habit]
    
    public init(completedHabits: Int, totalHabits: Int, incompleteHabits: [Habit]) {
        self.completedHabits = completedHabits
        self.totalHabits = totalHabits
        self.completionPercentage = totalHabits > 0 ? Double(completedHabits) / Double(totalHabits) : 0.0
        self.incompleteHabits = incompleteHabits
        
        // Generate motivational message based on progress
        if completionPercentage >= 1.0 {
            self.motivationalMessage = "Perfect day! All habits completed! 🎉"
        } else if completionPercentage >= 0.8 {
            let remaining = totalHabits - completedHabits
            self.motivationalMessage = "Great work! \(remaining) habit\(remaining == 1 ? "" : "s") left"
        } else if completionPercentage >= 0.5 {
            self.motivationalMessage = "Keep going! You're halfway there"
        } else if completedHabits > 0 {
            self.motivationalMessage = "Good start! Let's build momentum"
        } else {
            self.motivationalMessage = "Ready to start your day?"
        }
    }
}

public struct WeeklyProgress {
    public let daysCompleted: [Bool] // 7 days, starting from user's week start day
    public let weeklyCompletionRate: Double
    public let currentDayIndex: Int
    public let weekDescription: String
    
    public init(daysCompleted: [Bool], currentDayIndex: Int) {
        self.daysCompleted = daysCompleted
        self.currentDayIndex = currentDayIndex
        
        let completedDays = daysCompleted.filter { $0 }.count
        self.weeklyCompletionRate = Double(completedDays) / 7.0
        
        let percentage = Int(weeklyCompletionRate * 100)
        self.weekDescription = "\(completedDays) days completed • \(percentage)% weekly"
    }
}

public struct StreakInfo: Identifiable {
    public let id: String
    public let habitName: String
    public let emoji: String
    public let currentStreak: Int
    public let isActive: Bool
    
    public var flameCount: Int {
        if currentStreak >= 30 { return 3 }
        else if currentStreak >= 14 { return 2 }
        else if currentStreak >= 7 { return 1 }
        else { return 0 }
    }
    
    public var flameEmoji: String {
        String(repeating: "🔥", count: flameCount)
    }
    
    public init(id: String, habitName: String, emoji: String, currentStreak: Int, isActive: Bool) {
        self.id = id
        self.habitName = habitName
        self.emoji = emoji
        self.currentStreak = currentStreak
        self.isActive = isActive
    }
}

public struct SmartInsight {
    public let title: String
    public let message: String
    public let type: InsightType
    
    public enum InsightType {
        case pattern
        case suggestion
        case celebration
        case warning
    }
    
    public init(title: String, message: String, type: InsightType) {
        self.title = title
        self.message = message
        self.type = type
    }
}

// MARK: - ViewModel

@MainActor
public final class OverviewV2ViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published public var todaysSummary: TodaysSummary?
    @Published public var weeklyProgress: WeeklyProgress?
    @Published public var activeStreaks: [StreakInfo] = []
    @Published public var smartInsights: [SmartInsight] = []
    @Published public var calendarData: [Date: [Habit]] = [:]
    @Published public var selectedDate: Date = Date()
    @Published public var isCalendarExpanded: Bool = false
    
    @Published public var isLoading: Bool = false
    @Published public var error: Error?
    
    // MARK: - Computed Properties
    public var incompleteHabits: [Habit] {
        todaysSummary?.incompleteHabits ?? []
    }
    
    public var shouldShowQuickActions: Bool {
        !incompleteHabits.isEmpty
    }
    
    public var shouldShowActiveStreaks: Bool {
        !activeStreaks.isEmpty && activeStreaks.contains { $0.currentStreak >= 3 }
    }
    
    public var shouldShowInsights: Bool {
        !smartInsights.isEmpty
    }
    
    // MARK: - Dependencies
    @Injected(\.habitRepository) private var habitRepository
    @Injected(\.logRepository) private var logRepository
    
    private let userId = UUID() // For now, using default UUID
    
    public init() {}
    
    // MARK: - Public Methods
    
    public func loadData() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        
        do {
            async let todaySummaryTask = loadTodaysSummary()
            async let weeklyProgressTask = loadWeeklyProgress()
            async let activeStreaksTask = loadActiveStreaks()
            async let insightsTask = loadSmartInsights()
            async let calendarTask = loadCalendarData()
            
            let (todaySummary, weeklyProgress, streaks, insights, calendar) = try await (
                todaySummaryTask,
                weeklyProgressTask,
                activeStreaksTask,
                insightsTask,
                calendarTask
            )
            
            await MainActor.run {
                self.todaysSummary = todaySummary
                self.weeklyProgress = weeklyProgress
                self.activeStreaks = streaks
                self.smartInsights = insights
                self.calendarData = calendar
            }
            
        } catch {
            await MainActor.run {
                self.error = error
                print("Failed to load OverviewV2 data: \(error)")
            }
        }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
    
    public func refresh() async {
        await loadData()
    }
    
    public func completeHabit(_ habit: Habit) async {
        do {
            // Create habit log for today
            let log = HabitLog(
                id: UUID(),
                habitID: habit.id,
                date: Date(),
                value: habit.kind == .numeric ? habit.dailyTarget ?? 1.0 : 1.0
            )
            
            try await logRepository.upsert(log)
            
            // Refresh data to show updated progress
            await loadData()
            
        } catch {
            await MainActor.run {
                self.error = error
                print("Failed to complete habit: \(error)")
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTodaysSummary() async throws -> TodaysSummary {
        let today = Date()
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        
        var allTodaysLogs: [HabitLog] = []
        for habit in habits {
            let habitLogs = try await logRepository.logs(for: habit.id)
            let todaysLogs = habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            allTodaysLogs.append(contentsOf: todaysLogs)
        }
        
        let completedHabits = allTodaysLogs.count
        let incompleteHabits = habits.filter { habit in
            !allTodaysLogs.contains { $0.habitID == habit.id }
        }
        
        return TodaysSummary(
            completedHabits: completedHabits,
            totalHabits: habits.count,
            incompleteHabits: incompleteHabits
        )
    }
    
    private func loadWeeklyProgress() async throws -> WeeklyProgress {
        let calendar = Calendar.current
        let today = Date()
        
        // Get the start of the current week
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: today) else {
            throw NSError(domain: "WeeklyProgress", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get week interval"])
        }
        
        var daysCompleted: [Bool] = []
        let currentDayIndex = calendar.component(.weekday, from: today) - 1
        
        // Check each day of the week
        for dayOffset in 0..<7 {
            if let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekInterval.start) {
                let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
                
                var dayLogs: [HabitLog] = []
                for habit in habits {
                    let habitLogs = try await logRepository.logs(for: habit.id)
                    let logsForDay = habitLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: dayDate) }
                    dayLogs.append(contentsOf: logsForDay)
                }
                
                // Consider day completed if any habits were logged
                let isCompleted = !dayLogs.isEmpty && Double(dayLogs.count) / Double(habits.count) > 0.5
                daysCompleted.append(isCompleted)
            } else {
                daysCompleted.append(false)
            }
        }
        
        return WeeklyProgress(daysCompleted: daysCompleted, currentDayIndex: currentDayIndex)
    }
    
    private func loadActiveStreaks() async throws -> [StreakInfo] {
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        var streaks: [StreakInfo] = []
        
        for habit in habits {
            // Calculate current streak (simplified)
            let currentStreak = try await calculateCurrentStreak(for: habit)
            
            if currentStreak >= 3 { // Only show streaks of 3+ days
                let streakInfo = StreakInfo(
                    id: habit.id.uuidString,
                    habitName: habit.name,
                    emoji: habit.emoji ?? "📊",
                    currentStreak: currentStreak,
                    isActive: true
                )
                streaks.append(streakInfo)
            }
        }
        
        // Sort by streak length (longest first)
        return streaks.sorted { $0.currentStreak > $1.currentStreak }
    }
    
    private func calculateCurrentStreak(for habit: Habit) async throws -> Int {
        // Simplified streak calculation - in a real implementation,
        // this would check consecutive days with habit logs
        return Int.random(in: 0...21) // Mock data for now
    }
    
    private func loadSmartInsights() async throws -> [SmartInsight] {
        // Mock insights for now - in real implementation, this would analyze patterns
        let insights = [
            SmartInsight(
                title: "Strong Tuesday Pattern",
                message: "You complete 85% more habits on Tuesdays",
                type: .pattern
            ),
            SmartInsight(
                title: "Friday Focus Needed",
                message: "Try scheduling fewer habits on Fridays",
                type: .suggestion
            )
        ]
        
        return insights
    }
    
    private func loadCalendarData() async throws -> [Date: [Habit]] {
        // Load calendar data for the current month
        let calendar = Calendar.current
        let today = Date()
        
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else {
            return [:]
        }
        
        var calendarData: [Date: [Habit]] = [:]
        let habits = try await habitRepository.fetchAllHabits().filter { $0.isActive }
        
        // For now, return mock data
        return calendarData
    }
}