# HabitCompletionCheckService Usage Guide

## Overview

The `HabitCompletionCheckService` is a focused service responsible for determining if a habit should show a notification based on its completion status. It follows the single responsibility principle and integrates seamlessly with the existing Clean Architecture.

## Service Interface

```swift
public protocol HabitCompletionCheckService {
    /// Determines if a notification should be shown for a habit on a specific date
    /// - Parameters:
    ///   - habitId: The unique identifier of the habit
    ///   - date: The date to check completion status for
    /// - Returns:
    ///   - `false` if the habit is completed (don't show notification)
    ///   - `true` if the habit is not completed (show notification)  
    ///   - `true` if any error occurs (fail-safe approach)
    func shouldShowNotification(habitId: UUID, date: Date) async -> Bool
}
```

## Dependency Injection

The service is registered in the DI container and can be injected using Factory:

```swift
// Service registration in Container+Services.swift
var habitCompletionCheckService: Factory<HabitCompletionCheckService> {
    self { 
        DefaultHabitCompletionCheckService(
            habitRepository: self.habitRepository(),
            logRepository: self.logRepository(),
            habitCompletionService: self.habitCompletionServiceProtocol()
        )
    }
    .singleton
}
```

## Usage Examples

### In a ViewModel or UseCase

```swift
import Factory

class NotificationViewModel: ObservableObject {
    @Injected(\.habitCompletionCheckService) private var completionCheckService
    
    func checkIfShouldNotify(habitId: UUID, date: Date = Date()) async {
        let shouldShow = await completionCheckService.shouldShowNotification(
            habitId: habitId, 
            date: date
        )
        
        if shouldShow {
            // Show notification logic
            print("Habit not completed - show notification")
        } else {
            // Don't show notification
            print("Habit already completed - skip notification")
        }
    }
}
```

### In a Notification UseCase

```swift
class ShouldSendNotificationUseCase {
    @Injected(\.habitCompletionCheckService) private var completionCheckService
    
    func execute(habitId: UUID, scheduledDate: Date) async -> Bool {
        return await completionCheckService.shouldShowNotification(
            habitId: habitId,
            date: scheduledDate
        )
    }
}
```

## Key Features

### 1. **Fail-Safe Behavior**
The service always returns `true` (show notification) on errors to ensure users don't miss important reminders due to technical issues.

### 2. **Single Responsibility** 
The service has one job: determine notification visibility. It delegates completion logic to the existing `HabitCompletionService`.

### 3. **Clean Architecture Compliance**
- Uses repository patterns for data access
- Delegates business logic to appropriate services
- Follows dependency inversion principle

### 4. **Comprehensive Error Handling**
- Handles missing habits gracefully
- Catches repository errors
- Always provides a safe fallback decision

## Implementation Details

The service coordinates between:
- `HabitRepository`: To fetch habit details
- `LogRepository`: To get habit logs
- `HabitCompletionServiceProtocol`: To determine completion status

It follows this logic flow:
1. Fetch habit by ID from repository
2. Fetch logs for that habit
3. Use existing completion service to check if habit is completed
4. Return inverse of completion status (completed = don't show, not completed = show)
5. Return true (show) on any error for fail-safe behavior

## Testing

The service includes comprehensive unit tests covering:
- ✅ Don't show notifications when habit is completed
- ✅ Show notifications when habit is not completed  
- ✅ Fail-safe behavior when habit not found
- ✅ Fail-safe behavior when repositories throw errors
- ✅ Proper delegation to completion service

## Integration with Notification System

This service can be integrated with the existing notification system:

```swift
// Example integration in NotificationService
class LocalNotificationService {
    @Injected(\.habitCompletionCheckService) private var completionCheckService
    
    private func shouldSendReminder(for habit: Habit) async -> Bool {
        return await completionCheckService.shouldShowNotification(
            habitId: habit.id,
            date: Date()
        )
    }
}
```

This keeps the notification logic clean and focused while leveraging existing completion business logic.