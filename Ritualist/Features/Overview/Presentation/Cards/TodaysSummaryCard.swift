import SwiftUI
import RitualistCore
import FactoryKit
import TipKit

/// Consolidated state identifier for TodaysSummaryCard onChange optimization.
/// Combines all values that should trigger habit list updates into a single Equatable type,
/// avoiding multiple onChange handlers that would cause redundant recalculations.
private struct SummaryStateId: Equatable {
    let completedCount: Int
    let totalHabits: Int
    let incompleteCount: Int
    let progressStateId: String
    let viewingDate: Date
}

struct TodaysSummaryCard: View {
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) var horizontalSizeClass

    // MARK: - Dependencies
    @Injected(\.debugLogger) var logger
    @Injected(\.subscriptionService) var subscriptionService

    // MARK: - Tips
    let tapHabitTip = TapHabitTip()
    let tapCompletedHabitTip = TapCompletedHabitTip()
    let longPressLogTip = LongPressLogTip()
    let summary: TodaysSummary?
    let viewingDate: Date
    let isViewingToday: Bool
    let timezone: TimeZone
    let canGoToPrevious: Bool
    let canGoToNext: Bool
    /// Daily completion data for week selector - keys are normalized dates
    let weeklyData: [Date: Double]
    let currentSlogan: String?
    let onQuickAction: (Habit) -> Void
    let onNumericHabitUpdate: ((Habit, Double) async throws -> Void)?
    let getProgress: ((Habit) -> Double)
    let onNumericHabitAction: ((Habit) -> Void)? // Callback for numeric habit sheet
    let onBinaryHabitAction: ((Habit) -> Void)? // Callback for binary habit confirmation sheet
    let onLongPressComplete: ((Habit) -> Void)? // Callback for long-press quick-log
    let onDeleteHabitLog: (Habit) -> Void // New callback for deleting habit log
    let getScheduleStatus: (Habit) -> HabitScheduleStatus // New callback for schedule status
    let getValidationMessage: (Habit) async -> String? // New callback for validation message
    let getStreakStatus: ((Habit) -> HabitStreakStatus)? // Callback for streak at risk indicator
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onGoToToday: () -> Void
    /// Direct date selection callback - prevents race conditions from rapid sequential day callbacks
    let onDateSelected: (Date) -> Void
    let isLoggingLocked: Bool // When true, all habit logging is disabled (over habit limit)
    
    // Persisted view state - survives navigation and app restarts
    @AppStorage(UserDefaultsKeys.todaySummaryCompletedViewCompact) var isCompletedViewCompact = true
    @AppStorage(UserDefaultsKeys.todaySummaryRemainingViewCompact) var isRemainingViewCompact = false
    @State var showingDeleteAlert = false
    @State var habitToDelete: Habit?
    @State var showingScheduleInfoSheet = false
    @State var showingNoHabitsInfoSheet = false
    @State var habitToUncomplete: Habit?
    @State var animatingHabitId: UUID?
    @State var glowingHabitId: UUID?
    @State var animatingProgress: Double = 0.0
    @State var isAnimatingCompletion = false
    @State var habitAnimatedProgress: [UUID: Double] = [:] // Track animated progress per habit
    @State var isPremiumUser = false
    @State var longPressHabitId: UUID? // Currently long-pressed habit
    @State var longPressProgress: Double = 0.0 // Progress of long-press (0.0 to 1.0)
    @State var recentlyCompletedViaLongPress: Set<UUID> = [] // Habits that just completed via long-press (show checkmark briefly)

    // Task references for proper cancellation on view disappear
    @State var quickActionGlowTask: Task<Void, Never>?
    @State var habitRowGlowTask: Task<Void, Never>?
    @State var completionAnimationTask: Task<Void, Never>?
    @State var longPressCompletionTasks: [UUID: Task<Void, Never>] = [:] // Per-habit long-press completion animation tasks

    // Animation timing constants (in nanoseconds)
    enum AnimationTiming {
        static let completionGlowDelay: UInt64 = 500_000_000          // 0.5s - completion glow duration
        static let completionAnimationDelay: UInt64 = 800_000_000     // 0.8s - completion animation duration
        static let animationCleanupDelay: UInt64 = 500_000_000        // 0.5s - cleanup delay after animation
        static let longPressCheckmarkDisplay: UInt64 = 1_500_000_000  // 1.5s - checkmark display after long-press
    }

    // PERFORMANCE: Pre-computed arrays to avoid creating NEW arrays on every render
    @State var visibleIncompleteHabits: [Habit] = []
    @State var visibleCompletedHabits: [Habit] = []
    @State var scheduledIncompleteCount: Int = 0  // Track filtered count for display

    // Icon visibility settings (persisted in UserDefaults)
    @AppStorage(UserDefaultsKeys.showTimeReminderIcon) var showTimeReminderIcon = true
    @AppStorage(UserDefaultsKeys.showLocationIcon) var showLocationIcon = true
    @AppStorage(UserDefaultsKeys.showScheduleIcon) var showScheduleIcon = true
    @AppStorage(UserDefaultsKeys.showStreakAtRiskIcon) var showStreakAtRiskIcon = true

    // Computed ID that changes when any numeric habit progress changes
    private var habitProgressStateId: String {
        guard let summary = summary else { return "" }
        return summary.incompleteHabits
            .filter { $0.kind == .numeric }
            .map { "\($0.id.uuidString)-\(getProgress($0))" }
            .joined(separator: "|")
    }

    /// Consolidated state trigger for onChange - combines all values that should trigger updates.
    /// Using a struct avoids multiple onChange handlers causing redundant recalculations.
    private var summaryStateId: SummaryStateId {
        SummaryStateId(
            completedCount: summary?.completedHabitsCount ?? 0,
            totalHabits: summary?.totalHabits ?? 0,
            incompleteCount: summary?.incompleteHabits.count ?? 0,
            progressStateId: habitProgressStateId,
            viewingDate: viewingDate
        )
    }

    init(summary: TodaysSummary?,
         viewingDate: Date,
         isViewingToday: Bool,
         timezone: TimeZone = .current,
         canGoToPrevious: Bool,
         canGoToNext: Bool,
         weeklyData: [Date: Double] = [:],
         currentSlogan: String? = nil,
         onQuickAction: @escaping (Habit) -> Void,
         onNumericHabitUpdate: ((Habit, Double) async throws -> Void)? = nil,
         getProgressSync: @escaping (Habit) -> Double,
         onNumericHabitAction: ((Habit) -> Void)? = nil,
         onBinaryHabitAction: ((Habit) -> Void)? = nil,
         onLongPressComplete: ((Habit) -> Void)? = nil,
         onDeleteHabitLog: @escaping (Habit) -> Void,
         getScheduleStatus: @escaping (Habit) -> HabitScheduleStatus,
         getValidationMessage: @escaping (Habit) async -> String?,
         getStreakStatus: ((Habit) -> HabitStreakStatus)? = nil,
         onPreviousDay: @escaping () -> Void,
         onNextDay: @escaping () -> Void,
         onGoToToday: @escaping () -> Void,
         onDateSelected: @escaping (Date) -> Void,
         isLoggingLocked: Bool = false) {
        self.summary = summary
        self.viewingDate = viewingDate
        self.isViewingToday = isViewingToday
        self.timezone = timezone
        self.canGoToPrevious = canGoToPrevious
        self.canGoToNext = canGoToNext
        self.weeklyData = weeklyData
        self.currentSlogan = currentSlogan
        self.onQuickAction = onQuickAction
        self.onNumericHabitUpdate = onNumericHabitUpdate
        self.getProgress = getProgressSync
        self.onNumericHabitAction = onNumericHabitAction
        self.onBinaryHabitAction = onBinaryHabitAction
        self.onLongPressComplete = onLongPressComplete
        self.onDeleteHabitLog = onDeleteHabitLog
        self.getScheduleStatus = getScheduleStatus
        self.getValidationMessage = getValidationMessage
        self.getStreakStatus = getStreakStatus
        self.onPreviousDay = onPreviousDay
        self.onNextDay = onNextDay
        self.onGoToToday = onGoToToday
        self.onDateSelected = onDateSelected
        self.isLoggingLocked = isLoggingLocked
    }

    // PERFORMANCE: Update visible arrays only when needed
    private func updateVisibleHabits() {
        guard let summary = summary else {
            visibleIncompleteHabits = []
            visibleCompletedHabits = []
            scheduledIncompleteCount = 0
            return
        }

        // BUGFIX: Capture viewingDate at start to ensure consistency during filter
        // Additional safety filter to prevent race condition where summary contains habits
        // from previous viewingDate. Only show habits that are actually scheduled for viewingDate
        // AND have started (date >= habit.startDate).
        // Use display timezone for correct weekday calculation across timezone boundaries.
        let capturedDate = viewingDate
        let scheduledIncompleteHabits = summary.incompleteHabits.filter { $0.isScheduledOn(date: capturedDate, timezone: timezone) }

        // Store the filtered count for display
        scheduledIncompleteCount = scheduledIncompleteHabits.count

        // Show all habits - compact/expanded toggle controls view style, not item count
        visibleIncompleteHabits = scheduledIncompleteHabits
        visibleCompletedHabits = summary.completedHabits
    }

    // Update habit progress animations when data changes
    private func updateHabitProgressAnimations() {
        guard let summary = summary else { return }

        // Get current incomplete habit IDs
        let currentHabitIds = Set(summary.incompleteHabits.filter { $0.kind == .numeric }.map { $0.id })

        // Remove progress for habits that are no longer in the list
        habitAnimatedProgress = habitAnimatedProgress.filter { currentHabitIds.contains($0.key) }

        // Update only numeric habits whose progress actually changed
        for habit in summary.incompleteHabits where habit.kind == .numeric {
            let currentValue = getProgress(habit)
            let target = habit.dailyTarget ?? 1.0
            let actualProgress = calculateProgress(current: currentValue, target: target)

            // If not tracked (new habit or coming from non-scheduled day), start from 0 and animate
            if habitAnimatedProgress[habit.id] == nil {
                habitAnimatedProgress[habit.id] = 0.0
                // Animate from 0 to actual progress
                withAnimation(.easeInOut(duration: 0.5)) {
                    habitAnimatedProgress[habit.id] = actualProgress
                }
            } else if habitAnimatedProgress[habit.id] != actualProgress {
                // Only animate if progress actually changed - prevents redundant animations
                withAnimation(.easeInOut(duration: 0.5)) {
                    habitAnimatedProgress[habit.id] = actualProgress
                }
            }
            // Skip animation if progress unchanged (optimization for 10+ habits)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            dateNavigationHeader
            contentSection
        }
        .accessibilityIdentifier(AccessibilityID.Overview.todaysSummaryCard)
        .alert("Remove Log Entry?", isPresented: $showingDeleteAlert) {
            Button(Strings.Common.cancel, role: .cancel) { habitToDelete = nil }
            Button(Strings.Common.remove, role: .destructive) {
                if let habit = habitToDelete { performRemovalAnimation(for: habit) }
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text("This will remove the log entry for \"\(habit.name)\" from \(isViewingToday ? "today" : CalendarUtils.formatCompact(viewingDate, includeDayName: true, timezone: timezone)). The habit itself will remain.")
            }
        }
        .sheet(isPresented: $showingScheduleInfoSheet) { ScheduleIconInfoSheet() }
        .sheet(item: $habitToUncomplete) { habit in
            UncompleteHabitSheet(
                habit: habit,
                onUncomplete: { onDeleteHabitLog(habit); habitToUncomplete = nil },
                onCancel: { habitToUncomplete = nil }
            )
        }
        .onAppear { updateVisibleHabits(); updateHabitProgressAnimations() }
        .task { isPremiumUser = await subscriptionService.isPremiumUser() }
        .onReceive(NotificationCenter.default.publisher(for: .premiumStatusDidChange)) { _ in
            // Refresh premium status when purchase completes
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            Task { @MainActor in isPremiumUser = await subscriptionService.isPremiumUser() }
        }
        .onDisappear { cancelAllAnimationTasks() }
        // Consolidated onChange: triggers updates when any relevant summary state changes
        // This avoids redundant recalculations from multiple separate onChange handlers
        .onChange(of: summaryStateId) { oldValue, newValue in
            updateVisibleHabits()
            updateHabitProgressAnimations()
            // Clear long-press indicators only when completed count changes (habits moved between sections)
            if oldValue.completedCount != newValue.completedCount {
                recentlyCompletedViaLongPress.removeAll()
            }
        }
    }

    // MARK: - Body Helper Views

    @ViewBuilder
    private var dateNavigationHeader: some View {
        // Week date selector with animated swipe navigation
        // Includes "Return to Today" button in header when not viewing today
        // Day circles show completion status using the same colors as MonthlyCalendarCard
        WeekDateSelector(
            selectedDate: viewingDate,
            timezone: timezone,
            canGoToPrevious: canGoToPrevious,
            canGoToNext: canGoToNext,
            isViewingToday: isViewingToday,
            weeklyData: weeklyData,
            onDateSelected: onDateSelected,
            onGoToToday: onGoToToday
        )
    }

    @ViewBuilder
    private var contentSection: some View {
        if let summary = summary {
            if !summary.incompleteHabits.isEmpty || !summary.completedHabits.isEmpty {
                habitsSection(summary: summary)
            } else {
                noHabitsScheduledView
            }
        } else {
            loadingView
        }
    }

    // MARK: - Body Helper Methods

    private func cancelAllAnimationTasks() {
        quickActionGlowTask?.cancel()
        habitRowGlowTask?.cancel()
        completionAnimationTask?.cancel()
        // Cancel all pending long-press completion tasks
        longPressCompletionTasks.values.forEach { $0.cancel() }
        longPressCompletionTasks.removeAll()
    }
}

