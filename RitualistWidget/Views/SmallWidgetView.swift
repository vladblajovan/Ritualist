//
//  SmallWidgetView.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

/// Small widget view (70x70 points) showing remaining habits count and top 2 habits
/// Adapts the QuickActionsCard design for compact widget display
struct SmallWidgetView: View {
    let habits: [Habit]
    let habitProgress: [UUID: Int]
    let completionPercentage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header matching QuickActionsCard style
            headerView
            
            if habits.isEmpty {
                completedStateView
            } else {
                habitsListView
            }
        }
        .padding(.top, 14)
        .padding([.leading, .trailing, .bottom], 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack(spacing: 6) {
            Text("⚡")
                .font(.title3)
            
            Text("\(habits.count) left")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    private var completedStateView: some View {
        VStack(spacing: 4) {
            Spacer()
            
            Text("🎉")
                .font(.title)
                .frame(maxWidth: .infinity)
            
            Text("All done!")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
    }
    
    private var habitsListView: some View {
        VStack(spacing: 6) {
            // Show top 2 habits
            ForEach(Array(habits.prefix(2).enumerated()), id: \.element.id) { index, habit in
                WidgetHabitChip(habit: habit, currentProgress: habitProgress[habit.id] ?? 0)
            }
            
            // Show remaining count if more than 2 habits
            if habits.count > 2 {
                HStack {
                    Text("+\(habits.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Small Widget - With Habits") {
    let habits = [
        Habit(
            id: UUID(),
            name: "Morning Reading",
            emoji: "📚",
            kind: .binary,
            schedule: .daily,
            isActive: true,
            displayOrder: 1
        ),
        Habit(
            id: UUID(),
            name: "Exercise",
            emoji: "🏃",
            kind: .numeric,
            dailyTarget: 30,
            schedule: .daily,
            isActive: true,
            displayOrder: 2
        ),
        Habit(
            id: UUID(),
            name: "Meditation",
            emoji: "🧘",
            kind: .binary,
            schedule: .daily,
            isActive: true,
            displayOrder: 3
        )
    ]
    let habitProgress = Dictionary(uniqueKeysWithValues: habits.enumerated().map { ($1.id, $0 * 5) })
    
    return SmallWidgetView(
        habits: habits,
        habitProgress: habitProgress,
        completionPercentage: 0.3
    )
    .frame(width: 155, height: 155)
    .background(Color(.systemBackground))
}

#Preview("Small Widget - All Done") {
    SmallWidgetView(
        habits: [],
        habitProgress: [:],
        completionPercentage: 1.0
    )
    .frame(width: 155, height: 155)
    .background(Color(.systemBackground))
}