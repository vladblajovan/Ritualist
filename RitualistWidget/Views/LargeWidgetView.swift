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
    
    // Dynamic sizing based on available space
    private var chipSize: CGFloat {
        // Base size that scales well on different devices
        // Widget width is 338, with 6+6 padding = 326 available width
        // For ~7 chips per row: (326 - 6*6 spacing) / 7 ≈ 41
        return 41
    }
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date navigation header
            WidgetDateNavigationHeader(entry: entry, size: .large, completionPercentage: entry.completionPercentage)
            
            headerView
            
            habitsSections
            
            Spacer()
        }
        .padding(.top, 4)
        .padding([.leading, .trailing, .bottom], 6)
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
                    .foregroundColor(CardDesign.progressColor(for: entry.completionPercentage))
                
                Spacer()
                
                Text("\(Int(entry.completionPercentage * 100))%")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(CardDesign.progressColor(for: entry.completionPercentage))
            }
            
            ProgressView(value: entry.completionPercentage)
                .tint(CardDesign.progressColor(for: entry.completionPercentage))
        }
    }
    
    
    
    private var habitsSections: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Remaining habits section
            if !remainingHabits.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "Remaining", count: remainingHabits.count)
                    
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(remainingHabits.prefix(6).enumerated()), id: \.element.habit.id) { index, habitInfo in
                            WidgetHabitChip(
                                habitDisplayInfo: habitInfo, 
                                isViewingToday: entry.navigationInfo.isViewingToday,
                                selectedDate: entry.navigationInfo.selectedDate,
                                widgetSize: .large
                            )
                            .frame(height: chipSize)
                        }
                    }
                    
                    // Show count if there are more remaining habits
                    if remainingHabits.count > 6 {
                        Text("+\(remainingHabits.count - 6) more remaining")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 4)
                    }
                }
            }
            
            // Completed habits section
            if !completedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "Completed", count: completedHabits.count)
                    
                    flowingHabitChips(habits: Array(completedHabits.prefix(10)))
                }
            }
        }
    }
    
    // MARK: - Section Components
    
    @ViewBuilder
    private func flowingHabitChips(habits: [HabitDisplayInfo]) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: chipSize, maximum: chipSize), spacing: 6)
            ],
            alignment: .leading,
            spacing: 6
        ) {
            ForEach(habits, id: \.habit.id) { habitInfo in
                WidgetHabitChip(
                    habitDisplayInfo: habitInfo, 
                    isViewingToday: entry.navigationInfo.isViewingToday,
                    selectedDate: entry.navigationInfo.selectedDate,
                    widgetSize: .large
                )
                .frame(width: chipSize, height: chipSize)
            }
        }
    }
    
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
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
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
    let selectedDate = CalendarUtils.addDaysLocal(-3, to: Date(), timezone: .current)
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