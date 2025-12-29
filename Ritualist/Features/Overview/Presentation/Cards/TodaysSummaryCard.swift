import SwiftUI
import RitualistCore
import FactoryKit
import TipKit

struct TodaysSummaryCard: View { // swiftlint:disable:this type_body_length
    // MARK: - Environment
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    // MARK: - Dependencies
    @Injected(\.debugLogger) private var logger

    // MARK: - Tips
    private let tapHabitTip = TapHabitTip()
    private let tapCompletedHabitTip = TapCompletedHabitTip()
    let summary: TodaysSummary?
    let viewingDate: Date
    let isViewingToday: Bool
    let timezone: TimeZone
    let canGoToPrevious: Bool
    let canGoToNext: Bool
    let currentSlogan: String?
    let onQuickAction: (Habit) -> Void
    let onNumericHabitUpdate: ((Habit, Double) async throws -> Void)?
    let getProgress: ((Habit) -> Double)
    let onNumericHabitAction: ((Habit) -> Void)? // New callback for numeric habit sheet
    let onDeleteHabitLog: (Habit) -> Void // New callback for deleting habit log
    let getScheduleStatus: (Habit) -> HabitScheduleStatus // New callback for schedule status
    let getValidationMessage: (Habit) async -> String? // New callback for validation message
    let getStreakStatus: ((Habit) -> HabitStreakStatus)? // Callback for streak at risk indicator
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onGoToToday: () -> Void
    
    @State private var isCompletedSectionExpanded = false
    @State private var isRemainingSectionExpanded = true  // Show all remaining habits by default
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?
    @State private var showingScheduleInfoSheet = false
    @State private var habitToUncomplete: Habit?
    @State private var animatingHabitId: UUID?
    @State private var glowingHabitId: UUID?
    @State private var animatingProgress: Double = 0.0
    @State private var isAnimatingCompletion = false
    @State private var habitAnimatedProgress: [UUID: Double] = [:] // Track animated progress per habit

    // Task references for proper cancellation on view disappear
    @State private var quickActionGlowTask: Task<Void, Never>?
    @State private var habitRowGlowTask: Task<Void, Never>?
    @State private var completionAnimationTask: Task<Void, Never>?

    // Animation timing constants (in nanoseconds)
    private enum AnimationTiming {
        static let completionGlowDelay: UInt64 = 500_000_000          // 0.5s - completion glow duration
        static let completionAnimationDelay: UInt64 = 800_000_000     // 0.8s - completion animation duration
        static let animationCleanupDelay: UInt64 = 500_000_000        // 0.5s - cleanup delay after animation
    }

    // MARK: - Layout Configuration

    /// Default visible remaining items when collapsed
    private var defaultVisibleRemaining: Int {
        horizontalSizeClass == .regular
            ? BusinessConstants.iPadHabitGridColumns * BusinessConstants.iPadDefaultVisibleRemainingRows
            : BusinessConstants.iPhoneDefaultVisibleRemaining
    }

    /// Default visible completed items when collapsed
    private var defaultVisibleCompleted: Int {
        horizontalSizeClass == .regular
            ? BusinessConstants.iPadHabitGridColumns * BusinessConstants.iPadDefaultVisibleCompletedRows
            : BusinessConstants.iPhoneDefaultVisibleCompleted
    }

