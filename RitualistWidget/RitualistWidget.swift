//
//  RitualistWidget.swift
//  RitualistWidget
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import WidgetKit
import SwiftUI
import Factory
import RitualistCore

// MARK: - Timeline Provider

@MainActor
struct RemainingHabitsProvider: TimelineProvider {
    typealias Entry = RemainingHabitsEntry

    @Injected(\.hasValidDataAccess) private var hasValidDataAccess
    @Injected(\.widgetHabitsViewModel) private var viewModel
    @Injected(\.widgetDateNavigationService) private var navigationService
    @Injected(\.widgetLogger) private var logger

    func placeholder(in context: Context) -> Entry {
        // Placeholder is synchronous, so we use device timezone as fallback
        // Real data will use the user's display timezone preference
        let selectedDate = navigationService.currentDate
        let placeholderHabits = createPlaceholderHabits()
        let habitDisplayInfo = placeholderHabits.map { habit in
            HabitDisplayInfo(habit: habit, currentProgress: 0, isCompleted: false)
        }
        let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate, timezone: .current)

        return Entry(
            date: Date(),
            habitDisplayInfo: habitDisplayInfo,
            completionPercentage: 0.3,
            navigationInfo: navigationInfo
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        // Check for data access before proceeding
        guard hasValidDataAccess else {
            logger.log("Widget snapshot failed - no data access", level: .error, category: .widget)
            completion(Entry.errorEntry())
            return
        }

        let viewModel = self.viewModel
        let selectedDate = navigationService.currentDate
        Task {
            let timezone = await viewModel.getDisplayTimezone()
            let habitsWithProgress = await viewModel.getHabitsWithProgress(for: selectedDate, timezone: timezone)
            let percentage = await viewModel.getCompletionPercentage(for: selectedDate, timezone: timezone)

            let entry = Entry(
                date: Date(),
                habitsWithProgress: habitsWithProgress,
                completionPercentage: percentage,
                selectedDate: selectedDate,
                timezone: timezone
            )
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        // Check for data access before proceeding
        guard hasValidDataAccess else {
            logger.log("Widget timeline failed - no data access", level: .error, category: .widget)
            let errorTimeline = Timeline(entries: [Entry.errorEntry()], policy: .after(Date().addingTimeInterval(3600)))
            completion(errorTimeline)
            return
        }

        let viewModel = self.viewModel
        let selectedDate = navigationService.currentDate
        Task {
            let timezone = await viewModel.getDisplayTimezone()
            let actualToday = Date()
            let isToday = CalendarUtils.areSameDayLocal(selectedDate, actualToday, timezone: timezone)

            let habitsWithProgress = await viewModel.getHabitsWithProgress(for: selectedDate, timezone: timezone)
            let percentage = await viewModel.getCompletionPercentage(for: selectedDate, timezone: timezone)

            let timeline = self.generateOptimizedTimeline(
                habitsWithProgress: habitsWithProgress,
                percentage: percentage,
                selectedDate: selectedDate,
                timezone: timezone,
                isViewingToday: isToday
            )

            completion(timeline)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Generate optimized timeline based on viewing context and navigation state
    private func generateOptimizedTimeline(
        habitsWithProgress: [(habit: Habit, currentProgress: Int, isCompleted: Bool)],
        percentage: Double,
        selectedDate: Date,
        timezone: TimeZone,
        isViewingToday: Bool
    ) -> Timeline<Entry> {
        var entries: [Entry] = []
        let currentDate = Date()

        // Create value objects once and reuse across all entries (major performance optimization)
        let habitDisplayInfo = habitsWithProgress.map { data in
            HabitDisplayInfo(
                habit: data.habit,
                currentProgress: data.currentProgress,
                isCompleted: data.isCompleted
            )
        }
        let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate, timezone: timezone)
        
        // Different timeline strategies based on viewing context
        if isViewingToday {
            // Today: More frequent updates for real-time habit completion tracking
            for hourOffset in 0..<WidgetConstants.timelineHours {
                let entryDate = CalendarUtils.utcCalendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                entries.append(Entry(
                    date: entryDate,
                    habitDisplayInfo: habitDisplayInfo,
                    completionPercentage: percentage,
                    navigationInfo: navigationInfo
                ))
            }
            
            // Refresh every 30 minutes for today to catch habit completions
            let nextRefresh = CalendarUtils.addMinutes(30, to: currentDate)
            return Timeline(entries: entries, policy: .after(nextRefresh))
            
        } else {
            // Historical dates: Fewer updates since data is static (no new completions possible)
            // Create fewer entries for historical dates (every 2 hours instead of every hour)
            for hourOffset in stride(from: 0, to: WidgetConstants.timelineHours, by: 2) {
                let entryDate = CalendarUtils.utcCalendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                entries.append(Entry(
                    date: entryDate,
                    habitDisplayInfo: habitDisplayInfo,
                    completionPercentage: percentage,
                    navigationInfo: navigationInfo
                ))
            }
            
            // Longer refresh interval for historical dates (2 hours vs 30 minutes)
            let nextRefresh = CalendarUtils.utcCalendar.date(byAdding: .hour, value: 2, to: currentDate) ?? currentDate.addingTimeInterval(7200)
            return Timeline(entries: entries, policy: .after(nextRefresh))
        }
    }
    
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
        // Fallback uses device timezone as we can't access async timezone service
        let selectedDate = navigationService.currentDate
        let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate, timezone: .current)
        return Entry(
            date: Date(),
            habitDisplayInfo: [],
            completionPercentage: 0.0,
            navigationInfo: navigationInfo
        )
    }
    
