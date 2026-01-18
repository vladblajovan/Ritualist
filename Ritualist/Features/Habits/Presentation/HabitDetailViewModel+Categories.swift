//
//  HabitDetailViewModel+Categories.swift
//  Ritualist
//
//  Category and reminder management extracted to reduce type body length.
//

import Foundation
import RitualistCore

// MARK: - Category Management

extension HabitDetailViewModel {

    public func loadCategories() async {
        isLoadingCategories = true
        categoriesError = nil

        displayTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current

        do {
            categories = try await getActiveCategories.execute()

            if isEditMode,
               let originalHabit = originalHabit,
               let categoryId = originalHabit.categoryId {
                selectedCategory = categories.first { $0.id == categoryId }
            }
        } catch {
            categoriesError = error
            categories = []
        }

        isLoadingCategories = false
    }

    public func selectCategory(_ category: HabitCategory) {
        selectedCategory = category
        Task { @MainActor in
            await validateForDuplicates()
        }
    }

    public func createCustomCategory(name: String, emoji: String) async -> Bool {
        do {
            let isValid = try await validateCategoryName.execute(name: name)
            guard isValid else {
                return false
            }

            let newCategory = HabitCategory(
                id: UUID().uuidString,
                name: name.lowercased(),
                displayName: name,
                emoji: emoji,
                order: categories.count,
                isActive: true
            )

            try await createCustomCategory.execute(newCategory)
            await loadCategories()
            selectedCategory = newCategory
            return true
        } catch {
            return false
        }
    }

    public func validateForDuplicates() async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            isDuplicateHabit = false
            return
        }

        isValidatingDuplicate = true
        duplicateValidationFailed = false

        do {
            let isUnique = try await validateHabitUniqueness.execute(
                name: name,
                categoryId: selectedCategory?.id,
                excludeId: originalHabit?.id
            )
            isDuplicateHabit = !isUnique
        } catch {
            logger.log(
                "Failed to validate habit uniqueness for '\(name)': \(error.localizedDescription)",
                level: .error,
                category: .dataIntegrity
            )
            duplicateValidationFailed = true
            isDuplicateHabit = false
        }

        isValidatingDuplicate = false
    }

    public func loadEarliestLogDate() async {
        guard isEditMode, let habitId = originalHabit?.id else {
            return
        }

        isLoadingEarliestLogDate = true
        earliestLogDateLoadFailed = false

        do {
            earliestLogDate = try await getEarliestLogDate.execute(for: habitId)
        } catch {
            logger.log(
                "Failed to load earliest log date for habit \(habitId): \(error.localizedDescription)",
                level: .error,
                category: .dataIntegrity
            )
            earliestLogDateLoadFailed = true
            earliestLogDate = nil
        }

        isLoadingEarliestLogDate = false
    }
}

// MARK: - Reminder Management

extension HabitDetailViewModel {

    public func addReminder(hour: Int, minute: Int) {
        let alreadyExists = reminders.contains { $0.hour == hour && $0.minute == minute }
        guard !alreadyExists else {
            return
        }

        reminders.append(ReminderTime(hour: hour, minute: minute))
        reminders.sort { lhs, rhs in
            if lhs.hour != rhs.hour {
                return lhs.hour < rhs.hour
            }
            return lhs.minute < rhs.minute
        }
    }

    public func removeReminder(at index: Int) {
        guard index >= 0 && index < reminders.count else {
            return
        }
        reminders.remove(at: index)
    }

    public func removeReminder(_ reminder: ReminderTime) {
        reminders.removeAll { $0.hour == reminder.hour && $0.minute == reminder.minute }
    }
}
