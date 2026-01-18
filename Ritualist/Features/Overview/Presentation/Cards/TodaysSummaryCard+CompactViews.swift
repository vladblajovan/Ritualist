//
//  TodaysSummaryCard+CompactViews.swift
//  Ritualist
//
//  Compact view methods extracted from TodaysSummaryCard to reduce type body length.
//

import SwiftUI
import RitualistCore
import TipKit

// MARK: - Compact Completed View

extension TodaysSummaryCard {

    /// Header for completed section with expand/collapse toggle
    @ViewBuilder
    func completedSectionHeader(count: Int) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.green)
                Text(Strings.Overview.completed)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                isCompletedViewCompact.toggle()
            } label: {
                Image(systemName: isCompletedViewCompact ? "plus.circle" : "minus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.green)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isCompletedViewCompact ? "Expand completed habits" : "Collapse completed habits")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }

    /// Compact view showing only habit emoji circles in a flowing layout
    @ViewBuilder
    func compactCompletedCircles(habits: [Habit]) -> some View {
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
    func compactHabitCircle(habit: Habit) -> some View {
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
}

// MARK: - Compact Remaining View

extension TodaysSummaryCard {

    /// Header for remaining section with expand/collapse toggle
    @ViewBuilder
    func remainingSectionHeader(count: Int) -> some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "circle.dashed")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.brand)
                Text(Strings.Overview.remaining)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                isRemainingViewCompact.toggle()
            } label: {
                Image(systemName: isRemainingViewCompact ? "plus.circle" : "minus.circle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.brand)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(isRemainingViewCompact ? "Expand remaining habits" : "Collapse remaining habits")
        }
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }

    /// Compact view showing only remaining habit emoji circles in a flowing layout
    @ViewBuilder
    func compactRemainingCircles(habits: [Habit]) -> some View {
        FlowLayout(spacing: 8) {
            ForEach(habits, id: \.id) { habit in
                compactRemainingHabitCircle(habit: habit)
            }
        }
    }

    /// Single compact remaining habit circle (36pt) with brand color background and border
    /// Tapping shows the mark-complete confirmation (binary) or logging sheet (numeric)
    @ViewBuilder
    func compactRemainingHabitCircle(habit: Habit) -> some View {
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
}
