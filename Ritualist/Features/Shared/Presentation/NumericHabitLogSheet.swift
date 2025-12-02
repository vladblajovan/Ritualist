import SwiftUI
import RitualistCore
import FactoryKit

// Simple direct sheet - no fucking caches
public struct NumericHabitLogSheetDirect: View { // swiftlint:disable:this type_body_length
    let habit: Habit
    let viewingDate: Date
    let onSave: (Double) async -> Void
    let onCancel: () -> Void
    let initialValue: Double?

    @Injected(\.getLogs) private var getLogs
    @State private var currentValue: Double = 0.0
    @State private var isLoading = true
    @State private var isGlowing = false
    
    @State private var value: Double = 0.0
    @Environment(\.dismiss) private var dismiss
    
    public init(
        habit: Habit,
        viewingDate: Date,
        onSave: @escaping (Double) async -> Void,
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
        habit.unitLabel?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false 
            ? habit.unitLabel! 
            : "units"
    }
    
    /// Maximum allowed value (10% over target, minimum 50 over)
    private var maxAllowedValue: Double {
        dailyTarget + max(50, dailyTarget * 0.1)
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

    /// Adaptive quick increment values based on remaining progress
    /// Scales from small increments (close to target) to large (far from target)
    /// Handles targets from single digits to 100,000+
    private var quickIncrementAmounts: [Int] {
        let rem = Int(remaining)

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

                            if isCompleted {
                                Text("Target reached!")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [CardDesign.progressGreen, CardDesign.progressGreen.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .fontWeight(.medium)
                            }
                        }

                        // Quick increment buttons
                        if !quickIncrementAmounts.isEmpty {
                            HStack(spacing: Spacing.medium) {
                                ForEach(quickIncrementAmounts, id: \.self) { amount in
                                    quickIncrementButton(amount: amount)
                                }
                            }
                        }

                        // Reset and Complete All buttons - bottom row
                        HStack {
                            // Reset button - bottom left (only show if value > 0)
                            if value > 0 {
                                resetButton()
                            }

                            Spacer()

                            // Complete All button - bottom right (only show if not completed)
                            if !isCompleted {
                                completeButton()
                            }
                        }
                        .padding(.top, Spacing.small)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, Spacing.large)
                }
                
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
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
        .onChange(of: currentValue) { _, newValue in
            value = newValue
        }
        .onChange(of: value) { oldValue, newValue in
            // Auto-save when value changes (skip initial load)
            guard !isLoading, oldValue != newValue else { return }
            Task {
                await onSave(newValue)
            }
        }
        .completionGlow(isGlowing: isGlowing)
    }

    @ViewBuilder
    private func resetButton() -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = 0
            }
        } label: {
            Text("Reset")
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
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = dailyTarget
            }
        } label: {
            Text("Complete All")
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
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = min(value + Double(amount), maxAllowedValue)
            }
        } label: {
            Text("+\(formatAmount(amount))")
                .font(.headline)
                .foregroundColor(AppColors.brand)
                .padding(.horizontal, Spacing.medium)
                .frame(minWidth: 60)
                .frame(height: 36)
                .background(AppColors.brand.opacity(0.1))
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
        Task {
            do {
                let logs = try await getLogs.execute(for: habit.id, since: nil, until: nil)
                let targetDateLogs = logs.filter { CalendarUtils.areSameDayLocal($0.date, viewingDate) }
                let totalValue = targetDateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                
                await MainActor.run {
                    currentValue = totalValue
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    currentValue = 0.0
                    isLoading = false
                }
            }
        }
    }
}
