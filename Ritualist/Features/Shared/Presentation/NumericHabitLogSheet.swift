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
    
    private var dailyTarget: Double {
        max(habit.dailyTarget ?? 1.0, 1.0)
    }
    
    private var progressPercentage: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(max(value / dailyTarget, 0.0), 1.0)
    }
    
    private var isCompleted: Bool {
        value >= dailyTarget
    }
    
    private var unitLabel: String {
        if let label = habit.unitLabel?.trimmingCharacters(in: .whitespacesAndNewlines),
           !label.isEmpty {
            return label
        }
        return "units"
    }
    
    /// Maximum allowed value (10% over target, minimum 50 over, capped at 2x target)
    private var maxAllowedValue: Double {
        let calculated = dailyTarget + max(50, dailyTarget * 0.1)
        return min(calculated, dailyTarget * 2.0)
    }

    private var isValidValue: Bool {
        value >= 0 && value <= maxAllowedValue
    }

    private var canDecrement: Bool {
        value > 0
    }

    private var canIncrement: Bool {
        value < maxAllowedValue
    }

    /// Remaining amount to reach target
    private var remaining: Double {
        max(dailyTarget - value, 0)
    }

    /// Remaining amount to reach max allowed value
    private var remainingToMax: Double {
        max(maxAllowedValue - value, 0)
    }

    /// Adaptive quick increment values based on remaining progress
    /// Before target: computed against remaining to target
    /// After target: computed against remaining to max
    private var quickIncrementAmounts: [Int] {
        let rem = Int(isCompleted ? remainingToMax : remaining)

        switch rem {
        case ..<5:
            return []  // No quick buttons when very close
        case 5..<20:
            return [2, 5]
        case 20..<100:
            return [5, 10]
        case 100..<500:
            return [10, 50]
        case 500..<2000:
            return [100, 500]
        case 2000..<10000:
            return [500, 1000]
        case 10000..<50000:
            return [1000, 5000]
        default:
            return [5000, 10000]
        }
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
                                .font(.system(size: 48))
                            
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
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        value = max(0, value - 1)
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 44))
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

                                // Progress circle
                                ZStack {
                                    CircularProgressView(
                                        progress: progressPercentage,
                                        lineWidth: 10,
                                        showPercentage: false,
                                        useAdaptiveGradient: true
                                    )
                                    .frame(width: 120, height: 120)

                                    VStack(spacing: 2) {
                                        Text("\(Int(value))")
                                            .font(.system(size: 28, weight: .bold))
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

                                // Plus button - green to blue gradient
                                Button {
                                    HapticFeedbackService.shared.trigger(.light)
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        value += 1
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 44))
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
                            }

                            // Celebration text - fixed height to prevent layout jumps
                            Group {
                                if value == dailyTarget {
                                    HStack(spacing: Spacing.small) {
                                        Text("🏆")
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
                            .frame(height: 24)
                        }

                        // Quick increment buttons - fixed height to prevent layout jumps
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
                        .frame(height: 36)

                        // Reset and Complete All buttons
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
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading current value...")
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
        }
        .onDisappear {
            loadTask?.cancel()
            saveTask?.cancel()
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = 0
            }
        } label: {
            Text(Strings.NumericHabitLog.reset)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, Spacing.large)
                .frame(height: 44)
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
        }
    }

    @ViewBuilder
    private func completeButton() -> some View {
        let adaptiveColor = CircularProgressView.adaptiveProgressColors(for: 1.0).last ?? CardDesign.progressGreen
        Button {
            HapticFeedbackService.shared.trigger(.success)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = dailyTarget
            }
        } label: {
            Text(Strings.NumericHabitLog.completeAll)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(adaptiveColor)
                .padding(.horizontal, Spacing.large)
                .frame(height: 44)
                .background(adaptiveColor.opacity(0.1))
                .cornerRadius(12)
        }
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = min(value + Double(amount), maxAllowedValue)
            }
        } label: {
            Text("+\(formatAmount(amount))")
                .font(.headline)
                .foregroundStyle(gradient)
                .padding(.horizontal, Spacing.medium)
                .frame(minWidth: 60)
                .frame(height: 36)
                .background(gradient.opacity(0.15))
                .cornerRadius(8)
        }
    }

    /// Format large numbers with K suffix for readability
    private func formatAmount(_ amount: Int) -> String {
        if amount >= 1000 {
            let thousands = Double(amount) / 1000.0
            if thousands == Double(Int(thousands)) {
                return "\(Int(thousands))K"
            }
            return String(format: "%.1fK", thousands)
        }
        return "\(amount)"
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
