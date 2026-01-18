//
//  HabitsViewModel+CRUD.swift
//  Ritualist
//
//  CRUD operations extracted from HabitsViewModel to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Create Operations

extension HabitsViewModel {

    public func create(_ habit: Habit) async -> Bool {
        isCreating = true
        error = nil

        do {
            _ = try await createHabit.execute(habit)

            // Notify other tabs (Overview) to refresh - coalesced to prevent spam
            postCoalescedDataChangeNotification()

            await refresh()
            isCreating = false

            userActionTracker.track(.habitCreated(
                habitId: habit.id.uuidString,
                habitName: habit.name,
                habitType: habit.kind == .binary ? "binary" : "numeric"
            ))

            return true
        } catch {
            self.error = error
            isCreating = false
            userActionTracker.trackError(error, context: "habit_create", additionalProperties: ["habit_name": habit.name, "habit_type": habit.kind == .binary ? "binary" : "numeric"])
            return false
        }
    }

    /// Create habit from suggestion (for assistant)
    public func createHabitFromSuggestion(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        let result = await createHabitFromSuggestionUseCase.execute(suggestion)

        if result.didMutateData {
            NotificationCenter.default.post(name: .habitsDataDidChange, object: nil)
        }

        return result
    }
}

// MARK: - Update Operations

extension HabitsViewModel {

    public func update(_ habit: Habit) async -> Bool {
        isUpdating = true
        error = nil

        do {
            try await updateHabit.execute(habit)
            postCoalescedDataChangeNotification()
            await refresh()
            isUpdating = false

            userActionTracker.track(.habitUpdated(
                habitId: habit.id.uuidString,
                habitName: habit.name
            ))

            return true
        } catch {
            self.error = error
            isUpdating = false
            userActionTracker.trackError(error, context: "habit_update", additionalProperties: ["habit_id": habit.id.uuidString, "habit_name": habit.name])
            return false
        }
    }

    public func toggleActiveStatus(id: UUID) async -> Bool {
        isUpdating = true
        error = nil

        let habitToToggle = habitsData.habits.first { $0.id == id }

        do {
            _ = try await toggleHabitActiveStatus.execute(id: id)
            await refresh()
            isUpdating = false

            if let habit = habitToToggle {
                if habit.isActive {
                    userActionTracker.track(.habitArchived(habitId: habit.id.uuidString, habitName: habit.name))
                } else {
                    userActionTracker.track(.habitRestored(habitId: habit.id.uuidString, habitName: habit.name))
                }
            }

            return true
        } catch {
            self.error = error
            isUpdating = false
            userActionTracker.trackError(error, context: "habit_toggle_status", additionalProperties: ["habit_id": id.uuidString])
            return false
        }
    }

    public func reorderHabits(_ newOrder: [Habit]) async -> Bool {
        isReordering = true
        error = nil

        do {
            try await reorderHabits.execute(newOrder)
            habitsData = HabitsData(habits: newOrder, categories: habitsData.categories)
            isReordering = false
            return true
        } catch {
            self.error = error
            userActionTracker.trackError(error, context: "habit_reorder", additionalProperties: ["habits_count": newOrder.count])
            await refresh()
            isReordering = false
            return false
        }
    }
}

// MARK: - Delete Operations

extension HabitsViewModel {

    public func delete(id: UUID) async -> Bool {
        isDeleting = true
        error = nil

        let habitToDelete = habitsData.habits.first { $0.id == id }

        do {
            try await deleteHabit.execute(id: id)
            postCoalescedDataChangeNotification()
            await refresh()
            isDeleting = false

            if let habit = habitToDelete {
                userActionTracker.track(.habitDeleted(habitId: habit.id.uuidString, habitName: habit.name))
            }

            return true
        } catch {
            self.error = error
            isDeleting = false
            userActionTracker.trackError(error, context: "habit_delete", additionalProperties: ["habit_id": id.uuidString])
            return false
        }
    }
}
