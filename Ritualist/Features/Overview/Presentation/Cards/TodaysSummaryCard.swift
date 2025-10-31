import SwiftUI
import RitualistCore
import FactoryKit

// swiftlint:disable type_body_length function_body_length
struct TodaysSummaryCard: View {
    let summary: TodaysSummary?
    let viewingDate: Date
    let isViewingToday: Bool
    let canGoToPrevious: Bool
    let canGoToNext: Bool
    let currentSlogan: String?
    let onQuickAction: (Habit) -> Void
    let onNumericHabitUpdate: ((Habit, Double) async -> Void)?
    let getProgress: ((Habit) -> Double)
    let onNumericHabitAction: ((Habit) -> Void)? // New callback for numeric habit sheet
    let onDeleteHabitLog: (Habit) -> Void // New callback for deleting habit log
    let getScheduleStatus: (Habit) -> HabitScheduleStatus // New callback for schedule status
    let getValidationMessage: (Habit) async -> String? // New callback for validation message
    let onPreviousDay: () -> Void
    let onNextDay: () -> Void
    let onGoToToday: () -> Void
    
    @State private var isCompletedSectionExpanded = false
    @State private var isRemainingSectionExpanded = false
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?
    @State private var animatingHabitId: UUID? = nil
    @State private var glowingHabitId: UUID? = nil
    @State private var animatingProgress: Double = 0.0
    @State private var isAnimatingCompletion = false

    // PERFORMANCE: Pre-computed arrays to avoid creating NEW arrays on every render
    @State private var visibleIncompleteHabits: [Habit] = []
    @State private var visibleCompletedHabits: [Habit] = []

    // PERFORMANCE: Static DateFormatters - created ONCE, reused forever
    // DateFormatter is extremely expensive to create (50ms+ overhead eliminated)
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    private static let todayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM yyyy" // e.g., "16 August 2025"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // PERFORMANCE: Pre-compute navigation button colors to avoid repeated calculations
    private var navigationButtonColor: Color {
        // Use same color as circular progress (Icon-Inspired Gradient)
        return Color.ritualistBlue
    }

    private var navigationButtonBackgroundColor: Color {
        navigationButtonColor.opacity(0.1)
    }

    private var navigationButtonStrokeColor: Color {
        navigationButtonColor.opacity(0.3)
    }

    init(summary: TodaysSummary?,
         viewingDate: Date,
         isViewingToday: Bool,
         canGoToPrevious: Bool,
         canGoToNext: Bool,
         currentSlogan: String? = nil,
         onQuickAction: @escaping (Habit) -> Void,
         onNumericHabitUpdate: ((Habit, Double) async -> Void)? = nil,
         getProgressSync: @escaping (Habit) -> Double,
         onNumericHabitAction: ((Habit) -> Void)? = nil,
         onDeleteHabitLog: @escaping (Habit) -> Void,
         getScheduleStatus: @escaping (Habit) -> HabitScheduleStatus,
         getValidationMessage: @escaping (Habit) async -> String?,
         onPreviousDay: @escaping () -> Void,
         onNextDay: @escaping () -> Void,
         onGoToToday: @escaping () -> Void) {
        self.summary = summary
        self.viewingDate = viewingDate
        self.isViewingToday = isViewingToday
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
        self.onPreviousDay = onPreviousDay
        self.onNextDay = onNextDay
        self.onGoToToday = onGoToToday
    }

