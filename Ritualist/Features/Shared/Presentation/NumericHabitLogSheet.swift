import SwiftUI
import RitualistCore
import FactoryKit

// Simple direct sheet - no fucking caches
public struct NumericHabitLogSheetDirect: View {
    let habit: Habit
    let viewingDate: Date
    let getCurrentProgress: ((Habit) -> Double)?
    let onSave: (Double) -> Void
    let onCancel: () -> Void
    
    @Injected(\.logRepository) private var logRepository
    @State private var currentValue: Double = 0.0
    
    public var body: some View {
        NumericHabitLogSheet(
            habit: habit,
            currentValue: currentValue,
            onSave: onSave,
            onCancel: onCancel
        )
        .onAppear {
            loadCurrentValue()
        }
    }
    
    private func loadCurrentValue() {
        Task {
            do {
                let logs = try await logRepository.logs(for: habit.id)
                let targetDateLogs = logs.filter { Calendar.current.isDate($0.date, inSameDayAs: viewingDate) }
                let totalValue = targetDateLogs.reduce(0.0) { $0 + ($1.value ?? 0.0) }
                
                await MainActor.run {
                    currentValue = totalValue
                }
            } catch {
                await MainActor.run {
                    currentValue = 0.0
                }
            }
        }
    }
}

public struct NumericHabitLogSheet: View {
    let habit: Habit
    let currentValue: Double
    let onSave: (Double) -> Void
    let onCancel: () -> Void
    
    @State private var value: Double
    @Environment(\.dismiss) private var dismiss
    
    public init(
        habit: Habit,
        currentValue: Double = 0.0,
        onSave: @escaping (Double) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.habit = habit
        self.currentValue = currentValue
        self.onSave = onSave
        self.onCancel = onCancel
        self._value = State(initialValue: currentValue)
    }
    
    private var dailyTarget: Double {
        max(habit.dailyTarget ?? 1.0, 1.0) // Ensure target is at least 1
    }
    
    private var progressPercentage: Double {
        guard dailyTarget > 0 else { return 0 }
        return min(max(value / dailyTarget, 0.0), 1.0) // Clamp between 0 and 1
    }
    
    private var isCompleted: Bool {
        value >= dailyTarget
    }
    
    private var unitLabel: String {
        habit.unitLabel?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false 
            ? habit.unitLabel! 
            : "units"
    }
    
    private var isValidValue: Bool {
        value >= 0 && value <= dailyTarget + 50 // Allow some overshoot but not ridiculous values
    }
    
    private var canDecrement: Bool {
        value > 0
    }
    
    private var canIncrement: Bool {
        value < dailyTarget + 50 // Allow overshoot but prevent runaway values
    }
    
    private var hasChanges: Bool {
        abs(value - currentValue) > 0.001 // Account for floating point precision
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                // Header with habit info
                VStack(spacing: Spacing.medium) {
                    Text(habit.emoji ?? "📊")
                        .font(.system(size: 48))
                    
                    Text(habit.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.large)
                
                // Progress visualization
                VStack(spacing: Spacing.medium) {
                    // Circular progress
                    ZStack {
                        Circle()
                            .stroke(AppColors.brand.opacity(0.2), lineWidth: 8)
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .trim(from: 0, to: progressPercentage)
                            .stroke(
                                isCompleted ? .green : AppColors.brand,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progressPercentage)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(value))")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(isCompleted ? .green : .primary)
                            Text("/ \(Int(dailyTarget))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Text("\(Int(value)) of \(Int(dailyTarget)) \(unitLabel)")
                        .font(.headline)
                        .foregroundColor(isCompleted ? .green : .primary)
                    
                    if isCompleted {
                        Text("🎉 Target reached!")
                            .font(.subheadline)
                            .foregroundColor(.green)
                            .fontWeight(.medium)
                    }
                }
                
                // Controls
                VStack(spacing: Spacing.large) {
                    // Main increment/decrement controls
                    HStack(spacing: Spacing.large) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                value = max(0, value - 1)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(canDecrement ? AppColors.brand : AppColors.brand.opacity(0.3))
                        }
                        .disabled(!canDecrement)
                        
                        Spacer()
                        
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                value += 1
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(canIncrement ? AppColors.brand : AppColors.brand.opacity(0.3))
                        }
                        .disabled(!canIncrement)
                    }
                    .padding(.horizontal, Spacing.xlarge)
                    
                    // Quick increment buttons for larger targets
                    if dailyTarget >= 5 {
                        HStack(spacing: Spacing.medium) {
                            quickIncrementButton(amount: 5)
                            if dailyTarget >= 10 {
                                quickIncrementButton(amount: 10)
                            }
                        }
                    }
                    
                    // Complete all button
                    if !isCompleted && value < dailyTarget {
                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                value = dailyTarget
                            }
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Complete All (\(Int(dailyTarget)) \(unitLabel))")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.medium)
                            .background(AppColors.brand)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, Spacing.medium)
                    }
                    
                    // Show validation error if invalid value
                    if !isValidValue {
                        Text("Value must be between 0 and \(Int(dailyTarget + 50))")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.large)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Log Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        if isValidValue {
                            onSave(value)
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValidValue)
                }
            }
        }
    }
    
    @ViewBuilder
    private func quickIncrementButton(amount: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = min(value + Double(amount), dailyTarget + 10) // Allow slight overshoot
            }
        } label: {
            Text("+\(amount)")
                .font(.headline)
                .foregroundColor(AppColors.brand)
                .frame(width: 60, height: 36)
                .background(AppColors.brand.opacity(0.1))
                .cornerRadius(8)
        }
    }
}

#Preview {
    NumericHabitLogSheet(
        habit: Habit(
            id: UUID(),
            name: "Drink Water",
            emoji: "💧",
            kind: .numeric,
            unitLabel: "glasses",
            dailyTarget: 8.0,
            isActive: true
        ),
        currentValue: 3.0,
        onSave: { value in
            print("Saved value: \(value)")
        },
        onCancel: {
            print("Cancelled")
        }
    )
}