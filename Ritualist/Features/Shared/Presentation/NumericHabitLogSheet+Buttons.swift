//
//  NumericHabitLogSheet+Buttons.swift
//  Ritualist
//
//  Button view builders extracted from NumericHabitLogSheetDirect to reduce type body length.
//

import SwiftUI
import RitualistCore

// MARK: - Action Buttons

extension NumericHabitLogSheetDirect {

    /// Reset button - sets value back to zero.
    @ViewBuilder
    func resetButton() -> some View {
        Button {
            HapticFeedbackService.shared.trigger(.medium)
            animateIfAllowed(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = 0
            }
        } label: {
            Text(Strings.NumericHabitLog.reset)
                .font(.body.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.large)
                .frame(minHeight: buttonHeight)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(CornerRadius.xlarge)
        }
        .accessibilityHint(Strings.NumericHabitLog.resetHint)
    }

    /// Complete button - sets value to daily target.
    @ViewBuilder
    func completeButton() -> some View {
        let adaptiveColor = CircularProgressView.adaptiveProgressColors(for: 1.0).last ?? CardDesign.progressGreen
        Button {
            HapticFeedbackService.shared.trigger(.success)
            animateIfAllowed(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = dailyTarget
            }
        } label: {
            Text(Strings.NumericHabitLog.completeAll)
                .font(.body.weight(.semibold))
                .foregroundColor(adaptiveColor)
                .padding(.horizontal, Spacing.large)
                .frame(minHeight: buttonHeight)
                .background(adaptiveColor.opacity(0.1))
                .cornerRadius(CornerRadius.xlarge)
        }
        .accessibilityHint(Strings.NumericHabitLog.completeAllHint)
    }

    /// Done button - dismisses the sheet.
    @ViewBuilder
    func doneButton() -> some View {
        @Environment(\.dismiss) var dismiss

        Button {
            HapticFeedbackService.shared.trigger(.light)
            dismiss()
        } label: {
            Text(Strings.Common.done)
                .font(.body.weight(.semibold))
                .foregroundColor(.accentColor)
                .padding(.horizontal, Spacing.large)
                .frame(minHeight: buttonHeight)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(CornerRadius.xlarge)
        }
        .accessibilityHint(Strings.NumericHabitLog.doneHint)
    }

    /// Quick increment button for adding a specific amount.
    @ViewBuilder
    func quickIncrementButton(amount: Int) -> some View {
        let gradient = LinearGradient(
            colors: [CardDesign.progressGreen, .ritualistCyan],
            startPoint: .leading,
            endPoint: .trailing
        )

        Button {
            HapticFeedbackService.shared.trigger(.light)
            animateIfAllowed(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = min(value + Double(amount), maxAllowedValue)
            }
        } label: {
            Text("+\(formatAmount(amount))")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(gradient)
                .padding(.horizontal, Spacing.small)
                .padding(.vertical, Spacing.xsmall)
                .background(gradient.opacity(0.15))
                .cornerRadius(CornerRadius.xlarge)
        }
        .accessibilityLabel(Strings.NumericHabitLog.quickIncrementLabel(formatAmount(amount)))
        .accessibilityHint(Strings.NumericHabitLog.quickIncrementHint(formatAmount(amount)))
    }

    /// Formats an amount for display (e.g., 1000 → "1K").
    func formatAmount(_ amount: Int) -> String {
        NumericHabitLogViewLogic.formatAmount(amount)
    }
}
