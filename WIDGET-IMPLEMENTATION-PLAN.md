# Today's Remaining Habits Widget - Implementation Plan

## 🎯 Core Principle: Maximum Code Reuse from RitualistCore

`★ Insight ─────────────────────────────────────`
RitualistCore Architecture Discovery:
- The app has already extracted core business logic into a shared Swift package, including entities (Habit, HabitLog), utilities (DateUtils, ColorUtils), and services (HabitCompletionService)
- SwiftData models and persistence layer are ready for app group sharing
- The QuickActionsCard UI logic can be directly adapted for widget views with minimal changes
`─────────────────────────────────────────────────`

## Phase 1: Configure Shared Data Container

### 1.1 Update PersistenceContainer for App Groups

```swift
// Ritualist/Data/PersistenceContainer/PersistenceContainer.swift
public init(useSharedContainer: Bool = false) throws {
    let configuration: ModelConfiguration
    
    if useSharedContainer {
        guard let sharedURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladblajovan.Ritualist") else {
            throw PersistenceError.appGroupNotFound
        }
        let storeURL = sharedURL.appendingPathComponent("Ritualist.sqlite")
        configuration = ModelConfiguration(url: storeURL)
    } else {
        configuration = ModelConfiguration()
    }
    
    // REUSE existing models - no new models needed!
    container = try ModelContainer(
        for: HabitModel.self, HabitLogModel.self, UserProfileModel.self,
            HabitCategoryModel.self, OnboardingStateModel.self, PersonalityAnalysisModel.self,
        configurations: configuration
    )
    context = ModelContext(container)
}
```

### 1.2 Update App Initialization

```swift
// In Container+DataSources.swift
var persistenceContainer: Factory<PersistenceContainer> {
    self {
        try! PersistenceContainer(useSharedContainer: true)
    }.singleton
}
```

## Phase 2: Widget Data Service (Reusing Core Logic)

### 2.1 Create Widget Data Service

```swift
// RitualistWidget/Services/WidgetDataService.swift
import SwiftData
import RitualistCore // All our shared models and utilities!

@MainActor
class WidgetDataService {
    private let container: ModelContainer
    private let habitCompletionService = DefaultHabitCompletionService() // REUSE!
    
    init() throws {
        // Use shared container
        guard let sharedURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.vladblajovan.Ritualist") else {
            throw WidgetError.appGroupNotFound
        }
        
        let storeURL = sharedURL.appendingPathComponent("Ritualist.sqlite")
        let config = ModelConfiguration(url: storeURL)
        
        // REUSE exact same models from main app
        self.container = try ModelContainer(
            for: HabitModel.self, HabitLogModel.self,
            configurations: config
        )
    }
    
    func getTodaysRemainingHabits() async throws -> [Habit] {
        let context = ModelContext(container)
        let today = DateUtils.startOfDay(Date()) // REUSE DateUtils!
        
        // Fetch all active habits
        let descriptor = FetchDescriptor<HabitModel>(
            predicate: #Predicate { $0.isActive }
        )
        let habitModels = try context.fetch(descriptor)
        
        // Convert to domain models and filter incomplete
        var incompleteHabits: [Habit] = []
        
        for model in habitModels {
            let habit = model.toDomainModel() // REUSE mapping
            
            // REUSE completion logic from HabitCompletionService
            let logs = fetchLogs(for: habit.id, on: today, context: context)
            let isCompleted = habitCompletionService.isCompleted(
                habit: habit,
                on: today,
                logs: logs
            )
            
            if !isCompleted && isScheduledToday(habit, date: today) {
                incompleteHabits.append(habit)
            }
        }
        
        return incompleteHabits.sorted { $0.displayOrder < $1.displayOrder }
    }
    
    private func isScheduledToday(_ habit: Habit, date: Date) -> Bool {
        // REUSE schedule checking logic
        switch habit.schedule {
        case .daily:
            return true
        case .daysOfWeek(let days):
            let weekday = DateUtils.calendarWeekdayToHabitWeekday(
                Calendar.current.component(.weekday, from: date)
            )
            return days.contains(weekday)
        case .timesPerWeek:
            return true // Always available for flexible habits
        }
    }
}
```

## Phase 3: Widget Timeline Provider

### 3.1 Update Timeline Provider

```swift
// RitualistWidget/RitualistWidget.swift
import WidgetKit
import SwiftUI
import RitualistCore // Import shared resources

struct RemainingHabitsProvider: TimelineProvider {
    typealias Entry = RemainingHabitsEntry
    
    let dataService = try? WidgetDataService()
    
    func placeholder(in context: Context) -> Entry {
        Entry(date: Date(), habits: [], completionPercentage: 0)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        Task {
            let habits = try? await dataService?.getTodaysRemainingHabits() ?? []
            let entry = Entry(
                date: Date(),
                habits: habits ?? [],
                completionPercentage: calculateCompletion(habits ?? [])
            )
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let habits = try? await dataService?.getTodaysRemainingHabits() ?? []
            
            var entries: [Entry] = []
            let currentDate = Date()
            
            // Create timeline entries for next 6 hours
            for hourOffset in 0..<6 {
                let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
                entries.append(Entry(
                    date: entryDate,
                    habits: habits ?? [],
                    completionPercentage: calculateCompletion(habits ?? [])
                ))
            }
            
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
    
    private func calculateCompletion(_ habits: [Habit]) -> Double {
        // Logic from main app
        guard !habits.isEmpty else { return 0.0 }
        // This is simplified - in reality would check completed vs total
        return 0.0
    }
}

struct RemainingHabitsEntry: TimelineEntry {
    let date: Date
    let habits: [Habit] // REUSE existing Habit model!
    let completionPercentage: Double
}
```

