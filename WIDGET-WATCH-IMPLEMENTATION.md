# Widget and Apple Watch Implementation Plan

This document outlines the comprehensive strategy for adding Widget (WidgetKit) and Apple Watch (WatchKit) targets to the Ritualist habit tracking app.

## Current Architecture Assessment ✅ **ENHANCED FOR EXTENSIONS**

### Strengths for Extension
- ✅ **Clean Architecture**: Well-defined Domain/Data/Presentation layers
- ✅ **Modular Entity Framework**: **RitualistCore SPM** with all domain entities extracted and shared
- ✅ **Entity Models**: All core models (`Habit`, `HabitLog`, `UserProfile`, `Category`, etc.) now in shared framework
- ✅ **Repository Pattern**: Protocol-based data abstraction ready for sharing across targets
- ✅ **SwiftData Persistence**: Modern data layer with established models
- ✅ **Dependency Injection**: Factory-based system for modular architecture
- ✅ **Build Configurations**: Multiple configs (AllFeatures/Subscription) ready for extension
- ✅ **Notification Infrastructure**: Existing reminder and notification systems
- ✅ **Framework Isolation**: Zero duplicate entities - clean separation achieved

### Key Data Models Ready for Sharing
```swift
// Core entities perfect for widget/watch display
TodaysSummary {
    completedHabitsCount, totalHabits, completionPercentage
    motivationalMessage, incompleteHabits
}

WeeklyProgress {
    daysCompleted, weeklyCompletionRate, currentDayIndex
}

Habit {
    name, emoji, kind, reminders, isActive
}

HabitLog {
    habitID, date, value
}
```

## Phase 1: Widget Extension (WidgetKit)

### 1.1 Target Setup
```bash
# Create new Widget Extension target
- Target Name: RitualistWidget
- Language: SwiftUI
- Framework: WidgetKit
- Bundle ID: com.vladblajovan.ritualist.widget
```

**Configuration Steps:**
1. Add WidgetKit and SwiftUI frameworks
2. Configure App Groups: `group.com.vladblajovan.ritualist.shared`
3. Update entitlements for data sharing
4. Configure build settings for all configurations (Debug/Release, AllFeatures/Subscription)

### 1.2 Widget Size Implementations

#### Small Widget (2x2)
```swift
struct SmallHabitWidget: View {
    let entry: HabitEntry
    
    var body: some View {
        ZStack {
            // Progress ring showing daily completion
            CircularProgressView(percentage: entry.todaysSummary.completionPercentage)
            
            VStack {
                Text("\(Int(entry.todaysSummary.completionPercentage * 100))%")
                    .font(.system(size: 18, weight: .bold))
                Text("Today")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

#### Medium Widget (4x2)
```swift
struct MediumHabitWidget: View {
    let entry: HabitEntry
    
