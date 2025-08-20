//
//  MediumWidgetView.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

/// Medium widget view (338x155 points) showing remaining habits in a 2-column grid
/// Provides more space for habit details and progress indicators with date navigation
struct MediumWidgetView: View {
    let entry: RemainingHabitsEntry
    
    // Fixed height for consistent card appearance
    private let chipHeight: CGFloat = 50
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date navigation header
            WidgetDateNavigationHeader(entry: entry, size: .medium)
            
            headerView
            
            habitsSections
        }
        .padding(.top, 6)
        .padding([.leading, .trailing, .bottom], 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Current Progress header with percentage
            HStack {
                Text("Current Progress:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(Int(entry.completionPercentage * 100))%")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            
            ProgressView(value: entry.completionPercentage)
                .tint(Color.widgetBrand)
        }
    }
    
    
    
    private var habitsSections: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Remaining habits section
            if !remainingHabits.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "Remaining", count: remainingHabits.count)
                    
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(remainingHabits.prefix(4).enumerated()), id: \.element.habit.id) { index, habitInfo in
                            WidgetHabitChip(
                                habitDisplayInfo: habitInfo, 
                                isViewingToday: entry.navigationInfo.isViewingToday,
                                selectedDate: entry.navigationInfo.selectedDate,
                                widgetSize: .medium
                            )
                            .frame(height: chipHeight)
                        }
                        
                        // Show "more" indicator if there are additional remaining habits
                        if remainingHabits.count > 4 {
                            moreHabitsChip(remaining: remainingHabits.count - 4)
                                .frame(height: chipHeight)
                        }
                    }
                }
            }
            
            // Completed habits section
            if !completedHabits.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    sectionHeader(title: "Completed", count: completedHabits.count)
                    
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(completedHabits.prefix(2).enumerated()), id: \.element.habit.id) { index, habitInfo in
                            WidgetHabitChip(
                                habitDisplayInfo: habitInfo, 
                                isViewingToday: entry.navigationInfo.isViewingToday,
                                selectedDate: entry.navigationInfo.selectedDate,
                                widgetSize: .medium
                            )
                            .frame(height: chipHeight)
                        }
                        
                        // Show "more" indicator if there are additional completed habits
                        if completedHabits.count > 2 {
                            moreHabitsChip(remaining: completedHabits.count - 2)
                                .frame(height: chipHeight)
                        }
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
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("(\(count))")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
        }
    }
    
    private func moreHabitsChip(remaining: Int) -> some View {
        HStack(spacing: 6) {
            Text("...")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            
            Text("+\(remaining) more")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
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

#Preview("Medium Widget - Mixed Progress") {
    let habits = [
        Habit(id: UUID(), name: "Morning Reading", emoji: "📚", kind: .binary, schedule: .daily, isActive: true, displayOrder: 1),
        Habit(id: UUID(), name: "Exercise", emoji: "🏃", kind: .numeric, dailyTarget: 30, schedule: .daily, isActive: true, displayOrder: 2),
        Habit(id: UUID(), name: "Meditation", emoji: "🧘", kind: .binary, schedule: .daily, isActive: true, displayOrder: 3),
        Habit(id: UUID(), name: "Journaling", emoji: "📝", kind: .binary, schedule: .daily, isActive: true, displayOrder: 4),
        Habit(id: UUID(), name: "Water", emoji: "💧", kind: .numeric, dailyTarget: 8, schedule: .daily, isActive: true, displayOrder: 5)
    ]
    let habitDisplayInfo = [
        HabitDisplayInfo(habit: habits[0], currentProgress: 1, isCompleted: true),   // Completed
        HabitDisplayInfo(habit: habits[1], currentProgress: 15, isCompleted: false), // Remaining
        HabitDisplayInfo(habit: habits[2], currentProgress: 1, isCompleted: true),   // Completed
        HabitDisplayInfo(habit: habits[3], currentProgress: 0, isCompleted: false),  // Remaining
        HabitDisplayInfo(habit: habits[4], currentProgress: 3, isCompleted: false)   // Remaining
    ]
    let selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
    let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
    let entry = RemainingHabitsEntry(
        date: Date(),
        habitDisplayInfo: habitDisplayInfo,
        completionPercentage: 0.4,
        navigationInfo: navigationInfo
    )
    
    return MediumWidgetView(entry: entry)
    .frame(width: 338, height: 155)
    .background(Color(.systemBackground))
}

#Preview("Medium Widget - All Done") {
    let habits = [
        Habit(id: UUID(), name: "Morning Reading", emoji: "📚", kind: .binary, schedule: .daily, isActive: true, displayOrder: 1),
        Habit(id: UUID(), name: "Exercise", emoji: "🏃", kind: .numeric, dailyTarget: 30, schedule: .daily, isActive: true, displayOrder: 2),
        Habit(id: UUID(), name: "Meditation", emoji: "🧘", kind: .binary, schedule: .daily, isActive: true, displayOrder: 3)
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
    
    return MediumWidgetView(entry: entry)
        .frame(width: 338, height: 155)
        .background(Color(.systemBackground))
}
