# @unchecked Sendable Cleanup Plan

## Overview

This document tracks the remaining `@unchecked Sendable` occurrences in the codebase and the plan to eliminate them using proper Swift 6 concurrency patterns (primarily actors).

## Already Converted

| File | Class | Approach | PR |
|------|-------|----------|-----|
| `StoreKitSubscriptionService.swift` | `StoreKitSubscriptionService` | Actor | feat/premium-feature-gating-and-logging |
| `MockSecureSubscriptionService.swift` | `MockSecureSubscriptionService` | Actor | feat/premium-feature-gating-and-logging |
| `SecurePremiumCache.swift` | `SecurePremiumCache` | Actor | feat/premium-feature-gating-and-logging |
| `DebugLogger.swift` | `DebugLogger` | Actor (nonisolated log methods) | feat/premium-feature-gating-and-logging |
| `MigrationLogger.swift` | `MigrationLogger` | Proper Sendable (no mutable state) | feat/premium-feature-gating-and-logging |

## Worth Converting (Production Code)

### Medium Priority - Services with Mutable State

| File | Class | Notes |
|------|-------|-------|
| `PersonalityPreferencesDataSource.swift` | `DefaultPersonalityPreferencesDataSource` | Has mutable state |
| `UserService.swift` | `MockUserService` | Production mock with mutable state |
| `UserService.swift` | `ICloudUserService` | Has mutable state |

## Safe to Leave As-Is

### Thread-Safe Frameworks

These use Apple frameworks that are internally thread-safe:

| File | Class | Framework |
|------|-------|-----------|
| `DebugService.swift` | `DebugService` | @MainActor isolated |
| `UserDefaultsService.swift` | `DefaultUserDefaultsService` | UserDefaults is thread-safe |
| `NotificationService.swift` | `LocalNotificationService` | UNUserNotificationCenter is thread-safe |
| `iCloudKeyValueService.swift` | `DefaultiCloudKeyValueService` | NSUbiquitousKeyValueStore is thread-safe |

### Lock-Protected (Safe)

| File | Class | Notes |
|------|-------|-------|
| `UserDefaultsService.swift` | `MockUserDefaultsService` | Uses NSLock properly |
| `NetworkUtilities.swift` | `ContinuationState` | Internal helper, lock-protected |

### SwiftData Use Cases (Cannot Convert)

These use `ModelContext` which isn't `Sendable`. Converting would require major architectural changes:

| File | Class |
|------|-------|
| `SeedPredefinedCategoriesUseCase.swift` | `SeedPredefinedCategories` |
| `DefaultImportUserDataUseCase.swift` | `DefaultImportUserDataUseCase` |
| `DefaultDeleteDataUseCase.swift` | `DefaultDeleteDataUseCase` |
| `DebugUseCases.swift` | `PopulateTestData` |
| `iCloudSyncUseCases.swift` | `DefaultCheckiCloudStatusUseCase` |

## Test Mocks (Low Priority)

All in `RitualistTests/` - not worth the effort since tests are isolated:

- `MockiCloudKeyValueService`
- `MockUserDefaults`
- `InMemoryNotificationCenter`
- `MockOnboardingRepository`
- `MockProfileRepositoryForOnboarding`
- `MockiCloudKeyValueServiceForOnboarding`
- `MockPermissionCoordinator`
- `MockGetEarliestLogDate`
- `MockValidateHabitUniqueness`
- `MockGetActiveCategories`
- `MockPermissionCoordinatorForHabitDetail`
- `MockiCloudKeyValueServiceForViewModel`
- `MockProfileRepository`
- `MockHabitRepository`
- `MockLogRepository`
- `MockValidateHabitScheduleUseCase`
- `MockGetActiveHabitsUseCase`
- `MockGetLogsUseCase`
- `MockCheckiCloudStatusUseCase`

## Conversion Pattern

### Before (NSLock)
```swift
public final class DebugLogger: @unchecked Sendable {
    private var logBuffer: [LogEntry] = []
    private let bufferLock = NSLock()

    func log(...) {
        bufferLock.lock()
        defer { bufferLock.unlock() }
        logBuffer.append(entry)
    }
}
```

### After (Actor)
```swift
public actor DebugLogger {
    private var logBuffer: [LogEntry] = []

    func log(...) {
        logBuffer.append(entry)  // Automatically safe
    }
}
```

**Tradeoff:** Actor methods become `async`, requiring `await` at call sites.
