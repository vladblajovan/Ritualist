//
//  LargeWidgetView.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

/// Large widget view (338x354 points) showing comprehensive habit overview
/// Displays all remaining habits with detailed progress and time-based insights
struct LargeWidgetView: View {
    let habits: [Habit]
    let habitProgress: [UUID: Int]
    let completionPercentage: Double
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            
            if habits.isEmpty {
                completedStateView
            } else {
                VStack(spacing: 12) {
                    habitsGridView
                    
                    if habits.count > 6 {
                        additionalHabitsView
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 20)
        .padding([.leading, .trailing, .bottom], 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
    
    // MARK: - View Components
    
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 10) {
                    Text("⚡")
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today's Habits")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(habits.count) remaining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Progress circle
                progressCircleView
            }
            
            // Progress bar
            if completionPercentage > 0 {
                progressBarView
            }
        }
    }
    
    private var progressCircleView: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 3)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: completionPercentage)
                    .stroke(
                        Color.widgetBrand,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(-90))
                
                Text("\(Int(completionPercentage * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
    }
    
    private var progressBarView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Daily Progress")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(Int(completionPercentage * 100))% complete")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            ProgressView(value: completionPercentage)
                .tint(Color.widgetBrand)
        }
    }
    
    private var completedStateView: some View {
        VStack(spacing: 12) {
            Spacer()
            
            VStack(spacing: 8) {
                Text("🎉")
                    .font(.system(size: 48))
                
                Text("Outstanding!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.8)
                
                Text("All habits completed!")
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.7)
                
                Text("Keep up the momentum!")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                    .minimumScaleFactor(0.7)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)
    }
    
    private var habitsGridView: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(habits.prefix(6)) { habit in
                WidgetHabitChip(habit: habit, currentProgress: habitProgress[habit.id] ?? 0)
            }
        }
    }
    
    private var additionalHabitsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Additional Habits")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(habits.dropFirst(6).prefix(4)) { habit in
                        CompactHabitChip(habit: habit)
                    }
                    
                    if habits.count > 10 {
                        Text("+\(habits.count - 10) more")
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
}

// MARK: - Compact Habit Chip

private struct CompactHabitChip: View {
    let habit: Habit
    
    var body: some View {
        Link(destination: WidgetConstants.habitDeepLinkURL(for: habit.id)) {
            HStack(spacing: 4) {
                Text(habit.emoji ?? WidgetConstants.defaultHabitEmoji)
                    .font(.caption2)
                
                Text(habit.name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.widgetBrand.opacity(0.1))
            )
            .overlay(
                Capsule()
                    .stroke(Color.widgetBrand.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Preview

#Preview("Large Widget - With Many Habits") {
    let habits = [
        Habit(id: UUID(), name: "Morning Reading", emoji: "📚", kind: .binary, schedule: .daily, isActive: true, displayOrder: 1),
        Habit(id: UUID(), name: "Exercise", emoji: "🏃", kind: .numeric, dailyTarget: 10000, schedule: .daily, isActive: true, displayOrder: 2),
        Habit(id: UUID(), name: "Meditation", emoji: "🧘", kind: .binary, schedule: .daily, isActive: true, displayOrder: 3),
        Habit(id: UUID(), name: "Water", emoji: "💧", kind: .numeric, dailyTarget: 8, schedule: .daily, isActive: true, displayOrder: 4)
    ]
    let habitProgress = Dictionary(uniqueKeysWithValues: habits.enumerated().map { ($1.id, $0 * 3) })
    
    return LargeWidgetView(
        habits: habits,
        habitProgress: habitProgress,
        completionPercentage: 0.67
    )
    .frame(width: 338, height: 354)
    .background(Color(.systemBackground))
}

#Preview("Large Widget - All Done") {
    LargeWidgetView(
        habits: [],
        habitProgress: [:],
        completionPercentage: 1.0
    )
    .frame(width: 338, height: 354)
    .background(Color(.systemBackground))
}