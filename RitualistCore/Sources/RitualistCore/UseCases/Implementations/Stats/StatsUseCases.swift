import Foundation

// MARK: - Dashboard Analytics Use Case Implementations

public final class AnalyzeWeeklyPatternsUseCase: AnalyzeWeeklyPatternsUseCaseProtocol {
    private let getActiveHabitsUseCase: GetActiveHabitsUseCase
    private let getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    private let timezoneService: TimezoneService

    public init(
        getActiveHabitsUseCase: GetActiveHabitsUseCase,
        getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase,
        performanceAnalysisService: PerformanceAnalysisService,
        timezoneService: TimezoneService
    ) {
        self.getActiveHabitsUseCase = getActiveHabitsUseCase
        self.getHabitLogsUseCase = getHabitLogsUseCase
        self.performanceAnalysisService = performanceAnalysisService
        self.timezoneService = timezoneService
    }

    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult {
        let habits = try await getActiveHabitsUseCase.execute()
        let logs = try await getHabitLogsUseCase.execute(for: userId, from: startDate, to: endDate)
        let timezone = (try? await timezoneService.getDisplayTimezone()) ?? .current

        return performanceAnalysisService.analyzeWeeklyPatterns(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate,
            timezone: timezone
        )
    }
}

public final class CalculateHabitPerformanceUseCase: CalculateHabitPerformanceUseCaseProtocol {
    private let getActiveHabitsUseCase: GetActiveHabitsUseCase
    private let getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    private let timezoneService: TimezoneService

    public init(
        getActiveHabitsUseCase: GetActiveHabitsUseCase,
        getHabitLogsUseCase: GetHabitLogsForAnalyticsUseCase,
        performanceAnalysisService: PerformanceAnalysisService,
        timezoneService: TimezoneService
    ) {
        self.getActiveHabitsUseCase = getActiveHabitsUseCase
        self.getHabitLogsUseCase = getHabitLogsUseCase
        self.performanceAnalysisService = performanceAnalysisService
        self.timezoneService = timezoneService
    }

    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitPerformanceResult] {
        let habits = try await getActiveHabitsUseCase.execute()
        let logs = try await getHabitLogsUseCase.execute(for: userId, from: startDate, to: endDate)
        let timezone = (try? await timezoneService.getDisplayTimezone()) ?? .current

        return performanceAnalysisService.calculateHabitPerformance(
            habits: habits,
            logs: logs,
            from: startDate,
            to: endDate,
            timezone: timezone
        )
    }
}

public final class GenerateProgressChartDataUseCase: GenerateProgressChartDataUseCaseProtocol {
    private let getHabitCompletionStatsUseCase: GetHabitCompletionStatsUseCase
    private let performanceAnalysisService: PerformanceAnalysisService
    private let timezoneService: TimezoneService

    public init(
        getHabitCompletionStatsUseCase: GetHabitCompletionStatsUseCase,
        performanceAnalysisService: PerformanceAnalysisService,
        timezoneService: TimezoneService
    ) {
        self.getHabitCompletionStatsUseCase = getHabitCompletionStatsUseCase
        self.performanceAnalysisService = performanceAnalysisService
        self.timezoneService = timezoneService
    }

    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [ProgressChartDataPoint] {
        let timezone = (try? await timezoneService.getDisplayTimezone()) ?? .current
        var completionStatsByDate: [Date: HabitCompletionStats] = [:]
        var currentDate = startDate

        while currentDate <= endDate {
            let dayEnd = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: timezone)

            let dayStats = try await getHabitCompletionStatsUseCase.execute(
                for: userId,
                from: currentDate,
                to: dayEnd
            )

            completionStatsByDate[currentDate] = dayStats

            currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: timezone)
        }

        return performanceAnalysisService.generateProgressChartData(
            completionStats: completionStatsByDate
        )
    }
}