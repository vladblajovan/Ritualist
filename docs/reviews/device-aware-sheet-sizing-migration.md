# deviceAwareSheetSizing Migration Report

## Summary
The custom `deviceAwareSheetSizing` extension can be replaced with the native SwiftUI `.presentationDetents` API (iOS 16+).

## Native API Options
```swift
.presentationDetents([.medium])           // ~half screen
.presentationDetents([.large])            // full screen
.presentationDetents([.height(400)])      // specific height
.presentationDetents([.fraction(0.7)])    // 70% of screen
.presentationDetents([.medium, .large])   // user can resize
```

## Files to Migrate

| File | Line | Notes |
|------|------|-------|
| `StreakDetailSheet.swift` | 135 | |
| `HabitsAssistantSheet.swift` | 117 | |
| `HabitsAssistantSheet.swift` | 347 | |
| `TipsBottomSheet.swift` | 82 | |
| `TipDetailView.swift` | 38 | |
| `PersonalityAnalysisDeepLinkSheet.swift` | 50 | |
| `PersonalityInsightsView.swift` | 376 | |
| `PersonalityInsightsView.swift` | 480 | |
| `PersonalityInsightsSettingsRow.swift` | 65 | |

## Already Migrated
- `NumericHabitLogSheet.swift` - now uses `.presentationDetents([.medium])`

## After Migration
Once all usages are migrated, delete:
- `Ritualist/Core/Extensions/View+DeviceAwareSizing.swift`
- `SizeMultiplier` struct
