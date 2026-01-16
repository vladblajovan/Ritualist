# Ritualist Haptic Feedback Implementation Plan

> Generated: January 2026
> Status: **Implemented**

---

## Overview

This document tracks the haptic feedback implementation across the Ritualist iOS app. The app has a well-architected `HapticFeedbackService` that provides centralized haptic management with a **global enable/disable setting** accessible from Settings > App Settings.

### Haptic Style Guide

| Haptic Type | Use Case | Examples |
|-------------|----------|----------|
| `.heavy` | Destructive actions | Delete, permanent changes |
| `.medium` | Primary confirmations | Complete habit, save changes |
| `.light` | Navigation, soft feedback | Button taps, creation actions |
| `.selection` | State/mode changes | Toggles, multi-select, pickers |
| `.success` | Goal achievement | Completion milestones, targets reached |
| `.warning` | Important alerts | Validation errors, cautions |
| `.error` | Critical problems | Failures, serious errors |

---

## Global Haptic Settings

The `HapticFeedbackService` now includes:
- **`isEnabled`**: A published Bool property that persists to UserDefaults
- **Automatic early-return**: When disabled, all `trigger()` calls are no-ops
- **Settings UI**: App Settings view with toggle at `Settings > App Settings > Haptic Feedback`

---

## Current Implementation Status

### Already Implemented (Before This Update)

- [x] `CompleteHabitSheet.swift:56` - Mark habit complete (`.medium`)
- [x] `UncompleteHabitSheet.swift:56` - Mark habit uncomplete (`.medium`)
- [x] `NumericHabitLogSheet.swift:115` - Increment/decrement buttons (`.light`)
- [x] `NumericHabitLogSheet.swift` - Target reached (`.success`)
- [x] `LongPressProgressModifier.swift:89` - Long-press begins (`.light`)
- [x] `LongPressProgressModifier.swift:113` - Long-press completes (`.success`)
- [x] `ToastService.swift` - Context-aware toasts (success/error/warning/info)
- [x] `WeekDateSelector.swift:89` - Date selection (`.light`)
- [x] `LocationConfigCard.swift:332` - Radius slider adjustment (`.light`)
- [x] `CelebrationAnimationModifier.swift:75` - Celebration trigger (`.heavy`)
- [x] `PersonalityAnalysisDeepLinkSheet.swift:65-66` - Sheet welcome (`.success`)

### Newly Implemented (January 2026)

- [x] `HabitsView.swift:418` - Delete habit confirmation (`.heavy`)
- [x] `HabitsView.swift:436` - Batch delete habits (`.heavy`)
- [x] `HabitsView.swift:328` - Swipe to toggle active/inactive (`.medium`)
- [x] `HabitsView.swift:360` - Pull-to-refresh (`.light`)
- [x] `ReminderConfigurationView.swift:76` - Delete reminder (`.medium`)
- [x] `ReminderConfigurationView.swift:33` - Add reminder button (`.light`)
- [x] `ActiveStatusSection.swift:18` - Habit activate/deactivate button (`.selection`)
- [x] `LocationConfigurationSection.swift:21` - Location reminder toggle (`.selection`)
- [x] `StatsView.swift:94` - Pull-to-refresh (`.light`)
- [x] `LocationConfigCard.swift:387` - Trigger type chips (`.selection`)
- [x] `LocationConfigCard.swift:443` - Frequency preset buttons (`.selection`)
- [x] `CategoryFilterCarousel.swift:116` - Category filter selection (`.light`)
- [x] `WeekDateSelector.swift:178` - Return to Today button (`.light`)
- [x] `PersonalizationSettingsView.swift:33` - Gender picker (`.selection`)
- [x] `PersonalizationSettingsView.swift:47` - Age group picker (`.selection`)
- [x] `AppSettingsView.swift` - New settings page with haptic toggle

### Carousel & Onboarding Haptics (January 2026)

