//
//  TodaysSummaryCard+HabitRows.swift
//  Ritualist
//
//  Habit row methods extracted from TodaysSummaryCard to reduce type body length.
//

import SwiftUI
import RitualistCore
import TipKit

// MARK: - Habit Row Methods

extension TodaysSummaryCard {

    @ViewBuilder
    func habitRow(habit: Habit, isCompleted: Bool) -> some View {
        let scheduleStatus = getScheduleStatus(habit)
        let isDisabled = !isCompleted && (!scheduleStatus.isAvailable || isLoggingLocked)
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
            duration: 0.8, isEnabled: canLongPress,
            progress: Binding(get: { longPressHabitId == habit.id ? longPressProgress : 0.0 },
                              set: { if $0 > 0 { longPressHabitId = habit.id }; longPressProgress = $0 }),
            onStart: { handleLongPressStart(habit: habit) },
            onComplete: { handleLongPressComplete(habit: habit) },
            onCancel: { longPressHabitId = nil; longPressProgress = 0.0 }
        )
    }

    func handleLongPressStart(habit: Habit) {
        longPressHabitId = habit.id; longPressProgress = 0.0
        TapHabitTip.wasDismissed.sendDonation()
        tapHabitTip.invalidate(reason: .actionPerformed)
        longPressLogTip.invalidate(reason: .actionPerformed)
    }

    func handleLongPressComplete(habit: Habit) {
        onLongPressComplete?(habit)
        recentlyCompletedViaLongPress.insert(habit.id)
        longPressProgress = 0.0
        Task { @MainActor in try? await Task.sleep(nanoseconds: 100_000_000); longPressHabitId = nil }
        TapCompletedHabitTip.firstHabitCompleted.sendDonation()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            LongPressLogTip.wasDismissed.sendDonation()
            CircleProgressTip.longPressTipDismissed.sendDonation()
            logger.log("Long-press complete - circle progress tip enabled", level: .debug, category: .ui)
        }
        longPressCompletionTasks[habit.id]?.cancel()
        longPressCompletionTasks[habit.id] = Task { @MainActor in
            try? await Task.sleep(nanoseconds: AnimationTiming.longPressCheckmarkDisplay)
            guard !Task.isCancelled else { return }
            _ = withAnimation(.easeOut(duration: 0.3)) { recentlyCompletedViaLongPress.remove(habit.id) }
            longPressCompletionTasks.removeValue(forKey: habit.id)
        }
    }

    @ViewBuilder
    func habitRowMainButton(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
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

    func handleHabitRowTap(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus) {
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
    func habitEmojiView(habit: Habit, isCompleted: Bool) -> some View {
        let isLongPressing = longPressHabitId == habit.id
        let currentProgress = isLongPressing ? longPressProgress : 0.0
        let isRecentlyCompleted = !isCompleted && recentlyCompletedViaLongPress.contains(habit.id)
        let opacities = calculateCrossfadeOpacities(isLongPressing: isLongPressing, progress: currentProgress, isRecentlyCompleted: isRecentlyCompleted)
        let showGreen = isRecentlyCompleted || (isLongPressing && currentProgress >= 0.8)

        ZStack {
            emojiBackgroundCircle(habit: habit, showGreen: showGreen)
            if habit.kind == .numeric && !isCompleted && !isLongPressing && !isRecentlyCompleted {
                numericProgressRing(habit: habit)
            }
            longPressProgressRing(habit: habit, isLongPressing: isLongPressing)
            if isRecentlyCompleted && !isLongPressing { completedGreenRing }
            Text(habit.emoji ?? "📊").font(CardDesign.title2).opacity(opacities.emoji)
            Image(systemName: "checkmark").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(.green).opacity(opacities.checkmark)
        }.animation(.easeInOut(duration: 0.3), value: isRecentlyCompleted)
    }

    func calculateCrossfadeOpacities(isLongPressing: Bool, progress: Double, isRecentlyCompleted: Bool) -> (emoji: Double, checkmark: Double) {
        let start = 0.8
        if isRecentlyCompleted { return (0, 1.0) }
        if !isLongPressing { return (1.0, 0) }
        if progress < start { return (1.0, 0) }
        let fade = (progress - start) / (1.0 - start)
        return (max(0, 1.0 - fade), min(1.0, fade))
    }

    @ViewBuilder
    func emojiBackgroundCircle(habit: Habit, showGreen: Bool) -> some View {
        Circle().fill(Color(hex: habit.colorHex).opacity(0.15)).frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
            .overlay(Circle().fill(Color.green.opacity(0.15)).opacity(showGreen ? 1 : 0))
    }

    @ViewBuilder
    func numericProgressRing(habit: Habit) -> some View {
        let currentValue = getProgress(habit); let target = habit.dailyTarget ?? 1.0
        let actualProgress = calculateProgress(current: currentValue, target: target)
        let animatedProgress = habitAnimatedProgress[habit.id] ?? actualProgress
        Circle().trim(from: 0, to: animatedProgress)
            .stroke(.linearGradient(colors: progressGradientColors(for: actualProgress), startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge).rotationEffect(.degrees(-90))
    }

    @ViewBuilder
    func longPressProgressRing(habit: Habit, isLongPressing: Bool) -> some View {
        Circle().trim(from: 0, to: longPressHabitId == habit.id ? longPressProgress : 0.0)
            .stroke(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge).rotationEffect(.degrees(-90))
            .opacity(isLongPressing ? 1 : 0).animation(.linear(duration: 0.65), value: longPressProgress)
    }

    var completedGreenRing: some View {
        Circle().stroke(LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
            .frame(width: IconSize.xxxlarge, height: IconSize.xxxlarge)
    }

    @ViewBuilder
    func habitInfoView(habit: Habit, isCompleted: Bool, isDisabled: Bool, scheduleStatus: HabitScheduleStatus) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(habit.name)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isCompleted ? .gray : (isDisabled ? .secondary.opacity(0.7) : .primary))
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
    func habitRowTrailingButton(habit: Habit, isCompleted: Bool, scheduleStatus: HabitScheduleStatus) -> some View {
        if isCompleted {
            Button { habitToDelete = habit; showingDeleteAlert = true } label: {
                Image(systemName: "ellipsis.circle.fill").font(.system(size: 14)).foregroundColor(.gray.opacity(0.8))
                    .padding(.leading, 8).contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
        } else {
            Button { showingScheduleInfoSheet = true } label: {
                HStack(spacing: 8) {
                    streakAtRiskIndicator(habit: habit)
                    habitRowIndicators(habit: habit, scheduleStatus: scheduleStatus)
                }.padding(.leading, 8).contentShape(Rectangle())
            }.buttonStyle(PlainButtonStyle())
        }
    }

    @ViewBuilder
    func streakAtRiskIndicator(habit: Habit) -> some View {
        if showStreakAtRiskIcon, isViewingToday, let streakStatus = getStreakStatus?(habit), streakStatus.isAtRisk {
            ZStack(alignment: .topTrailing) {
                Text("🔥").font(.system(size: 12))
                Text("\(streakStatus.atRisk)")
                    .font(.system(size: 8, weight: .bold, design: .rounded)).foregroundColor(.white)
                    .padding(.horizontal, 3).padding(.vertical, 1)
                    .background(Capsule().fill(Color(red: 0.9, green: 0.45, blue: 0.1)))
                    .offset(x: 4, y: -2)
            }.modifier(PulseAnimationModifier())
        }
    }

    @ViewBuilder
    func habitRowIndicators(habit: Habit, scheduleStatus: HabitScheduleStatus) -> some View {
        HStack(spacing: 4) {
            if showTimeReminderIcon, isPremiumUser, !habit.reminders.isEmpty {
                Image(systemName: "bell.fill").font(.system(size: 14)).foregroundColor(.orange)
                    .accessibilityLabel("Time-based reminders enabled")
            }
            if showLocationIcon, isPremiumUser, habit.locationConfiguration?.isEnabled == true {
                Image(systemName: "location.fill").font(.system(size: 14)).foregroundColor(.purple)
                    .accessibilityLabel("Location-based reminders enabled")
            }
            if showScheduleIcon { HabitScheduleIndicator(status: scheduleStatus, size: .xlarge, style: .iconOnly) }
        }
    }

    func habitRowBackground(isCompleted: Bool, isDisabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
            .fill(isCompleted ? Color.green.opacity(0.1) : (isDisabled ? CardDesign.secondaryBackground.opacity(0.5) : AppColors.brand.opacity(0.1)))
    }

    func habitRowBorder(isCompleted: Bool, isDisabled: Bool) -> some View {
        RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
            .stroke(isCompleted ? Color.green.opacity(0.2) : (isDisabled ? Color.secondary.opacity(0.1) : AppColors.brand.opacity(0.2)), lineWidth: 1)
    }

    @ViewBuilder
    func scheduleIcon(for schedule: HabitSchedule) -> some View {
        let (iconName, color) = scheduleIconInfo(for: schedule)

        Image(systemName: iconName)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(color)
    }

    func scheduleIconInfo(for schedule: HabitSchedule) -> (String, Color) {
        switch schedule {
        case .daily:
            return ("arrow.clockwise", .blue)
        case .daysOfWeek(let days):
            return days.count == 7 ? ("arrow.clockwise", .blue) : ("calendar", .orange)
        }
    }
}
