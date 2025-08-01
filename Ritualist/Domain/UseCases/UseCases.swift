import Foundation

// MARK: - Habit Use Cases
public protocol CreateHabitUseCase { func execute(_ habit: Habit) async throws }
public protocol GetActiveHabitsUseCase { func execute() async throws -> [Habit] }
public protocol GetAllHabitsUseCase { func execute() async throws -> [Habit] }
public protocol UpdateHabitUseCase { func execute(_ habit: Habit) async throws }
public protocol DeleteHabitUseCase { func execute(id: UUID) async throws }
public protocol ToggleHabitActiveStatusUseCase { func execute(id: UUID) async throws -> Habit }

// MARK: - Log Use Cases
public protocol GetLogsUseCase { func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] }
public protocol LogHabitUseCase { func execute(_ log: HabitLog) async throws }
public protocol DeleteLogUseCase { func execute(id: UUID) async throws }
public protocol GetLogForDateUseCase { func execute(habitID: UUID, date: Date) async throws -> HabitLog? }

// MARK: - Profile Use Cases  
public protocol LoadProfileUseCase { func execute() async throws -> UserProfile }
public protocol SaveProfileUseCase { func execute(_ profile: UserProfile) async throws }

// MARK: - Calendar Use Cases
public protocol GenerateCalendarDaysUseCase { 
    func execute(for month: Date, userProfile: UserProfile?) -> [Date] 
}
public protocol GenerateCalendarGridUseCase { 
    func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] 
}

// MARK: - Habit Logging Use Cases
public protocol ToggleHabitLogUseCase {
    func execute(
        date: Date,
        habit: Habit,
        currentLoggedDates: Set<Date>,
        currentHabitLogValues: [Date: Double]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double])
}

// MARK: - Tip Use Cases
public protocol GetAllTipsUseCase { func execute() async throws -> [Tip] }
public protocol GetFeaturedTipsUseCase { func execute() async throws -> [Tip] }
public protocol GetTipByIdUseCase { func execute(id: UUID) async throws -> Tip? }
public protocol GetTipsByCategoryUseCase { func execute(category: TipCategory) async throws -> [Tip] }

// MARK: - Onboarding Use Cases
public protocol GetOnboardingStateUseCase { func execute() async throws -> OnboardingState }
public protocol SaveOnboardingStateUseCase { func execute(_ state: OnboardingState) async throws }
public protocol CompleteOnboardingUseCase { func execute(userName: String?, hasNotifications: Bool) async throws }

// MARK: - Slogan Use Cases
public protocol GetCurrentSloganUseCase { func execute() -> String }

// MARK: - Habit Use Case Implementations
public final class CreateHabit: CreateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws { try await repo.create(habit) }
}

public final class GetActiveHabits: GetActiveHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] {
        // Business logic: Filter only active habits
        let allHabits = try await repo.fetchAllHabits()
        return allHabits.filter { $0.isActive }
    }
}

public final class GetAllHabits: GetAllHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] { try await repo.fetchAllHabits() }
}

public final class UpdateHabit: UpdateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws { try await repo.update(habit) }
}

public final class DeleteHabit: DeleteHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws { try await repo.delete(id: id) }
}

public final class ToggleHabitActiveStatus: ToggleHabitActiveStatusUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Habit {
        let allHabits = try await repo.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == id }) else {
            throw NSError(domain: "ToggleHabitActiveStatus", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
        }
        
        let updatedHabit = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: habit.endDate,
            isActive: !habit.isActive
        )
        
        try await repo.update(updatedHabit)
        return updatedHabit
    }
}

// MARK: - Profile Use Case Implementations
public final class LoadProfile: LoadProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute() async throws -> UserProfile { try await repo.loadProfile() }
}

public final class SaveProfile: SaveProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute(_ profile: UserProfile) async throws { try await repo.saveProfile(profile) }
}

// MARK: - Log Use Case Implementations
public final class GetLogs: GetLogsUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        // Get all logs from repository (no filtering in repository layer)
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Filter by date range
        return allLogs.filter { log in
            if let since, log.date < since { return false }
            if let until, log.date > until { return false }
            return true
        }
    }
}

public final class LogHabit: LogHabitUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(_ log: HabitLog) async throws {
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

        // Business logic: Find log for specific date (comparing day only)
        let calendar = Calendar.current
        return allLogs.first { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }
    }
}

// MARK: - Tip Use Case Implementations
public final class GetAllTips: GetAllTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] { try await repo.getAllTips() }
}

public final class GetFeaturedTips: GetFeaturedTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] {
        // Business logic: Get featured tips and sort by order
        let featuredTips = try await repo.getFeaturedTips()
        return featuredTips.sorted { $0.order < $1.order }
    }
}

public final class GetTipById: GetTipByIdUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Tip? { try await repo.getTip(by: id) }
}

public final class GetTipsByCategory: GetTipsByCategoryUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(category: TipCategory) async throws -> [Tip] { try await repo.getTips(by: category) }
}

// MARK: - Onboarding Use Case Implementations
public final class GetOnboardingState: GetOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute() async throws -> OnboardingState { try await repo.getOnboardingState() }
}

public final class SaveOnboardingState: SaveOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute(_ state: OnboardingState) async throws { try await repo.saveOnboardingState(state) }
}

public final class CompleteOnboarding: CompleteOnboardingUseCase {
    private let onboardingRepo: OnboardingRepository
    private let profileRepo: ProfileRepository
    
    public init(repo: OnboardingRepository, profileRepo: ProfileRepository) { 
        self.onboardingRepo = repo 
        self.profileRepo = profileRepo
    }
    