    var body: some View {
        HStack {
            // Progress ring
            CircularProgressView(percentage: entry.todaysSummary.completionPercentage)
                .frame(width: 60, height: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Today's Progress")
                    .font(.headline)
                
                // Next 2-3 incomplete habits
                ForEach(entry.nextHabits.prefix(3), id: \.id) { habit in
                    HStack {
                        Text(habit.emoji ?? "📝")
                        Text(habit.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

#### Large Widget (4x4)
```swift
struct LargeHabitWidget: View {
    let entry: HabitEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with progress
            HStack {
                Text("Weekly Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(entry.weeklyProgress.weeklyCompletionRate * 100))%")
                    .font(.title2.bold())
            }
            
            // 7-day progress grid
            WeeklyProgressGrid(progress: entry.weeklyProgress)
            
            Divider()
            
            // Today's remaining habits
            Text("Today's Tasks")
                .font(.subheadline.weight(.medium))
            
            ForEach(entry.incompleteHabits.prefix(4), id: \.id) { habit in
                HabitRowView(habit: habit)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### 1.3 Interactive Widgets (iOS 17+)
```swift
struct InteractiveHabitWidget: View {
    let entry: HabitEntry
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(entry.nextHabits.prefix(3), id: \.id) { habit in
                Button(intent: CompleteHabitIntent(habitId: habit.id.uuidString)) {
                    HStack {
                        Text(habit.emoji ?? "📝")
                        Text(habit.name)
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }
}
```

### 1.4 Timeline Provider
```swift
struct HabitTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> HabitEntry {
        HabitEntry(date: Date(), todaysSummary: mockSummary, weeklyProgress: mockProgress)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
        let entry = loadCurrentData()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
        let currentDate = Date()
        let entries: [HabitEntry] = [
            // Update every 15 minutes during active hours (6 AM - 11 PM)
            // Update every hour during inactive hours
        ]
        
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }
}
```

## Phase 2: Apple Watch App (WatchKit)

### 2.1 WatchOS Target Setup
```bash
# Create watchOS app target
- Target Name: RitualistWatch
- Platform: watchOS
- Language: SwiftUI
- Bundle ID: com.vladblajovan.ritualist.watchkitapp
```

**Configuration:**
1. Link `RitualistCore` shared framework
2. Configure WatchConnectivity for iPhone sync
3. Set up HealthKit integration permissions
4. Configure complications and notifications

### 2.2 Watch App Architecture

#### Main Habit List View
```swift
struct HabitListView: View {
    @StateObject private var vm: WatchHabitViewModel
    
    var body: some View {
        NavigationView {
            List {
                // Progress ring at top
                ProgressSectionView(summary: vm.todaysSummary)
                
                // Today's habits with large tap targets
                ForEach(vm.todaysHabits, id: \.id) { habit in
                    HabitRowView(habit: habit) {
                        Task {
                            await vm.toggleHabit(habit)
                        }
                    }
                }
            }
            .navigationTitle("Habits")
            .onAppear {
                Task { await vm.loadData() }
            }
        }
    }
}
```

#### Watch-Optimized Habit Row
```swift
struct WatchHabitRowView: View {
    let habit: Habit
    let isCompleted: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                // Large emoji for easy recognition
                Text(habit.emoji ?? "📝")
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(habit.name)
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(2)
                    
                    if habit.kind == .numeric, let target = habit.dailyTarget {
                        Text("Target: \(Int(target))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Completion indicator
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isCompleted ? .green : .secondary)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
}
```

#### Progress Ring View
```swift
struct WatchProgressRingView: View {
    let summary: TodaysSummary
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 6)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: summary.completionPercentage)
                    .stroke(progressColor, lineWidth: 6)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: summary.completionPercentage)
                
                Text("\(Int(summary.completionPercentage * 100))%")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            
            Text("\(summary.completedHabitsCount)/\(summary.totalHabits)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
```

### 2.3 Watch Complications
```swift
struct HabitComplication: Widget {
    let kind: String = "HabitComplication"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HabitComplicationProvider()) { entry in
            HabitComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Habit Progress")
        .description("Shows your daily habit completion progress")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline
        ])
    }
}

struct CircularComplicationView: View {
    let entry: HabitComplicationEntry
    
    var body: some View {
        Gauge(value: entry.completionPercentage, in: 0...1) {
            Text("\(Int(entry.completionPercentage * 100))%")
                .font(.system(size: 12, weight: .bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
    }
}
```

## Phase 3: Shared Infrastructure

### 3.1 RitualistCore Framework ✅ **IMPLEMENTED**
```swift
// ✅ COMPLETED - Actual framework structure implemented
RitualistCore/
├── Sources/RitualistCore/
│   ├── Entities/
│   │   ├── ✅ Habit.swift
│   │   ├── ✅ HabitLog.swift
│   │   ├── ✅ UserProfile.swift
│   │   ├── ✅ Category.swift
│   │   ├── ✅ CalendarDay.swift
│   │   ├── ✅ HabitNotification.swift
│   │   ├── ✅ HabitSuggestion.swift
│   │   ├── ✅ NotificationAction.swift
│   │   ├── ✅ OnboardingState.swift
│   │   ├── ✅ PaywallBenefit.swift
│   │   ├── ✅ Product.swift
│   │   ├── ✅ ReminderTime.swift
│   │   └── ✅ Tip.swift
│   ├── Enums/
│   │   ├── ✅ HabitKind.swift
│   │   ├── ✅ HabitSchedule.swift
│   │   ├── ✅ SubscriptionPlan.swift
│   │   ├── ✅ AuthError.swift
│   │   ├── ✅ PaywallError.swift
│   │   ├── ✅ ProductDuration.swift
│   │   ├── ✅ PurchaseState.swift
│   │   └── ✅ TipCategory.swift
│   └── ✅ RitualistCore.swift
├── Package.swift (✅ Static library configuration)
└── Tests/ (Ready for future widget/watch data models)

// ✅ Framework properly configured as local SPM dependency
// ✅ All main app files using: import RitualistCore
// ✅ Build successful and verified working
```

### 3.2 App Groups Data Sharing
```swift
// Shared container for SwiftData
class SharedDataContainer {
    static let shared = SharedDataContainer()
    
    private let appGroupIdentifier = "group.com.vladblajovan.ritualist.shared"
    
    lazy var container: ModelContainer = {
        let schema = Schema([
            SDHabit.self,
            SDHabitLog.self,
            SDUserProfile.self
        ])
        
        let configuration = ModelConfiguration(
            schema: schema,
            url: containerURL,
            readOnly: false,
            cloudKitDatabase: .automatic
        )
        
        return try! ModelContainer(for: schema, configurations: [configuration])
    }()
    
    private var containerURL: URL {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Failed to get App Group container URL")
        }
        return url.appendingPathComponent("RitualistData.sqlite")
    }
}
```

### 3.3 Widget Data Provider
```swift
class WidgetDataProvider {
    private let container = SharedDataContainer.shared.container
    
    func getTodaysSummary() -> TodaysSummary {
        let context = ModelContext(container)
        
        // Fetch today's active habits
        let today = Calendar.current.startOfDay(for: Date())
        let habitDescriptor = FetchDescriptor<SDHabit>(
            predicate: #Predicate { $0.isActive }
        )
        
        // Fetch today's logs
        let logDescriptor = FetchDescriptor<SDHabitLog>(
            predicate: #Predicate { $0.date >= today }
        )
        
        // Calculate summary data
        // ... implementation details
    }
    
    func getWeeklyProgress() -> WeeklyProgress {
        // Calculate 7-day progress
        // ... implementation details
    }
}
```

### 3.4 WatchConnectivity Sync
```swift
class WatchDataSyncService: NSObject, ObservableObject {
    private let session = WCSession.default
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }
    
    func syncHabitCompletion(_ habitId: UUID, completed: Bool) {
        guard session.isReachable else {
            // Store for later sync
            queuePendingSync(habitId: habitId, completed: completed)
            return
        }
        
        let message = [
            "action": "toggle_habit",
            "habitId": habitId.uuidString,
            "completed": completed
        ] as [String : Any]
        
        session.sendMessage(message, replyHandler: nil) { error in
            print("Failed to sync habit: \(error.localizedDescription)")
            // Queue for retry
            self.queuePendingSync(habitId: habitId, completed: completed)
        }
    }
}
```

## Phase 4: Advanced Features

### 4.1 Control Widgets (iOS 18)
```swift
struct HabitControlWidget: ControlWidget {
    static let kind: String = "HabitControlWidget"
    
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: HabitControlProvider()
        ) { value in
            ControlWidgetToggle(
                "Complete Habit",
                isOn: value.isCompleted,
                action: CompleteHabitIntent(habitId: value.habitId)
            ) {
                Label {
                    Text(value.habitName)
                } icon: {
                    Text(value.habitEmoji)
                }
            }
        }
        .displayName("Quick Habit Toggle")
        .description("Complete your most important habit from the Lock Screen")
    }
}
```

### 4.2 Live Activities
```swift
struct HabitSessionActivityWidget: Widget {
    let kind: String = "HabitSessionActivityWidget"
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HabitSessionAttributes.self) { context in
            // Lock screen/banner UI
            VStack {
                Text("Active Habit Session")
                Text(context.attributes.habitName)
                    .font(.headline)
            }
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.habitEmoji)
                        .font(.largeTitle)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.elapsedTime)
                        .font(.title2)
                        .monospacedDigit()
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text(context.attributes.habitName)
                        .font(.headline)
                }
            } compactLeading: {
                Text(context.attributes.habitEmoji)
            } compactTrailing: {
                Text(context.state.elapsedTime)
                    .monospacedDigit()
            } minimal: {
                Text(context.attributes.habitEmoji)
            }
        }
    }
}
```

### 4.3 Siri Shortcuts Integration
```swift
struct CompleteHabitIntent: AppIntent {
    static var title: LocalizedStringResource = "Complete Habit"
    static var description = IntentDescription("Mark a habit as completed for today")
    