- [x] `WeekDateSelector.swift:215` - Page snap on week swipe (`.selection` via `.sensoryFeedback`)
- [x] `InspirationCarouselView.swift:40` - Page snap on inspiration card swipe (`.selection` via `.sensoryFeedback`)
- [x] `OnboardingFlowView.swift:63` - Page snap on onboarding swipe (`.selection` via `.sensoryFeedback`)
- [x] `OnboardingFlowView.swift:126` - Skip button (`.light`)
- [x] `OnboardingFlowView.swift:149` - Back button (`.light`)
- [x] `OnboardingFlowView.swift:172` - Continue/Get Started button (`.light`)
- [x] `ReturningUserOnboardingView.swift:88` - Step transition (`.light`)

---

## Implementation Checklist

### Critical Priority (High Impact) - ✅ COMPLETE

#### Destructive Actions
- [x] **Delete habit confirmation** - `HabitsView.swift:418`
  - Haptic: `.heavy`
  - Context: Permanent data loss requires strong feedback

- [x] **Batch delete habits** - `HabitsView.swift:436`
  - Haptic: `.heavy`
  - Context: Multiple items deleted

- [x] **Delete reminder** - `ReminderConfigurationView.swift:76`
  - Haptic: `.medium`
  - Context: Destructive but smaller scope

#### Toggle/Status Changes
- [x] **Swipe to toggle active/inactive** - `HabitsView.swift:328`
  - Haptic: `.medium`
  - Context: Status change confirmation

- [x] **Habit activate/deactivate button** - `ActiveStatusSection.swift:18`
  - Haptic: `.selection`
  - Context: Important status change

- [x] **Location reminder toggle** - `LocationConfigurationSection.swift:21`
  - Haptic: `.selection`
  - Context: Premium feature toggle

#### Refresh Actions
- [x] **Pull-to-refresh Habits** - `HabitsView.swift:360`
  - Haptic: `.light`
  - Context: Refresh completion feedback

- [x] **Pull-to-refresh Stats** - `StatsView.swift:94`
  - Haptic: `.light`
  - Context: Refresh completion feedback

---

### Medium Priority (Good-to-Have) - ✅ COMPLETE

#### Selection Feedback
- [x] **Location trigger type chips** - `LocationConfigCard.swift:387`
  - Haptic: `.selection`
  - Context: Arriving/Leaving/Both selection

- [x] **Frequency preset buttons** - `LocationConfigCard.swift:443`
  - Haptic: `.selection`
  - Context: Frequency option selection

- [x] **Category filter selection** - `CategoryFilterCarousel.swift:116`
  - Haptic: `.light`
  - Context: Filter application

#### Navigation & Actions
- [x] **Return to Today button** - `WeekDateSelector.swift:178`
  - Haptic: `.light`
  - Context: Navigation confirmation

- [x] **Edit mode toggle** - `HabitsView.swift:216`
  - Haptic: `.light`
  - Context: Mode transition

- [x] **Add reminder button** - `ReminderConfigurationView.swift:33`
  - Haptic: `.light`
  - Context: Creation action

- [x] **Add category button** - `CategoryManagementView.swift:59`
  - Haptic: `.light`
  - Context: Creation action

- [x] **Statistics card taps** - `StatsView.swift:423`
  - Haptic: `.light`
  - Context: Navigation drill-down (category performance rows)

#### Settings
- [x] **Settings toggle switches** - `PersonalizationSettingsView.swift`
  - Haptic: `.selection`
  - Context: Preference changes

- [x] **Notification toggles** - Various settings
  - Haptic: `.selection`
  - Context: Permission/preference changes
  - Locations: `OnboardingPage6View.swift:93`, `PersonalityInsightsView.swift:198`

---

### Low Priority (Nice-to-Have) - ⏸️ DEFERRED

- [x] **Carousel snap points** - `WeekDateSelector`, `InspirationCarouselView`
  - Haptic: `.selection` via `.sensoryFeedback` modifier
  - Context: Provides picker-like feedback on page snaps

- [x] **Onboarding page advancement** - `OnboardingFlowView`, `ReturningUserOnboardingView`
  - Haptic: `.selection` (page swipe) + `.light` (buttons)
  - Context: Guides user through onboarding flow

