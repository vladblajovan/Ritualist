import SwiftUI
import RitualistCore
import FactoryKit
import TipKit

/// Direct sheet implementation without caching layer
public struct NumericHabitLogSheetDirect: View { // swiftlint:disable:this type_body_length
    let habit: Habit
    let viewingDate: Date
    let timezone: TimeZone
    let onSave: (Double) async throws -> Void
    let onCancel: () -> Void
    let initialValue: Double?

    @Injected(\.getLogs) private var getLogs
    @Injected(\.debugLogger) private var logger
    @Injected(\.toastService) private var toastService
    @State private var currentValue: Double = 0.0
    @State private var isLoading = true
    @State private var isGlowing = false
    
    @State private var value: Double = 0.0
    @State private var extraMileText: String?
    @State private var loadTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    // MARK: - Dynamic Type Scaling
    @ScaledMetric(relativeTo: .title) private var incrementButtonSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title) private var progressCircleSize: CGFloat = 120
    @ScaledMetric(relativeTo: .subheadline) private var celebrationHeight: CGFloat = 30
    @ScaledMetric(relativeTo: .headline) private var quickIncrementHeight: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var buttonHeight: CGFloat = 44
    
    public init(
        habit: Habit,
        viewingDate: Date,
        timezone: TimeZone = .current,
        onSave: @escaping (Double) async throws -> Void,
        onCancel: @escaping () -> Void = {},
        initialValue: Double? = nil
    ) {
        self.habit = habit
        self.viewingDate = viewingDate
        self.timezone = timezone
        self.onSave = onSave
        self.onCancel = onCancel
        self.initialValue = initialValue
    }
    
    // MARK: - Computed Properties (delegating to ViewLogic for testability)

    private var dailyTarget: Double {
        NumericHabitLogViewLogic.effectiveDailyTarget(from: habit.dailyTarget)
    }

    private var progressPercentage: Double {
        NumericHabitLogViewLogic.progressPercentage(value: value, dailyTarget: dailyTarget)
    }

    private var isCompleted: Bool {
        NumericHabitLogViewLogic.isCompleted(value: value, dailyTarget: dailyTarget)
    }

    private var unitLabel: String {
        NumericHabitLogViewLogic.unitLabel(from: habit.unitLabel)
    }

    private var maxAllowedValue: Double {
        NumericHabitLogViewLogic.maxAllowedValue(for: dailyTarget)
    }

    private var isValidValue: Bool {
        NumericHabitLogViewLogic.isValidValue(value, dailyTarget: dailyTarget)
    }

    private var canDecrement: Bool {
        NumericHabitLogViewLogic.canDecrement(value: value)
    }

    private var canIncrement: Bool {
        NumericHabitLogViewLogic.canIncrement(value: value, dailyTarget: dailyTarget)
    }

    private var quickIncrementAmounts: [Int] {
        NumericHabitLogViewLogic.quickIncrementAmounts(value: value, dailyTarget: dailyTarget)
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Spacer()

                // Centered content group (header + progress)
                VStack(spacing: Spacing.large) {
                    // Header with emoji and name
                    VStack(spacing: Spacing.medium) {
                        Text(habit.emoji ?? "📊")
                            .font(.system(size: 48))

                        Text(habit.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                    }

                    // Progress circle with +/- controls
                    VStack(spacing: Spacing.medium) {
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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            Strings.NumericHabitLog.progressLabel(
                                current: Int(value),
                                target: Int(dailyTarget),
                                isCompleted: isCompleted
                            )
                        )

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

                    // Celebration text - fixed height
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

                    // Quick increment buttons
                    Group {
                        if !quickIncrementAmounts.isEmpty {
                            HStack(spacing: Spacing.medium) {
                                ForEach(quickIncrementAmounts, id: \.self) { amount in
                                    quickIncrementButton(amount: amount)
                                }
                            }
                        } else {
                            Color.clear
                        }
                    }
                    .frame(height: quickIncrementHeight)
                }

                Spacer()

                // Action buttons at bottom
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
            .navigationTitle(Strings.NumericHabitLog.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .scrollContentBackground(.hidden)
        .presentationDetents(isIPad ? [.large] : [.medium, .large])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .overlay(
            Group {
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
        )
        .onAppear {
            if let initial = initialValue, initial > 0 {
                currentValue = initial
                value = initial
                isLoading = false
            } else {
                loadCurrentValue()
            }
            // Announce sheet to VoiceOver for focus management
            DispatchQueue.main.asyncAfter(deadline: .now() + AccessibilityConfig.voiceOverAnnouncementDelay) {
                UIAccessibility.post(notification: .screenChanged, argument: "Log \(habit.name)")
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil

            // Save on dismiss if value changed - user sees Overview animate with new progress
            if value != currentValue {
                Task {
                    do {
                        try await onSave(value)
                    } catch {
                        logger.log(
                            "Failed to save habit value on dismiss",
                            level: .error,
                            category: .dataIntegrity,
                            metadata: ["habit_id": habit.id.uuidString, "value": "\(value)", "error": error.localizedDescription]
                        )
                    }
                }
            }
        }
        .onChange(of: currentValue) { _, newValue in
            value = newValue
        }
        .onChange(of: value) { oldValue, newValue in
            // Set extra mile text when first exceeding target
            if newValue > dailyTarget && extraMileText == nil {
                extraMileText = Strings.NumericHabitLog.extraMilePhrases.randomElement()
            }

            // Trigger tip for completed habits when reaching target for the first time
            if newValue >= dailyTarget && oldValue < dailyTarget {
                TapCompletedHabitTip.shouldShowCompletedTip.sendDonation()
                logger.log("Numeric habit completed - donated shouldShowCompletedTip event", level: .debug, category: .ui)
            }
        }
        .completionGlow(isGlowing: isGlowing)
    }

    @ViewBuilder
    private func resetButton() -> some View {
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

    @ViewBuilder
    private func completeButton() -> some View {
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

    @ViewBuilder
    private func doneButton() -> some View {
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

    @ViewBuilder
    private func quickIncrementButton(amount: Int) -> some View {
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
                .cornerRadius(6)
        }
        .accessibilityLabel(Strings.NumericHabitLog.quickIncrementLabel(formatAmount(amount)))
        .accessibilityHint(Strings.NumericHabitLog.quickIncrementHint(formatAmount(amount)))
    }

    private func formatAmount(_ amount: Int) -> String {
        NumericHabitLogViewLogic.formatAmount(amount)
    }
    
    private func loadCurrentValue() {
        loadTask = Task { @MainActor in
            do {
                let logs = try await getLogs.execute(for: habit.id, since: nil, until: nil)

                guard !Task.isCancelled else { return }

                // Use cross-timezone comparison: log's calendar day (in its stored timezone) vs viewing date (in display timezone)
                let targetDateLogs = logs.filter { log in
                    let logTimezone = log.resolvedTimezone(fallback: timezone)
                    return CalendarUtils.areSameDayAcrossTimezones(
                        log.date,
                        timezone1: logTimezone,
                        viewingDate,
                        timezone2: timezone
                    )
                }
                let totalValue = targetDateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }

                guard !Task.isCancelled else { return }
                currentValue = totalValue
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                currentValue = 0.0
                isLoading = false
            }
        }
    }
}