    @Parameter(title: "Habit")
    var habit: HabitEntity
    
    func perform() async throws -> some IntentResult {
        // Complete habit logic
        let dataProvider = WidgetDataProvider()
        try await dataProvider.completeHabit(habit.id)
        
        return .result(dialog: "Marked \(habit.name) as completed!")
    }
}
```

## Phase 5: Implementation Timeline

### Week 1-2: Foundation
- [x] **COMPLETED**: Extract shared entities into RitualistCore framework
  - ✅ All 13 domain entities (Habit, UserProfile, Category, HabitLog, etc.) moved to RitualistCore SPM
  - ✅ All 8 core enums (HabitKind, HabitSchedule, SubscriptionPlan, etc.) moved to RitualistCore SPM
  - ✅ Static library configuration for sharing across targets
  - ✅ Local Swift Package Manager setup with proper dependencies
  - ✅ All imports updated throughout main app (`import RitualistCore`)
  - ✅ Build verified and working - no duplicate entities remaining
  - ✅ Clean architecture maintained with framework boundary
- [ ] Set up App Groups and data sharing
- [ ] Configure Widget Extension target
- [ ] Implement basic small widget with progress ring

### Week 3-4: Widget Development
- [ ] Medium widget with habit list
- [ ] Large widget with weekly progress
- [ ] Timeline Provider with smart refresh logic
- [ ] Widget configuration and customization

### Week 5-6: Interactive Features
- [ ] Interactive widgets for habit completion
- [ ] App Intents for Siri integration
- [ ] Background refresh optimization
- [ ] Error handling and offline support

### Week 7-8: Apple Watch Foundation
- [ ] WatchOS target setup and basic UI
- [ ] Main habit list with completion toggles
- [ ] WatchConnectivity for iPhone sync
- [ ] Local data persistence for offline use

### Week 9-10: Watch Advanced Features
- [ ] Watch complications for all families
- [ ] Haptic feedback and animations
- [ ] Digital Crown navigation
- [ ] Force Touch context menus

### Week 11-12: Polish and Testing
- [ ] Control Widgets for iOS 18
- [ ] Live Activities for habit sessions
- [ ] Comprehensive testing across all targets
- [ ] Performance optimization and battery usage

## Technical Considerations

### Performance Optimization
- **Widget Memory Limits**: Keep widget views lightweight, cache essential data
- **Watch Battery Usage**: Minimize background processing, use efficient sync patterns
- **Data Queries**: Optimize SwiftData queries for widget timeline generation
- **Background Refresh**: Smart scheduling based on user usage patterns

### Data Synchronization
- **Conflict Resolution**: Last-write-wins for habit completion, merge for different properties
- **Offline Support**: Local caching with background sync when connectivity restored
- **Real-time Updates**: Push notifications to trigger widget/watch updates
- **Data Consistency**: Transactional updates across all targets

### User Experience
- **Onboarding**: Guided setup for widget placement and watch app installation
- **Accessibility**: VoiceOver support, Dynamic Type, high contrast modes
- **Customization**: Widget configuration, habit selection, display preferences
- **Privacy**: Sensitive data handling in widgets and complications

### Testing Strategy
- **Unit Tests**: Core business logic, data synchronization, progress calculations
- **Widget Tests**: Snapshot testing for all widget sizes and states
- **Watch Tests**: Critical user flows, complication rendering
- **Integration Tests**: End-to-end sync between iPhone, widgets, and watch
- **Performance Tests**: Memory usage, battery drain, sync efficiency

This comprehensive plan provides a roadmap for extending Ritualist into the full Apple ecosystem while maintaining the app's clean architecture and user-focused design principles.