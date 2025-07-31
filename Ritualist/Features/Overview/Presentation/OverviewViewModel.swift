import Foundation
import Observation
import Combine

@MainActor @Observable
public final class OverviewViewModel {
    private let getActiveHabits: GetActiveHabitsUseCase
    private let getLogs: GetLogsUseCase
    private let getLogForDate: GetLogForDateUseCase
    private let streakEngine: StreakEngine
    private let loadProfile: LoadProfileUseCase
    private let userActionTracker: UserActionTracker
    private let refreshTrigger: RefreshTrigger
    
    // Domain use cases for business logic
    private let generateCalendarDays: GenerateCalendarDaysUseCase
    private let generateCalendarGrid: GenerateCalendarGridUseCase
    private let toggleHabitLog: ToggleHabitLogUseCase
    
    // Reactive coordination
    private var cancellables = Set<AnyCancellable>()
    
    // Simple helper managers (no business logic)
    private let scheduleManager: HabitScheduleManager
    
    public private(set) var habits: [Habit] = []
    public private(set) var selectedHabit: Habit?
    public private(set) var currentMonth = Date()
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var loggingDate: Date?
    
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
                getLogs: GetLogsUseCase,
                getLogForDate: GetLogForDateUseCase,
                streakEngine: StreakEngine,
                loadProfile: LoadProfileUseCase,
                generateCalendarDays: GenerateCalendarDaysUseCase,
                generateCalendarGrid: GenerateCalendarGridUseCase,
                toggleHabitLog: ToggleHabitLogUseCase,
                userActionTracker: UserActionTracker,
                refreshTrigger: RefreshTrigger) { 
        self.getActiveHabits = getActiveHabits
        self.getLogs = getLogs
        self.getLogForDate = getLogForDate
        self.streakEngine = streakEngine
        self.loadProfile = loadProfile
        self.generateCalendarDays = generateCalendarDays
        self.generateCalendarGrid = generateCalendarGrid
        self.toggleHabitLog = toggleHabitLog
        self.userActionTracker = userActionTracker
        self.refreshTrigger = refreshTrigger
        
        // Initialize simple helper managers
        self.scheduleManager = HabitScheduleManager()
        
        updateCalendarDays()
        setupRefreshObservation()
    }
    
    private func setupRefreshObservation() {
        // React to refresh triggers
        refreshTrigger.$overviewNeedsRefresh
            .sink { [weak self] needsRefresh in
                if needsRefresh {
                    Task { [weak self] in
                        await self?.load()
                        await MainActor.run {
                            self?.refreshTrigger.resetOverviewRefresh()
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        do {
            // Load user profile for calendar preferences
            userProfile = try await loadProfile.execute()
            
            // Update managers with user profile
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
        
        // Track habit selection
        userActionTracker.track(.screenViewed(screen: "habit_overview"), context: [
            "habit_id": habit.id.uuidString,
            "habit_name": habit.name
        ])
        
        await loadLogsForSelectedHabit()
        await calculateStreaks(isInitialLoad: false)
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
        let calendar = Calendar.current
        let today = Date()
        let currentMonthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let todayMonthStart = calendar.dateInterval(of: .month, for: today)?.start ?? today
        
        return calendar.isDate(currentMonthStart, equalTo: todayMonthStart, toGranularity: .month)
    }
    
    public func incrementHabitForDate(_ date: Date) async {
        guard let habit = selectedHabit else { return }
        
        // Check if this date is schedulable for the habit
        guard isDateSchedulable(date) else { return }
        
        loggingDate = Calendar.current.startOfDay(for: date)
        error = nil
        
        do {
            // Store previous best streak before logging to check for improvements
            let previousBest = bestStreak
            
            let result = try await toggleHabitLog.execute(
                date: date,
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
            
            // Check if we should trigger celebration animation after logging
            if bestStreak > previousBest && bestStreak > 0 {
                shouldAnimateBestStreak = true
            }
        } catch {
            self.error = error
        }
        
        loggingDate = nil
    }
    
    public func retry() async {
        await load()
    }
    
    public func getHabitValueForDate(_ date: Date) -> Double {
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return habitLogValues[normalizedDate] ?? 0.0
    }
    
    /// Check if a specific date is currently being logged
    public func isLoggingDate(_ date: Date) -> Bool {
        guard let loggingDate = loggingDate else { return false }
        let normalizedDate = Calendar.current.startOfDay(for: date)
        return Calendar.current.isDate(normalizedDate, inSameDayAs: loggingDate)
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
        monthDays = generateCalendarDays.execute(for: currentMonth, userProfile: userProfile)
        fullCalendarDays = generateCalendarGrid.execute(for: currentMonth, userProfile: userProfile)
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
            
            let result = try await loadLogsForDates(habit: habit, dates: daysToCheck)
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
        
        // Only show loading state on initial load to prevent calendar flashing
        if isInitialLoad {
            isLoadingStreaks = true
        }
        
        do {
            // Get all logs for the habit (no date filtering for streak calculation)
            let allLogs = try await getLogs.execute(for: habit.id, since: nil, until: nil)
            
            // Calculate streaks using the streak engine
            currentStreak = streakEngine.currentStreak(for: habit, logs: allLogs, asOf: Date())
            let newBestStreak = streakEngine.bestStreak(for: habit, logs: allLogs)
            
            // Always update streak values (no animation logic here)
            bestStreak = newBestStreak
            previousBestStreak = newBestStreak
        } catch {
            self.error = error
            currentStreak = 0
            bestStreak = 0
        }
        
        // Only reset loading state if we set it
        if isInitialLoad {
            isLoadingStreaks = false
        }
    }
    
    /// Reset the best streak animation trigger
    public func resetBestStreakAnimation() {
        shouldAnimateBestStreak = false
        // Update previousBestStreak to current value after animation completes
        previousBestStreak = bestStreak
    }
    
    // MARK: - Private Helper Methods
    
    /// Load logs for a habit for the given dates (data transformation utility)
    private func loadLogsForDates(
        habit: Habit,
        dates: [Date]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double]) {
        let calendar = Calendar.current
        var loggedDays: Set<Date> = []
        var logValues: [Date: Double] = [:]
        
        for day in dates {
            let logForDate = try await getLogForDate.execute(habitID: habit.id, date: day)
            let normalizedDay = calendar.startOfDay(for: day)
            
            if let log = logForDate, let value = log.value {
                logValues[normalizedDay] = value
                
                // For count habits, only mark as "logged" if target is reached
                if habit.kind == .binary {
                    loggedDays.insert(normalizedDay)
                } else if let target = habit.dailyTarget, value >= target {
                    loggedDays.insert(normalizedDay)
                }
            } else if logForDate != nil {
                // Handle legacy logs without value (treat as binary)
                logValues[normalizedDay] = 1.0
                loggedDays.insert(normalizedDay)
            }
        }
        
        return (loggedDates: loggedDays, habitLogValues: logValues)
    }
}
