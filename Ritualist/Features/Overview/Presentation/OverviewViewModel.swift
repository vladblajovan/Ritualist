import Foundation
import Observation

@MainActor @Observable
public final class OverviewViewModel {
    private let getActiveHabits: GetActiveHabitsUseCase
    private let getLogs: GetLogsUseCase
    private let getLogForDate: GetLogForDateUseCase
    private let streakEngine: StreakEngine
    private let loadProfile: LoadProfileUseCase
    private let trackUserAction: TrackUserActionUseCase
    private let trackHabitLogged: TrackHabitLoggedUseCase
    private let checkFeatureAccess: CheckFeatureAccessUseCase
    private let checkHabitCreationLimit: CheckHabitCreationLimitUseCase
    private let getPaywallMessage: GetPaywallMessageUseCase
    
    // Domain use cases for business logic
    private let generateCalendarDays: GenerateCalendarDaysUseCase
    private let generateCalendarGrid: GenerateCalendarGridUseCase
    private let toggleHabitLog: ToggleHabitLogUseCase
    private let getCurrentSlogan: GetCurrentSloganUseCase
    private let validateHabitSchedule: ValidateHabitScheduleUseCase
    private let checkWeeklyTarget: CheckWeeklyTargetUseCase
    
    public private(set) var habits: [Habit] = []
    public private(set) var selectedHabit: Habit?
    public private(set) var currentMonth = Calendar.current.startOfDay(for: Date())
    public private(set) var isLoading = false
    public private(set) var error: Error?
    public private(set) var loggingDate: Date?
    public private(set) var currentSlogan: String = ""
    
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
    
    // MARK: - Paywall Protection
    
    /// Check if user has access to advanced analytics/stats  
    public var hasAdvancedAnalytics: Bool {
        checkFeatureAccess.execute()
    }
    
    /// Get message to display when stats are blocked by paywall
    public func getStatsBlockedMessage() -> String {
        getPaywallMessage.execute()
    }
    
    /// Check if user can create more habits based on current count
    public var canCreateMoreHabits: Bool {
        checkHabitCreationLimit.execute(currentCount: habits.count)
    }
    
    public init(getActiveHabits: GetActiveHabitsUseCase,
                getLogs: GetLogsUseCase,
                getLogForDate: GetLogForDateUseCase,
                streakEngine: StreakEngine,
                loadProfile: LoadProfileUseCase,
                generateCalendarDays: GenerateCalendarDaysUseCase,
                generateCalendarGrid: GenerateCalendarGridUseCase,
                toggleHabitLog: ToggleHabitLogUseCase,
                getCurrentSlogan: GetCurrentSloganUseCase,
                trackUserAction: TrackUserActionUseCase,
                trackHabitLogged: TrackHabitLoggedUseCase,
                checkFeatureAccess: CheckFeatureAccessUseCase,
                checkHabitCreationLimit: CheckHabitCreationLimitUseCase,
                getPaywallMessage: GetPaywallMessageUseCase,
                validateHabitSchedule: ValidateHabitScheduleUseCase,
                checkWeeklyTarget: CheckWeeklyTargetUseCase) { 
        self.getActiveHabits = getActiveHabits
        self.getLogs = getLogs
        self.getLogForDate = getLogForDate
        self.streakEngine = streakEngine
        self.loadProfile = loadProfile
        self.generateCalendarDays = generateCalendarDays
        self.generateCalendarGrid = generateCalendarGrid
        self.toggleHabitLog = toggleHabitLog
        self.getCurrentSlogan = getCurrentSlogan
        self.trackUserAction = trackUserAction
        self.trackHabitLogged = trackHabitLogged
        self.checkFeatureAccess = checkFeatureAccess
        self.checkHabitCreationLimit = checkHabitCreationLimit
        self.getPaywallMessage = getPaywallMessage
        self.validateHabitSchedule = validateHabitSchedule
        self.checkWeeklyTarget = checkWeeklyTarget
        
        // Get initial slogan
        self.currentSlogan = getCurrentSlogan.execute()
        
        updateCalendarDays()
        setupRefreshObservation()
    }
    
    private func setupRefreshObservation() {
        // No manual refresh triggers needed - @Observable reactivity handles updates
    }
    
    public func load() async {
        isLoading = true
        error = nil
        
        // Get a fresh slogan when loading
        currentSlogan = getCurrentSlogan.execute()
        
        do {
            // Load user profile for calendar preferences
            userProfile = try await loadProfile.execute()
            
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
        trackUserAction.execute(action: .screenViewed(screen: "habit_overview"), context: [
            "habit_id": habit.id.uuidString,
            "habit_name": habit.name
        ])
        
        await loadLogsForSelectedHabit()
        await calculateStreaks(isInitialLoad: false)
    }
    
    public func navigateToMonth(_ direction: Int) async {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: direction, to: currentMonth) {
            currentMonth = calendar.startOfDay(for: newMonth)
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
            currentMonth = calendar.startOfDay(for: today)
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
            trackHabitLogged.execute(
                habitId: habit.id.uuidString,
                habitName: habit.name,
                date: date,
                logType: wasLogged ? "completed" : "uncompleted",
                value: result.habitLogValues[Calendar.current.startOfDay(for: date)]
            )
            
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
        return validateHabitSchedule.execute(date: date, habit: habit)
    }
    
    /// For weekly habits, check if the weekly target is met for the week containing this date
    public func isWeeklyTargetMet(for date: Date) -> Bool {
        guard let habit = selectedHabit else { return false }
        return checkWeeklyTarget.execute(date: date, habit: habit, habitLogValues: habitLogValues, userProfile: userProfile)
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
