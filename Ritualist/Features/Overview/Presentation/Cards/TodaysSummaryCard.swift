import SwiftUI
import RitualistCore
import FactoryKit
import TipKit

struct TodaysSummaryCard: View { // swiftlint:disable:this type_body_length
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Dependencies
    @Injected(\.debugLogger) private var logger
    @Injected(\.subscriptionService) private var subscriptionService

    // MARK: - Tips
    private let tapHabitTip = TapHabitTip()
    private let tapCompletedHabitTip = TapCompletedHabitTip()
    private let longPressLogTip = LongPressLogTip()
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
    
    @State private var isCompletedViewCompact = true  // Compact view shows only emoji circles
    @State private var isRemainingViewCompact = false  // Remaining habits show expanded by default (user needs to see what to do)
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?
    @State private var showingScheduleInfoSheet = false
    @State private var showingNoHabitsInfoSheet = false
    @State private var habitToUncomplete: Habit?
    @State private var animatingHabitId: UUID?
    @State private var glowingHabitId: UUID?
    @State private var animatingProgress: Double = 0.0
    @State private var isAnimatingCompletion = false
    @State private var habitAnimatedProgress: [UUID: Double] = [:] // Track animated progress per habit
    @State private var isPremiumUser = false
    @State private var longPressHabitId: UUID? // Currently long-pressed habit
    @State private var longPressProgress: Double = 0.0 // Progress of long-press (0.0 to 1.0)
    @State private var recentlyCompletedViaLongPress: Set<UUID> = [] // Habits that just completed via long-press (show checkmark briefly)

    // Task references for proper cancellation on view disappear
    @State private var quickActionGlowTask: Task<Void, Never>?
    @State private var habitRowGlowTask: Task<Void, Never>?
    @State private var completionAnimationTask: Task<Void, Never>?
    @State private var longPressCompletionTasks: [UUID: Task<Void, Never>] = [:] // Per-habit long-press completion animation tasks

    // Animation timing constants (in nanoseconds)
    private enum AnimationTiming {
        static let completionGlowDelay: UInt64 = 500_000_000          // 0.5s - completion glow duration
        static let completionAnimationDelay: UInt64 = 800_000_000     // 0.8s - completion animation duration
        static let animationCleanupDelay: UInt64 = 500_000_000        // 0.5s - cleanup delay after animation
        static let longPressCheckmarkDisplay: UInt64 = 1_500_000_000  // 1.5s - checkmark display after long-press
    }

    // PERFORMANCE: Pre-computed arrays to avoid creating NEW arrays on every render
    @State private var visibleIncompleteHabits: [Habit] = []
    @State private var visibleCompletedHabits: [Habit] = []
    @State private var scheduledIncompleteCount: Int = 0  // Track filtered count for display

    // Icon visibility settings (persisted in UserDefaults)
    @AppStorage(UserDefaultsKeys.showTimeReminderIcon) private var showTimeReminderIcon = true
    @AppStorage(UserDefaultsKeys.showLocationIcon) private var showLocationIcon = true
    @AppStorage(UserDefaultsKeys.showScheduleIcon) private var showScheduleIcon = true
    @AppStorage(UserDefaultsKeys.showStreakAtRiskIcon) private var showStreakAtRiskIcon = true

