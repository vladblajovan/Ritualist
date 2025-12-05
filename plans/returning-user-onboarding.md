# Returning User Onboarding Plan

## Problem Statement

When a user sets up a new device with existing iCloud data:
1. App shows full onboarding (name, avatar, habit creation)
2. AI assistant might suggest creating habits
3. But their data is already syncing from iCloud
4. This creates a confusing and redundant experience

## Device-Local vs Cloud-Synced Data

### Device-Local (must request per device)
- Notification permissions
- Location permissions
- Widget setup

### Cloud-Synced (via iCloud)
- User profile (name, avatar, appearance)
- Habits & completion logs
- Categories
- Timezone preferences
- Personality analysis data

## Proposed Solution

### 1. Launch Screen (Data Detection Phase)

On fresh install, show a branded launch screen while checking for iCloud data:

```
┌─────────────────────────────────┐
│                                 │
│                                 │
│                                 │
│         [App Icon]              │
│                                 │
│         Ritualist               │
│                                 │
│                                 │
│       ◌ (Loading Spinner)       │
│                                 │
│                                 │
│                                 │
└─────────────────────────────────┘
```

**Why a Launch Screen:**
- Seamless transition from iOS launch screen
- Hides detection logic elegantly
- Feels polished and professional
- No jarring transitions or blank screens
- User perceives app as "loading" rather than "deciding what to show"

**Detection Logic (runs behind the scenes):**
- Check if CloudKit has existing data:
  - Habits count > 0, OR
  - Profile exists with non-empty name
- Determine: `isReturningUser: Bool`
- Timeout after 3-4 seconds (graceful fallback to new user flow)

### 2. Two Onboarding Flows

#### New User Flow (existing)
```
Name Entry → Avatar Selection → Habit Suggestions → Permissions → Main App
```

#### Returning User Flow (new)
```
Welcome Back Screen → Permissions Only → Main App
```

### 3. Welcome Back Screen Design

```
┌─────────────────────────────────┐
│                                 │
│         [User Avatar]           │
│                                 │
│     Welcome back, [Name]!       │
│                                 │
│   Your data has been synced     │
│        from iCloud              │
│                                 │
│   ┌─────────────────────────┐   │
│   │  ✓ 12 habits synced     │   │
│   │  ✓ 5 categories synced  │   │
│   │  ✓ Profile restored     │   │
│   └─────────────────────────┘   │
│                                 │
│   Let's set up this device      │
│                                 │
│      [ Continue Button ]        │
│                                 │
└─────────────────────────────────┘
```

### 4. Permissions Flow (Returning User)

After Welcome Back screen:
1. **Notification Permission**
   - Request notification authorization
   - Explain: "Get reminders for your habits"

2. **Location Permission** (conditional)
   - Only show if synced habits include location-based reminders
   - Request location authorization
   - Explain: "Enable location-based habit reminders"

3. **Skip to Main App**
   - No habit creation suggestions
   - No AI assistant prompts for new habits

### 5. Edge Cases

| Scenario | Behavior |
|----------|----------|
| iCloud disabled | Standard new user onboarding |
| iCloud data empty (user deleted everything) | Standard new user onboarding |
| Sync timeout (>5 seconds) | Standard onboarding with "Sync later" option |
| Sync fails | Standard onboarding, sync will happen in background |
| Partial data (profile but no habits) | Returning user flow (they may have intentionally deleted habits) |

### 6. Technical Implementation

#### 6.1 New Types

```swift
enum OnboardingFlowType {
    case newUser
    case returningUser
}

struct SyncedDataSummary {
    let habitsCount: Int
    let categoriesCount: Int
    let hasProfile: Bool
    let profileName: String?
    let profileAvatar: Data?
}
```

#### 6.2 Detection Logic

```swift
// In OnboardingCoordinator or similar
func determineOnboardingFlow() async -> OnboardingFlowType {
    // 1. Check if onboarding already completed
    guard !hasCompletedOnboarding else { return .newUser } // Already done

    // 2. Check iCloud availability
    let iCloudStatus = await checkiCloudStatus.execute()
    guard iCloudStatus == .available else { return .newUser }

    // 3. Wait briefly for initial sync
    try? await Task.sleep(for: .seconds(2))

    // 4. Check for existing data
    let summary = await fetchSyncedDataSummary()

    if summary.habitsCount > 0 || summary.hasProfile {
        return .returningUser
    }

    return .newUser
}
```

#### 6.3 Files to Modify/Create

**New Files:**
- `AppLaunchView.swift` - Branded launch screen with spinner (shown during detection)
- `WelcomeBackView.swift` - UI for returning user welcome screen
- `ReturningUserPermissionsView.swift` - Streamlined permissions flow
- `iCloudDataDetectionService.swift` - Service to check for existing iCloud data

**Modify:**
- `OnboardingCoordinator.swift` - Add flow type detection
- `OnboardingStateModel.swift` - Track flow type if needed
- `RitualistApp.swift` - Integrate launch screen and detection at launch
- `RootTabView.swift` or equivalent - Show launch screen before onboarding decision

