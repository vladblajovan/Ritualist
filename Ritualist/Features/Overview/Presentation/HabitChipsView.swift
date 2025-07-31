import SwiftUI

public struct HabitChipsView: View {
    let habits: [Habit]
    let selectedHabit: Habit?
    let onHabitSelect: (Habit) async -> Void
    
    public init(habits: [Habit], selectedHabit: Habit?, onHabitSelect: @escaping (Habit) async -> Void) {
        self.habits = habits
        self.selectedHabit = selectedHabit
        self.onHabitSelect = onHabitSelect
    }
    
    public var body: some View {
        VStack(spacing: Spacing.small) {
            // Scroll view with chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.medium) {
                    ForEach(habits, id: \.id) { habit in
                        HabitChip(
                            habit: habit,
                            isSelected: selectedHabit?.id == habit.id
                        ) {
                            await onHabitSelect(habit)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .mask(
                // Fade out edges when content overflows
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black, location: 0.05),
                        .init(color: .black, location: 0.95),
                        .init(color: .clear, location: 1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            
            // Scroll indicator dots (if more than 3 habits)
            if habits.count > 3 {
                HStack(spacing: Spacing.xxsmall) {
                    ForEach(0..<min(habits.count, 5), id: \.self) { index in
                        Circle()
                            .fill(selectedHabit?.id == habits[index].id ? AppColors.brand : Color.secondary.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                    
                    if habits.count > 5 {
                        Text("...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
    }
}

public struct HabitChip: View {
    public let habit: Habit
    public let isSelected: Bool
    public let onTap: () async -> Void
    
    public init(habit: Habit, isSelected: Bool, onTap: @escaping () async -> Void) {
        self.habit = habit
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            Task { await onTap() }
        } label: {
            HStack(spacing: Spacing.small) {
                Text(habit.emoji ?? "•")
                Text(habit.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ? Color(hex: habit.colorHex) ?? AppColors.brand : Color(.systemGray6),
                in: Capsule()
            )
            .foregroundColor(
                isSelected ? .white : .primary
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Strings.Accessibility.habitChip(habit.name))
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}