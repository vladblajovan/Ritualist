import Foundation

// MARK: - Analytics Use Case Implementations

public final class CalculateStreakAnalysis: CalculateStreakAnalysisUseCase {
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(performanceAnalysisService: PerformanceAnalysisService) {
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(habits: [Habit], logs: [HabitLog], from startDate: Date, to endDate: Date) -> StreakAnalysisResult {
        performanceAnalysisService.calculateStreakAnalysis(habits: habits, logs: logs, from: startDate, to: endDate)
    }
}

public final class RefreshWidget: RefreshWidgetUseCase {
    private let widgetRefreshService: WidgetRefreshServiceProtocol
    
    public init(widgetRefreshService: WidgetRefreshServiceProtocol) {
        self.widgetRefreshService = widgetRefreshService
    }
    
    public func execute(habitId: UUID) {
        Task { @MainActor in
            widgetRefreshService.refreshWidgetsForHabit(habitId)
        }
    }
}

public final class GetHabitLogsForAnalytics: GetHabitLogsForAnalyticsUseCase {
    private let habitRepository: HabitRepository
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(habitRepository: HabitRepository, getBatchLogs: GetBatchLogsUseCase) {
        self.habitRepository = habitRepository
        self.getBatchLogs = getBatchLogs
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        // Business logic moved from Service to UseCase
        
        // Get active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabits = allHabits.filter { $0.isActive }
        
        // Use batch loading for efficiency (N+1 query elimination)
        let habitIds = activeHabits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(
            for: habitIds,
            since: startDate,
            until: endDate
        )
        
        // Flatten results
        return logsByHabitId.values.flatMap { $0 }
    }
}

public final class GetHabitCompletionStats: GetHabitCompletionStatsUseCase {
    private let habitRepository: HabitRepository
    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(habitRepository: HabitRepository, scheduleAnalyzer: HabitScheduleAnalyzerProtocol, getBatchLogs: GetBatchLogsUseCase) {
        self.habitRepository = habitRepository
        self.scheduleAnalyzer = scheduleAnalyzer
        self.getBatchLogs = getBatchLogs
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        // Business logic moved from Service to UseCase
        
        // Get active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let habits = allHabits.filter { $0.isActive }
        
        // Get logs using batch loading
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(
            for: habitIds,
            since: startDate,
            until: endDate
        )
        let logs = logsByHabitId.values.flatMap { $0 }
        
        let totalHabits = habits.count
        let logsByDate = Dictionary(grouping: logs, by: { CalendarUtils.startOfDayUTC(for: $0.date) })
        
        var totalExpectedDays = 0
        var totalCompletedDays = 0
        var habitsWithCompletions: Set<UUID> = []
        
        // Calculate expected days based on each habit's schedule
        var currentDate = startDate
        while currentDate <= endDate {
            let dayLogs = logsByDate[CalendarUtils.startOfDayUTC(for: currentDate)] ?? []
            
            for habit in habits {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate) {
                    totalExpectedDays += 1
                    
                    if dayLogs.contains(where: { $0.habitID == habit.id }) {
                        totalCompletedDays += 1
                        habitsWithCompletions.insert(habit.id)
                    }
                }
            }
            
            currentDate = CalendarUtils.addDays(1, to: currentDate)
        }
        
        let completionRate = totalExpectedDays > 0 ? Double(totalCompletedDays) / Double(totalExpectedDays) : 0.0
        let successfulHabits = habitsWithCompletions.count
        
        return HabitCompletionStats(
            totalHabits: totalHabits,
            completedHabits: successfulHabits,
            completionRate: completionRate
        )
    }
}