    public func execute(userName: String?, hasNotifications: Bool) async throws {
        // Mark onboarding as completed
        try await onboardingRepo.markOnboardingCompleted(userName: userName, hasNotifications: hasNotifications)
        
        // Update user profile with the name if provided
        if let userName = userName, !userName.isEmpty {
            var profile = try await profileRepo.loadProfile()
            profile.name = userName
            try await profileRepo.saveProfile(profile)
        }
    }
}

// MARK: - User Management Use Cases

public protocol UpdateUserUseCase {
    func execute(_ user: User) async throws -> User
}

public final class UpdateUser: UpdateUserUseCase {
    private let userSession: any UserSessionProtocol
    
    public init(userSession: any UserSessionProtocol) {
        self.userSession = userSession
    }
    
    public func execute(_ user: User) async throws -> User {
        try await userSession.updateUser(user)
        return user
    }
}

// MARK: - Calendar Use Case Implementations

public final class GenerateCalendarDays: GenerateCalendarDaysUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [Date] {
        let calendar = DateUtils.userCalendar(firstDayOfWeek: userProfile?.firstDayOfWeek)
        
        // Ensure we start with a normalized date (start of day)
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        // Generate current month days, ensuring we work with start of day
        var days: [Date] = []
        var date = calendar.startOfDay(for: monthInterval.start)
        let endOfMonth = monthInterval.end
        
        while date < endOfMonth {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
}

public final class GenerateCalendarGrid: GenerateCalendarGridUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] {
        let calendar = DateUtils.userCalendar(firstDayOfWeek: userProfile?.firstDayOfWeek)
        
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        // Find the first day to display (might be from previous month)
        let weekdayOfFirst = calendar.component(.weekday, from: startOfMonth)
        let firstDisplayDay = calendar.date(byAdding: .day, value: -(weekdayOfFirst - 1), to: startOfMonth) ?? startOfMonth
        
        // Generate 42 days (6 weeks) for a complete calendar grid
        var calendarDays: [CalendarDay] = []
        var currentDate = firstDisplayDay
        
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: normalizedCurrentMonth, toGranularity: .month)
            calendarDays.append(CalendarDay(date: currentDate, isCurrentMonth: isCurrentMonth))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return calendarDays
    }
}

// MARK: - Habit Logging Use Case Implementation

public final class ToggleHabitLog: ToggleHabitLogUseCase {
    private let getLogForDate: GetLogForDateUseCase
    private let logHabit: LogHabitUseCase
    private let deleteLog: DeleteLogUseCase
    
    public init(getLogForDate: GetLogForDateUseCase, logHabit: LogHabitUseCase, deleteLog: DeleteLogUseCase) {
        self.getLogForDate = getLogForDate
        self.logHabit = logHabit
        self.deleteLog = deleteLog
    }
    
    public func execute(
        date: Date,
        habit: Habit,
        currentLoggedDates: Set<Date>,
        currentHabitLogValues: [Date: Double]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double]) {
        let existingLog = try await getLogForDate.execute(habitID: habit.id, date: date)
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        var updatedLoggedDates = currentLoggedDates
        var updatedHabitLogValues = currentHabitLogValues
        
        if habit.kind == .binary {
            // Business Logic: Binary habit toggle
            if existingLog != nil {
                // Remove log
                try await deleteLog.execute(id: existingLog!.id)
                updatedLoggedDates.remove(normalizedDate)
                updatedHabitLogValues.removeValue(forKey: normalizedDate)
            } else {
                // Add log
                let newLog = HabitLog(habitID: habit.id, date: date, value: 1.0)
                try await logHabit.execute(newLog)
                updatedLoggedDates.insert(normalizedDate)
                updatedHabitLogValues[normalizedDate] = 1.0
            }
        } else {
            // Count habit: increment value or reset if target is reached
            let currentValue = existingLog?.value ?? 0.0
            
            // If target is already reached, reset to 0
            let newValue: Double
            if let target = habit.dailyTarget, currentValue >= target {
                newValue = 0.0
            } else {
                newValue = currentValue + 1.0
            }
            
            if newValue == 0.0 {
                // Reset to 0: delete the log entry
                if let existingLog = existingLog {
                    try await deleteLog.execute(id: existingLog.id)
                }
                updatedHabitLogValues.removeValue(forKey: normalizedDate)
                updatedLoggedDates.remove(normalizedDate)
            } else {
                // Increment: update or create log
                if let existingLog = existingLog {
                    // Update existing log
                    let updatedLog = HabitLog(id: existingLog.id, habitID: habit.id, date: date, value: newValue)
                    try await logHabit.execute(updatedLog)
                } else {
                    // Create new log
                    let newLog = HabitLog(habitID: habit.id, date: date, value: newValue)
                    try await logHabit.execute(newLog)
                }
                
                updatedHabitLogValues[normalizedDate] = newValue
                
                // Check if target is reached for logged dates tracking
                if let target = habit.dailyTarget, newValue >= target {
                    updatedLoggedDates.insert(normalizedDate)
                } else {
                    updatedLoggedDates.remove(normalizedDate)
                }
            }
        }
        
        return (loggedDates: updatedLoggedDates, habitLogValues: updatedHabitLogValues)
    }
}

// MARK: - Slogan Use Case Implementations

public final class GetCurrentSlogan: GetCurrentSloganUseCase {
    private let slogansService: SlogansServiceProtocol
    
    public init(slogansService: SlogansServiceProtocol) {
        self.slogansService = slogansService
    }
    
    public func execute() -> String {
        return slogansService.getCurrentSlogan()
    }
}
