//
//  SmallWidgetView.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

/// Small widget view (155x155 points) showing remaining habits count and top 2 habits
/// Adapts the QuickActionsCard design for compact widget display with date navigation
struct SmallWidgetView: View {
    let entry: RemainingHabitsEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Date navigation header
            WidgetDateNavigationHeader(entry: entry, size: .small)
            
            // Header matching QuickActionsCard style  
            headerView
            
            habitsListView
        }
        .padding(.top, 8)
        .padding([.leading, .trailing, .bottom], 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack(spacing: 6) {
            Text("⚡")
                .font(.title3)
            
            Text("\(entry.habitDisplayInfo.count) habits")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    
    private var habitsListView: some View {
        VStack(spacing: 6) {
            // Show top 2 habits
            ForEach(Array(entry.habitDisplayInfo.prefix(2).enumerated()), id: \.element.habit.id) { index, habitInfo in
                WidgetHabitChip(
                    habitDisplayInfo: habitInfo, 
                    isViewingToday: entry.navigationInfo.isViewingToday,
                    selectedDate: entry.navigationInfo.selectedDate
                )
            }
            
            // Show remaining count if more than 2 habits
            if entry.habitDisplayInfo.count > 2 {
                HStack {
                    Text("+\(entry.habitDisplayInfo.count - 2) more")
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
    let habitDisplayInfo = habits.enumerated().map { index, habit in
        HabitDisplayInfo(habit: habit, currentProgress: index * 5, isCompleted: false)
    }
    let selectedDate = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: habitDisplayInfo,
        completionPercentage: 0.3,
        navigationInfo: navigationInfo
    )
    
    return SmallWidgetView(entry: entry)
        .frame(width: 155, height: 155)
        .background(Color(.systemBackground))
}

#Preview("Small Widget - All Done") {
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
        )
    ]
    let habitDisplayInfo = habits.map { habit in
        HabitDisplayInfo(habit: habit, currentProgress: Int(habit.dailyTarget ?? 1), isCompleted: true)
    }
    let navigationInfo = WidgetNavigationInfo(selectedDate: Date())
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: habitDisplayInfo,
        completionPercentage: 1.0,
        navigationInfo: navigationInfo
    )
    
    return SmallWidgetView(entry: entry)
        .frame(width: 155, height: 155)
        .background(Color(.systemBackground))
}