import SwiftUI

struct QuickActionsCard: View {
    let incompleteHabits: [Habit]
    let completedHabits: [Habit]
    let currentSlogan: String?
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let onHabitComplete: (Habit) -> Void
    
    @State private var animatingHabitId: UUID? = nil
    
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
    }
    
    @ViewBuilder
    private func habitChip(for habit: Habit, isCompleted: Bool) -> some View {
        Button {
            if !isCompleted {
                // Start fade animation before calling completion
                withAnimation(.easeOut(duration: 0.3)) {
                    animatingHabitId = habit.id
                }
                
                // Delay the completion callback to allow fade animation
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    onHabitComplete(habit)
                    animatingHabitId = nil
                }
            }
        } label: {
            HStack(spacing: 12) {
                // Habit Emoji
                Text(habit.emoji ?? "📊")
                    .font(.title3)
                    .frame(width: 28, height: 28)
                
                // Habit Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(isCompleted ? .primary.opacity(0.8) : .primary)
                        .lineLimit(1)
                    
                    if habit.kind == .numeric, let unitLabel = habit.unitLabel {
                        Text("\(Int(habit.dailyTarget ?? 1.0)) \(unitLabel)")
                            .font(.caption)
                            .foregroundColor(isCompleted ? .secondary.opacity(0.7) : .secondary)
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
                    .fill(isCompleted ? Color.green.opacity(0.15) : Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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
            onHabitComplete: { _ in }
        )
        
        // Perfect day state
        QuickActionsCard(
            incompleteHabits: [],
            completedHabits: [],
            currentSlogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            onHabitComplete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