    private func createFallbackTimeline() -> Timeline<Entry> {
        let fallbackEntry = createFallbackEntry()
        return Timeline(entries: [fallbackEntry], policy: .after(Date().addingTimeInterval(3600)))
    }
}

// MARK: - Value Objects

/// Encapsulates habit display information to avoid dictionary lookups
public struct HabitDisplayInfo {
    let habit: Habit
    let currentProgress: Int
    let isCompleted: Bool
    
    var progressText: String {
        habit.kind == .binary ? (isCompleted ? "✓" : "○") : "\(currentProgress)/\(Int(habit.dailyTarget ?? 0))"
    }
}

/// Encapsulates navigation state to separate concerns
public struct WidgetNavigationInfo {
    let selectedDate: Date
    let dateDisplayText: String
    let canGoBack: Bool
    let canGoForward: Bool
    let isViewingToday: Bool
    let daysDifference: Int

    /// Convenience initializer with default timezone for previews
    init(selectedDate: Date) {
        self.init(selectedDate: selectedDate, timezone: .current)
    }

    init(selectedDate: Date, timezone: TimeZone) {
        // Use display timezone for all date calculations (same as main app)
        var calendar = Calendar.current
        calendar.timeZone = timezone
        let now = Date() // Single Date() call for consistency
        let today = CalendarUtils.startOfDayLocal(for: now, timezone: timezone)
        let normalizedDate = CalendarUtils.startOfDayLocal(for: selectedDate, timezone: timezone)
        let maxHistoryDays = 30
        let earliestAllowed = CalendarUtils.addDaysLocal(-maxHistoryDays, to: today, timezone: timezone)

        self.selectedDate = normalizedDate
        self.canGoBack = normalizedDate > earliestAllowed
        self.canGoForward = normalizedDate < today
        self.isViewingToday = CalendarUtils.areSameDayLocal(normalizedDate, now, timezone: timezone)
        self.daysDifference = calendar.dateComponents([.day], from: today, to: normalizedDate).day ?? 0
        self.dateDisplayText = Self.formatDateForDisplay(normalizedDate, referenceToday: today, calendar: calendar)
    }
    
