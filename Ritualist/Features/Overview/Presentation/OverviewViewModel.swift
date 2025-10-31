import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// swiftlint:disable file_length type_body_length

// MARK: - ViewModel

@MainActor
@Observable
public final class OverviewViewModel {
    // MARK: - Observable Properties
    public var todaysSummary: TodaysSummary?
    public var activeStreaks: [StreakInfo] = []
    public var smartInsights: [SmartInsight] = []
    public var personalityInsights: [OverviewPersonalityInsight] = []
    public var shouldShowPersonalityInsights = true // Always show the card
    public var isPersonalityDataSufficient = false // Track if data is sufficient for new analysis
    public var personalityThresholdRequirements: [ThresholdRequirement] = [] // Current requirements status
    public var dominantPersonalityTrait: String? = nil
    public var selectedDate: Date = Date()
    public var viewingDate: Date = CalendarUtils.startOfDayLocal(for: Date()) // The date being viewed in Today's Progress card
    public var showInspirationCard: Bool = false
    
    // Inspiration card tracking
    @ObservationIgnored private var lastShownInspirationTrigger: InspirationTrigger?
    @ObservationIgnored private var sessionStartTime: Date = Date()
    @ObservationIgnored private var dismissedTriggersToday: Set<InspirationTrigger> = []
    @ObservationIgnored private var cachedInspirationMessage: String?
    
    public var isLoading: Bool = false
    public var error: Error?
    
    // Shared sheet state
    public var selectedHabitForSheet: Habit?
    public var showingNumericSheet = false
    
    // Notification-triggered sheet state
    public var pendingNumericHabitFromNotification: Habit?
    
    // Track if pending habit has been processed to prevent double-processing
    @ObservationIgnored private var hasPendingHabitBeenProcessed: Bool = false
    
    // Track view visibility to handle immediate processing when habit is set
    public var isViewVisible: Bool = false
    
    // Single source of truth for all overview data
    public var overviewData: OverviewData?
    
    // MARK: - Computed Properties
    public var incompleteHabits: [Habit] {
        todaysSummary?.incompleteHabits ?? []
    }
    
    public var completedHabits: [Habit] {
        todaysSummary?.completedHabits ?? []
    }
    
    public var shouldShowQuickActions: Bool {
        // Only show QuickActions when there are incomplete habits (completed habits now shown in Today's card)
        return !incompleteHabits.isEmpty
    }
    
    public var shouldShowActiveStreaks: Bool {
        !activeStreaks.isEmpty
    }
    
    public var shouldShowInsights: Bool {
        !smartInsights.isEmpty
    }
    
    public var canGoToPreviousDay: Bool {
        let today = Date()
        let thirtyDaysAgo = CalendarUtils.addDays(-30, to: today)
        let viewingDayStart = CalendarUtils.startOfDayUTC(for: viewingDate)
        let boundaryStart = CalendarUtils.startOfDayUTC(for: thirtyDaysAgo)
        return viewingDayStart > boundaryStart
    }
    
    public var canGoToNextDay: Bool {
        let today = Date()
        let viewingDayStart = CalendarUtils.startOfDayUTC(for: viewingDate)
        let todayStart = CalendarUtils.startOfDayUTC(for: today)
        return viewingDayStart < todayStart
    }
    
    public var isViewingToday: Bool {
        return CalendarUtils.areSameDayLocal(viewingDate, Date())
    }
    
    public var currentSlogan: String {
        getCurrentSlogan.execute()
    }
    
    public var currentTimeOfDay: TimeOfDay {
        TimeOfDay.current()
    }
    
    public var shouldShowInspirationCard: Bool {
        guard isViewingToday else { return false }
        return showInspirationCard
    }
    
    // InspirationTrigger moved to RitualistCore/Enums/MotivationEnums.swift
    private typealias InspirationTrigger = RitualistCore.InspirationTrigger
    
    
    public var monthlyCompletionData: [Date: Double] = [:]
    
