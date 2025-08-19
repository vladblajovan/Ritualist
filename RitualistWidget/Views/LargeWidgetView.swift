//
//  LargeWidgetView.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

/// Large widget view (338x354 points) showing comprehensive habit overview
/// Displays all remaining habits with detailed progress and time-based insights with date navigation
struct LargeWidgetView: View {
    let entry: RemainingHabitsEntry
    
    // Fixed heights to ensure uniform card appearance
    private let chipHeight: CGFloat = 50
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date navigation header
            WidgetDateNavigationHeader(entry: entry, size: .large)
            
            headerView
            
            habitsSections
            
            Spacer()
        }
        .padding(.top, 16)
        .padding([.leading, .trailing, .bottom], 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Current Progress header with percentage
            HStack {
                Text("Current Progress:")
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(Int(entry.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            
            ProgressView(value: entry.completionPercentage)
                .tint(Color.widgetBrand)
        }
    }
    
    
    
    private var habitsSections: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Remaining habits section
            if !remainingHabits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader(title: "Remaining", count: remainingHabits.count)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(remainingHabits.prefix(6).enumerated()), id: \.element.habit.id) { index, habitInfo in
                            WidgetHabitChip(
                                habitDisplayInfo: habitInfo, 
                                isViewingToday: entry.navigationInfo.isViewingToday,
                                selectedDate: entry.navigationInfo.selectedDate
                            )
                            .frame(height: chipHeight)
                        }
                    }
                    
                    // Additional remaining habits in horizontal scroll if needed
                    if remainingHabits.count > 6 {
                        additionalHabitsView(habits: Array(remainingHabits.dropFirst(6)))
                    }
                }
            }
            
            // Completed habits section
            if !completedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader(title: "Completed", count: completedHabits.count)
                    
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(completedHabits.prefix(4).enumerated()), id: \.element.habit.id) { index, habitInfo in
                            WidgetHabitChip(
                                habitDisplayInfo: habitInfo, 
                                isViewingToday: entry.navigationInfo.isViewingToday,
                                selectedDate: entry.navigationInfo.selectedDate
                            )
                            .frame(height: chipHeight)
                        }
                    }
                    
                    // Additional completed habits in horizontal scroll if needed
                    if completedHabits.count > 4 {
                        additionalHabitsView(habits: Array(completedHabits.dropFirst(4)))
                    }
                }
            }
        }
    }
    
    // MARK: - Section Components
    
    @ViewBuilder
    private func sectionHeader(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("(\(count))")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    private func additionalHabitsView(habits: [HabitDisplayInfo]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Additional")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(habits.prefix(6), id: \.habit.id) { habitInfo in
                        CompactHabitChip(habitDisplayInfo: habitInfo)
                    }
                    
                    if habits.count > 6 {
                        Text("+\(habits.count - 6) more")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var remainingHabits: [HabitDisplayInfo] {
        entry.habitDisplayInfo.filter { !$0.isCompleted }
    }
    
    private var completedHabits: [HabitDisplayInfo] {
        entry.habitDisplayInfo.filter { $0.isCompleted }
    }
}

// MARK: - Compact Habit Chip

private struct CompactHabitChip: View {
    let habitDisplayInfo: HabitDisplayInfo
    
    private var habit: Habit {
        habitDisplayInfo.habit
    }
    
    var body: some View {
        Link(destination: WidgetConstants.habitDeepLinkURL(for: habit.id)) {
            HStack(spacing: 4) {
                Text(habit.emoji ?? WidgetConstants.defaultHabitEmoji)
                    .font(.caption2)
                
                Text(habit.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                // Show completion indicator for completed habits
                if habitDisplayInfo.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(habitDisplayInfo.isCompleted ? Color.green.opacity(0.1) : Color.widgetBrand.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(habitDisplayInfo.isCompleted ? Color.green.opacity(0.2) : Color.widgetBrand.opacity(0.2), lineWidth: 1)
            )
            .opacity(habitDisplayInfo.isCompleted ? 1.0 : 0.7)
        }
    }
}

// MARK: - Preview

#Preview("Large Widget - Mixed Progress") {
    let habits = [
        Habit(id: UUID(), name: "Morning Reading", emoji: "📚", kind: .binary, schedule: .daily, isActive: true, displayOrder: 1),
        Habit(id: UUID(), name: "Exercise", emoji: "🏃", kind: .numeric, dailyTarget: 10000, schedule: .daily, isActive: true, displayOrder: 2),
        Habit(id: UUID(), name: "Meditation", emoji: "🧘", kind: .binary, schedule: .daily, isActive: true, displayOrder: 3),
        Habit(id: UUID(), name: "Water", emoji: "💧", kind: .numeric, dailyTarget: 8, schedule: .daily, isActive: true, displayOrder: 4),
        Habit(id: UUID(), name: "Journaling", emoji: "📝", kind: .binary, schedule: .daily, isActive: true, displayOrder: 5),
        Habit(id: UUID(), name: "Stretching", emoji: "🤸", kind: .binary, schedule: .daily, isActive: true, displayOrder: 6),
        Habit(id: UUID(), name: "Learning", emoji: "📖", kind: .binary, schedule: .daily, isActive: true, displayOrder: 7),
        Habit(id: UUID(), name: "Walk", emoji: "🚶", kind: .numeric, dailyTarget: 5000, schedule: .daily, isActive: true, displayOrder: 8)
    ]
    let habitDisplayInfo = [
        HabitDisplayInfo(habit: habits[0], currentProgress: 1, isCompleted: true),    // Completed
        HabitDisplayInfo(habit: habits[1], currentProgress: 7500, isCompleted: false), // Remaining
        HabitDisplayInfo(habit: habits[2], currentProgress: 1, isCompleted: true),    // Completed
        HabitDisplayInfo(habit: habits[3], currentProgress: 6, isCompleted: false),   // Remaining
        HabitDisplayInfo(habit: habits[4], currentProgress: 0, isCompleted: false),   // Remaining
        HabitDisplayInfo(habit: habits[5], currentProgress: 1, isCompleted: true),    // Completed
        HabitDisplayInfo(habit: habits[6], currentProgress: 0, isCompleted: false),   // Remaining
        HabitDisplayInfo(habit: habits[7], currentProgress: 3200, isCompleted: false) // Remaining
    ]
    let selectedDate = Calendar.current.date(byAdding: .day, value: -3, to: Date())!
    let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: habitDisplayInfo,
        completionPercentage: 0.375, // 3 completed out of 8
        navigationInfo: navigationInfo
    )
    
    return LargeWidgetView(entry: entry)
    .frame(width: 338, height: 354)
    .background(Color(.systemBackground))
}

#Preview("Large Widget - All Done") {
    let habits = [
        Habit(id: UUID(), name: "Morning Reading", emoji: "📚", kind: .binary, schedule: .daily, isActive: true, displayOrder: 1),
        Habit(id: UUID(), name: "Exercise", emoji: "🏃", kind: .numeric, dailyTarget: 30, schedule: .daily, isActive: true, displayOrder: 2),
        Habit(id: UUID(), name: "Meditation", emoji: "🧘", kind: .binary, schedule: .daily, isActive: true, displayOrder: 3),
        Habit(id: UUID(), name: "Water", emoji: "💧", kind: .numeric, dailyTarget: 8, schedule: .daily, isActive: true, displayOrder: 4)
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
    
    return LargeWidgetView(entry: entry)
        .frame(width: 338, height: 354)
        .background(Color(.systemBackground))
}