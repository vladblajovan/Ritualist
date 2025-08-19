//
//  RitualistWidget.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import SwiftUI
import FactoryKit
import RitualistCore

// MARK: - Timeline Provider

struct RemainingHabitsProvider: TimelineProvider {
    typealias Entry = RemainingHabitsEntry
    
    @Injected(\.widgetDataService) private var dataService
    
    func placeholder(in context: Context) -> Entry {
        let placeholderHabits = createPlaceholderHabits()
        let habitProgress = Dictionary(uniqueKeysWithValues: placeholderHabits.map { ($0.id, 0) })
        return Entry(
            date: Date(),
            habits: placeholderHabits,
            habitProgress: habitProgress,
            completionPercentage: 0.3
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot called")
        Task {
            do {
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot: Starting data fetch...")
                let habitsWithProgress = try await dataService.getTodaysRemainingHabitsWithProgress()
                let percentage = try await dataService.getTodaysCompletionPercentage()
                
                let habits = habitsWithProgress.map { $0.habit }
                let habitProgress = Dictionary(uniqueKeysWithValues: habitsWithProgress.map { ($0.habit.id, $0.currentProgress) })
                
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot: Got \(habits.count) habits, \(percentage * 100)% completion")
                let entry = Entry(
                    date: Date(),
                    habits: habits,
                    habitProgress: habitProgress,
                    completionPercentage: percentage
                )
                completion(entry)
            } catch {
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot: Error occurred: \(error)")
                // Fallback to placeholder data on error
                let placeholderHabits = createPlaceholderHabits()
                let habitProgress = Dictionary(uniqueKeysWithValues: placeholderHabits.map { ($0.id, 0) })
                completion(Entry(
                    date: Date(),
                    habits: placeholderHabits,
                    habitProgress: habitProgress,
                    completionPercentage: 0.0
                ))
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline called")
        Task {
            do {
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline: Starting data fetch...")
                let habitsWithProgress = try await dataService.getTodaysRemainingHabitsWithProgress()
                let percentage = try await dataService.getTodaysCompletionPercentage()
                
                let habits = habitsWithProgress.map { $0.habit }
                let habitProgress = Dictionary(uniqueKeysWithValues: habitsWithProgress.map { ($0.habit.id, $0.currentProgress) })
                
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline: Got \(habits.count) habits, \(percentage * 100)% completion")
                
                var entries: [Entry] = []
                let currentDate = Date()
                
                // Create timeline entries for next hours using BusinessConstants
                // Widget will refresh when habits are completed in main app
                for hourOffset in 0..<WidgetConstants.timelineHours {
                    let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                    entries.append(Entry(
                        date: entryDate,
                        habits: habits,
                        habitProgress: habitProgress,
                        completionPercentage: percentage
                    ))
                }
                
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline: Created \(entries.count) timeline entries")
                // Refresh more frequently to catch any missed widget refresh calls
                let nextRefresh = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate) ?? currentDate.addingTimeInterval(1800)
                let timeline = Timeline(entries: entries, policy: .after(nextRefresh))
                completion(timeline)
            } catch {
                print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline: Error occurred: \(error)")
                // Fallback timeline on error
                let placeholderHabits = createPlaceholderHabits()
                let habitProgress = Dictionary(uniqueKeysWithValues: placeholderHabits.map { ($0.id, 0) })
                let fallbackEntry = Entry(
                    date: Date(),
                    habits: placeholderHabits,
                    habitProgress: habitProgress,
                    completionPercentage: 0.0
                )
                let timeline = Timeline(entries: [fallbackEntry], policy: .after(Date().addingTimeInterval(3600)))
                completion(timeline)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createPlaceholderHabits() -> [Habit] {
        [
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
    }
    
    private func createFallbackEntry() -> Entry {
        Entry(
            date: Date(),
            habits: [],
            habitProgress: [:],
            completionPercentage: 0.0
        )
    }
    
    private func createFallbackTimeline() -> Timeline<Entry> {
        let fallbackEntry = createFallbackEntry()
        return Timeline(entries: [fallbackEntry], policy: .after(Date().addingTimeInterval(3600)))
    }
}

// MARK: - Timeline Entry

struct RemainingHabitsEntry: TimelineEntry {
    let date: Date
    let habits: [Habit] // Reuse existing Habit model from RitualistCore!
    let habitProgress: [UUID: Int] // Maps habit ID to current progress
    let completionPercentage: Double
}

// MARK: - Main Widget View

struct RemainingHabitsWidgetView: View {
    let entry: RemainingHabitsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(habits: entry.habits, habitProgress: entry.habitProgress, completionPercentage: entry.completionPercentage)
        case .systemMedium:
            MediumWidgetView(habits: entry.habits, habitProgress: entry.habitProgress, completionPercentage: entry.completionPercentage)
        case .systemLarge:
            LargeWidgetView(habits: entry.habits, habitProgress: entry.habitProgress, completionPercentage: entry.completionPercentage)
        default:
            EmptyView()
        }
    }
}

// MARK: - Widget Configuration

struct RitualistWidget: Widget {
    let kind: String = "RemainingHabitsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemainingHabitsProvider()) { entry in
            RemainingHabitsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Habits")
        .description("Track your remaining habits for today")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
