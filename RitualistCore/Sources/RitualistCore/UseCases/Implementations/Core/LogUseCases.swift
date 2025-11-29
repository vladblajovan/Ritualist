import Foundation

// MARK: - Log Use Case Implementations

public final class GetLogs: GetLogsUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        // Get all logs from repository (no filtering in repository layer)
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Filter by date range using LOCAL day boundaries
        return allLogs.filter { log in
            if let since {
                let sinceStart = CalendarUtils.startOfDayLocal(for: since)
                let logStart = CalendarUtils.startOfDayLocal(for: log.date)
                if logStart < sinceStart { return false }
            }
            if let until {
                let untilStart = CalendarUtils.startOfDayLocal(for: until)
                let logStart = CalendarUtils.startOfDayLocal(for: log.date)
                if logStart > untilStart { return false }
            }
            return true
        }
    }
}

public final class GetBatchLogs: GetBatchLogsUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitIDs: [UUID], since: Date?, until: Date?) async throws -> [UUID: [HabitLog]] {
        // TRUE batch query - single database call instead of N calls
        let allLogs = try await repo.logs(for: habitIDs)
        
        // Group logs by habitID and apply date filtering
        var result: [UUID: [HabitLog]] = [:]
        
        // Initialize empty arrays for all requested habitIDs
        for habitID in habitIDs {
            result[habitID] = []
        }
        
        // Group and filter logs
        for log in allLogs {
            // Apply same date filtering logic as single GetLogs UseCase using LOCAL day boundaries
            var includeLog = true

            if let since {
                let sinceStart = CalendarUtils.startOfDayLocal(for: since)
                let logStart = CalendarUtils.startOfDayLocal(for: log.date)
                if logStart < sinceStart { includeLog = false }
            }
            if let until {
                let untilStart = CalendarUtils.startOfDayLocal(for: until)
                let logStart = CalendarUtils.startOfDayLocal(for: log.date)
                if logStart > untilStart { includeLog = false }
            }
            
            if includeLog {
                result[log.habitID, default: []].append(log)
            }
        }
        
        return result
    }
}

public final class GetSingleHabitLogs: GetSingleHabitLogsUseCase {
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(getBatchLogs: GetBatchLogsUseCase) {
        self.getBatchLogs = getBatchLogs
    }
    
    public func execute(for habitID: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        // Use batch loading with single habit ID for consistency and potential caching benefits
        let logsByHabitId = try await getBatchLogs.execute(
            for: [habitID],
            since: startDate,
            until: endDate
        )
        
        return logsByHabitId[habitID] ?? []
    }
}

public final class LogHabit: LogHabitUseCase {
    private let repo: LogRepository
    private let habitRepo: HabitRepository
    private let validateSchedule: ValidateHabitScheduleUseCase
    
    public init(repo: LogRepository, habitRepo: HabitRepository, validateSchedule: ValidateHabitScheduleUseCase) { 
        self.repo = repo
        self.habitRepo = habitRepo
        self.validateSchedule = validateSchedule
    }
    
    public func execute(_ log: HabitLog) async throws {
        // Fetch the habit to validate schedule
        let allHabits = try await habitRepo.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == log.habitID }) else {
            throw HabitScheduleValidationError.habitUnavailable(habitName: "Unknown Habit")
        }
        
        // Check if habit is active
        guard habit.isActive else {
            throw HabitScheduleValidationError.habitUnavailable(habitName: habit.name)
        }

        // Check if log date is before habit's start date
        let logDay = CalendarUtils.startOfDayLocal(for: log.date)
        let startDay = CalendarUtils.startOfDayLocal(for: habit.startDate)
        guard logDay >= startDay else {
            throw HabitScheduleValidationError.dateBeforeStartDate(habitName: habit.name)
        }

        // Validate schedule before logging
        let validationResult = try await validateSchedule.execute(habit: habit, date: log.date)
        
        // If validation fails, throw descriptive error
        if !validationResult.isValid {
            throw HabitScheduleValidationError.fromValidationResult(validationResult, habitName: habit.name)
        }
        
        // If validation passes, proceed with logging
        try await repo.upsert(log)
    }
}

public final class DeleteLog: DeleteLogUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(id: UUID) async throws {
        try await repo.deleteLog(id: id)
    }
}

public final class GetLogForDate: GetLogForDateUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(habitID: UUID, date: Date) async throws -> HabitLog? {
        // Get all logs for the habit
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Find log for specific date using LOCAL day comparison
        return allLogs.first { log in
            CalendarUtils.areSameDayLocal(log.date, date)
        }
    }
}

public final class GetEarliestLogDate: GetEarliestLogDateUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitID: UUID) async throws -> Date? {
        let allLogs = try await repo.logs(for: habitID)
        return allLogs.map { CalendarUtils.startOfDayLocal(for: $0.date) }.min()
    }
}