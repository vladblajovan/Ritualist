import SwiftUI
import RitualistCore

struct QuickActionsCard: View {
    let incompleteHabits: [Habit]
    let completedHabits: [Habit]
    let currentSlogan: String?
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let viewingDate: Date // Add viewing date from ViewModel
    let onHabitComplete: (Habit) -> Void
    let getProgressSync: (Habit) -> Double // Sync callback to get current progress from ViewModel
    let onNumericHabitUpdate: (Habit, Double) -> Void // New callback for numeric habit updates
    let onNumericHabitAction: ((Habit) -> Void)? // New callback for numeric habit sheet
    let onDeleteHabitLog: (Habit) -> Void // New callback for deleting habit log
    
    @State private var animatingHabitId: UUID? = nil
    @State private var showingDeleteAlert = false
    @State private var habitToDelete: Habit?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                HStack(spacing: 8) {
                    Text("⚡")
                        .font(.title2)
                    Text("Quick Log")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text("\(incompleteHabits.count) remaining")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(CardDesign.secondaryBackground)
                    )
            }
            
            // Always show Horizontal Scrolling Habit Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Incomplete habits first
                    ForEach(incompleteHabits, id: \.id) { habit in
                        habitChip(for: habit, isCompleted: false)
                            .opacity(animatingHabitId == habit.id ? 0.0 : 1.0)
                            .animation(.easeOut(duration: 0.3), value: animatingHabitId)
                    }
                    
                    // Completed habits at the end
                    ForEach(completedHabits, id: \.id) { habit in
                        habitChip(for: habit, isCompleted: true)
                    }
                }
                .padding(.horizontal, 2) // Small padding for shadow
            }
        }
        .cardStyle()
        .alert("Delete Log Entry?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {
                habitToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let habit = habitToDelete {
                    onDeleteHabitLog(habit)
                }
                habitToDelete = nil
            }
        } message: {
            if let habit = habitToDelete {
                Text("This will remove the log entry for \"\(habit.name)\" from today. The habit itself will remain.")
            }
        }
    }
    
    @ViewBuilder
    private func habitChip(for habit: Habit, isCompleted: Bool) -> some View {
        Button {
            if !isCompleted {
                if habit.kind == .numeric {
                    onNumericHabitAction?(habit)
                } else {
                    // For binary habits, complete immediately with animation
                    withAnimation(.easeOut(duration: 0.3)) {
                        animatingHabitId = habit.id
                    }
                    
                    Task {
                        // Small delay for animation, then complete
                        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
                        await MainActor.run {
                            onHabitComplete(habit)
                            animatingHabitId = nil
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Circular Progress Indicator with Emoji
                ZStack {
                    // Background circle with habit color at low opacity
                    Circle()
                        .fill(Color(hex: habit.colorHex).opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    // Progress border (only for incomplete habits)
                    if !isCompleted {
                        let progressValue: Double = {
                            if habit.kind == .numeric {
                                let currentValue = getProgressSync(habit)
                                let target = habit.dailyTarget ?? 1.0
                                return min(max(currentValue / target, 0.0), 1.0)
                            } else {
                                return 0.0 // Binary incomplete = 0%
                            }
                        }()
                        
                        Circle()
                            .trim(from: 0, to: progressValue)
                            .stroke(Color(hex: habit.colorHex), lineWidth: 3)
                            .frame(width: 40, height: 40)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.3), value: progressValue)
                    } 
                    // else {
                        // Completed habits show full circle - DISABLED: UX overkill
                        // Circle()
                        //     .trim(from: 0, to: 1.0)
                        //     .stroke(.green, lineWidth: 3)
                        //     .frame(width: 40, height: 40)
                        //     .rotationEffect(.degrees(-90))
                    // }
                    
                    // Emoji
                    Text(habit.emoji ?? "📊")
                        .font(.title3)
                }
                
                // Habit Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isCompleted ? .primary.opacity(0.8) : .primary)
                        .lineLimit(1)
                    
                    if habit.kind == .numeric, let unitLabel = habit.unitLabel {
                        numericHabitStatusText(habit: habit, unitLabel: unitLabel, isCompleted: isCompleted)
                    } else {
                        Text(isCompleted ? "Completed" : "Tap to complete")
                            .font(.caption)
                            .foregroundColor(isCompleted ? .green : .secondary)
                    }
                }
                
                // Complete Icon
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : AppColors.brand)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCompleted ? Color.green.opacity(0.15) : CardDesign.secondaryBackground)
                    .shadow(color: isCompleted ? .black.opacity(0.08) : .clear, radius: isCompleted ? 4 : 0, x: 0, y: isCompleted ? 2 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCompleted ? Color.green.opacity(0.3) : CardDesign.secondaryBackground, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCompleted)
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: incompleteHabits.count)
        .onLongPressGesture {
            if isCompleted {
                habitToDelete = habit
                showingDeleteAlert = true
            }
        }
    }
    
    
    @ViewBuilder
    private func numericHabitStatusText(habit: Habit, unitLabel: String, isCompleted: Bool) -> some View {
        if isCompleted {
            let target = Int(habit.dailyTarget ?? 1.0)
            Text("\(target) \(unitLabel) - Completed")
                .font(.caption)
                .foregroundColor(.green)
        } else {
            let currentValue = getProgressSync(habit)
            let target = habit.dailyTarget ?? 1.0
            let currentInt = Int(currentValue)
            let targetInt = Int(target)
            Text("\(currentInt)/\(targetInt) \(unitLabel)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // With incomplete and completed habits
        QuickActionsCard(
            incompleteHabits: [
                Habit(
                    id: UUID(),
                    name: "Morning Workout",
                    emoji: "💪",
                    kind: .binary,
                    unitLabel: nil,
                    dailyTarget: 1.0,
                    schedule: .daily,
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                ),
                Habit(
                    id: UUID(),
                    name: "Evening Reading",
                    emoji: "📚",
                    kind: .binary,
                    unitLabel: nil,
                    dailyTarget: 1.0,
                    schedule: .daily,
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                )
            ],
            completedHabits: [
                Habit(
                    id: UUID(),
                    name: "Water Intake",
                    emoji: "💧",
                    kind: .numeric,
                    unitLabel: "glasses",
                    dailyTarget: 8.0,
                    schedule: .daily,
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                )
            ],
            currentSlogan: "Rise with purpose, rule your day.",
            timeOfDay: .morning,
            completionPercentage: 0.6,
            viewingDate: Date(),
            onHabitComplete: { _ in },
            getProgressSync: { _ in 3.0 }, // Mock progress
            onNumericHabitUpdate: { _, _ in },
            onNumericHabitAction: { _ in },
            onDeleteHabitLog: { _ in }
        )
        
        // Perfect day state
        QuickActionsCard(
            incompleteHabits: [],
            completedHabits: [],
            currentSlogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            viewingDate: Date(),
            onHabitComplete: { _ in },
            getProgressSync: { _ in 0.0 },
            onNumericHabitUpdate: { _, _ in },
            onNumericHabitAction: { _ in },
            onDeleteHabitLog: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
