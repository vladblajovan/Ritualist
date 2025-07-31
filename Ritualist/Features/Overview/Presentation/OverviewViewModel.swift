import Foundation
import Observation

@MainActor @Observable
public final class OverviewViewModel {
    private let getActiveHabits: GetActiveHabitsUseCase
    private let getLogs: GetLogsUseCase
    private let streakEngine: StreakEngine
    private let profileRepository: ProfileRepository
    private let userActionTracker: UserActionTracker
    
    // Helper managers
    private let calendarManager: CalendarManager
    private let scheduleManager: HabitScheduleManager
    private let loggingManager: HabitLoggingManager
    
    public private(set) var habits: [Habit] = []
    public private(set) var selectedHabit: Habit?
    public private(set) var currentMonth = Date()
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var isLoggingHabit = false
    
    // Calendar state
    public private(set) var monthDays: [Date] = []
    public private(set) var fullCalendarDays: [CalendarDay] = []
    public private(set) var loggedDates: Set<Date> = []
    public private(set) var habitLogValues: [Date: Double] = [:]
    
    // Streak state
    public private(set) var currentStreak: Int = 0
    public private(set) var bestStreak: Int = 0
    public private(set) var isLoadingStreaks = false
    
    // Animation state
    public private(set) var shouldAnimateBestStreak = false
    private var previousBestStreak: Int = 0
    
    // User preferences
    private var userProfile: UserProfile?
    
    /// User's preferred first day of week for calendar display
    public var userFirstDayOfWeek: Int? {
        userProfile?.firstDayOfWeek
    }
    
    public init(getActiveHabits: GetActiveHabitsUseCase,
                getLogForDate: GetLogForDateUseCase,
                logHabit: LogHabitUseCase,
                deleteLog: DeleteLogUseCase,
                getLogs: GetLogsUseCase,
                streakEngine: StreakEngine,
                profileRepository: ProfileRepository,
                userActionTracker: UserActionTracker) { 
        self.getActiveHabits = getActiveHabits
        self.getLogs = getLogs
        self.streakEngine = streakEngine
        self.profileRepository = profileRepository
        self.userActionTracker = userActionTracker
        
        // Initialize helper managers
        self.calendarManager = CalendarManager()
        self.scheduleManager = HabitScheduleManager()
        self.loggingManager = HabitLoggingManager(
            getLogForDate: getLogForDate,
            logHabit: logHabit,
            deleteLog: deleteLog
        )
        
        updateCalendarDays()
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        do {
            // Load user profile for calendar preferences
            userProfile = try await profileRepository.loadProfile()
            
            // Update managers with user profile
            calendarManager.updateUserProfile(userProfile)
            scheduleManager.updateUserProfile(userProfile)
            
            habits = try await getActiveHabits.execute()
            
            // Auto-select first habit if none selected
            if selectedHabit == nil, let firstHabit = habits.first {
                selectedHabit = firstHabit
                await loadLogsForSelectedHabit()
                await calculateStreaks(isInitialLoad: true)
            }
        } catch {
            self.error = error
            habits = []
        }
        
        isLoading = false
    }
    
    public func selectHabit(_ habit: Habit) async {
        selectedHabit = habit
        // Reset animation state when switching habits
        shouldAnimateBestStreak = false
        // Reset previous best streak when switching habits
        previousBestStreak = 0
        bestStreak = 0
        
        // Track habit selection
        userActionTracker.track(.screenViewed(screen: "habit_overview"), context: [
            "habit_id": habit.id.uuidString,
            "habit_name": habit.name
        ])
        
        await loadLogsForSelectedHabit()
        await calculateStreaks(isInitialLoad: true)
    }
    
