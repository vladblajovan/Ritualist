//
//  TodaysSummaryCard+QuickActions.swift
//  Ritualist
//
//  Quick action button methods extracted from TodaysSummaryCard to reduce type body length.
//

import SwiftUI
import RitualistCore
import TipKit

// MARK: - Quick Action Button Methods

extension TodaysSummaryCard {

    @ViewBuilder
    func quickActionButton(for habit: Habit) -> some View {
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

    func handleQuickActionTap(habit: Habit, scheduleStatus: HabitScheduleStatus) {
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
    func quickActionButtonLabel(habit: Habit, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
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
    func quickActionProgressIndicator(habit: Habit) -> some View {
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
    func quickActionTextContent(habit: Habit, scheduleStatus: HabitScheduleStatus, isDisabled: Bool) -> some View {
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
}

// MARK: - Progress Calculation Helper

extension TodaysSummaryCard {

    /// Calculates progress percentage using truncated integers to match text display
    /// - Parameters:
    ///   - current: Current progress value
    ///   - target: Target/goal value
    /// - Returns: Progress as a percentage (0.0 to 1.0)
    func calculateProgress(current: Double, target: Double) -> Double {
        // Use truncated integers to match the text display (e.g., "4/5")
        // This prevents visual mismatch where text shows "4/5" but circle shows 4.8/5.0 = 96%
        let currentInt = Int(current)
        let targetInt = Int(target)
        return targetInt > 0 ? min(max(Double(currentInt) / Double(targetInt), 0.0), 1.0) : 0.0
    }

    /// Calculate gradient colors based on completion percentage
    /// Delegates to CircularProgressView.adaptiveProgressColors to maintain consistency
    func progressGradientColors(for completion: Double) -> [Color] {
        CircularProgressView.adaptiveProgressColors(for: completion)
    }
}
