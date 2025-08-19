//
//  WidgetHabitChip.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore
import AppIntents

/// Habit chip for widget display - adapted from QuickActionsCard design
/// Behavior varies based on habit type, completion status, and date context
struct WidgetHabitChip: View {
    let habitDisplayInfo: HabitDisplayInfo
    let isViewingToday: Bool
    let selectedDate: Date
    
    // Legacy computed properties for backward compatibility
    private var habit: Habit {
        habitDisplayInfo.habit
    }
    
    private var currentProgress: Int {
        habitDisplayInfo.currentProgress
    }
    
    var body: some View {
        // Implementation of Phase 2 behavior:
        // - Binary + Today + Incomplete: Button with CompleteHabitIntent
        // - Binary + Historical + Incomplete: Button with CompleteHistoricalHabitIntent
        // - Binary + Historical + Completed: Link to app (view-only)
        // - Numeric + Historical: Link with date + action=progress parameter
        // - Numeric + Today: Link to app (existing behavior)
        
        if habit.kind == .binary && !habitDisplayInfo.isCompleted {
            // Binary habits that are incomplete
            if isViewingToday {
                // Today's incomplete binary habit: Use existing CompleteHabitIntent
                Button(intent: completeHabitIntent) {
                    chipContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                // Historical incomplete binary habit: Use CompleteHistoricalHabitIntent
                Button(intent: completeHistoricalHabitIntent) {
                    chipContent
                }
                .buttonStyle(PlainButtonStyle())
            }
        } else {
            // All other cases use deep link to app
            Link(destination: contextualDeepLinkURL) {
                chipContent
            }
        }
    }
    
    // MARK: - Shared Content
    
    private var chipContent: some View {
        HStack(alignment: .top, spacing: 6) {
            // Habit emoji
            Text(habit.emoji ?? WidgetConstants.defaultHabitEmoji)
                .font(.caption)
            
            // Habit name with better text wrapping
            Text(habit.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .minimumScaleFactor(0.8)
            
            Spacer(minLength: 0)
            
            // Progress indicator based on habit type and completion status
            progressIndicator
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(chipBackground)
        .overlay(chipBorder)
        .opacity(completionOpacity)
    }
    
    // MARK: - View Components
    
    private var chipBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(brandColor.opacity(0.1))
    }
    
    private var chipBorder: some View {
        RoundedRectangle(cornerRadius: 8)
            .stroke(brandColor.opacity(0.2), lineWidth: 1)
    }
    
    // MARK: - Helper Properties
    
    private var brandColor: Color {
        .widgetBrand
    }
    
    /// Returns appropriate deep link URL based on context (date and action)
    private var contextualDeepLinkURL: URL {
        // For numeric habits, always use progress action with date context
        if habit.kind == .numeric {
            return WidgetConstants.habitDeepLinkURL(for: habit.id, date: selectedDate, action: .progress)
        }
        
        // For binary habits, use view action with date context
        return WidgetConstants.habitDeepLinkURL(for: habit.id, date: selectedDate, action: .view)
    }
    
    private var completeHabitIntent: CompleteHabitIntent {
        let intent = CompleteHabitIntent()
        intent.habitId = habit.id.uuidString
        return intent
    }
    
    private var completeHistoricalHabitIntent: CompleteHistoricalHabitIntent {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let intent = CompleteHistoricalHabitIntent()
        intent.habitId = habit.id.uuidString
        intent.targetDate = dateFormatter.string(from: selectedDate)
        return intent
    }
    
    // MARK: - Progress Indicators
    
    @ViewBuilder
    private var progressIndicator: some View {
        if habit.kind == .binary {
            binaryProgressIndicator
        } else if habit.kind == .numeric, let target = habit.dailyTarget {
            numericProgressIndicator(target: target)
        }
    }
    
    @ViewBuilder
    private var binaryProgressIndicator: some View {
        if habitDisplayInfo.isCompleted {
            // Show completion checkmark for all completed binary habits (today and historical)
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.green)
        } else if isViewingToday {
            // Show empty circle for today's incomplete binary habits (indicates tap-to-complete)
            Image(systemName: "circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            // Show empty circle for historical incomplete binary habits
            Image(systemName: "circle")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    @ViewBuilder
    private func numericProgressIndicator(target: Double) -> some View {
        if habitDisplayInfo.isCompleted {
            // Show standard completion checkmark for all completed numeric habits
            Image(systemName: "checkmark.circle.fill")
                .font(.caption2)
                .foregroundColor(.green)
        } else {
            // Show progress text for incomplete numeric habits
            Text("\(currentProgress)/\(Int(target))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    
    private var completionOpacity: Double {
        // For historical dates, show completed habits at full opacity, incomplete at reduced opacity
        if !isViewingToday {
            return habitDisplayInfo.isCompleted ? 1.0 : 0.6
        } else {
            // For today, always show at full opacity
            return 1.0
        }
    }
}

// MARK: - Preview

#Preview("Binary Habit Chip - Today Incomplete") {
    let habit = Habit(
        id: UUID(),
        name: "Morning Reading",
        emoji: "📚",
        kind: .binary,
        schedule: .daily,
        isActive: true,
        displayOrder: 1
    )
    let habitDisplayInfo = HabitDisplayInfo(habit: habit, currentProgress: 0, isCompleted: false)
    
    return WidgetHabitChip(
        habitDisplayInfo: habitDisplayInfo,
        isViewingToday: true,
        selectedDate: Date()
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Binary Habit Chip - Today Completed") {
    let habit = Habit(
        id: UUID(),
        name: "Morning Reading",
        emoji: "📚",
        kind: .binary,
        schedule: .daily,
        isActive: true,
        displayOrder: 1
    )
    let habitDisplayInfo = HabitDisplayInfo(habit: habit, currentProgress: 1, isCompleted: true)
    
    return WidgetHabitChip(
        habitDisplayInfo: habitDisplayInfo,
        isViewingToday: true,
        selectedDate: Date()
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Numeric Habit Chip - Historical Incomplete") {
    let habit = Habit(
        id: UUID(),
        name: "Exercise",
        emoji: "🏃",
        kind: .numeric,
        dailyTarget: 30,
        schedule: .daily,
        isActive: true,
        displayOrder: 2
    )
    let habitDisplayInfo = HabitDisplayInfo(habit: habit, currentProgress: 4, isCompleted: false)
    
    return WidgetHabitChip(
        habitDisplayInfo: habitDisplayInfo,
        isViewingToday: false,
        selectedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Binary Habit Chip - Historical Completed") {
    let habit = Habit(
        id: UUID(),
        name: "Practice Mindfulness and Meditation",
        emoji: "🧘",
        kind: .binary,
        schedule: .daily,
        isActive: true,
        displayOrder: 3
    )
    let habitDisplayInfo = HabitDisplayInfo(habit: habit, currentProgress: 1, isCompleted: true)
    
    return WidgetHabitChip(
        habitDisplayInfo: habitDisplayInfo,
        isViewingToday: false,
        selectedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Numeric Habit Chip - Historical Completed") {
    let habit = Habit(
        id: UUID(),
        name: "Steps",
        emoji: "🚶",
        kind: .numeric,
        dailyTarget: 10000,
        schedule: .daily,
        isActive: true,
        displayOrder: 4
    )
    let habitDisplayInfo = HabitDisplayInfo(habit: habit, currentProgress: 12500, isCompleted: true)
    
    return WidgetHabitChip(
        habitDisplayInfo: habitDisplayInfo,
        isViewingToday: false,
        selectedDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())!
    )
    .padding()
    .background(Color(.systemBackground))
}