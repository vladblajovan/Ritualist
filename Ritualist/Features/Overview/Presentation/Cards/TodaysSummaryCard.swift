import SwiftUI
import RitualistCore
import FactoryKit
import TipKit


struct TodaysSummaryCard: View { // swiftlint:disable:this type_body_length
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
    @State private var animatingHabitId: UUID? = nil
    @State private var glowingHabitId: UUID? = nil
    @State private var animatingProgress: Double = 0.0
    @State private var isAnimatingCompletion = false
    @State private var showProgressGlow = false
    @State private var animatedCompletionPercentage: Double = 0.0
    @State private var hasInitializedProgress = false
    @State private var habitAnimatedProgress: [UUID: Double] = [:] // Track animated progress per habit

    // Task references for proper cancellation on view disappear
    @State private var progressGlowTask: Task<Void, Never>?
    @State private var quickActionGlowTask: Task<Void, Never>?
    @State private var habitRowGlowTask: Task<Void, Never>?
    @State private var completionAnimationTask: Task<Void, Never>?

    // CONFIGURATION: Set to false to disable progress bar animation on initial load
    // When true (default), the progress bar will animate from 0% to current value when the view first appears
    // When false, it will immediately show the current value without animation
    private let animateProgressOnLoad: Bool = true

    // Animation timing constants (in nanoseconds)
    private enum AnimationTiming {
        static let progressAnimationDelay: UInt64 = 600_000_000       // 0.6s - match progress bar animation
        static let glowFadeDelay: UInt64 = 2_000_000_000              // 2s - glow fade out delay
        static let completionGlowDelay: UInt64 = 500_000_000          // 0.5s - completion glow duration
        static let completionAnimationDelay: UInt64 = 800_000_000     // 0.8s - completion animation duration
        static let animationCleanupDelay: UInt64 = 500_000_000        // 0.5s - cleanup delay after animation
    }

    // App name from bundle (uses display name if available, falls back to bundle name)
    private static let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        ?? "Ritualist"

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