    // Computed ID that changes when any numeric habit progress changes
    private var habitProgressStateId: String {
        guard let summary = summary else { return "" }
        return summary.incompleteHabits
            .filter { $0.kind == .numeric }
            .map { "\($0.id.uuidString)-\(getProgress($0))" }
            .joined(separator: "|")
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

    // MARK: - Progress Calculation Helper

    /// Calculates progress percentage using truncated integers to match text display
    /// - Parameters:
    ///   - current: Current progress value
    ///   - target: Target/goal value
    /// - Returns: Progress as a percentage (0.0 to 1.0)
    private func calculateProgress(current: Double, target: Double) -> Double {
        // Use truncated integers to match the text display (e.g., "4/5")
        // This prevents visual mismatch where text shows "4/5" but circle shows 4.8/5.0 = 96%
        let currentInt = Int(current)
        let targetInt = Int(target)
        return targetInt > 0 ? min(max(Double(currentInt) / Double(targetInt), 0.0), 1.0) : 0.0
    }

    // Update habit progress animations when data changes
    private func updateHabitProgressAnimations() {
        guard let summary = summary else { return }

        // Get current incomplete habit IDs
        let currentHabitIds = Set(summary.incompleteHabits.filter { $0.kind == .numeric }.map { $0.id })

        // Remove progress for habits that are no longer in the list
        habitAnimatedProgress = habitAnimatedProgress.filter { currentHabitIds.contains($0.key) }

        // Update all incomplete numeric habits only
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
            } else {
                // Already tracked, animate from previous value
                withAnimation(.easeInOut(duration: 0.5)) {
                    habitAnimatedProgress[habit.id] = actualProgress
                }
            }
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
        .onChange(of: summary?.completedHabitsCount) { _, _ in
            updateVisibleHabits()
            updateHabitProgressAnimations()
            // Clear any stale long-press completion indicators when habits move between sections
            recentlyCompletedViaLongPress.removeAll()
        }
        .onChange(of: summary?.totalHabits) { _, _ in updateVisibleHabits() }
        .onChange(of: summary?.incompleteHabits.count) { _, _ in updateHabitProgressAnimations() }
        .onChange(of: habitProgressStateId) { _, _ in updateHabitProgressAnimations() }
        .onChange(of: viewingDate) { _, _ in updateVisibleHabits(); updateHabitProgressAnimations() }
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

    // MARK: - Progress Bar Helpers

    /// Calculate gradient colors based on completion percentage
    /// Delegates to CircularProgressView.adaptiveProgressColors to maintain consistency
    private func progressGradientColors(for completion: Double) -> [Color] {
        CircularProgressView.adaptiveProgressColors(for: completion)
    }

    @ViewBuilder
    private func quickActionButton(for habit: Habit) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !scheduleStatus.isAvailable

        Button {
            handleQuickActionTap(habit: habit, scheduleStatus: scheduleStatus)
        } label: {
            quickActionButtonLabel(habit: habit, scheduleStatus: scheduleStatus, isDisabled: isDisabled)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.7 : 1.0)
        .scaleEffect(1.0)
        .completionGlow(isGlowing: glowingHabitId == habit.id)
    }

    private func handleQuickActionTap(habit: Habit, scheduleStatus: HabitScheduleStatus) {
        guard scheduleStatus.isAvailable else { return }
        // Auto-dismiss the "tap to log" tip when user performs the action
        // IMPORTANT: Also donate wasDismissed to enable tip chain progression
        TapHabitTip.wasDismissed.sendDonation()
        tapHabitTip.invalidate(reason: .actionPerformed)
        if habit.kind == .numeric {
            onNumericHabitAction?(habit)
        } else {
            // Show confirmation sheet for binary habits
            onBinaryHabitAction?(habit)
        }
    }

    @ViewBuilder
    private func quickActionButtonLabel(habit: Habit, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
        HStack(spacing: 12) {
            quickActionProgressIndicator(habit: habit)
            quickActionTextContent(habit: habit, scheduleStatus: scheduleStatus, isDisabled: isDisabled)
            Spacer()
            Image(systemName: isDisabled ? "minus.circle" : "plus.circle.fill")
                .font(CardDesign.title2)
                .foregroundColor(isDisabled ? .secondary : AppColors.brand)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(isDisabled ? CardDesign.secondaryBackground.opacity(0.5) : AppColors.brand.opacity(0.1))
        .cornerRadius(CardDesign.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .stroke(isDisabled ? Color.secondary.opacity(0.3) : AppColors.brand.opacity(0.2), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func quickActionProgressIndicator(habit: Habit) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: habit.colorHex).opacity(0.15))
                .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)

            if habit.kind == .numeric {
                let currentValue = getProgress(habit)
                let target = habit.dailyTarget ?? 1.0
                let actualProgress = calculateProgress(current: currentValue, target: target)
                let animatedProgress = habitAnimatedProgress[habit.id] ?? actualProgress

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        .linearGradient(
                            colors: progressGradientColors(for: actualProgress),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
                    .rotationEffect(.degrees(-90))
            }

            Text(habit.emoji ?? "📊").font(CardDesign.title2)
        }
    }

    @ViewBuilder
    private func quickActionTextContent(habit: Habit, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Strings.Overview.nextHabit(habit.name))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(isDisabled ? .primary.opacity(0.6) : .primary)

