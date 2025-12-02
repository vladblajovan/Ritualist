# ViewModel Patterns

Common patterns used across ViewModels in the Ritualist app.

## hasLoadedInitialData Pattern

### Purpose

Prevents redundant data loading when a view appears multiple times (e.g., tab switching, navigation stack changes).

### Problem It Solves

SwiftUI's `.task` modifier runs every time a view appears. Without this guard, data would be re-fetched unnecessarily on every tab switch, causing:
- Redundant network/database calls
- UI flashing as data reloads
- Wasted battery and performance

### Implementation

```swift
@Observable
public final class ExampleViewModel {
    private var hasLoadedInitialData = false

    public func loadData() async {
        // Guard against redundant loads
        guard !hasLoadedInitialData else { return }
        hasLoadedInitialData = true

        // Perform actual data loading
        await fetchFromDatabase()
    }

    /// Force refresh - bypasses the guard
    public func refresh() async {
        // Don't check hasLoadedInitialData - always refresh
        await fetchFromDatabase()
    }
}
```

### Key Points

1. **Initial load**: `loadData()` only executes once per ViewModel lifecycle
2. **Manual refresh**: `refresh()` method bypasses the guard for pull-to-refresh
3. **Reset on logout**: Clear the flag if user data should reload after sign-out

### ViewModels Using This Pattern

- `DashboardViewModel` - Dashboard stats and charts
- `HabitsViewModel` - Habit list
- `SettingsViewModel` - User profile and preferences

### When to Use

Use this pattern when:
- Data is expensive to load (database/network)
- View appears frequently (tab bar items)
- Data doesn't need real-time updates on every appearance

Don't use when:
- Data must be fresh on every appearance
- View appears rarely (detail screens)