#### Deferred (Not Implemented)
- Text field focus (`.light`) - Too subtle, adds noise without clear UX benefit
- Progress milestones at 50%/100% (`.selection`) - Would require threshold tracking in OverviewViewModel
- View transitions (`.light`) - Scope unclear; iOS handles most transitions
- Empty state appearance (`.light`) - Low impact for complexity

---

## Implementation Examples

### Delete Confirmation
```swift
Button(Strings.Common.delete, role: .destructive) {
    HapticFeedbackService.shared.trigger(.heavy)
    // deletion logic
}
```

### Swipe Action
```swift
.swipeActions(edge: .leading) {
    Button {
        HapticFeedbackService.shared.trigger(.medium)
        await vm.toggleActiveStatus(id: habit.id)
    } label: {
        Label("Toggle", systemImage: "power")
    }
}
```

### Toggle Change
```swift
Toggle(isOn: $isEnabled) {
    Text("Enable Feature")
}
.onChange(of: isEnabled) { _, newValue in
    HapticFeedbackService.shared.trigger(.selection)
}
```

### Pull-to-Refresh
```swift
.refreshable {
    await viewModel.refresh()
    HapticFeedbackService.shared.trigger(.light)
}
```

### Selection Chips
```swift
Button {
    selectedOption = option
    HapticFeedbackService.shared.trigger(.selection)
} label: {
    ChipView(option: option, isSelected: selectedOption == option)
}
```

### Carousel Page Snap (iOS 17+ `.sensoryFeedback`)
```swift
TabView(selection: $currentIndex) {
    ForEach(items) { item in
        ItemView(item: item)
            .tag(item.index)
    }
}
.tabViewStyle(.page(indexDisplayMode: .never))
.sensoryFeedback(.selection, trigger: currentIndex) // Haptic on page snap
```

---

## Coverage Metrics

| Area | Before | After | Target | Status |
|------|--------|-------|--------|--------|
| Habit logging | 90% | 90% | 90% | ✅ Complete |
| Destructive actions | 0% | 100% | 100% | ✅ Complete |
| Toggle/status changes | 20% | 100% | 100% | ✅ Complete |
| Refresh actions | 0% | 100% | 100% | ✅ Complete |
| Selection feedback | 0% | 80% | 80% | ✅ Complete |
| Toast notifications | 100% | 100% | 100% | ✅ Complete |
| Navigation | 60% | 85% | 80% | ✅ Complete |
| Settings | 0% | 100% | 100% | ✅ Complete |
| **Carousel snap** | 0% | 100% | 100% | ✅ Complete |
| **Onboarding** | 0% | 100% | 100% | ✅ Complete |

---

## New Features

### Global Haptic Toggle
- **Location**: Settings > App Settings > Haptic Feedback
- **Persistence**: UserDefaults (`hapticFeedbackEnabled`)
- **Default**: Enabled (true)
- **Feedback on enable**: Medium haptic when turning back on

---

## Notes

- All haptics use the centralized `HapticFeedbackService.shared.trigger()` API
- **NEW**: Global enable/disable respects user preference via `isEnabled` property
- iOS respects user's system haptic settings automatically
- Test haptics on physical device (simulator doesn't provide haptic feedback)
- Consider accessibility: haptics complement but don't replace visual/audio feedback

---

## Changelog

| Date | Changes |
|------|---------|
| 2026-01-16 | Initial plan created |
| 2026-01-16 | Implemented Critical + Medium priority haptics |
| 2026-01-16 | Added global haptic settings toggle in AppSettingsView |
| 2026-01-16 | Updated HapticFeedbackService with isEnabled property |
| 2026-01-16 | Added carousel snap haptics using iOS 17+ `.sensoryFeedback` modifier |
| 2026-01-16 | Added onboarding page transition haptics |
| 2026-01-16 | Completed remaining Medium priority: edit mode toggle, add category, stats card taps, notification toggles |
| 2026-01-16 | Deferred all Low Priority items (text field focus, progress milestones, view transitions, empty state) |