    /// Formats date for user-friendly display following main app patterns
    /// Uses consistent calendar and reference today to avoid midnight/timezone edge cases
    private static func formatDateForDisplay(_ date: Date, referenceToday: Date, calendar: Calendar) -> String {
        let normalizedDate = calendar.startOfDay(for: date)

        // Today
        let isToday = calendar.isDate(normalizedDate, inSameDayAs: referenceToday)
        if isToday {
            return "Today"
        }

        // Yesterday (use the calendar's timezone)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: referenceToday) ?? referenceToday
        let isYesterday = calendar.isDate(normalizedDate, inSameDayAs: yesterday)
        if isYesterday {
            return "Yesterday"
        }

        // This week (show weekday name)
        let daysFromToday = calendar.dateComponents([.day], from: normalizedDate, to: referenceToday).day ?? 0
        if daysFromToday <= 7 && daysFromToday > 1 {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.calendar = calendar
            weekdayFormatter.dateFormat = "EEEE"
            return weekdayFormatter.string(from: normalizedDate)
        }

        // Older dates (show month and day)
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar
        if calendar.component(.year, from: normalizedDate) == calendar.component(.year, from: referenceToday) {
            dateFormatter.dateFormat = "MMM d"
        } else {
            dateFormatter.dateFormat = "MMM d, yyyy"
        }

        return dateFormatter.string(from: normalizedDate)
    }
    
}

// MARK: - Timeline Entry

struct RemainingHabitsEntry: TimelineEntry {
    let date: Date
    let habitDisplayInfo: [HabitDisplayInfo]
    let completionPercentage: Double
    let navigationInfo: WidgetNavigationInfo
    /// Indicates if widget failed to access shared data (e.g., app group misconfiguration)
    let hasDataAccessError: Bool

    // MARK: - Initializers

    /// Primary initializer with optimized value objects
    init(
        date: Date,
        habitDisplayInfo: [HabitDisplayInfo],
        completionPercentage: Double,
        navigationInfo: WidgetNavigationInfo,
        hasDataAccessError: Bool = false
    ) {
        self.date = date
        self.habitDisplayInfo = habitDisplayInfo
        self.completionPercentage = completionPercentage
        self.navigationInfo = navigationInfo
        self.hasDataAccessError = hasDataAccessError
    }

    /// Creates an error entry when data access fails
    static func errorEntry() -> RemainingHabitsEntry {
        RemainingHabitsEntry(
            date: Date(),
            habitDisplayInfo: [],
            completionPercentage: 0,
            navigationInfo: WidgetNavigationInfo(selectedDate: Date()),
            hasDataAccessError: true
        )
    }
    
    /// Convenience initializer from raw data (creates value objects internally)
    init(
        date: Date,
        habitsWithProgress: [(habit: Habit, currentProgress: Int, isCompleted: Bool)],
        completionPercentage: Double,
        selectedDate: Date,
        timezone: TimeZone
    ) {
        self.date = date
        self.habitDisplayInfo = habitsWithProgress.map { data in
            HabitDisplayInfo(
                habit: data.habit,
                currentProgress: data.currentProgress,
                isCompleted: data.isCompleted
            )
        }
        self.completionPercentage = completionPercentage
        self.navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate, timezone: timezone)
        self.hasDataAccessError = false
    }

    /// Legacy initializer for backward compatibility
    init(
        date: Date,
        habits: [Habit],
        habitProgress: [UUID: Int],
        habitCompletionStatus: [UUID: Bool],
        completionPercentage: Double,
        selectedDate: Date,
        timezone: TimeZone = .current
    ) {
        let habitsWithProgress = habits.map { habit in
            (habit: habit, currentProgress: habitProgress[habit.id] ?? 0, isCompleted: habitCompletionStatus[habit.id] ?? false)
        }
        self.init(
            date: date,
            habitsWithProgress: habitsWithProgress,
            completionPercentage: completionPercentage,
            selectedDate: selectedDate,
            timezone: timezone
        )
    }
}

// MARK: - Main Widget View

struct RemainingHabitsWidgetView: View {
    let entry: RemainingHabitsEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.hasDataAccessError {
            WidgetErrorView()
        } else {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry)
            case .systemMedium:
                MediumWidgetView(entry: entry)
            case .systemLarge:
                LargeWidgetView(entry: entry)
            default:
                EmptyView()
            }
        }
    }
}

/// Shown when widget cannot access shared app data
private struct WidgetErrorView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(.orange)
            Text("Unable to load data")
                .font(.headline)
            Text("Open the app to sync")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Widget Configuration

struct RitualistWidget: Widget {
    let kind: String = "RemainingHabitsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemainingHabitsProvider()) { entry in
            RemainingHabitsWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    WidgetGradientBackground()
                }
        }
        .configurationDisplayName("Today's Habits")
        .description("View your habits with completion status")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