    // PERFORMANCE: Update visible arrays only when needed
    private func updateVisibleHabits() {
        guard let summary = summary else {
            visibleIncompleteHabits = []
            visibleCompletedHabits = []
            return
        }

        // Pre-compute incomplete habits array
        visibleIncompleteHabits = isRemainingSectionExpanded ?
            summary.incompleteHabits :
            Array(summary.incompleteHabits.prefix(3))

        // Pre-compute completed habits array
        visibleCompletedHabits = isCompletedSectionExpanded ?
            Array(summary.completedHabits.dropFirst(2)) :
            []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Card Header with Date Navigation
            VStack(spacing: 12) {
                HStack {
                    // Previous Day Button
                    Button(action: onPreviousDay) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(canGoToPrevious ? navigationButtonColor : .secondary)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(canGoToPrevious ? navigationButtonBackgroundColor : Color.clear)
                            )
                            .overlay(
                                Circle()
                                    .stroke(
                                        canGoToPrevious ? navigationButtonStrokeColor : Color.secondary.opacity(0.2),
                                        lineWidth: 1.0
                                    )
                            )
                    }
                    .disabled(!canGoToPrevious)
                    
                    Spacer()
                    
                    // Date and Title
                    VStack(spacing: 4) {
                        if isViewingToday {
                            Text("Today, \(Self.todayFormatter.string(from: CalendarUtils.startOfDayLocal(for: Date())))")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        } else {
                            Text(CalendarUtils.formatForDisplay(viewingDate, style: .full))
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    // Next Day Button or Today Button
                    if !isViewingToday && canGoToNext {
                        Button(action: onNextDay) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(navigationButtonColor)
                                .frame(width: 28, height: 28)
                                .background(
                                    Circle()
                                        .fill(navigationButtonBackgroundColor)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(navigationButtonStrokeColor, lineWidth: 1.0)
                                )
                        }
                    } else if !isViewingToday {
                        Button(action: onGoToToday) {
                            Text("Today")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(navigationButtonColor)
                        }
                    } else {
                        // Invisible placeholder for alignment
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.clear)
                    }
                }
            }
            
            if let summary = summary {
                // Main Progress Section
                HStack(alignment: .top, spacing: 32) {
                    // Progress Ring (Icon-Inspired Gradient)
                    ZStack {
                        Circle()
                            .stroke(CardDesign.secondaryBackground, lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0.0, to: summary.completionPercentage)
                            .stroke(
                                .linearGradient(
                                    colors: [Color.ritualistCyan, Color.ritualistBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 8
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            // PERFORMANCE: Removed animation - causes lag during scroll when data updates

                        Text("\(Int(summary.completionPercentage * 100))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.ritualistBlue)
                    }
                    
                    // Progress Details
                    VStack(alignment: .leading, spacing: 12) {
                        // PERFORMANCE: Simplified to progress bar instead of 12-20+ circles with shadows/overlays
                        // Previous implementation was massive view hierarchy causing scroll lag
                        HStack(spacing: 8) {
                            // Progress bar (Icon-Inspired Gradient)
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(CardDesign.secondaryBackground)
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            .linearGradient(
                                                colors: [Color.ritualistCyan, Color.ritualistBlue],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * summary.completionPercentage, height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                        
                        // Habit Count Text
                        Text("\(summary.completedHabitsCount)/\(summary.totalHabits) habits completed")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // Motivational Message (different styles for incomplete vs complete)
                        if summary.completionPercentage >= 1.0 {
                            // Celebration message with icon checkmark gradient
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [Color.ritualistYellowLime, Color.ritualistOrange],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )

                                Text(summary.motivationalMessage)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [Color.ritualistYellowLime, Color.ritualistOrange],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        } else {
                            // Regular motivational message for incomplete days
                            Text(summary.motivationalMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    
                    Spacer()
                }
                
                // Enhanced Habits Section - show both completed and incomplete habits
                if !summary.incompleteHabits.isEmpty || !summary.completedHabits.isEmpty {
                    habitsSection(summary: summary)
                }
            } else {
                // Loading State
                loadingView
            }
        }
        .glassmorphicContentStyle()
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
                Text("This will remove the log entry for \"\(habit.name)\" from \(isViewingToday ? "today" : Self.dateFormatter.string(from: viewingDate)). The habit itself will remain.")
            }
        }
        // PERFORMANCE: Update pre-computed arrays when data or expansion state changes
        .onAppear {
            updateVisibleHabits()
        }
        .onChange(of: summary?.completedHabitsCount) { _, _ in
            updateVisibleHabits()
        }
        .onChange(of: summary?.totalHabits) { _, _ in
            updateVisibleHabits()
        }
        .onChange(of: isRemainingSectionExpanded) { _, _ in
            updateVisibleHabits()
        }
        .onChange(of: isCompletedSectionExpanded) { _, _ in
            updateVisibleHabits()
        }
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
                    
                    // Small delay for glow effect, then complete
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds for glow
                        await MainActor.run {
                            onQuickAction(habit)
                            glowingHabitId = nil
                        }
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
                        .frame(width: 44, height: 44)
                    
                    // Progress border for numeric habits (Icon-Inspired Gradient)
                    if habit.kind == .numeric {
                        let currentValue = getProgress(habit)
                        let target = habit.dailyTarget ?? 1.0
                        let progressValue = min(max(currentValue / target, 0.0), 1.0)

                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(
                                .linearGradient(
                                    colors: [Color.ritualistCyan, Color.ritualistBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 44, height: 44)
                            .rotationEffect(.degrees(-90))
                            // PERFORMANCE: Removed animation - numeric progress updates don't need animation
                    }
                    
                    // Emoji
                    Text(habit.emoji ?? "📊")
                        .font(.title2)
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
                        Text("\(Int(currentValue))/\(Int(target)) \(habit.unitLabel?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? habit.unitLabel! : "units")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Tap to complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !isDisabled {
                        HabitScheduleIndicator.compact(status: scheduleStatus)
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
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
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
        HStack(spacing: 24) {
            // Loading Ring
            Circle()
                .stroke(CardDesign.secondaryBackground, lineWidth: 8)
                .frame(width: 80, height: 80)
                .overlay(
                    ProgressView()
                        .scaleEffect(0.8)
                )
            
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(CardDesign.secondaryBackground)
                    .frame(width: 120, height: 12)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(CardDesign.secondaryBackground)
                    .frame(width: 80, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(CardDesign.secondaryBackground)
                    .frame(width: 160, height: 12)
            }
            
            Spacer()
        }
        .redacted(reason: .placeholder)
    }
    
    private func progressColor(for percentage: Double) -> Color {
        if percentage >= 0.8 {
            return CardDesign.progressGreen
        } else if percentage >= 0.5 {
            return CardDesign.progressOrange
        } else {
            return CardDesign.progressRed
        }
    }
    
    // MARK: - Enhanced Habits Section
    
    @ViewBuilder
    private func habitsSection(summary: TodaysSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            if !summary.incompleteHabits.isEmpty {
                HStack {
                    Text("Remaining Habits")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(summary.incompleteHabits.count)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(CardDesign.secondaryBackground)
                        )
                }
            }
            
            // Incomplete habits
            if !summary.incompleteHabits.isEmpty {
                VStack(spacing: 8) {
                    // Show first 3 habits, or all if expanded
                    // PERFORMANCE: Use pre-computed array instead of creating NEW array on every render
                    ForEach(visibleIncompleteHabits, id: \.id) { habit in
                        habitRow(habit: habit, isCompleted: false)
                    }
                    
                    if summary.incompleteHabits.count > 3 {
                        if isRemainingSectionExpanded {
                            // Collapse button
                            Button {
                                // PERFORMANCE: Removed animation - expansion/collapse doesn't need animation
                                isRemainingSectionExpanded = false
                            } label: {
                                HStack {
                                    Text("Show less")
                                        .font(.caption)
                                        .foregroundColor(AppColors.brand)
                                    
                                    Image(systemName: "chevron.up")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.brand)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                        } else {
                            // Expand button
                            Button {
                                // PERFORMANCE: Removed animation - expansion/collapse doesn't need animation
                                isRemainingSectionExpanded = true
                            } label: {
                                HStack {
                                    Text("+ \(summary.incompleteHabits.count - 3) more remaining")
                                        .font(.caption)
                                        .foregroundColor(AppColors.brand)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.caption2)
                                        .foregroundColor(AppColors.brand)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 2)
                        }
                    }
                }
            }
            
            // Completed habits section (always show if any exist)
            if !summary.completedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Completed")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(summary.completedHabits.count)")
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.green.opacity(0.1))
                            )
                    }
                    .padding(.top, summary.incompleteHabits.isEmpty ? 0 : 16)
                    
                    VStack(spacing: 6) {
                        // Always show first 2 completed habits
                        ForEach(summary.completedHabits.prefix(2), id: \.id) { habit in
                            habitRow(habit: habit, isCompleted: true)
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
                                    // PERFORMANCE: Removed animation - expansion/collapse doesn't need animation
                                    isCompletedSectionExpanded = false
                                } label: {
                                    HStack {
                                        Text("Show less")
                                            .font(.caption)
                                            .foregroundColor(AppColors.brand)
                                        
                                        Image(systemName: "chevron.up")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.brand)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 4)
                            } else {
                                // Expand button
                                Button {
                                    // PERFORMANCE: Removed animation - expansion/collapse doesn't need animation
                                    isCompletedSectionExpanded = true
                                } label: {
                                    HStack {
                                        Text("+ \(summary.completedHabits.count - 2) more completed")
                                            .font(.caption)
                                            .foregroundColor(AppColors.brand)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.caption2)
                                            .foregroundColor(AppColors.brand)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.top, 2)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func habitRow(habit: Habit, isCompleted: Bool) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !isCompleted && !scheduleStatus.isAvailable
        
        Button {
            if !isCompleted && scheduleStatus.isAvailable {
                if habit.kind == .numeric {
                    onNumericHabitAction?(habit)
                } else {
                    // Binary habit - animate completion with glow
                    glowingHabitId = habit.id
                    performCompletionAnimation(for: habit)
                    
                    // Clear glow after animation
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await MainActor.run {
                            glowingHabitId = nil
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Habit emoji with progress indicator and completion animation
                ZStack {
                    Circle()
                        .fill(Color(hex: habit.colorHex).opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    // Progress ring for numeric habits (Icon-Inspired Gradient)
                    if habit.kind == .numeric && !isCompleted {
                        let currentValue = getProgress(habit)
                        let target = habit.dailyTarget ?? 1.0
                        let progressValue = min(max(currentValue / target, 0.0), 1.0)

                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(
                                .linearGradient(
                                    colors: [Color.ritualistCyan, Color.ritualistBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 32, height: 32)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    // PERFORMANCE: Removed animation overlays - causing scroll lag
                    // These complex conditional animations were evaluated on every frame
                    
                    // Habit emoji
                    Text(habit.emoji ?? "📊")
                        .font(.system(size: 16))
                        // PERFORMANCE: Removed complex opacity calculation - caused evaluation on every habit during scroll
                }
                
                // Habit info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(habit.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isCompleted ? .gray : (isDisabled ? .secondary.opacity(0.7) : .primary))
                            .lineLimit(1)
                        
                        // Schedule indicator icon
                        scheduleIcon(for: habit.schedule)
                    }
                    
                    if isCompleted {
                        Text("Completed")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if habit.kind == .numeric {
                        let currentValue = getProgress(habit)
                        let target = habit.dailyTarget ?? 1.0
                        let currentInt = Int(currentValue)
                        let targetInt = Int(target)
                        Text("\(currentInt)/\(targetInt) \(habit.unitLabel ?? "units")")
                            .font(.caption)
                            .foregroundColor(.gray)
                    } else if isDisabled {
                        Text(scheduleStatus.displayText)
                            .font(.caption)
                            .foregroundColor(scheduleStatus.color)
                    } else {
                        Text("Tap to complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Action icon - show delete option for completed habits
                if isCompleted {
                    Button {
                        habitToDelete = habit
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    Image(systemName: isDisabled ? "minus.circle" : "plus.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(isDisabled ? .secondary : AppColors.brand)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isCompleted ? Color.green.opacity(0.08) : (isDisabled ? .clear : AppColors.brand.opacity(0.05)))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1.0)
        // PERFORMANCE: Removed scale effect and animation - causes lag during scroll
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
        
        // After animation completes, fade and trigger actual completion
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            await MainActor.run {
                // Start fade out
                withAnimation(.easeOut(duration: 0.4)) {
                    // Fade effect handled by opacity in view
                }
                
                // Complete the habit
                onQuickAction(habit)
                
                // Clean up animation state
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        resetAnimationState()
                    }
                }
            }
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
        
        // After animation completes, fade and trigger actual removal
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            await MainActor.run {
                // Start fade out
                withAnimation(.easeOut(duration: 0.4)) {
                    // Fade effect handled by opacity in view
                }
                
                // Remove the habit log
                onDeleteHabitLog(habit)
                
                // Clean up animation state
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    await MainActor.run {
                        resetAnimationState()
                    }
                }
            }
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
            viewingDate: CalendarUtils.addDays(-3, to: Date()),
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
