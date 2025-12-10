import SwiftUI
import RitualistCore
import FactoryKit

/// Direct sheet implementation without caching layer
public struct NumericHabitLogSheetDirect: View { // swiftlint:disable:this type_body_length
    let habit: Habit
    let viewingDate: Date
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
    @State private var saveTask: Task<Void, Never>?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Dynamic Type Scaling
    @ScaledMetric(relativeTo: .title) private var incrementButtonSize: CGFloat = 44
    @ScaledMetric(relativeTo: .title) private var progressCircleSize: CGFloat = 120
    @ScaledMetric(relativeTo: .subheadline) private var celebrationHeight: CGFloat = 24
    @ScaledMetric(relativeTo: .headline) private var quickIncrementHeight: CGFloat = 36
    @ScaledMetric(relativeTo: .body) private var buttonHeight: CGFloat = 44
    
    public init(
        habit: Habit,
        viewingDate: Date,
        onSave: @escaping (Double) async throws -> Void,
        onCancel: @escaping () -> Void = {},
        initialValue: Double? = nil
    ) {
        self.habit = habit
        self.viewingDate = viewingDate
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
                // Scrollable content area
                ScrollView {
                    VStack(spacing: Spacing.large) {
                        // Header with emoji and name
                        VStack(spacing: Spacing.medium) {
                            Text(habit.emoji ?? "📊")
                                .font(.system(size: 48)) // Keep fixed for decorative emoji
                            
                            Text(habit.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Progress circle with +/- controls on sides
                        VStack(spacing: Spacing.medium) {
                            HStack(spacing: Spacing.xlarge) {
                                // Minus button - orange to blue gradient
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

                                // Plus button - green to blue gradient
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

                            // Celebration text - fixed height to prevent layout jumps
                            Group {
                                if value == dailyTarget {
                                    HStack(spacing: Spacing.small) {
                                        Text("🏆")
                                            .accessibilityHidden(true) // Decorative emoji
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
                                            .accessibilityHidden(true) // Decorative emoji
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
                            .frame(minHeight: celebrationHeight)
                        }

                        // Quick increment buttons - scales with Dynamic Type
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
                        .frame(minHeight: quickIncrementHeight)

                        // Reset, Complete All, and Done buttons
                        HStack {
                            // Reset button - bottom left (only show if value > 0)
                            if value > 0 {
                                resetButton()
                            }

                            Spacer()

                            // Complete All button - disabled when target reached
                            completeButton()
                                .disabled(isCompleted)
                                .opacity(isCompleted ? 0.4 : 1)

                            // Done button - dismisses sheet
                            doneButton()
                        }
                        .padding(.top, Spacing.small)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, Spacing.large)
                }
            }
            .navigationTitle(Strings.NumericHabitLog.title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.fraction(0.6)])
        .presentationDragIndicator(.visible)
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                UIAccessibility.post(notification: .screenChanged, argument: "Log \(habit.name)")
            }
        }
        .onDisappear {
            loadTask?.cancel()
            loadTask = nil
            saveTask?.cancel()
            saveTask = nil
        }
        .onChange(of: currentValue) { _, newValue in
            value = newValue
        }
        .onChange(of: value) { oldValue, newValue in
            // Auto-save when value changes (skip initial load)
            guard !isLoading, oldValue != newValue else { return }

            // Set extra mile text when first exceeding target
            if newValue > dailyTarget && extraMileText == nil {
                extraMileText = Strings.NumericHabitLog.extraMilePhrases.randomElement()
            }

            // Debounce saves to prevent excessive database writes during rapid changes
            saveTask?.cancel()
            saveTask = Task {
                // Wait 300ms before saving - allows rapid clicks to coalesce
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }

                do {
                    try await onSave(newValue)
                } catch {
                    logger.log(
                        "Failed to auto-save habit value",
                        level: .error,
                        category: .dataIntegrity,
                        metadata: ["habit_id": habit.id.uuidString, "value": "\(newValue)", "error": error.localizedDescription]
                    )
                    #if DEBUG
                    toastService.error(Strings.Error.failedToSave)
                    #endif
                }
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
                .cornerRadius(12)
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
                .cornerRadius(12)
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
                .cornerRadius(12)
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
                .font(.headline)
                .foregroundStyle(gradient)
                .padding(.horizontal, Spacing.medium)
                .frame(minWidth: 60)
                .frame(minHeight: buttonHeight)
                .background(gradient.opacity(0.15))
                .cornerRadius(8)
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

                let targetDateLogs = logs.filter { CalendarUtils.areSameDayLocal($0.date, viewingDate) }
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
