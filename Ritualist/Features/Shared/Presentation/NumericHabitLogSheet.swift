import SwiftUI
import RitualistCore
import FactoryKit

// Simple direct sheet - no fucking caches
public struct NumericHabitLogSheetDirect: View {
    let habit: Habit
    let viewingDate: Date
    let onSave: (Double) async -> Void
    let onCancel: () -> Void
    let initialValue: Double?
    
    @Injected(\.getLogs) private var getLogs
    @Injected(\.hapticFeedbackService) private var hapticService
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
    
    private var isValidValue: Bool {
        value >= 0 && value <= dailyTarget + 50
    }
    
    private var canDecrement: Bool {
        value > 0
    }
    
    private var canIncrement: Bool {
        value < dailyTarget + 50
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
                        
                        // Progress circle and status
                        VStack(spacing: Spacing.medium) {
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
                        
                        // Increment/decrement controls
                        VStack(spacing: Spacing.large) {
                            HStack(spacing: 24) {
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
                            
                            if dailyTarget >= 5 {
                                HStack(spacing: Spacing.medium) {
                                    quickIncrementButton(amount: 5)
                                    if dailyTarget >= 10 {
                                        quickIncrementButton(amount: 10)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Fixed button area at bottom
                VStack(spacing: Spacing.small) {
                    if !isValidValue {
                        Text("Value must be between 0 and \(Int(dailyTarget + 50))")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, Spacing.large)
                    }
                    
                    HStack(spacing: Spacing.medium) {
                        if !isCompleted && value < dailyTarget {
                            if #available(iOS 26.0, *) {
                                Button {
                                    // Trigger glow effect and success haptic
                                    isGlowing = true
                                    hapticService.triggerCompletion(type: .milestone)
                                    
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        value = dailyTarget
                                    }
                                    
                                    Task {
                                        // Small delay for glow effect
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                        await onSave(dailyTarget)
                                        await MainActor.run {
                                            isGlowing = false
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Complete All")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.medium)
                                }
                                .buttonStyle(.plain)
                                .glassEffect(.regular.tint(AppColors.brand), in: RoundedRectangle(cornerRadius: 25))
                            } else {
                                Button {
                                    // Trigger glow effect and success haptic
                                    isGlowing = true
                                    hapticService.triggerCompletion(type: .milestone)
                                    
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        value = dailyTarget
                                    }
                                    
                                    Task {
                                        // Small delay for glow effect
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                        await onSave(dailyTarget)
                                        await MainActor.run {
                                            isGlowing = false
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                        Text("Complete All")
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.medium)
                                    .background(AppColors.brand)
                                    .cornerRadius(25)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if #available(iOS 26.0, *) {
                            Button {
                                if isValidValue {
                                    // Trigger glow effect and progress haptic
                                    isGlowing = true
                                    hapticService.triggerCompletion(type: .standard)
                                    
                                    Task {
                                        // Small delay for glow effect
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                        await onSave(value)
                                        await MainActor.run {
                                            isGlowing = false
                                            dismiss()
                                        }
                                    }
                                }
                            } label: {
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.medium)
                            }
                            .glassEffect(.regular.tint(.green), in: RoundedRectangle(cornerRadius: 25))
                            .disabled(!isValidValue)
                        } else {
                            Button {
                                if isValidValue {
                                    // Trigger glow effect and progress haptic
                                    isGlowing = true
                                    hapticService.triggerCompletion(type: .standard)
                                    
                                    Task {
                                        // Small delay for glow effect
                                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                                        await onSave(value)
                                        await MainActor.run {
                                            isGlowing = false
                                            dismiss()
                                        }
                                    }
                                }
                            } label: {
                                Text("Save")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, Spacing.medium)
                                    .background(.green)
                                    .cornerRadius(25)
                            }
                            .disabled(!isValidValue)
                        }
                    }
                    .padding(.horizontal, Spacing.medium)
                }
                .padding(.bottom, Spacing.medium)
                .background(.regularMaterial)
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
            }
        }
        .deviceAwareSheetSizing(
            compactMultiplier: SizeMultiplier(min: 0.92, ideal: 0.95, max: 0.98),
            regularMultiplier: SizeMultiplier(min: 0.67, ideal: 0.73, max: 0.87),
            largeMultiplier: SizeMultiplier(min: 0.61, ideal: 0.67, max: 0.78)
        )
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
        .completionGlow(isGlowing: isGlowing)
    }
    
    @ViewBuilder
    private func quickIncrementButton(amount: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                value = min(value + Double(amount), dailyTarget + 10)
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
    
    private func loadCurrentValue() {
        Task {
            do {
                let logs = try await getLogs.execute(for: habit.id, since: nil, until: nil)
                let targetDateLogs = logs.filter { CalendarUtils.areSameDayUTC($0.date, viewingDate) }
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