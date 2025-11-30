import Foundation

// MARK: - Dashboard Analytics Use Case Implementations

public final class AnalyzeWeeklyPatternsUseCase: AnalyzeWeeklyPatternsUseCaseProtocol {
    private let getActiveHabitsUseCase: GetActiveHabitsUseCase
    private let getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        getActiveHabitsUseCase: GetActiveHabitsUseCase,
        getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.getActiveHabitsUseCase = getActiveHabitsUseCase
        self.getHabitLogsUseCase = getHabitLogsUseCase
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult {
        let habits = try await getActiveHabitsUseCase.execute()
        let logs = try await getHabitLogsUseCase.execute(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.analyzeWeeklyPatterns(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}

public final class CalculateHabitPerformanceUseCase: CalculateHabitPerformanceUseCaseProtocol {
    private let getActiveHabitsUseCase: GetActiveHabitsUseCase
    private let getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        getActiveHabitsUseCase: GetActiveHabitsUseCase,
        getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.getActiveHabitsUseCase = getActiveHabitsUseCase
        self.getHabitLogsUseCase = getHabitLogsUseCase
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitPerformanceResult] {
        let habits = try await getActiveHabitsUseCase.execute()
        let logs = try await getHabitLogsUseCase.execute(for: userId, from: startDate, to: endDate)
        
        return performanceAnalysisService.calculateHabitPerformance(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate
        )
    }
}

public final class GenerateProgressChartDataUseCase: GenerateProgressChartDataUseCaseProtocol {
    private let getHabitCompletionStatsUseCase: GetHabitCompletionStatsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(
        getHabitCompletionStatsUseCase: GetHabitCompletionStatsUseCase,
        performanceAnalysisService: PerformanceAnalysisService
    ) {
        self.getHabitCompletionStatsUseCase = getHabitCompletionStatsUseCase
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [ProgressChartDataPoint] {
        var completionStatsByDate: [Date: HabitCompletionStats] = [:]
        var currentDate = startDate
        
        while currentDate <= endDate {
            let dayEnd = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: .current)

            let dayStats = try await getHabitCompletionStatsUseCase.execute(
                for: userId,
                from: currentDate,
                to: dayEnd
            )

            completionStatsByDate[currentDate] = dayStats

            currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: .current)
        }
        
        return performanceAnalysisService.generateProgressChartData(
            completionStats: completionStatsByDate
        )
    }
}