    public func navigateToMonth(_ direction: Int) async {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) {
            currentMonth = newMonth
            updateCalendarDays()
            await loadLogsForSelectedHabit()
        }
    }
    
    public func navigateToDate(_ date: Date) async {
        let calendar = Calendar.current
        let targetMonth = calendar.dateInterval(of: .month, for: date)?.start ?? date
        if !calendar.isDate(targetMonth, equalTo: currentMonth, toGranularity: .month) {
            currentMonth = targetMonth
            updateCalendarDays()
            await loadLogsForSelectedHabit()
        }
    }
    
    public func navigateToToday() async {
        let today = Date()
        let calendar = Calendar.current
        let currentMonthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let todayMonthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        if !calendar.isDate(currentMonthStart, equalTo: todayMonthStart, toGranularity: .month) {
            currentMonth = today
            updateCalendarDays()
            await loadLogsForSelectedHabit()
        }
    }
    
    public var isViewingCurrentMonth: Bool {
        calendarManager.isViewingCurrentMonth(currentMonth)
    }
    
    public func incrementHabitForDate(_ date: Date) async {
        guard let habit = selectedHabit else { return }
        
        // Check if this date is schedulable for the habit
        guard isDateSchedulable(date) else { return }
        
        isLoggingHabit = true
        error = nil
        
        do {
            let result = try await loggingManager.incrementHabitForDate(
                date,
                habit: habit,
                currentLoggedDates: loggedDates,
                currentHabitLogValues: habitLogValues
            )
            
            loggedDates = result.loggedDates
            habitLogValues = result.habitLogValues
            
            // Track habit logging
            let wasLogged = result.loggedDates.contains(Calendar.current.startOfDay(for: date))
            userActionTracker.track(.habitLogged(
                habitId: habit.id.uuidString,
                habitName: habit.name,
                date: date,
                logType: wasLogged ? "completed" : "uncompleted",
                value: result.habitLogValues[Calendar.current.startOfDay(for: date)]
            ))
            
            // Recalculate streaks after logging/unlogging
            await calculateStreaks()
        } catch {
            self.error = error
        }
        
        isLoggingHabit = false
    }
    
    public func retry() async {
        await load()
    }
    
    public func getHabitValueForDate(_ date: Date) -> Double {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return habitLogValues[normalizedDate] ?? 0.0
    }
    
    /// Check if a date is schedulable for the selected habit
    public func isDateSchedulable(_ date: Date) -> Bool {
        guard let habit = selectedHabit else { return false }
        return scheduleManager.isDateSchedulable(date, for: habit)
    }
    
    /// For weekly habits, check if the weekly target is met for the week containing this date
    public func isWeeklyTargetMet(for date: Date) -> Bool {
        guard let habit = selectedHabit else { return false }
        return scheduleManager.isWeeklyTargetMet(for: date, habit: habit, habitLogValues: habitLogValues)
    }
    
    private func updateCalendarDays() {
        monthDays = calendarManager.generateMonthDays(for: currentMonth)
        fullCalendarDays = calendarManager.generateFullCalendarGrid(for: currentMonth)
    }
    
    private func loadLogsForSelectedHabit() async {
        guard let habit = selectedHabit else { return }
        
        do {
            // For weekly habits and specific days, we need to load data for the full calendar grid to properly calculate weekly targets
            let daysToCheck = if case .timesPerWeek = habit.schedule {
                fullCalendarDays.map { $0.date }
            } else if case .daysOfWeek = habit.schedule {
                fullCalendarDays.map { $0.date }
            } else {
                monthDays
            }
            
            let result = try await loggingManager.loadLogsForHabit(habit, dates: daysToCheck)
            loggedDates = result.loggedDates
            habitLogValues = result.habitLogValues
        } catch {
            self.error = error
            loggedDates = []
            habitLogValues = [:]
        }
    }
    
    private func calculateStreaks(isInitialLoad: Bool = false) async {
        guard let habit = selectedHabit else {
            currentStreak = 0
            bestStreak = 0
            return
        }
        
        isLoadingStreaks = true
        
        do {
            // Get all logs for the habit (no date filtering for streak calculation)
            let allLogs = try await getLogs.execute(for: habit.id, since: nil, until: nil)
            
            // Calculate streaks using the streak engine
            currentStreak = streakEngine.currentStreak(for: habit, logs: allLogs, asOf: Date())
            let newBestStreak = streakEngine.bestStreak(for: habit, logs: allLogs)
            
            // Check if we should trigger the best streak animation
            // Animate when best streak increases, but not on initial load
            if !isInitialLoad && newBestStreak > previousBestStreak && newBestStreak > 0 {
                shouldAnimateBestStreak = true
                bestStreak = newBestStreak
                // Don't update previousBestStreak yet - wait for animation to complete
            } else {
                bestStreak = newBestStreak
                previousBestStreak = newBestStreak
            }
        } catch {
            self.error = error
            currentStreak = 0
            bestStreak = 0
        }
        
        isLoadingStreaks = false
    }
    
    /// Reset the best streak animation trigger
    public func resetBestStreakAnimation() {
        shouldAnimateBestStreak = false
        // Update previousBestStreak to current value after animation completes
        previousBestStreak = bestStreak
    }
}
