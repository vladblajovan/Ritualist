import SwiftUI

struct QuickActionsCard: View {
    let incompleteHabits: [Habit]
    let currentSlogan: String?
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let onHabitComplete: (Habit) -> Void
    
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
            
            if incompleteHabits.isEmpty {
                perfectDayState
            } else {
                // Horizontal Scrolling Habit Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(incompleteHabits, id: \.id) { habit in
                            habitChip(for: habit)
                        }
                    }
                    .padding(.horizontal, 2) // Small padding for shadow
                }
            }
        }
        .cardStyle()
    }
    
    @ViewBuilder
    private var perfectDayState: some View {
        VStack(spacing: 16) {
            // Time-aware celebration
            VStack(spacing: 8) {
                celebrationIcon
                    .font(.system(size: 36))
                    .scaleEffect(1.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8).repeatCount(1), value: incompleteHabits.isEmpty)
                
                Text(celebrationTitle)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
            }
            
            // Inspirational message based on time of day and slogan
            if let slogan = currentSlogan {
                Text(slogan)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(celebrationColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .italic()
            } else {
                Text(fallbackCelebrationMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Subtle animation elements
            HStack(spacing: 8) {
                ForEach(0..<5, id: \.self) { index in
                    Circle()
                        .fill(celebrationColor.opacity(0.6))
                        .frame(width: 4, height: 4)
                        .scaleEffect(1.0)
                        .animation(
                            .easeInOut(duration: 1.2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                            value: incompleteHabits.isEmpty
                        )
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            celebrationColor.opacity(0.08)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        )
    }
    
    private var celebrationIcon: Text {
        switch timeOfDay {
        case .morning:
            return Text("🌅") // sunrise
        case .noon:
            return Text("✨") // sparkles
        case .evening:
            return Text("🎆") // fireworks
        }
    }
    
    private var celebrationTitle: String {
        switch timeOfDay {
        case .morning:
            return "Perfect Morning!"
        case .noon:
            return "Crushing It!"
        case .evening:
            return "Day Complete!"
        }
    }
    
    private var celebrationColor: Color {
        switch timeOfDay {
        case .morning:
            return .orange
        case .noon:
            return .green
        case .evening:
            return .purple
        }
    }
    
    private var fallbackCelebrationMessage: String {
        switch timeOfDay {
        case .morning:
            return "All morning habits completed! Ready to conquer the day ahead."
        case .noon:
            return "Fantastic progress! You're staying consistent throughout the day."
        case .evening:
            return "Perfect finish! You've successfully completed all your habits today."
        }
    }
    
    @ViewBuilder
    private func habitChip(for habit: Habit) -> some View {
        Button {
            onHabitComplete(habit)
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
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if habit.kind == .numeric, let unitLabel = habit.unitLabel {
                        Text("\(Int(habit.dailyTarget ?? 1.0)) \(unitLabel)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Tap to complete")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Complete Icon
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundColor(AppColors.brand)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(CardDesign.secondaryBackground, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: incompleteHabits.count)
    }
}

#Preview {
    VStack(spacing: 20) {
        // With incomplete habits
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
                ),
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
            currentSlogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            onHabitComplete: { _ in }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