            if isDisabled {
                Text(scheduleStatus.displayText)
                    .font(CardDesign.caption)
                    .foregroundColor(scheduleStatus.color)
            } else if habit.kind == .numeric {
                let currentValue = getProgress(habit)
                let target = habit.dailyTarget ?? 1.0
                let unitText = habit.unitLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                Text("\(Int(currentValue))/\(Int(target)) \(!unitText.isEmpty ? unitText : "units")")
                    .font(CardDesign.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        // Loading progress bar placeholder
        RoundedRectangle(cornerRadius: 4)
            .fill(CardDesign.secondaryBackground)
            .frame(height: 8)
            .redacted(reason: .placeholder)
            .accessibilityLabel(Strings.Accessibility.loadingHabits)
    }

    @ViewBuilder
    private var noHabitsScheduledView: some View {
        HStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary.opacity(0.6))
                .accessibilityHidden(true) // Decorative icon

            Text(Strings.EmptyState.noHabitsScheduled)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.secondary)

            Button {
                showingNoHabitsInfoSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(Strings.Accessibility.noHabitsInfoButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.noHabitsScheduledAccessibility)
        .sheet(isPresented: $showingNoHabitsInfoSheet) {
            NoHabitsScheduledInfoSheet()
        }
    }

    // MARK: - Enhanced Habits Section