    // PERFORMANCE: Pre-computed arrays to avoid creating NEW arrays on every render
    @State private var visibleIncompleteHabits: [Habit] = []
    @State private var visibleCompletedHabits: [Habit] = []
    @State private var scheduledIncompleteCount: Int = 0  // Track filtered count for display

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
         currentSlogan: String? = nil,
         onQuickAction: @escaping (Habit) -> Void,
         onNumericHabitUpdate: ((Habit, Double) async throws -> Void)? = nil,
         getProgressSync: @escaping (Habit) -> Double,
         onNumericHabitAction: ((Habit) -> Void)? = nil,
         onDeleteHabitLog: @escaping (Habit) -> Void,
         getScheduleStatus: @escaping (Habit) -> HabitScheduleStatus,
         getValidationMessage: @escaping (Habit) async -> String?,
         getStreakStatus: ((Habit) -> HabitStreakStatus)? = nil,
         onPreviousDay: @escaping () -> Void,
         onNextDay: @escaping () -> Void,
         onGoToToday: @escaping () -> Void) {
        self.summary = summary
        self.viewingDate = viewingDate
        self.isViewingToday = isViewingToday
        self.timezone = timezone
        self.canGoToPrevious = canGoToPrevious
        self.canGoToNext = canGoToNext
        self.currentSlogan = currentSlogan
        self.onQuickAction = onQuickAction
        self.onNumericHabitUpdate = onNumericHabitUpdate
        self.getProgress = getProgressSync
        self.onNumericHabitAction = onNumericHabitAction
        self.onDeleteHabitLog = onDeleteHabitLog
        self.getScheduleStatus = getScheduleStatus
        self.getValidationMessage = getValidationMessage
        self.getStreakStatus = getStreakStatus
        self.onPreviousDay = onPreviousDay
        self.onNextDay = onNextDay
        self.onGoToToday = onGoToToday
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

        // Pre-compute incomplete habits array
        visibleIncompleteHabits = isRemainingSectionExpanded ?
            scheduledIncompleteHabits :
            Array(scheduledIncompleteHabits.prefix(defaultVisibleRemaining))

        // Pre-compute completed habits array (no need to filter - completed habits are always valid)
        visibleCompletedHabits = isCompletedSectionExpanded ?
            Array(summary.completedHabits.dropFirst(defaultVisibleCompleted)) :
            []
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
            Button("Cancel", role: .cancel) { habitToDelete = nil }
            Button("Remove", role: .destructive) {
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
        .onDisappear { cancelAllAnimationTasks() }
        .onChange(of: summary?.completedHabitsCount) { _, _ in updateVisibleHabits(); updateHabitProgressAnimations() }
        .onChange(of: summary?.totalHabits) { _, _ in updateVisibleHabits() }
        .onChange(of: summary?.incompleteHabits.count) { _, _ in updateHabitProgressAnimations() }
        .onChange(of: habitProgressStateId) { _, _ in updateHabitProgressAnimations() }
        .onChange(of: viewingDate) { _, _ in updateVisibleHabits(); updateHabitProgressAnimations() }
        .onChange(of: isRemainingSectionExpanded) { _, _ in updateVisibleHabits() }
        .onChange(of: isCompletedSectionExpanded) { _, _ in updateVisibleHabits() }
    }

    // MARK: - Body Helper Views

    @ViewBuilder
    private var dateNavigationHeader: some View {
        VStack(spacing: 12) {
            HStack {
                previousDayButton
                Spacer()
                dateTitle
                Spacer()
                nextDayButton
            }
        }
    }

    @ViewBuilder
    private var previousDayButton: some View {
        Button(action: onPreviousDay) {
            Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(canGoToPrevious ? .secondary : .secondary.opacity(0.3))
        }
        .disabled(!canGoToPrevious)
        .accessibilityLabel("Previous day")
        .accessibilityHint(Strings.Accessibility.previousDayHint)
        .accessibilityIdentifier(AccessibilityID.Overview.previousDayButton)
    }

    @ViewBuilder
    private var nextDayButton: some View {
        Button(action: onNextDay) {
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(canGoToNext ? .secondary : .secondary.opacity(0.3))
        }
        .disabled(!canGoToNext)
        .accessibilityLabel("Next day")
        .accessibilityHint(Strings.Accessibility.nextDayHint)
        .accessibilityIdentifier(AccessibilityID.Overview.nextDayButton)
    }

    @ViewBuilder
    private var dateTitle: some View {
        VStack(spacing: 4) {
            if isViewingToday {
                Text("Today, \(CalendarUtils.formatCompact(viewingDate, timezone: timezone))")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
            } else {
                HStack(spacing: 6) {
                    Button(action: onGoToToday) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("Return to today")
                    .accessibilityHint(Strings.Accessibility.returnToTodayHint)
                    .accessibilityIdentifier(AccessibilityID.Overview.todayButton)

                    Text(CalendarUtils.formatCompact(viewingDate, includeDayName: true, timezone: timezone))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .accessibilityAddTraits(.isHeader)
                }
            }
        }
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
        tapHabitTip.invalidate(reason: .actionPerformed)
        if habit.kind == .numeric {
            onNumericHabitAction?(habit)
        } else {
            glowingHabitId = habit.id
            quickActionGlowTask?.cancel()
            quickActionGlowTask = Task {
                try? await Task.sleep(nanoseconds: AnimationTiming.completionGlowDelay)
                onQuickAction(habit)
                glowingHabitId = nil
            }
        }
    }

    @ViewBuilder
    private func quickActionButtonLabel(habit: Habit, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
        HStack(spacing: 12) {
            quickActionProgressIndicator(habit: habit)
            quickActionTextContent(habit: habit, scheduleStatus: scheduleStatus, isDisabled: isDisabled)
            Spacer()
            Image(systemName: isDisabled ? "minus.circle" : "plus.circle.fill")
                .font(.title2)
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
                .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)

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
                    .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)
                    .rotationEffect(.degrees(-90))
            }

            Text(habit.emoji ?? "📊").font(.title3)
        }
    }

    @ViewBuilder
    private func quickActionTextContent(habit: Habit, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Next: \(habit.name)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(isDisabled ? .primary.opacity(0.6) : .primary)

            if isDisabled {
                Text(scheduleStatus.displayText)
                    .font(.caption)
                    .foregroundColor(scheduleStatus.color)
            } else if habit.kind == .numeric {
                let currentValue = getProgress(habit)
                let target = habit.dailyTarget ?? 1.0
                let unitText = habit.unitLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                Text("\(Int(currentValue))/\(Int(target)) \(!unitText.isEmpty ? unitText : "units")")
                    .font(.caption)
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Strings.Accessibility.noHabitsScheduledAccessibility)
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
                if scheduledIncompleteCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remaining")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)

                        LazyVGrid(columns: iPadGrid, spacing: 8) {
                            ForEach(visibleIncompleteHabits, id: \.id) { habit in
                                habitRow(habit: habit, isCompleted: false)
                            }
                        }

                        if scheduledIncompleteCount > defaultVisibleRemaining {
                            sectionToggleButton(
                                isExpanded: isRemainingSectionExpanded,
                                expandText: "+ \(scheduledIncompleteCount - defaultVisibleRemaining) more remaining",
                                color: AppColors.brand,
                                onToggle: { isRemainingSectionExpanded.toggle() }
                            )
                        }
                    }
                }

                // Completed section - only show if there are completed habits
                if !summary.completedHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completed")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)

                        LazyVGrid(columns: iPadGrid, spacing: 8) {
                            ForEach(summary.completedHabits.prefix(isCompletedSectionExpanded ? summary.completedHabits.count : defaultVisibleCompleted), id: \.id) { habit in
                                habitRow(habit: habit, isCompleted: true)
                            }
                        }

                        if summary.completedHabits.count > defaultVisibleCompleted {
                            sectionToggleButton(
                                isExpanded: isCompletedSectionExpanded,
                                expandText: "+ \(summary.completedHabits.count - defaultVisibleCompleted) more completed",
                                color: .green,
                                onToggle: { isCompletedSectionExpanded.toggle() }
                            )
                        }
                    }
                }
            }
        } else {
            // iPhone: Stacked layout with labels
            VStack(alignment: .leading, spacing: 16) {
                // Remaining section - only show if there are remaining habits
                if scheduledIncompleteCount > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remaining")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)

                        incompleteHabitsContent(summary: summary)
                    }
                }

                // Completed section - only show if there are completed habits
                if !summary.completedHabits.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Completed")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)

                        completedHabitsContent(summary: summary)
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

                if scheduledIncompleteCount > defaultVisibleRemaining {
                    sectionToggleButton(
                        isExpanded: isRemainingSectionExpanded,
                        expandText: "+ \(scheduledIncompleteCount - defaultVisibleRemaining) more remaining",
                        color: AppColors.brand,
                        onToggle: { isRemainingSectionExpanded.toggle() }
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func incompleteHabitItem(habit: Habit, isFirstItem: Bool) -> some View {
        if isFirstItem {
            VStack(spacing: 4) {
                TipView(tapHabitTip, arrowEdge: .bottom) { _ in
                    TapCompletedHabitTip.shouldShowCompletedTip.sendDonation()
                    logger.log("First tip dismissed - donated shouldShowCompletedTip event", level: .debug, category: .ui)
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
            ForEach(Array(summary.completedHabits.prefix(defaultVisibleCompleted).enumerated()), id: \.element.id) { index, habit in
                completedHabitItem(habit: habit, isFirstItem: index == 0)
            }

            if summary.completedHabits.count > defaultVisibleCompleted {
                completedHabitsExpandableSection(summary: summary)
            }
        }
    }

    @ViewBuilder
    private func completedHabitItem(habit: Habit, isFirstItem: Bool) -> some View {
        if isFirstItem {
            VStack(spacing: 4) {
                TipView(tapCompletedHabitTip, arrowEdge: .bottom)
                habitRow(habit: habit, isCompleted: true)
            }
            .onAppear {
                logger.log("First completed habit row appeared - tip should show if eligible", level: .debug, category: .ui)
            }
        } else {
            habitRow(habit: habit, isCompleted: true)
        }
    }

    @ViewBuilder
    private func completedHabitsExpandableSection(summary: TodaysSummary) -> some View {
        if isCompletedSectionExpanded {
            ForEach(visibleCompletedHabits, id: \.id) { habit in
                habitRow(habit: habit, isCompleted: true)
            }
        }

        sectionToggleButton(
            isExpanded: isCompletedSectionExpanded,
            expandText: "+ \(summary.completedHabits.count - defaultVisibleCompleted) more completed",
            color: .green,
            onToggle: { isCompletedSectionExpanded.toggle() }
        )
    }

    @ViewBuilder
    private func sectionToggleButton(isExpanded: Bool, expandText: String, color: Color, onToggle: @escaping () -> Void) -> some View {
        Button(action: onToggle) {
            HStack {
                Text(isExpanded ? "Show less" : expandText)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(color)

                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.top, isExpanded ? 4 : 2)
    }

    @ViewBuilder
    private func habitRow(habit: Habit, isCompleted: Bool) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !isCompleted && !scheduleStatus.isAvailable

        HStack(spacing: 0) {
            habitRowMainButton(habit: habit, isCompleted: isCompleted, scheduleStatus: scheduleStatus, isDisabled: isDisabled)
            habitRowTrailingButton(habit: habit, isCompleted: isCompleted, scheduleStatus: scheduleStatus)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(habitRowBackground(isCompleted: isCompleted, isDisabled: isDisabled))
        .overlay(habitRowBorder(isCompleted: isCompleted, isDisabled: isDisabled))
        .opacity(isDisabled ? 0.6 : 1.0)
        .completionGlow(isGlowing: glowingHabitId == habit.id)
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
        .disabled(isDisabled && !isCompleted)
    }

    private func handleHabitRowTap(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus) {
        if isCompleted {
            // Auto-dismiss the "adjust completed habits" tip when user performs the action
            tapCompletedHabitTip.invalidate(reason: .actionPerformed)
            if habit.kind == .numeric {
                onNumericHabitAction?(habit)
            } else {
                habitToUncomplete = habit
            }
        } else if scheduleStatus.isAvailable {
            // Auto-dismiss the "tap to log" tip when user performs the action
            tapHabitTip.invalidate(reason: .actionPerformed)
            if habit.kind == .numeric {
                onNumericHabitAction?(habit)
            } else {
                glowingHabitId = habit.id
                performCompletionAnimation(for: habit)
                habitRowGlowTask?.cancel()
                habitRowGlowTask = Task {
                    try? await Task.sleep(nanoseconds: AnimationTiming.completionGlowDelay)
                    glowingHabitId = nil
                }
            }
        }
    }

    @ViewBuilder
    private func habitEmojiView(habit: Habit, isCompleted: Bool) -> some View {
        ZStack {
            Circle()
                .fill(Color(hex: habit.colorHex).opacity(0.15))
                .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)

            if habit.kind == .numeric && !isCompleted {
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
                    .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)
                    .rotationEffect(.degrees(-90))
            }

            Text(habit.emoji ?? "📊")
                .font(.title3)
        }
    }

    @ViewBuilder
    private func habitInfoView(habit: Habit, isCompleted: Bool, isDisabled: Bool, scheduleStatus: HabitScheduleStatus) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isCompleted ? .gray : (isDisabled ? .secondary.opacity(0.7) : .primary))
                .strikethrough(isCompleted, color: .gray)
                .lineLimit(1)

            if habit.kind == .numeric {
                let currentValue = getProgress(habit)
                let target = habit.dailyTarget ?? 1.0
                Text("\(Int(currentValue))/\(Int(target)) \(habit.unitLabel ?? "units")")
                    .font(.caption)
                    .foregroundColor(.gray)
            } else if !isCompleted && isDisabled {
                Text(scheduleStatus.displayText)
                    .font(.caption)
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
                HStack(spacing: 6) {
                    if isViewingToday, let streakStatus = getStreakStatus?(habit), streakStatus.isAtRisk {
                        HStack(spacing: 2) {
                            Text("\(streakStatus.atRisk)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("🔥").font(.system(size: 12))
                        }
                        .modifier(PulseAnimationModifier())
                    }
                    HabitScheduleIndicator(status: scheduleStatus, size: .medium, style: .iconOnly)
                }
                .padding(.leading, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private func habitRowBackground(isCompleted: Bool, isDisabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: CardDesign.innerCornerRadius)
            .fill(isCompleted ? Color.green.opacity(0.1) : (isDisabled ? CardDesign.secondaryBackground.opacity(0.5) : AppColors.brand.opacity(0.1)))
    }

    private func habitRowBorder(isCompleted: Bool, isDisabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: CardDesign.innerCornerRadius)
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
        // Note: Task inherits MainActor context from View, no MainActor.run needed
        completionAnimationTask = Task {
            try? await Task.sleep(nanoseconds: AnimationTiming.completionAnimationDelay)

            // Start fade out
            withAnimation(.easeOut(duration: 0.4)) {
                // Fade effect handled by opacity in view
            }

            // Complete the habit
            onQuickAction(habit)

            // Trigger tip for completed habits (so second tip can appear)
            TapCompletedHabitTip.shouldShowCompletedTip.sendDonation()
            logger.log("Habit completed - donated shouldShowCompletedTip event", level: .debug, category: .ui)

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
        // Note: Task inherits MainActor context from View, no MainActor.run needed
        completionAnimationTask = Task {
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
            onGoToToday: { }
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
            onGoToToday: { }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