    // Date formatters - use instance method to respect timezone parameter
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }

    private func formatTodayDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy" // e.g., "16 August 2025"
        formatter.timeZone = timezone
        return formatter.string(from: date)
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
            Array(scheduledIncompleteHabits.prefix(3))

        // Pre-compute completed habits array (no need to filter - completed habits are always valid)
        visibleCompletedHabits = isCompletedSectionExpanded ?
            Array(summary.completedHabits.dropFirst(2)) :
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
            // Card Title and Progress Bar - grouped with smaller spacing
            VStack(alignment: .leading, spacing: 12) {
                // Card Title - gradient flows continuously across icon and text
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.title2)
                    Text(Self.appName)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .overlay(
                    LinearGradient(
                        colors: progressGradientColors(for: summary?.completionPercentage ?? 0.0),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .mask(
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.title2)
                            Text(Self.appName)
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    )
                )
                .shadow(
                    color: showProgressGlow ? Color.green.opacity(0.6) : .clear,
                    radius: showProgressGlow ? 8 : 0,
                    x: 0,
                    y: 0
                )

                if let summary = summary {
                    // Main Progress Section - Full Width
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(CardDesign.secondaryBackground)
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    .linearGradient(
                                        colors: progressGradientColors(for: animatedCompletionPercentage),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * animatedCompletionPercentage, height: 8)
                                .shadow(
                                    color: showProgressGlow ? Color.green.opacity(0.6) : .clear,
                                    radius: showProgressGlow ? 8 : 0,
                                    x: 0,
                                    y: 0
                                )
                        }
                    }
                    .frame(height: 8)
                }
            }

            // Card Header with Date Navigation
            VStack(spacing: 12) {
                HStack {
                    // Previous Day Button
                    Button(action: onPreviousDay) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(canGoToPrevious ? .secondary : .secondary.opacity(0.3))
                    }
                    .disabled(!canGoToPrevious)
                    .accessibilityLabel("Previous day")
                    .accessibilityHint(Strings.Accessibility.previousDayHint)
                    .accessibilityIdentifier(AccessibilityID.Overview.previousDayButton)

                    Spacer()

                    // Date and Title
                    VStack(spacing: 4) {
                        if isViewingToday {
                            Text("Today, \(formatTodayDate(CalendarUtils.startOfDayLocal(for: Date(), timezone: timezone)))")
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

                                Text(CalendarUtils.formatForDisplay(viewingDate, style: .full, timezone: timezone))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .accessibilityAddTraits(.isHeader)
                            }
                        }
                    }

                    Spacer()

                    // Next Day Button
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
            }

            if let summary = summary {

                // Enhanced Habits Section - show both completed and incomplete habits
                if !summary.incompleteHabits.isEmpty || !summary.completedHabits.isEmpty {
                    habitsSection(summary: summary)
                } else {
                    // Empty state - no habits scheduled for this day
                    noHabitsScheduledView
                }
            } else {
                // Loading State
                loadingView
            }
        }
        .glassmorphicContentStyle()
        .accessibilityIdentifier(AccessibilityID.Overview.todaysSummaryCard)
        .alert("Remove Log Entry?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
            Button("Remove", role: .destructive) {
                if let habit = habitToDelete {
                    performRemovalAnimation(for: habit)
                }
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text("This will remove the log entry for \"\(habit.name)\" from \(isViewingToday ? "today" : formatDate(viewingDate)). The habit itself will remain.")
            }
        }
        .sheet(isPresented: $showingScheduleInfoSheet) {
            ScheduleIconInfoSheet()
        }
        .sheet(item: $habitToUncomplete) { habit in
            UncompleteHabitSheet(
                habit: habit,
                onUncomplete: {
                    onDeleteHabitLog(habit)
                    habitToUncomplete = nil
                },
                onCancel: {
                    habitToUncomplete = nil
                }
            )
        }
        // PERFORMANCE: Update pre-computed arrays when data or expansion state changes
        .onAppear {
            updateVisibleHabits()
            updateHabitProgressAnimations()
            // Note: animatedCompletionPercentage starts at 0.0
            // The onChange handler will handle initial animation based on animateProgressOnLoad flag
        }
        .onDisappear {
            // Cancel all running animation tasks to prevent memory leaks
            progressGlowTask?.cancel()
            quickActionGlowTask?.cancel()
            habitRowGlowTask?.cancel()
            completionAnimationTask?.cancel()
        }
        .onChange(of: summary?.completedHabitsCount) { _, _ in
            updateVisibleHabits()
            updateHabitProgressAnimations()
        }
        .onChange(of: summary?.totalHabits) { _, _ in
            updateVisibleHabits()
        }
        .onChange(of: summary?.incompleteHabits.count) { _, _ in
            updateHabitProgressAnimations()
        }
        .onChange(of: habitProgressStateId) { _, _ in
            updateHabitProgressAnimations()
        }
        .onChange(of: viewingDate) { _, _ in
            // When date changes, update visible habits list and animations
            updateVisibleHabits()
            updateHabitProgressAnimations()
        }
        .onChange(of: isRemainingSectionExpanded) { _, _ in
            updateVisibleHabits()
        }
        .onChange(of: isCompletedSectionExpanded) { _, _ in
            updateVisibleHabits()
        }
        .onChange(of: summary?.completionPercentage) { oldValue, newValue in
            guard let newValue = newValue else { return }

            // Determine if we should animate this change
            // First time: animate only if animateProgressOnLoad is true
            // Subsequent times: always animate
            let shouldAnimate = hasInitializedProgress ? true : animateProgressOnLoad

            // Animate the progress bar filling/draining smoothly
            if shouldAnimate {
                withAnimation(.easeInOut(duration: 0.6)) {
                    animatedCompletionPercentage = newValue
                }
            } else {
                // No animation - instant update
                animatedCompletionPercentage = newValue
            }

            // Mark as initialized after first change
            hasInitializedProgress = true

            // Trigger glow when reaching 100% completion (only if animated)
            if shouldAnimate && newValue >= 1.0, oldValue ?? 0.0 < 1.0 {
                // Cancel any existing glow task
                progressGlowTask?.cancel()

                // Delay glow until progress animation completes
                // Note: Task inherits MainActor context from View, no MainActor.run needed
                progressGlowTask = Task {
                    try? await Task.sleep(nanoseconds: AnimationTiming.progressAnimationDelay)
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showProgressGlow = true
                    }

                    // Fade out the glow after 2 seconds
                    try? await Task.sleep(nanoseconds: AnimationTiming.glowFadeDelay)
                    withAnimation(.easeOut(duration: 0.5)) {
                        showProgressGlow = false
                    }
                }
            }
        }
    }
    
    // MARK: - Progress Bar Helpers

    /// Calculate gradient colors based on completion percentage
    /// Delegates to CircularProgressView.adaptiveProgressColors to maintain consistency
    private func progressGradientColors(for completion: Double) -> [Color] {
        return CircularProgressView.adaptiveProgressColors(for: completion)
    }

    @ViewBuilder
    private func quickActionButton(for habit: Habit) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !scheduleStatus.isAvailable
        
        Button {
            if scheduleStatus.isAvailable {
                if habit.kind == .numeric {
                    onNumericHabitAction?(habit)
                } else {
                    // For binary habits, complete with glow effect
                    glowingHabitId = habit.id

                    // Cancel any existing quick action glow task
                    quickActionGlowTask?.cancel()

                    // Small delay for glow effect, then complete
                    // Note: Task inherits MainActor context from View, no MainActor.run needed
                    quickActionGlowTask = Task {
                        try? await Task.sleep(nanoseconds: AnimationTiming.completionGlowDelay)
                        onQuickAction(habit)
                        glowingHabitId = nil
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Circular Progress Indicator with Emoji
                ZStack {
                    // Background circle with habit color at low opacity
                    Circle()
                        .fill(Color(hex: habit.colorHex).opacity(0.15))
                        .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)

                    // Progress border for numeric habits with animated gradient
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

                    // Emoji
                    Text(habit.emoji ?? "📊")
                        .font(.title3)
                }
                
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
                
                Spacer()
                
                Image(systemName: isDisabled ? "minus.circle" : (habit.kind == .numeric ? "plus.circle.fill" : "plus.circle.fill"))
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
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.7 : 1.0)
        .scaleEffect(1.0)
        .completionGlow(isGlowing: glowingHabitId == habit.id)
        // PERFORMANCE: Removed animation on completedHabits changes - expensive for entire view
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
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 36))
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

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func habitsSection(summary: TodaysSummary) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // TEMPORARY: Commented out "Up Next" header until we find a better UX approach
            // The habits list is self-explanatory and the header adds visual clutter
            // if scheduledIncompleteCount > 0 {
            //     HStack {
            //         Text("Up Next")
            //             .font(.system(size: 15, weight: .semibold))
            //             .foregroundColor(.primary)
            //             .padding(.leading, 12)
            //
            //         Spacer()
            //
            //         Text("\(scheduledIncompleteCount)")
            //             .font(.system(size: 13, weight: .medium, design: .rounded))
            //             .foregroundColor(AppColors.brand)
            //             .padding(.horizontal, 8)
            //             .padding(.vertical, 2)
            //             .background(
            //                 RoundedRectangle(cornerRadius: 6)
            //                     .fill(AppColors.brand.opacity(0.1))
            //             )
            //             .padding(.trailing, 8)
            //     }
            // }

            // Incomplete habits
            if scheduledIncompleteCount > 0 {
                VStack(spacing: 8) {
                    // Show first 3 habits, or all if expanded
                    // PERFORMANCE: Use pre-computed array instead of creating NEW array on every render
                    ForEach(Array(visibleIncompleteHabits.enumerated()), id: \.element.id) { index, habit in
                        if index == 0 {
                            // Use TipView for the first incomplete habit to ensure tip shows
                            VStack(spacing: 4) {
                                TipView(tapHabitTip, arrowEdge: .bottom) { action in
                                    // When first tip is dismissed, trigger second tip eligibility
                                    TapCompletedHabitTip.shouldShowCompletedTip.sendDonation()
                                    tipLogger.info("📤 First tip dismissed - donated shouldShowCompletedTip event")
                                }
                                habitRow(habit: habit, isCompleted: false)
                            }
                            .onAppear {
                                tipLogger.info("🎯 First incomplete habit row appeared - tip should show if eligible")
                            }
                        } else {
                            habitRow(habit: habit, isCompleted: false)
                        }
                    }

                    if scheduledIncompleteCount > 3 {
                        if isRemainingSectionExpanded {
                            // Collapse button
                            Button {
                                isRemainingSectionExpanded = false
                            } label: {
                                HStack {
                                    Text("Show less")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.brand)

                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.brand)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                        } else {
                            // Expand button
                            Button {
                                isRemainingSectionExpanded = true
                            } label: {
                                HStack {
                                    Text("+ \(scheduledIncompleteCount - 3) more remaining")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(AppColors.brand)

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(AppColors.brand)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 2)
                        }
                    }
                }
            }

            // Completed habits section (always show if any exist)
            if !summary.completedHabits.isEmpty {
                VStack(spacing: 6) {
                    // Always show first 2 completed habits
                    ForEach(Array(summary.completedHabits.prefix(2).enumerated()), id: \.element.id) { index, habit in
                        if index == 0 {
                            // Use TipView for the first completed habit to ensure tip shows when it becomes eligible
                            VStack(spacing: 4) {
                                TipView(tapCompletedHabitTip, arrowEdge: .bottom)
                                habitRow(habit: habit, isCompleted: true)
                            }
                            .onAppear {
                                tipLogger.info("🎯 First completed habit row appeared - tip should show if eligible")
                            }
                        } else {
                            habitRow(habit: habit, isCompleted: true)
                        }
                    }

                    // Expandable section for additional completed habits
                    if summary.completedHabits.count > 2 {
                        if isCompletedSectionExpanded {
                            // Show all remaining completed habits
                            // PERFORMANCE: Use pre-computed array instead of creating NEW array on every render
                            ForEach(visibleCompletedHabits, id: \.id) { habit in
                                habitRow(habit: habit, isCompleted: true)
                            }

                            // Collapse button
                            Button {
                                isCompletedSectionExpanded = false
                            } label: {
                                HStack {
                                    Text("Show less")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.green)

                                    Image(systemName: "chevron.up")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                        } else {
                            // Expand button
                            Button {
                                isCompletedSectionExpanded = true
                            } label: {
                                HStack {
                                    Text("+ \(summary.completedHabits.count - 2) more completed")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.green)

                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.green)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 2)
                        }
                    }
                }
                .padding(.top, summary.incompleteHabits.isEmpty ? 0 : 12)
            }
        }
    }

    @ViewBuilder
    // swiftlint:disable:next function_body_length
    private func habitRow(habit: Habit, isCompleted: Bool) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !isCompleted && !scheduleStatus.isAvailable
        
        HStack(spacing: 0) {
            // LEFT ZONE: Main content - tappable for quick action or adjustment
            Button {
                if isCompleted {
                    // Completed habits: allow adjustment
                    if habit.kind == .numeric {
                        // Numeric habit: open progress sheet to adjust value
                        onNumericHabitAction?(habit)
                    } else {
                        // Binary habit: show uncomplete confirmation sheet
                        habitToUncomplete = habit
                    }
                } else if scheduleStatus.isAvailable {
                    if habit.kind == .numeric {
                        onNumericHabitAction?(habit)
                    } else {
                        // Binary habit - animate completion with glow
                        glowingHabitId = habit.id
                        performCompletionAnimation(for: habit)

                        // Cancel any existing habit row glow task
                        habitRowGlowTask?.cancel()

                        // Clear glow after animation
                        habitRowGlowTask = Task {
                            try? await Task.sleep(nanoseconds: AnimationTiming.completionGlowDelay)
                            glowingHabitId = nil
                        }
                    }
                }
            } label: {
                HStack(spacing: 12) {
                // Habit emoji with progress indicator and completion animation
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.colorHex).opacity(0.15))
                        .frame(width: IconSize.xxlarge, height: IconSize.xxlarge)

                    // Progress ring for numeric habits with animated gradient (only for incomplete)
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

                    // PERFORMANCE: Removed animation overlays - causing scroll lag
                    // These complex conditional animations were evaluated on every frame

                    // Habit emoji
                    Text(habit.emoji ?? "📊")
                        .font(.title3)
                        // PERFORMANCE: Removed complex opacity calculation - caused evaluation on every habit during scroll
                }

                // Habit info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(isCompleted ? .gray : (isDisabled ? .secondary.opacity(0.7) : .primary))
                        .strikethrough(isCompleted, color: .gray)
                        .lineLimit(1)

                    // Show progress for numeric habits (both completed and incomplete)
                    if habit.kind == .numeric {
                        let currentValue = getProgress(habit)
                        let target = habit.dailyTarget ?? 1.0
                        let currentInt = Int(currentValue)
                        let targetInt = Int(target)
                        Text("\(currentInt)/\(targetInt) \(habit.unitLabel ?? "units")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if !isCompleted && isDisabled {
                        // Show schedule status only for incomplete disabled habits
                        Text(scheduleStatus.displayText)
                            .font(.caption)
                            .foregroundColor(scheduleStatus.color)
                    }
                }

                Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled && !isCompleted)  // Allow completed habits to be tapped for adjustment

            // RIGHT ZONE: Icon area - tappable for info sheet (or delete for completed)
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
                        // Streak at risk indicator (only show for actual today, not retroactive days)
                        if isViewingToday,
                           let streakStatus = getStreakStatus?(habit),
                           streakStatus.isAtRisk {
                            HStack(spacing: 0) {
                                Text("🔥")
                                    .font(.system(size: 12))
                                Text("\(streakStatus.atRisk)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.orange)
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
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: CardDesign.innerCornerRadius)
                .fill(isCompleted ? Color.green.opacity(0.1) : (isDisabled ? CardDesign.secondaryBackground.opacity(0.5) : AppColors.brand.opacity(0.1)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.innerCornerRadius)
                .stroke(isCompleted ? Color.green.opacity(0.2) : (isDisabled ? Color.secondary.opacity(0.1) : AppColors.brand.opacity(0.2)), lineWidth: 1)
        )
        .opacity(isDisabled ? 0.6 : 1.0)
        .completionGlow(isGlowing: glowingHabitId == habit.id)
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
            tipLogger.info("📤 Habit completed - donated shouldShowCompletedTip event")

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

// MARK: - Schedule Icon Info Sheet

struct ScheduleIconInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ScheduleInfoRow(
                        icon: "infinity.circle.fill",
                        iconColor: .blue,
                        title: "Always Available",
                        description: "Daily habits that can be logged any day"
                    )

                    ScheduleInfoRow(
                        icon: "calendar.circle.fill",
                        iconColor: .green,
                        title: "Scheduled for Today",
                        description: "Habit is scheduled for specific days, and today is one of them"
                    )
                } header: {
                    Text("Schedule Icons")
                } footer: {
                    Text("These icons indicate when habits are available to log based on their schedule type.")
                }

                Section {
                    StreakInfoRow()
                } header: {
                    Text("Streak Indicator")
                } footer: {
                    Text("Keep your streaks alive by logging habits before midnight!")
                }
            }
            .navigationTitle("Habit Status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ScheduleInfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
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

private struct StreakInfoRow: View {
    var body: some View {
        HStack(spacing: 16) {
            Text("🔥")
                .font(.title2)
                .modifier(SheetPulseAnimationModifier())
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text("Streak at Risk")
                    .font(.headline)
                Text("You have an active streak! Log this habit today to keep it going. The number shows your current streak length.")
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

// MARK: - Pulse Animation for Streak At Risk

private struct PulseAnimationModifier: ViewModifier {
    @State private var pulseCount = 0
    @State private var scale: CGFloat = 0.95
    @State private var opacity: Double = 0.65

    private let maxPulses = 2

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                animatePulse()
            }
    }

    private func animatePulse() {
        guard pulseCount < maxPulses else {
            // Stop at ending size
            withAnimation(.easeOut(duration: 0.3)) {
                scale = 1.2
                opacity = 1.0
            }
            return
        }

        // Pulse up
        withAnimation(.easeInOut(duration: 0.45)) {
            scale = 1.2
            opacity = 1.0
        }

        // Pulse down after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.45)) {
                scale = 0.95
                opacity = 0.65
            }

            // Schedule next pulse
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                pulseCount += 1
                animatePulse()
            }
        }
    }
}

private struct SheetPulseAnimationModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.2 : 1.0)
            .opacity(isPulsing ? 1.0 : 0.7)
            .animation(
                .easeInOut(duration: 0.9)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