#### 6.4 Launch Screen Implementation

```swift
struct AppLaunchView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // App Icon
            Image("AppIconImage") // or use asset
                .resizable()
                .frame(width: 120, height: 120)
                .cornerRadius(24)

            // App Name
            Text("Ritualist")
                .font(.title)
                .fontWeight(.semibold)

            Spacer()

            // Loading Spinner
            ProgressView()
                .scaleEffect(1.2)
                .padding(.bottom, 60)
        }
    }
}
```

#### 6.5 Detection Service

```swift
actor iCloudDataDetectionService {
    func detectExistingData(timeout: TimeInterval = 3.5) async -> SyncedDataSummary? {
        // 1. Check iCloud availability
        let status = await checkiCloudStatus()
        guard status == .available else { return nil }

        // 2. Wait for initial sync with timeout
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            let summary = await fetchDataSummary()

            // If we found data, return immediately
            if summary.habitsCount > 0 || summary.hasProfile {
                return summary
            }

            // Brief pause before checking again
            try? await Task.sleep(for: .milliseconds(500))
        }

        // Timeout reached, return whatever we have
        return await fetchDataSummary()
    }

    private func fetchDataSummary() async -> SyncedDataSummary {
        // Query local store (which syncs from CloudKit)
        let habits = try? await habitRepository.fetchAllHabits()
        let profile = try? await profileRepository.fetchProfile()

        return SyncedDataSummary(
            habitsCount: habits?.count ?? 0,
            categoriesCount: /* fetch count */,
            hasProfile: profile?.name.isEmpty == false,
            profileName: profile?.name,
            profileAvatar: profile?.avatarImageData
        )
    }
}
```

### 7. User Experience Flow

```
App Launch (Fresh Install)
         │
         ▼
┌─────────────────────┐
│   Launch Screen     │
│   [App Icon]        │
│   ◌ Spinner         │
│                     │
│ (Detection running  │
│  in background)     │
└─────────────────────┘
         │
         ▼
   ┌─────────────┐
   │ Check iCloud │
   │   Status     │
   └─────────────┘
         │
    ┌────┴────┐
    │         │
Available  Unavailable
    │         │
    ▼         │
┌─────────┐   │
│Wait for │   │
│ sync    │   │
│(max 3-4s)   │
└─────────┘   │
    │         │
    ▼         │
┌─────────┐   │
│Check for│   │
│  data   │   │
└─────────┘   │
    │         │
  ┌─┴─┐       │
  │   │       │
 Yes  No      │
  │   │       │
  ▼   └───────┴──────┐
┌─────────────┐      │
│Welcome Back │      ▼
│   Flow      │  ┌─────────┐
└─────────────┘  │New User │
       │         │  Flow   │
       ▼         └─────────┘
┌─────────────┐      │
│ Permissions │      │
│    Only     │      │
└─────────────┘      │
       │             │
       └──────┬──────┘
              │
              ▼
         ┌─────────┐
         │Main App │
         └─────────┘
```

**Note:** The Launch Screen is only shown on fresh install when onboarding hasn't been completed yet. Returning to the app after onboarding goes directly to Main App.

### 8. Success Metrics

- Reduced time-to-main-app for returning users
- No duplicate habit creation prompts for returning users
- Permissions still granted on new devices
- Positive user feedback on "Welcome Back" experience

### 9. Future Enhancements

- Show last sync date: "Last used 3 days ago on iPhone 14"
- Device handoff: "Continue where you left off"
- Sync progress indicator for large datasets

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Create `OnboardingFlowType` enum
- [ ] Create `SyncedDataSummary` struct
- [ ] Create `iCloudDataDetectionService` with timeout logic

### Phase 2: Launch Screen
- [ ] Create `AppLaunchView` UI (app icon + spinner)
- [ ] Integrate launch screen in app startup flow
- [ ] Show only on fresh install (onboarding not completed)

### Phase 3: Detection Logic
- [ ] Implement `determineOnboardingFlow()` detection logic
- [ ] Add polling with 500ms intervals during sync wait
- [ ] Implement 3-4 second timeout with graceful fallback

### Phase 4: Welcome Back Flow
- [ ] Create `WelcomeBackView` UI (personalized greeting + sync summary)
- [ ] Create `ReturningUserPermissionsView` UI (streamlined permissions)
- [ ] Modify `OnboardingCoordinator` to support both flows

### Phase 5: Edge Cases
- [ ] Handle iCloud unavailable → new user flow
- [ ] Handle timeout → new user flow
- [ ] Handle partial data (profile only, no habits)
- [ ] Handle sync errors gracefully

### Phase 6: Testing
- [ ] Test on fresh device with existing iCloud data
- [ ] Test on fresh device with no iCloud data
- [ ] Test with iCloud disabled
- [ ] Test timeout scenario (slow network)
- [ ] Test interruption (app killed during detection)