    // MARK: - Dependencies
    @ObservationIgnored @Injected(\.getActiveHabits) private var getActiveHabits
    @ObservationIgnored @Injected(\.getLogs) private var getLogs
    @ObservationIgnored @Injected(\.getBatchLogs) private var getBatchLogs
    @ObservationIgnored @Injected(\.logHabit) private var logHabit
    @ObservationIgnored @Injected(\.deleteLog) private var deleteLog
    @ObservationIgnored @Injected(\.getCurrentSlogan) private var getCurrentSlogan
    @ObservationIgnored @Injected(\.getCurrentUserProfile) private var getCurrentUserProfile
    @ObservationIgnored @Injected(\.calculateCurrentStreak) private var calculateCurrentStreakUseCase
    @ObservationIgnored @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @ObservationIgnored @Injected(\.getPersonalityInsightsUseCase) private var getPersonalityInsightsUseCase
    @ObservationIgnored @Injected(\.updatePersonalityAnalysisUseCase) private var updatePersonalityAnalysisUseCase
    @ObservationIgnored @Injected(\.validateAnalysisDataUseCase) private var validateAnalysisDataUseCase
    @ObservationIgnored @Injected(\.isPersonalityAnalysisEnabledUseCase) private var isPersonalityAnalysisEnabledUseCase
    @ObservationIgnored @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    @ObservationIgnored @Injected(\.isHabitCompleted) private var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) private var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) private var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) private var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.refreshWidget) private var refreshWidget
    @ObservationIgnored @Injected(\.personalizedMessageGenerator) private var personalizedMessageGenerator
    
    private func getUserId() async -> UUID {
        await getCurrentUserProfile.execute().id
    }
    
    public init() {
        // Initialize dismissed triggers for the current day
        resetDismissedTriggersIfNewDay()
    }
    
    // MARK: - Public Methods
    
    public func loadData() async {
        guard !isLoading else { 
            return 
        }
        
        isLoading = true
        error = nil
        
        do {
            // Cache user name for synchronous message generation
            cachedUserName = await getUserName()
            
            // Load unified data once instead of multiple parallel operations
            let overviewData = try await loadOverviewData()
            
            // Store the overview data and extract all card data from it using unified approach
            self.overviewData = overviewData
            self.todaysSummary = extractTodaysSummary(from: overviewData)
            self.activeStreaks = extractActiveStreaks(from: overviewData)
            self.monthlyCompletionData = extractMonthlyData(from: overviewData)
            self.smartInsights = extractSmartInsights(from: overviewData)
            
            // Load personality insights separately (non-blocking)
            Task {
                await loadPersonalityInsights()
            }
            
            // Check if we should show inspiration card contextually
            self.checkAndShowInspirationCard()
            
        } catch {
            self.error = error
        }
        
        self.isLoading = false
    }
    
    public func refresh() async {
        await loadData()
    }
    
    public func openPersonalityAnalysis() {
        personalityDeepLinkCoordinator.showPersonalityAnalysisDirectly()
    }
    
    public func refreshPersonalityInsights() async {
        await loadPersonalityInsights()
    }
    
    public func completeHabit(_ habit: Habit) async {
        do {
            if habit.kind == .numeric {
                // For numeric habits, set to daily target (this should primarily be used for binary habits)
                // Most numeric habit interactions should go through updateNumericHabit instead
                await updateNumericHabit(habit, value: habit.dailyTarget ?? 1.0)
            } else {
                // Binary habit - just create a log with value 1.0 using UTC timestamp and timezone context
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayUTC(for: viewingDate),
                    value: 1.0,
                    timezone: TimeZone.current.identifier
                )
                
                try await logHabit.execute(log)
                
                // Refresh data to show updated progress
                await loadData()
                
                // Small delay to ensure data is committed to shared container before widget refresh
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                
                // Refresh widget to show updated habit status
                refreshWidget.execute(habitId: habit.id)
            }
            
        } catch {
            self.error = error
            print("Failed to complete habit: \(error)")
        }
    }
    
    public func getCurrentProgress(for habit: Habit) async -> Double {
        do {
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let logsForDate = allLogs.filter { CalendarUtils.areSameDayUTC($0.date, viewingDate) }
            
            if habit.kind == .numeric {
                return logsForDate.reduce(0.0) { $0 + ($1.value ?? 0.0) }
            } else {
                return logsForDate.isEmpty ? 0.0 : 1.0
            }
        } catch {
            print("Failed to get current progress for habit \(habit.name): \(error)")
            return 0.0
        }
    }
    
    
    public func updateNumericHabit(_ habit: Habit, value: Double) async {
        do {
            // Get existing logs for this habit on the viewing date
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let existingLogsForDate = allLogs.filter { CalendarUtils.areSameDayUTC($0.date, viewingDate) }
            
            if existingLogsForDate.isEmpty {
                // No existing log for this date - create new one using UTC timestamp and timezone context
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayUTC(for: viewingDate),
                    value: value,
                    timezone: TimeZone.current.identifier
                )
                try await logHabit.execute(log)
            } else if existingLogsForDate.count == 1 {
                // Single existing log - update it
                var updatedLog = existingLogsForDate[0]
                updatedLog.value = value
                try await logHabit.execute(updatedLog)
                
            } else {
                // Multiple logs exist for this date - this shouldn't happen for our UI
                // But let's handle it properly: delete all existing logs and create one new log
                for existingLog in existingLogsForDate {
                    try await deleteLog.execute(id: existingLog.id)
                }
                
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: CalendarUtils.startOfDayUTC(for: viewingDate),
                    value: value,
                    timezone: TimeZone.current.identifier
                )
                try await logHabit.execute(log)
            }
            
            // Refresh data to get updated values from database
            await loadData()
            
            // Small delay to ensure data is committed to shared container before widget refresh
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Refresh widget to show updated habit status
            refreshWidget.execute(habitId: habit.id)
            
        } catch {
            self.error = error
            print("Failed to update numeric habit: \(error)")
        }
    }
    
    public func getProgressSync(for habit: Habit) -> Double {
        // Use single source of truth from overviewData if available
        guard let data = overviewData else {
            return 0.0
        }
        
        let logs = data.logs(for: habit.id, on: viewingDate)
        
        if habit.kind == .binary {
            return logs.isEmpty ? 0.0 : 1.0
        } else {
            return logs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
        }
    }
    
    // MARK: - Schedule Status and Validation Methods
    
    public func getScheduleStatus(for habit: Habit) -> HabitScheduleStatus {
        return HabitScheduleStatus.forHabit(habit, date: viewingDate, isScheduledDay: isScheduledDay)
    }
    
