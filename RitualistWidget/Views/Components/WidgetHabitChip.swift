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
/// Binary habits use App Intent for direct completion, numeric habits deep link to app
struct WidgetHabitChip: View {
    let habit: Habit
    let currentProgress: Int
    
    var body: some View {
        if habit.kind == .binary {
            Button(intent: completeHabitIntent) {
                chipContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            Link(destination: deepLinkURL) {
                chipContent
            }
        }
    }
    
    // MARK: - Shared Content
    
    private var chipContent: some View {
        HStack(spacing: 6) {
            // Habit emoji
            Text(habit.emoji ?? WidgetConstants.defaultHabitEmoji)
                .font(.caption)
            
            // Habit name
            Text(habit.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
            
            Spacer(minLength: 0)
            
            // Progress indicator for numeric habits
            if habit.kind == .numeric, let target = habit.dailyTarget {
                Text("\(currentProgress)/\(Int(target))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(chipBackground)
        .overlay(chipBorder)
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
    
    private var deepLinkURL: URL {
        WidgetConstants.habitDeepLinkURL(for: habit.id)
    }
    
    private var completeHabitIntent: CompleteHabitIntent {
        let intent = CompleteHabitIntent()
        intent.habitId = habit.id.uuidString
        return intent
    }
}

// MARK: - Preview

#Preview("Binary Habit Chip") {
    WidgetHabitChip(
        habit: Habit(
            id: UUID(),
            name: "Morning Reading",
            emoji: "📚",
            kind: .binary,
            schedule: .daily,
            isActive: true,
            displayOrder: 1
        ),
        currentProgress: 0
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Numeric Habit Chip") {
    WidgetHabitChip(
        habit: Habit(
            id: UUID(),
            name: "Exercise",
            emoji: "🏃",
            kind: .numeric,
            dailyTarget: 30,
            schedule: .daily,
            isActive: true,
            displayOrder: 2
        ),
        currentProgress: 4
    )
    .padding()
    .background(Color(.systemBackground))
}

#Preview("Long Name Habit Chip") {
    WidgetHabitChip(
        habit: Habit(
            id: UUID(),
            name: "Practice Mindfulness and Meditation",
            emoji: "🧘",
            kind: .binary,
            schedule: .daily,
            isActive: true,
            displayOrder: 3
        ),
        currentProgress: 1
    )
    .padding()
    .background(Color(.systemBackground))
}