//
//  MediumWidgetView.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

/// Medium widget view (338x155 points) showing remaining habits in a 2-column grid
/// Provides more space for habit details and progress indicators
struct MediumWidgetView: View {
    let habits: [Habit]
    let habitProgress: [UUID: Int]
    let completionPercentage: Double
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerView
            
            if habits.isEmpty {
                completedStateView
            } else {
                habitsGridView
            }
        }
        .padding(.top, 16)
        .padding([.leading, .trailing, .bottom], 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        HStack {
            HStack(spacing: 8) {
                Text("⚡")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Habits")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(habits.count) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Progress indicator
            if completionPercentage > 0 {
                progressView
            }
        }
    }
    
    private var progressView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text("\(Int(completionPercentage * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ProgressView(value: completionPercentage)
                .frame(width: 40)
                .scaleEffect(0.8)
        }
    }
    
    private var completedStateView: some View {
        VStack(spacing: 8) {
            Spacer()
            
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Text("🎉")
                        .font(.largeTitle)
                    
                    Text("All habits completed!")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            
            Spacer()
        }
    }
    
    private var habitsGridView: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(habits.prefix(4)) { habit in
                WidgetHabitChip(habit: habit, currentProgress: habitProgress[habit.id] ?? 0)
            }
            
            // Show "more" indicator if there are additional habits
            if habits.count > 4 {
                moreHabitsChip
            }
        }
    }
    
    private var moreHabitsChip: some View {
        HStack(spacing: 6) {
            Text("...")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("+\(habits.count - 4) more")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
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
}

// MARK: - Preview

#Preview("Medium Widget - With Habits") {
    let habits = [
        Habit(id: UUID(), name: "Morning Reading", emoji: "📚", kind: .binary, schedule: .daily, isActive: true, displayOrder: 1),
        Habit(id: UUID(), name: "Exercise", emoji: "🏃", kind: .numeric, dailyTarget: 30, schedule: .daily, isActive: true, displayOrder: 2),
        Habit(id: UUID(), name: "Meditation", emoji: "🧘", kind: .binary, schedule: .daily, isActive: true, displayOrder: 3),
        Habit(id: UUID(), name: "Journaling", emoji: "📝", kind: .binary, schedule: .daily, isActive: true, displayOrder: 4),
        Habit(id: UUID(), name: "Water", emoji: "💧", kind: .numeric, dailyTarget: 8, schedule: .daily, isActive: true, displayOrder: 5)
    ]
    let habitProgress = Dictionary(uniqueKeysWithValues: habits.enumerated().map { ($1.id, $0) })
    
    return MediumWidgetView(
        habits: habits,
        habitProgress: habitProgress,
        completionPercentage: 0.4
    )
    .frame(width: 338, height: 155)
    .background(Color(.systemBackground))
}

#Preview("Medium Widget - All Done") {
    MediumWidgetView(
        habits: [],
        habitProgress: [:],
        completionPercentage: 1.0
    )
    .frame(width: 338, height: 155)
    .background(Color(.systemBackground))
}