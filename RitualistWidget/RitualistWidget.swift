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

struct RemainingHabitsProvider: TimelineProvider {
    typealias Entry = RemainingHabitsEntry
    
    @Injected(\.widgetHabitsViewModel) private var viewModel
    @Injected(\.widgetDateNavigationService) private var navigationService
    
    func placeholder(in context: Context) -> Entry {
        print("[WIDGET-DEBUG] RemainingHabitsProvider.placeholder called")
        
        let selectedDate = navigationService.currentDate
        print("[WIDGET-DEBUG] Placeholder using selectedDate: \(selectedDate)")
        
        let placeholderHabits = createPlaceholderHabits()
        let habitDisplayInfo = placeholderHabits.map { habit in
            HabitDisplayInfo(habit: habit, currentProgress: 0, isCompleted: false)
        }
        let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
        print("[WIDGET-DEBUG] Placeholder created navigationInfo with date: \(navigationInfo.selectedDate), displayText: \(navigationInfo.dateDisplayText)")
        
        return Entry(
            date: Date(),
            habitDisplayInfo: habitDisplayInfo,
            completionPercentage: 0.3,
            navigationInfo: navigationInfo
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot called")
        Task {
            print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot: Starting data fetch...")
            
            // Use selected date from navigation state
            let selectedDate = navigationService.currentDate
            let actualToday = Date()
            let isToday = CalendarUtils.areSameDayLocal(selectedDate, actualToday)
            print("[WIDGET-DEBUG] GetSnapshot - selectedDate: \(selectedDate), actualToday: \(actualToday), isToday: \(isToday)")
            
            // Use ViewModel with main app's Use Cases
            let habitsWithProgress = await viewModel.getHabitsWithProgress(for: selectedDate)
            let percentage = await viewModel.getCompletionPercentage(for: selectedDate)
            
            if isToday {
                print("[WIDGET-DEBUG] Snapshot loaded today's data: \(habitsWithProgress.count) habits, \(percentage * 100)% completion")
            } else {
                print("[WIDGET-DEBUG] Snapshot loaded historical data for \(selectedDate): \(habitsWithProgress.count) habits, \(percentage * 100)% completion")
            }
            
            print("[WIDGET-DEBUG] RemainingHabitsProvider.getSnapshot: Got \(habitsWithProgress.count) habits, \(percentage * 100)% completion for \(selectedDate)")
            
            // Create entry using optimized value objects
            let entry = Entry(
                date: Date(),
                habitsWithProgress: habitsWithProgress,
                completionPercentage: percentage,
                selectedDate: selectedDate
            )
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline called")
        Task {
            print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline: Starting data fetch...")
            
            // Use selected date from navigation state
            let selectedDate = navigationService.currentDate
            let actualToday = Date()
            let isToday = CalendarUtils.areSameDayLocal(selectedDate, actualToday)
            print("[WIDGET-DEBUG] GetTimeline - selectedDate: \(selectedDate), actualToday: \(actualToday), isToday: \(isToday)")
            
            // Use ViewModel with main app's Use Cases
            let habitsWithProgress = await viewModel.getHabitsWithProgress(for: selectedDate)
            let percentage = await viewModel.getCompletionPercentage(for: selectedDate)
            
            if isToday {
                print("[WIDGET-DEBUG] Loaded today's data: \(habitsWithProgress.count) habits, \(percentage * 100)% completion")
            } else {
                print("[WIDGET-DEBUG] Loaded historical data for \(selectedDate): \(habitsWithProgress.count) habits, \(percentage * 100)% completion")
            }
            
            print("[WIDGET-DEBUG] RemainingHabitsProvider.getTimeline: Got \(habitsWithProgress.count) habits, \(percentage * 100)% completion for \(selectedDate)")
            
            // Generate optimized timeline entries based on viewing context
            let timeline = generateOptimizedTimeline(
                habitsWithProgress: habitsWithProgress,
                percentage: percentage,
                selectedDate: selectedDate,
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
        let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
        
        // Different timeline strategies based on viewing context
        if isViewingToday {
            // Today: More frequent updates for real-time habit completion tracking
            print("[WIDGET-DEBUG] Generating today timeline with frequent updates")
            
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
            print("[WIDGET-DEBUG] Generating historical timeline with reduced update frequency")
            
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
        let selectedDate = navigationService.currentDate
        let navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
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
    
    init(selectedDate: Date) {
        // Use consistent calendar and date references to avoid midnight/timezone edge cases
        let calendar = CalendarUtils.currentLocalCalendar
        let now = Date() // Single Date() call for consistency
        let today = calendar.startOfDay(for: now)
        let normalizedDate = calendar.startOfDay(for: selectedDate)
        let maxHistoryDays = 30
        let earliestAllowed = CalendarUtils.addDays(-maxHistoryDays, to: today)
        
        print("[WIDGET-NAV-INFO] WidgetNavigationInfo.init - input selectedDate: \(selectedDate)")
        print("[WIDGET-NAV-INFO] WidgetNavigationInfo.init - now: \(now), today: \(today), normalizedDate: \(normalizedDate)")
        print("[WIDGET-NAV-INFO] WidgetNavigationInfo.init - calendar timezone: \(calendar.timeZone)")
        
        self.selectedDate = normalizedDate
        self.canGoBack = normalizedDate > earliestAllowed
        self.canGoForward = normalizedDate < today
        self.isViewingToday = CalendarUtils.areSameDayLocal(normalizedDate, now)
        self.daysDifference = calendar.dateComponents([.day], from: today, to: normalizedDate).day ?? 0
        self.dateDisplayText = Self.formatDateForDisplay(normalizedDate, referenceToday: today, calendar: calendar)
        
        // DEBUG: Enhanced logging for isViewingToday calculation
        print("[WIDGET-NAV-INFO-DEBUG] ====== ISVIEWINGTODAY CALCULATION ======")
        print("[WIDGET-NAV-INFO-DEBUG] Input selectedDate: \(selectedDate)")
        print("[WIDGET-NAV-INFO-DEBUG] Normalized selectedDate: \(normalizedDate)")
        print("[WIDGET-NAV-INFO-DEBUG] Today reference: \(today)")
        print("[WIDGET-NAV-INFO-DEBUG] Calendar timezone: \(calendar.timeZone)")
        print("[WIDGET-NAV-INFO-DEBUG] Same day check result: \(self.isViewingToday)")
        print("[WIDGET-NAV-INFO-DEBUG] Days difference: \(self.daysDifference)")
        print("[WIDGET-NAV-INFO-DEBUG] Display text: \(self.dateDisplayText)")
        if self.isViewingToday {
            print("[WIDGET-NAV-INFO-DEBUG] ✅ User IS viewing today")
        } else {
            print("[WIDGET-NAV-INFO-DEBUG] ❌ User is NOT viewing today (viewing historical date)")
        }
        print("[WIDGET-NAV-INFO-DEBUG] ==========================================")
        
        print("[WIDGET-NAV-INFO] WidgetNavigationInfo.init - result: selectedDate=\(self.selectedDate), displayText=\(self.dateDisplayText), isViewingToday=\(self.isViewingToday)")
    }
    
    /// Formats date for user-friendly display following main app patterns
    /// Uses consistent calendar and reference today to avoid midnight/timezone edge cases
    private static func formatDateForDisplay(_ date: Date, referenceToday: Date, calendar: Calendar) -> String {
        let normalizedDate = calendar.startOfDay(for: date)
        
        print("[WIDGET-FORMAT-DATE] formatDateForDisplay called with: \(date)")
        print("[WIDGET-FORMAT-DATE] referenceToday: \(referenceToday), normalizedDate: \(normalizedDate)")
        print("[WIDGET-FORMAT-DATE] calendar timezone: \(calendar.timeZone)")
        
        // Today
        let isToday = calendar.isDate(normalizedDate, inSameDayAs: referenceToday)
        print("[WIDGET-FORMAT-DATE] isToday check: \(isToday)")
        if isToday {
            print("[WIDGET-FORMAT-DATE] Returning 'Today'")
            return "Today"
        }
        
        // Yesterday
        let yesterday = CalendarUtils.addDays(-1, to: referenceToday)
        let isYesterday = calendar.isDate(normalizedDate, inSameDayAs: yesterday)
        print("[WIDGET-FORMAT-DATE] yesterday: \(yesterday), isYesterday: \(isYesterday)")
        if isYesterday {
            print("[WIDGET-FORMAT-DATE] Returning 'Yesterday'")
            return "Yesterday"
        }
        
        // This week (show weekday name)
        let daysFromToday = calendar.dateComponents([.day], from: normalizedDate, to: referenceToday).day ?? 0
        print("[WIDGET-FORMAT-DATE] daysFromToday: \(daysFromToday)")
        if daysFromToday <= 7 && daysFromToday > 1 {
            let weekdayFormatter = DateFormatter()
            weekdayFormatter.calendar = calendar // Use consistent calendar
            weekdayFormatter.dateFormat = "EEEE" // Full weekday name
            let result = weekdayFormatter.string(from: normalizedDate)
            print("[WIDGET-FORMAT-DATE] Returning weekday: \(result)")
            return result
        }
        
        // Older dates (show month and day)
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = calendar // Use consistent calendar
        if calendar.component(.year, from: normalizedDate) == calendar.component(.year, from: referenceToday) {
            // Same year: "Jan 15"
            dateFormatter.dateFormat = "MMM d"
        } else {
            // Different year: "Jan 15, 2024"
            dateFormatter.dateFormat = "MMM d, yyyy"
        }
        
        let result = dateFormatter.string(from: normalizedDate)
        print("[WIDGET-FORMAT-DATE] Returning formatted date: \(result)")
        return result
    }
    
    /// Legacy formatDateForDisplay method for backward compatibility
    /// Redirects to the consistent version using current date/calendar
    private static func formatDateForDisplay(_ date: Date) -> String {
        let calendar = CalendarUtils.currentLocalCalendar
        let today = calendar.startOfDay(for: Date())
        return formatDateForDisplay(date, referenceToday: today, calendar: calendar)
    }
}

// MARK: - Timeline Entry

struct RemainingHabitsEntry: TimelineEntry {
    let date: Date
    let habitDisplayInfo: [HabitDisplayInfo]
    let completionPercentage: Double
    let navigationInfo: WidgetNavigationInfo
    
    // MARK: - Initializers
    
    /// Primary initializer with optimized value objects
    init(
        date: Date,
        habitDisplayInfo: [HabitDisplayInfo],
        completionPercentage: Double,
        navigationInfo: WidgetNavigationInfo
    ) {
        self.date = date
        self.habitDisplayInfo = habitDisplayInfo
        self.completionPercentage = completionPercentage
        self.navigationInfo = navigationInfo
    }
    
    /// Convenience initializer from raw data (creates value objects internally)
    init(
        date: Date,
        habitsWithProgress: [(habit: Habit, currentProgress: Int, isCompleted: Bool)],
        completionPercentage: Double,
        selectedDate: Date
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
        self.navigationInfo = WidgetNavigationInfo(selectedDate: selectedDate)
    }
    
    /// Legacy initializer for backward compatibility
    init(
        date: Date,
        habits: [Habit],
        habitProgress: [UUID: Int],
        habitCompletionStatus: [UUID: Bool],
        completionPercentage: Double,
        selectedDate: Date
    ) {
        let habitsWithProgress = habits.map { habit in
            (habit: habit, currentProgress: habitProgress[habit.id] ?? 0, isCompleted: habitCompletionStatus[habit.id] ?? false)
        }
        self.init(
            date: date,
            habitsWithProgress: habitsWithProgress,
            completionPercentage: completionPercentage,
            selectedDate: selectedDate
        )
    }
}

// MARK: - Main Widget View

struct RemainingHabitsWidgetView: View {
    let entry: RemainingHabitsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
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