## Phase 4: Widget Views (Adapting QuickActionsCard)

### 4.1 Main Widget View

```swift
// RitualistWidget/Views/RemainingHabitsWidgetView.swift
import SwiftUI
import RitualistCore

struct RemainingHabitsWidgetView: View {
    let entry: RemainingHabitsEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(habits: entry.habits)
        case .systemMedium:
            MediumWidgetView(habits: entry.habits)
        case .systemLarge:
            LargeWidgetView(habits: entry.habits)
        default:
            EmptyView()
        }
    }
}
```

### 4.2 Small Widget View

```swift
// RitualistWidget/Views/SmallWidgetView.swift
struct SmallWidgetView: View {
    let habits: [Habit]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header matching QuickActionsCard
            HStack {
                Text("⚡")
                    .font(.title3)
                Text("\(habits.count) left")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if habits.isEmpty {
                Spacer()
                Text("🎉")
                    .font(.title)
                    .frame(maxWidth: .infinity)
                Text("All done!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(habits.prefix(2)) { habit in
                    WidgetHabitChip(habit: habit)
                }
                
                if habits.count > 2 {
                    Text("+\(habits.count - 2) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
    }
}
```

### 4.3 Habit Chip (Adapted from QuickActionsCard)

```swift
// RitualistWidget/Views/Components/WidgetHabitChip.swift
import SwiftUI
import RitualistCore

struct WidgetHabitChip: View {
    let habit: Habit
    
    var body: some View {
        Link(destination: URL(string: "ritualist://habit/\(habit.id)")!) {
            HStack(spacing: 6) {
                Text(habit.emoji ?? "📊")
                    .font(.caption)
                
                Text(habit.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                if habit.kind == .numeric, let target = habit.dailyTarget {
                    Text("0/\(Int(target))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    // REUSE AppColors RGB values for widget compatibility
                    .fill(Color(red: AppColors.RGB.brand.red,
                               green: AppColors.RGB.brand.green,
                               blue: AppColors.RGB.brand.blue)
                          .opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: AppColors.RGB.brand.red,
                                 green: AppColors.RGB.brand.green,
                                 blue: AppColors.RGB.brand.blue)
                           .opacity(0.2), lineWidth: 1)
            )
        }
    }
}
```

## Phase 5: Widget Configuration

### 5.1 Update Widget Definition

```swift
// RitualistWidget/RitualistWidget.swift
struct RitualistWidget: Widget {
    let kind: String = "RemainingHabitsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RemainingHabitsProvider()) { entry in
            RemainingHabitsWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Today's Habits")
        .description("Track your remaining habits")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
```

### 5.2 Clean up AppIntent

```swift
// RitualistWidget/AppIntent.swift
// Remove the default emoji configuration - we don't need it
// Can add meaningful configuration later (e.g., category filter)
```

## Phase 6: Deep Linking & Widget Refresh

### 6.1 Handle Deep Links in Main App

```swift
// Ritualist/Application/RitualistApp.swift
.onOpenURL { url in
    if url.scheme == "ritualist", url.host == "habit" {
        if let habitIdString = url.pathComponents.last,
           let habitId = UUID(uuidString: habitIdString) {
            // Navigate to habit or complete it
            // Use existing navigation system
        }
    }
}
```

### 6.2 Add Widget Refresh Service

```swift
// Ritualist/Core/Services/WidgetRefreshService.swift
import WidgetKit

@MainActor
class WidgetRefreshService {
    static func refreshWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "RemainingHabitsWidget")
    }
}

// Call in OverviewViewModel after habit completion:
await WidgetRefreshService.refreshWidgets()
```

## Phase 7: Add RitualistCore to Widget Target

### 7.1 Update Widget Target Dependencies
- Add RitualistCore package dependency to RitualistWidgetExtension target
- This gives widget access to all shared models and utilities

## ✅ Key Benefits of This Approach

1. **Zero Model Duplication**: Reuses existing Habit, HabitLog models
2. **Shared Business Logic**: Uses HabitCompletionService for consistency
3. **Consistent Styling**: Leverages AppColors.RGB values
4. **Unified Date Handling**: Uses DateUtils throughout
5. **Maintainable**: Changes to core logic benefit both app and widget
6. **Type Safe**: Same models ensure data integrity

## 📱 Widget Sizes

- **Small**: 2 habits + count
- **Medium**: 4 habits in grid
- **Large**: 6+ habits with details

This implementation maximally reuses RitualistCore while creating a native, performant widget experience!