// MARK: - No Habits Scheduled Info Sheet

struct NoHabitsScheduledInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    private var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NoHabitsExplanationRow(
                        icon: "calendar.badge.clock",
                        iconColor: .orange,
                        title: Strings.Overview.noHabitsReasonScheduleTitle,
                        description: Strings.Overview.noHabitsReasonScheduleDesc
                    )
                    NoHabitsExplanationRow(
                        icon: "calendar.badge.exclamationmark",
                        iconColor: .blue,
                        title: Strings.Overview.noHabitsReasonStartDateTitle,
                        description: Strings.Overview.noHabitsReasonStartDateDesc
                    )
                } header: {
                    Text(Strings.Overview.noHabitsReasonHeader)
                } footer: {
                    Text(Strings.Overview.noHabitsReasonFooter)
                }
            }
            .navigationTitle(Strings.Overview.noHabitsInfoTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Strings.Button.done) { dismiss() }
                }
            }
        }
        .presentationDetents(isIPad ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct NoHabitsExplanationRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Today state
        TodaysSummaryCard(
            summary: TodaysSummary(
                completedHabitsCount: 4,
                completedHabits: [],
                totalHabits: 5,
                incompleteHabits: [
                    Habit(
                        id: UUID(),
                        name: "Evening Reading",
                        emoji: "📚",
                        kind: .binary,
                        unitLabel: nil,
                        dailyTarget: 1.0,
                        schedule: .daily,
                        isActive: true,
                        categoryId: nil,
                        suggestionId: nil
                    )
                ]
            ),
            viewingDate: Date(),
            isViewingToday: true,
            canGoToPrevious: true,
            canGoToNext: false,
            currentSlogan: "Rise with purpose, rule your day.",
            onQuickAction: { _ in },
            onNumericHabitUpdate: { _, _ in },
            getProgressSync: { _ in 0.0 },
            onNumericHabitAction: { _ in },
            onDeleteHabitLog: { _ in },
            getScheduleStatus: { _ in .alwaysScheduled },
            getValidationMessage: { _ in nil },
            onPreviousDay: { },
            onNextDay: { },
            onGoToToday: { },
            onDateSelected: { _ in }
        )

        // Past day state
        TodaysSummaryCard(
            summary: TodaysSummary(
                completedHabitsCount: 2,
                completedHabits: [],
                totalHabits: 5,
                incompleteHabits: [
                    Habit(
                        id: UUID(),
                        name: "Morning Workout",
                        emoji: "💪",
                        kind: .binary,
                        unitLabel: nil,
                        dailyTarget: 1.0,
                        schedule: .daily,
                        isActive: true,
                        categoryId: nil,
                        suggestionId: nil
                    )
                ]
            ),
            viewingDate: CalendarUtils.addDaysLocal(-3, to: Date(), timezone: .current),
            isViewingToday: false,
            canGoToPrevious: true,
            canGoToNext: true,
            currentSlogan: nil,
            onQuickAction: { _ in },
            onNumericHabitUpdate: { _, _ in },
            getProgressSync: { _ in 0.0 },
            onNumericHabitAction: { _ in },
            onDeleteHabitLog: { _ in },
            getScheduleStatus: { _ in .alwaysScheduled },
            getValidationMessage: { _ in nil },
            onPreviousDay: { },
            onNextDay: { },
            onGoToToday: { },
            onDateSelected: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
