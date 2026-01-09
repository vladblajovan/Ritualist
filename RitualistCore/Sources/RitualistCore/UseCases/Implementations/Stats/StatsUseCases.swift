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

// MARK: - Consistency Heatmap Use Case

public final class GetConsistencyHeatmapData: GetConsistencyHeatmapDataUseCase {
    private let habitRepository: HabitRepository
    private let getLogsUseCase: GetLogsUseCase

    public init(
        habitRepository: HabitRepository,
        getLogsUseCase: GetLogsUseCase
    ) {
        self.habitRepository = habitRepository
        self.getLogsUseCase = getLogsUseCase
    }

    public func execute(habitId: UUID, period: TimePeriod, timezone: TimeZone) async throws -> ConsistencyHeatmapData {
        // Fetch the habit
        guard let habit = try await habitRepository.fetchHabit(by: habitId) else {
            throw HeatmapError.habitNotFound
        }

        // Get date range from period
        let dateRange = period.dateRange

        // Fetch logs for this habit in the date range
        let logs = try await getLogsUseCase.execute(
            for: habitId,
            since: dateRange.start,
            until: dateRange.end,
            timezone: timezone
        )

        // Build daily completions dictionary
        var dailyCompletions: [Date: Double] = [:]

        // Group logs by date (start of day in the given timezone)
        var logsByDate: [Date: HabitLog] = [:]
        for log in logs {
            let dayStart = CalendarUtils.startOfDayLocal(for: log.date, timezone: timezone)
            // Keep the latest log for each day (in case of multiple logs)
            if let existing = logsByDate[dayStart] {
                if log.date > existing.date {
                    logsByDate[dayStart] = log
                }
            } else {
                logsByDate[dayStart] = log
            }
        }

        // Calculate completion rate for each day in the period
        var currentDate = CalendarUtils.startOfDayLocal(for: dateRange.start, timezone: timezone)
        let endDate = CalendarUtils.startOfDayLocal(for: dateRange.end, timezone: timezone)

        while currentDate <= endDate {
            if let log = logsByDate[currentDate] {
                // Calculate completion rate based on habit type
                let completionRate: Double
                let logValue = log.value ?? 0.0
                switch habit.kind {
                case .binary:
                    // Binary: any positive value means complete
                    completionRate = logValue > 0 ? 1.0 : 0.0
                case .numeric:
                    // Numeric: value / target, capped at 1.0
                    let target = habit.dailyTarget ?? 1.0
                    completionRate = min(logValue / target, 1.0)
                }
                dailyCompletions[currentDate] = completionRate
            } else {
                // No log for this day - 0% completion
                dailyCompletions[currentDate] = 0.0
            }
            currentDate = CalendarUtils.addDaysLocal(1, to: currentDate, timezone: timezone)
        }

        return ConsistencyHeatmapData(
            habitId: habit.id,
            habitName: habit.name,
            habitEmoji: habit.emoji ?? "📊",
            dailyCompletions: dailyCompletions
        )
    }
}

public enum HeatmapError: Error, LocalizedError {
    case habitNotFound

    public var errorDescription: String? {
        switch self {
        case .habitNotFound:
            return "Habit not found"
        }
    }
}