    /// Grid columns for iPad layout
    private var iPadGrid: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: BusinessConstants.iPadHabitGridColumns)
    }

    @ViewBuilder
    private func habitsSection(summary: TodaysSummary) -> some View {
        // iPad: 3-column grid within each section
        // iPhone: stacked layout
        if horizontalSizeClass == .regular {
            VStack(alignment: .leading, spacing: 16) {
                // Remaining section - only show if there are remaining habits
                // Supports compact view (emoji circles only) and expanded view (full habit rows)
                if scheduledIncompleteCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        remainingSectionHeader(count: scheduledIncompleteCount)

                        if isRemainingViewCompact {
                            compactRemainingCircles(habits: visibleIncompleteHabits)
                                .padding(.horizontal, 12)
                        } else {
                            LazyVGrid(columns: iPadGrid, spacing: 8) {
                                ForEach(visibleIncompleteHabits, id: \.id) { habit in
                                    habitRow(habit: habit, isCompleted: false)
                                }
                            }
                        }
                    }
                }

                // Completed section - only show if there are completed habits
                // Supports compact view (emoji circles only) and expanded view (full habit rows)
                if !summary.completedHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        completedSectionHeader(count: summary.completedHabits.count)

                        if isCompletedViewCompact {
                            compactCompletedCircles(habits: summary.completedHabits)
                                .padding(.horizontal, 12)
                        } else {
                            LazyVGrid(columns: iPadGrid, spacing: 8) {
                                ForEach(summary.completedHabits, id: \.id) { habit in
                                    habitRow(habit: habit, isCompleted: true)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            // iPhone: Stacked layout with labels
            VStack(alignment: .leading, spacing: 16) {
                // Remaining section - only show if there are remaining habits
                // Supports compact view (emoji circles only) and expanded view (full habit rows)
                if scheduledIncompleteCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        remainingSectionHeader(count: scheduledIncompleteCount)

                        if isRemainingViewCompact {
                            compactRemainingCircles(habits: visibleIncompleteHabits)
                                .padding(.horizontal, 12)
                        } else {
                            incompleteHabitsContent(summary: summary)
                        }
                    }
                }

                // Completed section - only show if there are completed habits
                // Supports compact view (emoji circles only) and expanded view (full habit rows)
                if !summary.completedHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        completedSectionHeader(count: summary.completedHabits.count)

                        if isCompletedViewCompact {
                            compactCompletedCircles(habits: summary.completedHabits)
                                .padding(.horizontal, 12)
                        } else {
                            completedHabitsContent(summary: summary)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func incompleteHabitsContent(summary: TodaysSummary) -> some View {
        if scheduledIncompleteCount > 0 {
            VStack(spacing: 8) {
                ForEach(Array(visibleIncompleteHabits.enumerated()), id: \.element.id) { index, habit in
                    incompleteHabitItem(habit: habit, isFirstItem: index == 0)
                }
            }
        }
    }

    @ViewBuilder
    private func incompleteHabitItem(habit: Habit, isFirstItem: Bool) -> some View {
        if isFirstItem {
            VStack(spacing: 4) {
                // Show tap tip OR long-press tip based on TipKit rules
                // Status observers donate chain events on ANY dismissal (X button or action)
                TipView(tapHabitTip, arrowEdge: .bottom)
                    .task {
                        for await status in tapHabitTip.statusUpdates {
                            if case .invalidated = status {
                                TapHabitTip.wasDismissed.sendDonation()
                                logger.log("Tap habit tip dismissed - completed habit tip enabled", level: .debug, category: .ui)
                            }
                        }
                    }
                TipView(longPressLogTip, arrowEdge: .bottom)
                    .task {
                        for await status in longPressLogTip.statusUpdates {
                            // Only donate chain events for X button dismissal (.tipClosed)
                            // For programmatic dismissal (.actionPerformed), we donate in onComplete
                            // after the habit is actually completed and moved
                            if case .invalidated(let reason) = status, reason == .tipClosed {
                                LongPressLogTip.wasDismissed.sendDonation()
                                CircleProgressTip.longPressTipDismissed.sendDonation()
                                logger.log("Long-press tip X-dismissed - circle progress tip enabled", level: .debug, category: .ui)
                            }
                        }
                    }
                habitRow(habit: habit, isCompleted: false)
            }
            .onAppear {
                logger.log("First incomplete habit row appeared - tip should show if eligible", level: .debug, category: .ui)
            }
        } else {
            habitRow(habit: habit, isCompleted: false)
        }
    }

    @ViewBuilder
    private func completedHabitsContent(summary: TodaysSummary) -> some View {
        VStack(spacing: 6) {
            ForEach(Array(summary.completedHabits.enumerated()), id: \.element.id) { index, habit in
                completedHabitItem(habit: habit, isFirstItem: index == 0)
            }
        }
    }

    @ViewBuilder
    private func completedHabitItem(habit: Habit, isFirstItem: Bool) -> some View {
        if isFirstItem {
            VStack(spacing: 4) {
                // Status observer donates chain events on ANY dismissal (X button or action)
                TipView(tapCompletedHabitTip, arrowEdge: .bottom)
                    .task {
                        for await status in tapCompletedHabitTip.statusUpdates {
                            if case .invalidated = status {
                                TapCompletedHabitTip.wasDismissed.sendDonation()
                                LongPressLogTip.shouldShowLongPressTip.sendDonation()
                                logger.log("Completed habit tip dismissed - long-press tip enabled", level: .debug, category: .ui)
                            }
                        }
                    }
                habitRow(habit: habit, isCompleted: true)
            }
            .onAppear {
                logger.log("First completed habit row appeared - tip should show if eligible", level: .debug, category: .ui)
            }
        } else {
            habitRow(habit: habit, isCompleted: true)
        }
    }

    // MARK: - Compact Completed View

    /// Header for completed section with expand/collapse toggle
    @ViewBuilder
    private func completedSectionHeader(count: Int) -> some View {
        HStack {
            Text(Strings.Overview.completed)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isCompletedViewCompact.toggle()
                }
            } label: {
                Image(systemName: isCompletedViewCompact ? "plus.circle" : "minus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompletedViewCompact ? "Expand completed habits" : "Collapse completed habits")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }

    /// Compact view showing only habit emoji circles in a flowing layout
    @ViewBuilder
    private func compactCompletedCircles(habits: [Habit]) -> some View {
        // Use a flexible flow layout with wrapping
        FlowLayout(spacing: 8) {
            ForEach(habits, id: \.id) { habit in
                compactHabitCircle(habit: habit)
            }
        }
    }

    /// Single compact habit circle (36pt) with green background and border
    /// Tapping shows the uncomplete confirmation (binary) or adjustment sheet (numeric)
    @ViewBuilder
    private func compactHabitCircle(habit: Habit) -> some View {
        Button {
            // Same action as tapping a completed habit in expanded view
            // Dismiss tips and show appropriate sheet
            TapCompletedHabitTip.wasDismissed.sendDonation()
            LongPressLogTip.shouldShowLongPressTip.sendDonation()
            tapCompletedHabitTip.invalidate(reason: .actionPerformed)

            if habit.kind == .numeric {
                // Numeric: show adjustment sheet
                onNumericHabitAction?(habit)
            } else {
                // Binary: show uncomplete confirmation
                habitToUncomplete = habit
            }
        } label: {
            Text(habit.emoji ?? "✓")
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.green.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(habit.name), completed")
    }

    // MARK: - Compact Remaining View

    /// Header for remaining section with expand/collapse toggle
    @ViewBuilder
    private func remainingSectionHeader(count: Int) -> some View {
        HStack {
            Text(Strings.Overview.remaining)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.secondary)

            Spacer()

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isRemainingViewCompact.toggle()
                }
            } label: {
                Image(systemName: isRemainingViewCompact ? "plus.circle" : "minus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.brand)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isRemainingViewCompact ? "Expand remaining habits" : "Collapse remaining habits")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }

    /// Compact view showing only remaining habit emoji circles in a flowing layout
    @ViewBuilder
    private func compactRemainingCircles(habits: [Habit]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(habits, id: \.id) { habit in
                compactRemainingHabitCircle(habit: habit)
            }
        }
    }

    /// Single compact remaining habit circle (36pt) with brand color background and border
    /// Tapping shows the mark-complete confirmation (binary) or logging sheet (numeric)
    @ViewBuilder
    private func compactRemainingHabitCircle(habit: Habit) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !scheduleStatus.isAvailable || isLoggingLocked

        Button {
            guard !isDisabled else { return }
            // Same action as tapping an incomplete habit in expanded view
            // Dismiss tips and show appropriate sheet
            TapHabitTip.wasDismissed.sendDonation()
            tapHabitTip.invalidate(reason: .actionPerformed)

            if habit.kind == .numeric {
                onNumericHabitAction?(habit)
            } else {
                onBinaryHabitAction?(habit)
            }
        } label: {
            Text(habit.emoji ?? "📊")
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isDisabled ? Color.gray.opacity(0.1) : AppColors.brand.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(isDisabled ? Color.gray.opacity(0.2) : AppColors.brand.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        .accessibilityLabel("\(habit.name), remaining")
    }

    @ViewBuilder
    private func habitRow(habit: Habit, isCompleted: Bool) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        // Disable if: not available by schedule OR logging is locked (over habit limit)
        let isDisabled = !isCompleted && (!scheduleStatus.isAvailable || isLoggingLocked)
        // Long press only enabled if: not completed, available, has callback, AND not locked
        let canLongPress = !isCompleted && scheduleStatus.isAvailable && onLongPressComplete != nil && !isLoggingLocked

        HStack(spacing: 0) {
            habitRowMainButton(habit: habit, isCompleted: isCompleted, scheduleStatus: scheduleStatus, isDisabled: isDisabled)
            habitRowTrailingButton(habit: habit, isCompleted: isCompleted, scheduleStatus: scheduleStatus)
        }
        .padding(6)
        .background(habitRowBackground(isCompleted: isCompleted, isDisabled: isDisabled))
        .overlay(habitRowBorder(isCompleted: isCompleted, isDisabled: isDisabled))
        .opacity(isDisabled ? 0.6 : 1.0)
        .completionGlow(isGlowing: glowingHabitId == habit.id)
        .longPressProgress(
            duration: 0.8,
            isEnabled: canLongPress,
            progress: Binding(
                get: { longPressHabitId == habit.id ? longPressProgress : 0.0 },
                set: { newValue in
                    if newValue > 0 {
                        longPressHabitId = habit.id
                    }
                    longPressProgress = newValue
                }
            ),
            onStart: {
                // Track which habit is being long-pressed
                longPressHabitId = habit.id
                longPressProgress = 0.0
                // Dismiss tips when user starts learning the gesture
                // TapHabitTip chain event donated immediately (user is learning)
                TapHabitTip.wasDismissed.sendDonation()
                tapHabitTip.invalidate(reason: .actionPerformed)
                // LongPressLogTip dismissed visually, but chain event donated in onComplete
                // (after habit actually completes and moves to completed section)
                longPressLogTip.invalidate(reason: .actionPerformed)
            },
            onComplete: {
                // Quick-log the habit
                // For binary: completes the habit
                // For numeric: logs the daily target
                onLongPressComplete?(habit)

                // Add to recently completed set to keep checkmark visible
                recentlyCompletedViaLongPress.insert(habit.id)

                // Reset progress but delay clearing longPressHabitId to prevent button tap from firing
                longPressProgress = 0.0

                // Clear longPressHabitId after short delay (after button tap event passes)
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
                    longPressHabitId = nil
                }

                // Trigger tip for completed habits
                TapCompletedHabitTip.firstHabitCompleted.sendDonation()

                // Donate long-press tip chain events after short delay
                // This ensures avatar tip appears AFTER habit moves to completed section
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms - time for UI to update
                    LongPressLogTip.wasDismissed.sendDonation()
                    CircleProgressTip.longPressTipDismissed.sendDonation()
                    logger.log("Long-press complete - circle progress tip enabled", level: .debug, category: .ui)
                }

                // Schedule removal from recently completed set after delay
                longPressCompletionTasks[habit.id]?.cancel()
                longPressCompletionTasks[habit.id] = Task { @MainActor in
                    try? await Task.sleep(nanoseconds: AnimationTiming.longPressCheckmarkDisplay)
                    guard !Task.isCancelled else { return }
                    _ = withAnimation(.easeOut(duration: 0.3)) {
                        recentlyCompletedViaLongPress.remove(habit.id)
                    }
                    longPressCompletionTasks.removeValue(forKey: habit.id)
                }
            },
            onCancel: {
                // User released early - reset state
                longPressHabitId = nil
                longPressProgress = 0.0
            }
        )
    }

    @ViewBuilder
    private func habitRowMainButton(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
        Button {
            handleHabitRowTap(habit: habit, isCompleted: isCompleted, scheduleStatus: scheduleStatus)
        } label: {
            HStack(spacing: 12) {
                habitEmojiView(habit: habit, isCompleted: isCompleted)
                habitInfoView(habit: habit, isCompleted: isCompleted, isDisabled: isDisabled, scheduleStatus: scheduleStatus)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled((isDisabled && !isCompleted) || longPressHabitId == habit.id)
    }

    private func handleHabitRowTap(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus) {
        if isCompleted {
            // Auto-dismiss the "adjust completed habits" tip when user performs the action
            // IMPORTANT: Also donate wasDismissed events to enable tip chain progression
            TapCompletedHabitTip.wasDismissed.sendDonation()
            LongPressLogTip.shouldShowLongPressTip.sendDonation()
            tapCompletedHabitTip.invalidate(reason: .actionPerformed)
            if habit.kind == .numeric {
                onNumericHabitAction?(habit)
            } else {
                habitToUncomplete = habit
            }
        } else if scheduleStatus.isAvailable {
            // Auto-dismiss the "tap to log" tip when user performs the action
            // IMPORTANT: Also donate wasDismissed to enable tip chain progression
            TapHabitTip.wasDismissed.sendDonation()
            tapHabitTip.invalidate(reason: .actionPerformed)
            if habit.kind == .numeric {
                onNumericHabitAction?(habit)
            } else {
                // Show confirmation sheet for binary habits
                onBinaryHabitAction?(habit)
            }
        }
    }

    @ViewBuilder
    private func habitEmojiView(habit: Habit, isCompleted: Bool) -> some View {
        // Show long-press UI when this habit is being long-pressed (longPressHabitId is set on press start)
        let isLongPressing = longPressHabitId == habit.id
        let currentLongPressProgress = isLongPressing ? longPressProgress : 0.0
        // Only show long-press completion indicator for INCOMPLETE habits
        // Once a habit moves to Completed section, don't show the overlay
        let isRecentlyCompleted = !isCompleted && recentlyCompletedViaLongPress.contains(habit.id)

        // Crossfade threshold: emoji fades out and checkmark fades in between 0.8 and 1.0
        let crossfadeStart: Double = 0.8
        let emojiOpacity: Double = {
            if isRecentlyCompleted { return 0 }
            if !isLongPressing { return 1.0 }
            if currentLongPressProgress < crossfadeStart { return 1.0 }
            // Fade from 1.0 to 0.0 as progress goes from 0.8 to 1.0
            return max(0, 1.0 - (currentLongPressProgress - crossfadeStart) / (1.0 - crossfadeStart))
        }()
        let checkmarkOpacity: Double = {
            if isRecentlyCompleted { return 1.0 }
            if !isLongPressing { return 0 }
            if currentLongPressProgress < crossfadeStart { return 0 }
            // Fade from 0.0 to 1.0 as progress goes from 0.8 to 1.0
            return min(1.0, (currentLongPressProgress - crossfadeStart) / (1.0 - crossfadeStart))
        }()

        // Background turns green when checkmark is visible
        let showGreenBackground = isRecentlyCompleted || (isLongPressing && currentLongPressProgress >= crossfadeStart)

        ZStack {
            // Background circle - transitions to green as checkmark appears
            Circle()
                .fill(Color(hex: habit.colorHex).opacity(0.15))
                .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
                .overlay(
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .opacity(showGreenBackground ? 1 : 0)
                )

            // Numeric habit progress ring (shown when NOT long-pressing and NOT recently completed)
            if habit.kind == .numeric && !isCompleted && !isLongPressing && !isRecentlyCompleted {
                let currentValue = getProgress(habit)
                let target = habit.dailyTarget ?? 1.0
                let actualProgress = calculateProgress(current: currentValue, target: target)
                let animatedProgress = habitAnimatedProgress[habit.id] ?? actualProgress

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        .linearGradient(
                            colors: progressGradientColors(for: actualProgress),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
                    .rotationEffect(.degrees(-90))
            }

            // Long-press progress ring - always rendered, animates trim from 0 to 1
            Circle()
                .trim(from: 0, to: longPressHabitId == habit.id ? longPressProgress : 0.0)
                .stroke(
                    LinearGradient(
                        colors: [.green, .green.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
                .rotationEffect(.degrees(-90))
                .opacity(isLongPressing ? 1 : 0)
                .animation(.linear(duration: 0.65), value: longPressProgress)

            // Full green ring when recently completed (after long-press release)
            if isRecentlyCompleted && !isLongPressing {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [.green, .green.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
            }

            // Emoji - visible until 0.8, then fades out
            Text(habit.emoji ?? "📊")
                .font(CardDesign.title2)
                .opacity(emojiOpacity)

            // Checkmark - starts appearing at 0.8, fully visible at 1.0
            Image(systemName: "checkmark")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
                .opacity(checkmarkOpacity)
        }
        .animation(.easeInOut(duration: 0.3), value: isRecentlyCompleted)
    }

    @ViewBuilder
    private func habitInfoView(habit: Habit, isCompleted: Bool, isDisabled: Bool, scheduleStatus: HabitScheduleStatus) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isCompleted ? .gray : (isDisabled ? .secondary.opacity(0.7) : .primary))
                .strikethrough(isCompleted, color: .gray)
                .lineLimit(1)

            if habit.kind == .numeric {
                let currentValue = getProgress(habit)
                let target = habit.dailyTarget ?? 1.0
                Text("\(Int(currentValue))/\(Int(target)) \(habit.unitLabel ?? "units")")
                    .font(CardDesign.caption)
                    .foregroundColor(.gray)
            } else if !isCompleted && isDisabled {
                Text(scheduleStatus.displayText)
                    .font(CardDesign.caption)
                    .foregroundColor(scheduleStatus.color)
            }
        }
    }

    @ViewBuilder
    private func habitRowTrailingButton(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus) -> some View {
        if isCompleted {
            Button {
                habitToDelete = habit
                showingDeleteAlert = true
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gray.opacity(0.8))
                    .padding(.leading, 8)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            Button {
                showingScheduleInfoSheet = true
            } label: {
                HStack(spacing: 8) {
                    // Streak at risk indicator (first for urgency)
                    if showStreakAtRiskIcon, isViewingToday, let streakStatus = getStreakStatus?(habit), streakStatus.isAtRisk {
                        // Fire emoji with streak count badge overlay
                        ZStack(alignment: .topTrailing) {
                            Text("🔥")
                                .font(.system(size: 12))

                            // Badge with streak count
                            Text("\(streakStatus.atRisk)")
                                .font(.system(size: 8, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(
                                    Capsule()
                                        .fill(Color(red: 0.9, green: 0.45, blue: 0.1))
                                )
                                .offset(x: 4, y: -2)
                        }
                        .modifier(PulseAnimationModifier())
                    }

                    // Other indicators grouped with tighter spacing
                    HStack(spacing: 4) {
                        // Time-based reminders indicator (only for premium users with reminders)
                        if showTimeReminderIcon, isPremiumUser, !habit.reminders.isEmpty {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.orange)
                                .accessibilityLabel("Time-based reminders enabled")
                        }

                        // Location indicator (only for premium users with location enabled)
                        if showLocationIcon, isPremiumUser, habit.locationConfiguration?.isEnabled == true {
                            Image(systemName: "location.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.purple)
                                .accessibilityLabel("Location-based reminders enabled")
                        }

                        if showScheduleIcon {
                            HabitScheduleIndicator(status: scheduleStatus, size: .xlarge, style: .iconOnly)
                        }
                    }
                }
                .padding(.leading, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func habitRowBackground(isCompleted: Bool, isDisabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
            .fill(isCompleted ? Color.green.opacity(0.1) : (isDisabled ? CardDesign.secondaryBackground.opacity(0.5) : AppColors.brand.opacity(0.1)))
    }

    private func habitRowBorder(isCompleted: Bool, isDisabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
            .stroke(isCompleted ? Color.green.opacity(0.2) : (isDisabled ? Color.secondary.opacity(0.1) : AppColors.brand.opacity(0.2)), lineWidth: 1)
    }
    
    @ViewBuilder
    private func scheduleIcon(for schedule: HabitSchedule) -> some View {
        let (iconName, color) = scheduleIconInfo(for: schedule)
        
        Image(systemName: iconName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
    }
    
    private func scheduleIconInfo(for schedule: HabitSchedule) -> (String, Color) {
        switch schedule {
        case .daily:
            return ("arrow.clockwise", .blue)
        case .daysOfWeek(let days):
            return days.count == 7 ? ("arrow.clockwise", .blue) : ("calendar", .orange)
        }
    }

    // MARK: - Animation Methods
    
    private func performCompletionAnimation(for habit: Habit) {
        // Start completion animation
        animatingHabitId = habit.id
        isAnimatingCompletion = true
        animatingProgress = 0.0
        
        // Animate progress circle from 0 to 100%
        withAnimation(.easeInOut(duration: 0.6)) {
            animatingProgress = 1.0
        }

        // Cancel any existing completion animation task
        completionAnimationTask?.cancel()

        // After animation completes, fade and trigger actual completion
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        completionAnimationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: AnimationTiming.completionAnimationDelay)

            // Start fade out
            withAnimation(.easeOut(duration: 0.4)) {
                // Fade effect handled by opacity in view
            }

            // Complete the habit
            onQuickAction(habit)

            // Trigger tip for completed habits (so second tip can appear)
            TapCompletedHabitTip.firstHabitCompleted.sendDonation()
            logger.log("Habit completed - donated firstHabitCompleted event", level: .debug, category: .ui)

            // Clean up animation state
            try? await Task.sleep(nanoseconds: AnimationTiming.animationCleanupDelay)
            resetAnimationState()
        }
    }
    
    private func performRemovalAnimation(for habit: Habit) {
        // Start removal animation (reverse of completion)
        animatingHabitId = habit.id
        isAnimatingCompletion = false // Different animation type
        animatingProgress = 1.0
        
        // Animate progress circle from 100% to 0% (reverse)
        withAnimation(.easeInOut(duration: 0.6)) {
            animatingProgress = 0.0
        }

        // Cancel any existing completion animation task
        completionAnimationTask?.cancel()

        // After animation completes, fade and trigger actual removal
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        completionAnimationTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: AnimationTiming.completionAnimationDelay)

            // Start fade out
            withAnimation(.easeOut(duration: 0.4)) {
                // Fade effect handled by opacity in view
            }

            // Remove the habit log
            onDeleteHabitLog(habit)

            // Clean up animation state
            try? await Task.sleep(nanoseconds: AnimationTiming.animationCleanupDelay)
            resetAnimationState()
        }
    }
    
    private func resetAnimationState() {
        animatingHabitId = nil
        animatingProgress = 0.0
        isAnimatingCompletion = false
    }
}

// MARK: - No Habits Scheduled Info Sheet

private struct NoHabitsScheduledInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

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
                    Button(Strings.Button.done) {
                        dismiss()
                    }
                }
            }
        }
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