//    public func getWeeklyProgress(for habit: Habit) -> (completed: Int, target: Int) {
//        guard case .timesPerWeek = habit.schedule else {
//            return (completed: 0, target: 0)
//        }
//        
//        do {
//            // Get logs for the current week
//            let weekStart = CalendarUtils.startOfWeekUTC(for: viewingDate)
//            let weekEnd = CalendarUtils.endOfWeekUTC(for: viewingDate)
//            let logs = try loadLogsSynchronously(for: habit.id, from: weekStart, to: weekEnd)
//            
//            // Calculate weekly progress using business logic
//            guard case .timesPerWeek(let weeklyTarget) = habit.schedule else { return (0, 0) }
//            let filteredLogs = logs.filter { log in
//                log.habitID == habit.id && log.value != nil && log.value! > 0
//            }
//            let uniqueDays = Set(filteredLogs.map { log in
//                CalendarUtils.startOfDayUTC(for: log.date)
//            })
//            
//            return (uniqueDays.count, weeklyTarget)
//        } catch {
//            return (completed: 0, target: 0)
//        }
//    }
    
    private func loadLogsSynchronously(for habitId: UUID, from startDate: Date, to endDate: Date) throws -> [HabitLog] {
        // This is a simplified synchronous version - in production you'd want to cache this data
        // For now, we'll use cached data from overviewData if available
        guard let data = overviewData else { return [] }
        let habitLogs = data.habitLogs[habitId] ?? []
        return habitLogs.filter { log in
            log.date >= startDate && log.date <= endDate
        }
    }
    
    public func getScheduleValidationMessage(for habit: Habit) async -> String? {
        do {
            _ = try await validateHabitScheduleUseCase.execute(habit: habit, date: viewingDate)
            return nil // No validation errors
        } catch let error as HabitScheduleValidationError {
            return error.localizedDescription
        } catch {
            return "Unable to validate habit schedule"
        }
    }
    
    public func showNumericSheet(for habit: Habit) {
        selectedHabitForSheet = habit
        showingNumericSheet = true
    }
    
    public func setPendingNumericHabit(_ habit: Habit) {
        pendingNumericHabitFromNotification = habit
        hasPendingHabitBeenProcessed = false // Reset processing flag when new habit is set
        
        // RACE CONDITION FIX: If view is visible and ready, process immediately instead of waiting for onAppear
        if isViewVisible {
            processPendingNumericHabit()
        }
    }
    
    public var isPendingHabitProcessed: Bool {
        return hasPendingHabitBeenProcessed
    }
    
    public func setViewVisible(_ visible: Bool) {
        isViewVisible = visible
    }
    
    public func processPendingNumericHabit() {
        // Prevent double-processing if already handled
        guard !hasPendingHabitBeenProcessed,
              let habit = pendingNumericHabitFromNotification else {
            return
        }
        
        showNumericSheet(for: habit)
        
        // Clean up state after processing
        pendingNumericHabitFromNotification = nil
        hasPendingHabitBeenProcessed = true
    }
    
    public func deleteHabitLog(_ habit: Habit) async {
        do {
            // Get existing logs for this habit on the viewing date
            let allLogs = try await getLogs.execute(for: habit.id, since: viewingDate, until: viewingDate)
            let existingLogsForDate = allLogs.filter { CalendarUtils.areSameDayUTC($0.date, viewingDate) }
            
            // Delete all logs for this habit on this date
            for log in existingLogsForDate {
                try await deleteLog.execute(id: log.id)
            }
            
            // Refresh data to show updated UI
            await loadData()
            
            // Small delay to ensure data is committed to shared container before widget refresh
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Refresh widget to show updated habit status
            refreshWidget.execute(habitId: habit.id)
            
        } catch {
            self.error = error
            print("Failed to delete habit log: \(error)")
        }
    }
    
    public func goToPreviousDay() {
        if canGoToPreviousDay {
            viewingDate = CalendarUtils.previousDay(from: viewingDate)
            Task {
                await loadData()
            }
        }
    }
    
    public func goToNextDay() {
        if canGoToNextDay {
            viewingDate = CalendarUtils.nextDay(from: viewingDate)
            Task {
                await loadData()
            }
        }
    }
    
    public func goToToday() {
        viewingDate = CalendarUtils.startOfDayLocal(for: Date())
        Task {
            await loadData()
        }
    }
    
    public func goToDate(_ date: Date) {
        viewingDate = date
        Task {
            await loadData()
        }
    }
    
    public func showInspiration() {
        showInspirationCard = true
    }
    
    public func triggerMotivation() {
        // Manual motivation trigger - can be called from UI buttons or gestures
        let trigger: InspirationTrigger = {
            guard let summary = todaysSummary else { return .morningMotivation }
            
            let completionRate = summary.completionPercentage
            let timeOfDay = currentTimeOfDay
            
            if completionRate >= 1.0 {
                return .perfectDay
            } else if completionRate >= 0.75 {
                return .strongFinish
            } else if completionRate >= 0.5 {
                return .halfwayPoint
            } else {
                switch timeOfDay {
                case .morning: return .morningMotivation
                case .noon: return .strugglingMidDay
                case .evening: return .eveningReflection
                }
            }
        }()
        
        showInspirationWithTrigger(trigger)
    }
    
    private func checkForComebackStory(currentCompletion: Double) async -> Bool {
        // Check if today's progress is significantly better than yesterday
        let yesterday = CalendarUtils.previousDay(from: Date())
        
        do {
            let yesterdayHabits = try await getActiveHabits.execute()
            var yesterdayCompletedCount = 0
            
            for habit in yesterdayHabits {
                let logs = try await getLogs.execute(for: habit.id, since: yesterday, until: yesterday)
                if logs.contains(where: { CalendarUtils.areSameDayUTC($0.date, yesterday) }) {
                    yesterdayCompletedCount += 1
                }
            }
            
            let yesterdayCompletion = yesterdayHabits.isEmpty ? 0.0 : Double(yesterdayCompletedCount) / Double(yesterdayHabits.count)
            
            // If today is 25%+ better than yesterday, it's a comeback story
            return currentCompletion > yesterdayCompletion + 0.25 && yesterdayCompletion < 0.6
        } catch {
            // Ignore errors for comeback detection
            return false
        }
    }
    
    public func hideInspiration() {
        // Mark current trigger as dismissed for today
        if let currentTrigger = lastShownInspirationTrigger {
            dismissedTriggersToday.insert(currentTrigger)
            saveDismissedTriggers()
        }
        showInspirationCard = false
    }
    
    private func checkAndShowInspirationCard() {
        guard isViewingToday, let summary = todaysSummary else { return }
        
        Task {
            let triggers = await evaluateInspirationTriggers(summary: summary)
            
            if let bestTrigger = selectBestTrigger(from: triggers) {
                showInspirationWithTrigger(bestTrigger)
            }
        }
    }
    
    private func evaluateInspirationTriggers(summary: TodaysSummary) async -> [InspirationTrigger] {
        var triggers: [InspirationTrigger] = []
        let timeOfDay = currentTimeOfDay
        let completionRate = summary.completionPercentage
        let now = Date()
        let hour = CalendarUtils.hourComponentUTC(from: now)
        let isWeekend = [1, 7].contains(CalendarUtils.weekdayComponentUTC(from: now))
        
        // Session Start (first load of the day)
        if CalendarUtils.areSameDayUTC(sessionStartTime, now) && 
           CalendarUtils.daysBetweenUTC(sessionStartTime, now) == 0 {
            triggers.append(.sessionStart)
        }
        
        // Time-based triggers
        switch timeOfDay {
        case .morning:
            if completionRate == 0.0 {
                triggers.append(.morningMotivation)
            }
            if isWeekend {
                triggers.append(.weekendMotivation)
            }
        case .noon:
            if completionRate < 0.4 {
                triggers.append(.strugglingMidDay)
            }
        case .evening:
            if completionRate >= 0.6 {
                triggers.append(.eveningReflection)
            }
        }
        
        // Afternoon push (3-5 PM)
        if hour >= 15 && hour < 17 && completionRate < 0.6 {
            triggers.append(.afternoonPush)
        }
        
        // Progress-based triggers
        if completionRate >= 1.0 {
            triggers.append(.perfectDay)
        } else if completionRate >= 0.75 {
            triggers.append(.strongFinish)
        } else if completionRate >= 0.5 {
            triggers.append(.halfwayPoint)
        } else if completionRate > 0.0 && summary.completedHabitsCount == 1 {
            triggers.append(.firstHabitComplete)
        }
        
        // Comeback story trigger (improved from yesterday)
        if await checkForComebackStory(currentCompletion: completionRate) {
            triggers.append(.comebackStory)
        }
        
        return triggers
    }
    
    private func selectBestTrigger(from triggers: [InspirationTrigger]) -> InspirationTrigger? {
        let now = Date()
        
        // Filter out triggers that are on cooldown or dismissed today
        let availableTriggers = triggers.filter { trigger in
            // Skip if already dismissed today
            if dismissedTriggersToday.contains(trigger) {
                return false
            }
            
            // Check cooldown
            if let lastTrigger = lastShownInspirationTrigger,
               lastTrigger == trigger {
                let lastShownTime = CalendarUtils.startOfDayUTC(for: now)
                let cooldownEnd = CalendarUtils.addMinutes(trigger.cooldownMinutes, to: lastShownTime)
                return now >= cooldownEnd
            }
            return true
        }
        
        // Priority order (most impactful first)
        let priorityOrder: [InspirationTrigger] = [
            .perfectDay,           // Celebrate success immediately
            .sessionStart,         // Welcome back
            .firstHabitComplete,   // Build momentum
            .strongFinish,         // Celebrate near-completion
            .halfwayPoint,         // Acknowledge progress
            .strugglingMidDay,     // Provide mid-day boost
            .afternoonPush,        // Late-day motivation
            .eveningReflection,    // End positively
            .morningMotivation,    // Start the day right
            .weekendMotivation,    // Weekend encouragement
            .comebackStory         // Recovery motivation
        ]
        
        // Return highest priority available trigger
        return priorityOrder.first { availableTriggers.contains($0) }
    }
    
    private func showInspirationWithTrigger(_ trigger: InspirationTrigger) {
        let delay: Int = {
            switch trigger {
            case .perfectDay:
                return 1200  // Celebrate immediately but with dramatic pause
            case .firstHabitComplete, .halfwayPoint, .strongFinish:
                return 800   // Quick positive reinforcement
            case .sessionStart:
                return 2000  // Let user settle in first
            default:
                return 1500  // Standard timing
            }
        }()

        Task {
            try? await Task.sleep(for: .milliseconds(delay))

            // Generate and cache personalized message before showing card
            let message = await getPersonalizedMessage(for: trigger)
            self.cachedInspirationMessage = message

            self.lastShownInspirationTrigger = trigger
            self.showInspirationCard = true
        }
    }
    
    public var currentInspirationMessage: String {
        // Use cached message if available, otherwise fallback to slogan
        return cachedInspirationMessage ?? getCurrentSlogan.execute()
    }
    
    // MARK: - Private Methods
    
    /// Load overview data from database
    private func loadOverviewData() async throws -> OverviewData {
        // 1. Load habits ONCE
        let habits = try await getActiveHabits.execute()
        
        // 2. Determine date range (past 30 days for monthly data)
        let today = Date()
        let startDate = CalendarUtils.addDays(-30, to: today)
        
        // 3. Load logs ONCE for entire date range using batch operation
        let habitIds = habits.map(\.id)
        let habitLogs = try await getBatchLogs.execute(
            for: habitIds, 
            since: startDate, 
            until: today
        )
        
        return OverviewData(
            habits: habits,
            habitLogs: habitLogs,
            dateRange: startDate...today
        )
    }
    
    // MARK: - Data Extraction Methods
    
    /// Extract TodaysSummary from overview data
    internal func extractTodaysSummary(from data: OverviewData) -> TodaysSummary {
        let targetDate = viewingDate
        let habits = data.scheduledHabits(for: targetDate)
        
        var allTargetDateLogs: [HabitLog] = []
        var incompleteHabits: [Habit] = []
        var completedHabits: [Habit] = []
        
        for habit in habits {
            let logs = data.logs(for: habit.id, on: targetDate)
            allTargetDateLogs.append(contentsOf: logs)
            
            // Use centralized completion service for consistent calculation
            let isCompleted = isHabitCompleted.execute(habit: habit, on: targetDate, logs: logs)
            
            // Only show as incomplete if not completed AND not a future date
            if targetDate > Date() {
                // Don't add future dates to incomplete list
                if isCompleted {
                    completedHabits.append(habit)
                }
            } else {
                // Past/present dates
                if isCompleted {
                    completedHabits.append(habit)
                } else {
                    incompleteHabits.append(habit)
                }
            }
        }
        
        // Sort completed habits by latest log time (most recent first)
        completedHabits.sort { habit1, habit2 in
            let habit1Logs = allTargetDateLogs.filter { $0.habitID == habit1.id }
            let habit2Logs = allTargetDateLogs.filter { $0.habitID == habit2.id }
            let habit1LatestTime = habit1Logs.map { $0.date }.max() ?? Date.distantPast
            let habit2LatestTime = habit2Logs.map { $0.date }.max() ?? Date.distantPast
            return habit1LatestTime > habit2LatestTime  // Most recent first
        }
        
        let completionPercentage = habits.isEmpty ? 0.0 : Double(completedHabits.count) / Double(habits.count)
        
        return TodaysSummary(
            completedHabitsCount: completedHabits.count,
            completedHabits: completedHabits,
            totalHabits: habits.count,
            incompleteHabits: incompleteHabits
        )
    }
    
    
    /// Extract monthly completion data from overview data
    private func extractMonthlyData(from data: OverviewData) -> [Date: Double] {
        var result: [Date: Double] = [:]
        
        // Get dates from range, ensuring we use startOfDay for consistency
        for dayOffset in 0...30 {
            let date = CalendarUtils.addDays(-dayOffset, to: Date())
            let startOfDay = CalendarUtils.startOfDayUTC(for: date)
            // Use HabitCompletionService for single source of truth completion rate
            let scheduledHabits = data.scheduledHabits(for: startOfDay)
            if scheduledHabits.isEmpty {
                result[startOfDay] = 0.0
            } else {
                let completedCount = scheduledHabits.count { habit in
                    let logs = data.logs(for: habit.id, on: startOfDay)
                    return isHabitCompleted.execute(habit: habit, on: startOfDay, logs: logs)
                }
                result[startOfDay] = Double(completedCount) / Double(scheduledHabits.count)
            }
        }
        
        return result
    }
    
    /// Extract active streaks from overview data
    private func extractActiveStreaks(from data: OverviewData) -> [StreakInfo] {
        var streaks: [StreakInfo] = []
        let today = Date()
        
        for habit in data.habits {
            // Get logs for this habit from unified data
            let logs = data.habitLogs[habit.id] ?? []
            
            let currentStreak = calculateCurrentStreakUseCase.execute(habit: habit, logs: logs, asOf: today)
            
            if currentStreak >= 1 { // Show all active streaks (1+ days)
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
        let sortedStreaks = streaks.sorted { $0.currentStreak > $1.currentStreak }
        
        return sortedStreaks
    }
    
    /// Extract smart insights from unified overview data
    /// Uses pre-loaded data and UseCases for consistency
    private func extractSmartInsights(from data: OverviewData) -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let today = Date()
        
        // Get the proper week interval that respects user's first day of week preference
        let weekInterval = CalendarUtils.weekIntervalUTC(for: today) ?? DateInterval(start: today, duration: 0)
        let startOfWeek = weekInterval.start
        
        // Use unified data instead of separate queries
        guard !data.habits.isEmpty else {
            return []
        }
        
        // Analyze completion patterns over the past week using unified data
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)
        
        for habit in data.habits {
            let logs = data.habitLogs[habit.id] ?? []
            let recentLogs = logs.filter { log in
                log.date >= startOfWeek && log.date < weekInterval.end
            }
            
            // Count actual completions using IsHabitCompletedUseCase for single source of truth
            for log in recentLogs {
                let dayLogs = logs.filter { CalendarUtils.areSameDayUTC($0.date, log.date) }
                if isHabitCompleted.execute(habit: habit, on: log.date, logs: dayLogs) {
                    totalCompletions += 1
                    
                    // Count completions per day
                    let daysSinceStart = CalendarUtils.daysBetweenUTC(startOfWeek, log.date)
                    if daysSinceStart >= 0 && daysSinceStart < 7 {
                        dailyCompletions[daysSinceStart] += 1
                    }
                }
            }
        }
        
        let totalPossibleCompletions = data.habits.count * 7
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        // Generate insights based on actual patterns
        if completionRate >= 0.8 {
            insights.append(SmartInsight(
                title: "Excellent Consistency",
                message: "You're completing \(Int(completionRate * 100))% of your habits this week!",
                type: .celebration
            ))
        } else if completionRate >= 0.6 {
            insights.append(SmartInsight(
                title: "Good Progress",
                message: "You're on track with \(Int(completionRate * 100))% completion. Keep building momentum!",
                type: .pattern
            ))
        } else if completionRate >= 0.3 {
            insights.append(SmartInsight(
                title: "Room for Growth",
                message: "Focus on consistency - even small daily wins add up to big results.",
                type: .suggestion
            ))
        } else {
            insights.append(SmartInsight(
                title: "Fresh Start",
                message: "Every day is a new opportunity. Start with just one habit today.",
                type: .suggestion
            ))
        }
        
        return insights
    }
    
    private func loadSmartInsights() async throws -> [SmartInsight] {
        // DEPRECATED: This method is being replaced by extractSmartInsights() 
        // which uses unified OverviewData instead of separate queries
        return try await generateBasicHabitInsights()
    }
    
    private func loadPersonalityInsights() async {
        do {
            // Always get eligibility and requirements info using the UseCase
            let userId = await getUserId()
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
            
            // Update state with eligibility info
            isPersonalityDataSufficient = eligibility.isEligible
            personalityThresholdRequirements = requirements
            
            // Always show the card now - it will handle different states internally
            shouldShowPersonalityInsights = true
            
            // Get existing personality profile
            var personalityProfile = try await getPersonalityProfileUseCase.execute(for: userId)
            
            // If user is eligible but no profile exists, attempt to create one
            if eligibility.isEligible && personalityProfile == nil {
                do {
                    let newProfile = try await updatePersonalityAnalysisUseCase.execute(for: userId)
                    personalityProfile = newProfile
                } catch {
                    // If analysis fails, we still show the card but with error state
                    personalityInsights = []
                    dominantPersonalityTrait = nil
                    return
                }
            }
            
            // If we have a profile, get insights from it
            if let profile = personalityProfile {
                let insights = getPersonalityInsightsUseCase.getAllInsights(for: profile)
                
                // Convert to OverviewPersonalityInsight format for the new card
                var cardInsights: [OverviewPersonalityInsight] = []
                
                // Add pattern insights
                for insight in insights.patternInsights.prefix(2) {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: insight.title,
                        message: insight.description,
                        type: .pattern
                    ))
                }
                
                // Add habit recommendations
                for insight in insights.habitRecommendations.prefix(2) {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: insight.title,
                        message: insight.actionable,
                        type: .recommendation
                    ))
                }
                
                // Add one motivational insight
                if let motivationalInsight = insights.motivationalInsights.first {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: motivationalInsight.title,
                        message: motivationalInsight.actionable,
                        type: .motivation
                    ))
                }
                
                personalityInsights = cardInsights
                dominantPersonalityTrait = profile.dominantTrait.displayName
            } else {
                // No profile available (either data insufficient or analysis failed)
                personalityInsights = []
                dominantPersonalityTrait = nil
            }
            
        } catch {
            // Even on error, show the card but with empty state
            personalityInsights = []
            dominantPersonalityTrait = nil
            isPersonalityDataSufficient = false
            personalityThresholdRequirements = []
        }
    }
    
    private func checkPersonalityAnalysisEligibility() async throws -> Bool {
        // Use proper UseCases instead of direct repository access
        do {
            let userId = await getUserId()
            // Check if personality analysis service is enabled for this user
            let isEnabled = try await isPersonalityAnalysisEnabledUseCase.execute(for: userId)
            
            guard isEnabled else {
                return false
            }
            
            // Use the proper eligibility validation UseCase
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            return eligibility.isEligible
            
        } catch {
            return false
        }
    }
    
    private func generateBasicHabitInsights() async throws -> [SmartInsight] {
        var insights: [SmartInsight] = []
        let today = Date()
        
        // Get the proper week interval that respects user's first day of week preference
        let weekInterval = CalendarUtils.weekIntervalUTC(for: today) ?? DateInterval(start: today, duration: 0)
        let startOfWeek = weekInterval.start
        
        // Get user's active habits and recent logs
        let habits = try await getActiveHabits.execute()
        guard !habits.isEmpty else {
            return []
        }
        
        // Analyze completion patterns over the past week
        var totalCompletions = 0
        var dailyCompletions: [Int] = Array(repeating: 0, count: 7)
        
        // OPTIMIZATION: Batch load logs for all habits to avoid N+1 queries
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startOfWeek, until: weekInterval.end)
        
        for habit in habits {
            let logs = logsByHabitId[habit.id] ?? []
            let recentLogs = logs.filter { log in
                log.date >= startOfWeek && log.date < weekInterval.end
            }
            
            totalCompletions += recentLogs.count
            
            // Count completions per day
            for log in recentLogs {
                let daysSinceStart = CalendarUtils.daysBetweenUTC(startOfWeek, log.date)
                if daysSinceStart >= 0 && daysSinceStart < 7 {
                    dailyCompletions[daysSinceStart] += 1
                }
            }
        }
        
        let totalPossibleCompletions = habits.count * 7
        let completionRate = totalPossibleCompletions > 0 ? Double(totalCompletions) / Double(totalPossibleCompletions) : 0.0
        
        // Generate insights based on actual patterns
        if completionRate >= 0.8 {
            insights.append(SmartInsight(
                title: "Excellent Consistency",
                message: "You're completing \(Int(completionRate * 100))% of your habits this week!",
                type: .celebration
            ))
        } else if completionRate >= 0.6 {
            insights.append(SmartInsight(
                title: "Good Progress",
                message: "You're on track with \(Int(completionRate * 100))% completion. Keep building momentum!",
                type: .pattern
            ))
        } else if completionRate >= 0.3 {
            insights.append(SmartInsight(
                title: "Room for Growth",
                message: "Focus on consistency - even small daily wins add up to big results.",
                type: .suggestion
            ))
        } else {
            insights.append(SmartInsight(
                title: "Fresh Start",
                message: "Every day is a new opportunity. Start with just one habit today.",
                type: .suggestion
            ))
        }
        
        // Find best performing day
        if let bestDayIndex = dailyCompletions.enumerated().max(by: { $0.element < $1.element })?.offset {
            // Get the actual date for the best performing day
            let bestDate = CalendarUtils.addDays(bestDayIndex, to: startOfWeek)
            
            // Get the day name using the proper date
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let bestDayName = dayFormatter.string(from: bestDate)
            
            if dailyCompletions[bestDayIndex] > 0 {
                insights.append(SmartInsight(
                    title: "\(bestDayName) Strength",
                    message: "You completed \(dailyCompletions[bestDayIndex]) habits on \(bestDayName) - your strongest day!",
                    type: .pattern
                ))
            }
        }
        
        // Add motivational insight if they have multiple habits
        if habits.count >= 3 {
            insights.append(SmartInsight(
                title: "Multi-Habit Builder",
                message: "Tracking \(habits.count) habits shows commitment to growth. Focus on consistency over perfection.",
                type: .suggestion
            ))
        }
        
        return insights
    }
    
    
    
    private func resetDismissedTriggersIfNewDay() {
        let today = Date()
        
        // Check if we've moved to a new day since last session
        if let lastResetDate = UserDefaults.standard.object(forKey: "lastInspirationResetDate") as? Date {
            if !CalendarUtils.areSameDayUTC(lastResetDate, today) {
                dismissedTriggersToday.removeAll()
                UserDefaults.standard.set(today, forKey: "lastInspirationResetDate")
            } else {
                // Load dismissed triggers for today from UserDefaults
                if let dismissedData = UserDefaults.standard.data(forKey: "dismissedTriggersToday"),
                   let dismissedArray = try? JSONDecoder().decode([String].self, from: dismissedData) {
                    dismissedTriggersToday = Set(dismissedArray.compactMap { triggerString in
                        InspirationTrigger.allCases.first { "\($0)" == triggerString }
                    })
                }
            }
        } else {
            // First time - set today as reset date
            UserDefaults.standard.set(today, forKey: "lastInspirationResetDate")
        }
    }
    
    private func saveDismissedTriggers() {
        let dismissedArray = dismissedTriggersToday.map { "\($0)" }
        if let data = try? JSONEncoder().encode(dismissedArray) {
            UserDefaults.standard.set(data, forKey: "dismissedTriggersToday")
        }
    }
    
    // MARK: - Personalized Inspiration Messages

    private func getPersonalizedMessage(for trigger: InspirationTrigger) async -> String {
        // Load personality profile
        let personalityProfile = await loadPersonalityProfileForMessage()

        // Get current streak (longest streak from activeStreaks, or 0)
        let currentStreakValue = activeStreaks.first?.currentStreak ?? 0

        // Build message context
        let context = MessageContext(
            trigger: trigger,
            personality: personalityProfile,
            completionPercentage: todaysSummary?.completionPercentage ?? 0.0,
            timeOfDay: currentTimeOfDay,
            userName: userName,
            currentStreak: currentStreakValue,
            recentPattern: analyzeRecentPattern()
        )

        // Generate personalized message
        let message = await personalizedMessageGenerator.generateMessage(for: context)
        return message.content
    }

    private func loadPersonalityProfileForMessage() async -> PersonalityProfile? {
        // Get user ID
        let userId = await getUserId()

        // Check if personality analysis is enabled and available
        guard let isEnabled = try? await isPersonalityAnalysisEnabledUseCase.execute(for: userId),
              isEnabled else {
            return nil
        }

        // Get current personality profile
        return try? await getPersonalityProfileUseCase.execute(for: userId)
    }

    private func analyzeRecentPattern() -> CompletionPattern {
        // For Phase 1, return a basic pattern
        // Phase 2 will implement more sophisticated pattern analysis
        guard let completionPercentage = todaysSummary?.completionPercentage else {
            return .insufficient
        }

        // Simple heuristic based on current completion
        if completionPercentage >= 0.8 {
            return .consistent
        } else if completionPercentage >= 0.5 {
            return .improving
        } else if completionPercentage > 0 {
            return .declining
        } else {
            return .insufficient
        }
    }
    
    private var cachedUserName: String? = nil

    private func getUserName() async -> String? {
        let profile = await getCurrentUserProfile.execute()
        return profile.name.isEmpty ? nil : profile.name
    }

    private var userName: String? { cachedUserName }
}
