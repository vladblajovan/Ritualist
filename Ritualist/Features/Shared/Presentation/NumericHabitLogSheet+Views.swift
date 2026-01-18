//
//  NumericHabitLogSheet+Views.swift
//  Ritualist
//
//  View components extracted from NumericHabitLogSheetDirect to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - View Components

extension NumericHabitLogSheetDirect {

    /// Header section with emoji and habit name.
    @ViewBuilder
    func headerSection() -> some View {
        VStack(spacing: Spacing.medium) {
            Text(habit.emoji ?? "📊")
                .font(.system(size: 48))

            Text(habit.name)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
        }
    }

    /// Progress circle with increment/decrement controls.
    @ViewBuilder
    func progressSection(
        progressPercentage: Double,
        isCompleted: Bool,
        canDecrement: Bool,
        canIncrement: Bool,
        showCelebration: Binding<Bool>
    ) -> some View {
        HStack(spacing: Spacing.xlarge) {
            // Minus button
            Button {
                HapticFeedbackService.shared.trigger(.light)
                animateIfAllowed(.spring(response: 0.3, dampingFraction: 0.7)) {
                    value = max(0, value - 1)
                }
            } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.system(size: incrementButtonSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CardDesign.progressOrange, .ritualistCyan],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(canDecrement ? 1.0 : 0.3)
            }
            .disabled(!canDecrement)
            .accessibilityLabel(Strings.Common.decrease)
            .accessibilityHint(Strings.NumericHabitLog.decreaseHint)

            // Progress circle
            progressCircle(progressPercentage: progressPercentage, isCompleted: isCompleted, showCelebration: showCelebration)

            // Plus button
            Button {
                HapticFeedbackService.shared.trigger(.light)
                animateIfAllowed(.spring(response: 0.3, dampingFraction: 0.7)) {
                    value += 1
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: incrementButtonSize))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [CardDesign.progressGreen, .ritualistCyan],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(canIncrement ? 1.0 : 0.3)
            }
            .disabled(!canIncrement)
            .accessibilityLabel(Strings.Common.increase)
            .accessibilityHint(Strings.NumericHabitLog.increaseHint)
        }
    }

    /// The circular progress indicator showing current value.
    @ViewBuilder
    func progressCircle(
        progressPercentage: Double,
        isCompleted: Bool,
        showCelebration: Binding<Bool>
    ) -> some View {
        ZStack {
            CircularProgressView(
                progress: progressPercentage,
                lineWidth: 10,
                showPercentage: false,
                useAdaptiveGradient: true
            )
            .frame(width: progressCircleSize, height: progressCircleSize)

            VStack(spacing: 2) {
                Text("\(Int(value))")
                    .font(.title.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: CircularProgressView.adaptiveProgressColors(for: progressPercentage),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("/ \(Int(dailyTarget))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .celebrationAnimation(
            isTriggered: showCelebration.wrappedValue,
            config: .achievement
        ) {
            showCelebration.wrappedValue = false
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Strings.NumericHabitLog.progressLabel(
                current: Int(value),
                target: Int(dailyTarget),
                isCompleted: isCompleted
            )
        )
    }

    /// Celebration text displayed when target is reached or exceeded.
    @ViewBuilder
    func celebrationSection(extraMileText: String?) -> some View {
        Group {
            if value == dailyTarget {
                HStack(spacing: Spacing.small) {
                    Text("🏆")
                        .accessibilityHidden(true)
                    Text(Strings.NumericHabitLog.wellDoneExtraMile)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CardDesign.progressGreen, .ritualistCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            } else if value > dailyTarget, let text = extraMileText {
                HStack(spacing: Spacing.small) {
                    Text("🎉")
                        .accessibilityHidden(true)
                    Text(text)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [CardDesign.progressGreen, .ritualistCyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            } else {
                Color.clear
            }
        }
        .frame(height: celebrationHeight)
    }

    /// Quick increment buttons section.
    @ViewBuilder
    func quickIncrementSection(amounts: [Int]) -> some View {
        Group {
            if !amounts.isEmpty {
                HStack(spacing: Spacing.medium) {
                    ForEach(amounts, id: \.self) { amount in
                        quickIncrementButton(amount: amount)
                    }
                }
            } else {
                Color.clear
            }
        }
        .frame(height: quickIncrementHeight)
    }

    /// Loading overlay shown while fetching current value.
    @ViewBuilder
    func loadingOverlay(isLoading: Bool) -> some View {
        if isLoading {
            ZStack {
                Color(.systemBackground).opacity(0.8)
                VStack(spacing: Spacing.medium) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(Strings.NumericHabitLog.loadingCurrentValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    /// Action buttons row at the bottom of the sheet.
    @ViewBuilder
    func actionButtonsRow(isCompleted: Bool) -> some View {
        HStack {
            if value > 0 {
                resetButton()
            }

            Spacer()

            completeButton()
                .disabled(isCompleted)
                .opacity(isCompleted ? 0.4 : 1)

            doneButton()
        }
        .padding(.horizontal)
        .padding(.bottom, Spacing.large)
    }
}
