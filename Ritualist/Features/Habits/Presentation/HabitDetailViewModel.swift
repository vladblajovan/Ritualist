import Foundation
import Observation
import FactoryKit

// Helper enum for schedule picker
public enum ScheduleType: CaseIterable {
    case daily
    case daysOfWeek
    case timesPerWeek
}

@MainActor @Observable
public final class HabitDetailViewModel {
    @ObservationIgnored @Injected(\.createHabit) var createHabit
    @ObservationIgnored @Injected(\.updateHabit) var updateHabit
    @ObservationIgnored @Injected(\.deleteHabit) var deleteHabit
    @ObservationIgnored @Injected(\.toggleHabitActiveStatus) var toggleHabitActiveStatus
    @ObservationIgnored @Injected(\.getActiveCategories) var getActiveCategories
    @ObservationIgnored @Injected(\.createCustomCategory) var createCustomCategory
    @ObservationIgnored @Injected(\.validateCategoryName) var validateCategoryName
    @ObservationIgnored @Injected(\.validateHabitUniqueness) var validateHabitUniqueness
    @ObservationIgnored @Injected(\.scheduleHabitReminders) var scheduleHabitReminders
    
    // Form state
    public var name = ""
    public var selectedKind: HabitKind = .binary
    public var unitLabel = ""
    public var dailyTarget: Double = 1.0
    public var selectedSchedule: ScheduleType = .daily
    public var selectedDaysOfWeek: Set<Int> = []
    public var timesPerWeek = 1
    public var selectedEmoji = "⭐"
    public var selectedColorHex = "#2DA9E3"
    public var reminders: [ReminderTime] = []
    public var isActive = true
    
    // Category state
    public var selectedCategory: Category?
    public private(set) var categories: [Category] = []
    public private(set) var isLoadingCategories = false
    public private(set) var categoriesError: Error?
    
    // Validation state
    public private(set) var isDuplicateHabit = false
    public private(set) var isValidatingDuplicate = false
    
    // State management
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var isDeleting = false
    public private(set) var error: Error?
    public private(set) var isEditMode: Bool
    
    public let originalHabit: Habit?
    
    public init(habit: Habit? = nil) {
        self.originalHabit = habit
        self.isEditMode = habit != nil
        
        // Pre-populate form if editing
        if let habit = habit {
            loadHabitData(habit)
        }
    }
    
    public var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedKind == .binary || (dailyTarget > 0 && !unitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) &&
        (selectedSchedule != .daysOfWeek || !selectedDaysOfWeek.isEmpty) &&
        !isDuplicateHabit
    }
    
    // Individual validation properties for better UI feedback
    public var isNameValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var isUnitLabelValid: Bool {
        selectedKind == .binary || !unitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var isDailyTargetValid: Bool {
        selectedKind == .binary || dailyTarget > 0
    }
    
    public var isScheduleValid: Bool {
        selectedSchedule != .daysOfWeek || !selectedDaysOfWeek.isEmpty
    }
    
    public func save() async -> Bool {
        guard isFormValid else { return false }
        
        isSaving = true
        error = nil
        
        do {
            let habit = createHabitFromForm()
            
            if isEditMode {
                try await updateHabit.execute(habit)
            } else {
                _ = try await createHabit.execute(habit)
            }
            
            // Schedule notifications for the habit
            try await scheduleHabitReminders.execute(habit: habit)
            
            isSaving = false
            return true
        } catch {
            self.error = error
            isSaving = false
            return false
        }
    }
    
    public func delete() async -> Bool {
        guard let habitId = originalHabit?.id else { return false }
        
        isDeleting = true
        error = nil
        
        do {
            try await deleteHabit.execute(id: habitId)
            
            isDeleting = false
            return true
        } catch {
            self.error = error
            isDeleting = false
            return false
        }
    }
    
    public func toggleActiveStatus() async -> Bool {
        guard let habitId = originalHabit?.id else { return false }
        
        isSaving = true
        error = nil
        
        do {
            let updatedHabit = try await toggleHabitActiveStatus.execute(id: habitId)
            isActive = updatedHabit.isActive
            
            isSaving = false
            return true
        } catch {
            self.error = error
            isSaving = false
            return false
        }
    }
    
    public func retry() async {
        // No specific retry logic needed for form
        error = nil
    }
    
    // MARK: - Reminder Management
    
    public func addReminder(hour: Int, minute: Int) {
        let newReminder = ReminderTime(hour: hour, minute: minute)
        
        // Check if reminder already exists
        guard !reminders.contains(where: { $0.hour == hour && $0.minute == minute }) else {
            return
        }
        
        reminders.append(newReminder)
        // Sort reminders by time
        reminders.sort { first, second in
            if first.hour != second.hour {
                return first.hour < second.hour
            }
            return first.minute < second.minute
        }
    }
    
    public func removeReminder(at index: Int) {
        guard index >= 0 && index < reminders.count else { return }
        reminders.remove(at: index)
    }
    
    public func removeReminder(_ reminder: ReminderTime) {
        reminders.removeAll { $0.hour == reminder.hour && $0.minute == reminder.minute }
    }
    
    // MARK: - Category Management
    
    public func loadCategories() async {
        isLoadingCategories = true
        categoriesError = nil
        
        do {
            categories = try await getActiveCategories.execute()
            
            // Set selected category if editing and habit has a category
            if isEditMode, let originalHabit = originalHabit, 
               originalHabit.categoryId != nil {
                // For habits from suggestions, categoryId contains suggestion ID, not category ID
                // For custom categories, categoryId will be nil
                // For now, we'll handle this in the UI display logic
                selectedCategory = nil
            }
        } catch {
            categoriesError = error
            categories = []
        }
        
        isLoadingCategories = false
    }
    
    public func selectCategory(_ category: Category) {
        selectedCategory = category
        // Re-validate for duplicates when category changes
        Task {
            await validateForDuplicates()
        }
    }
    
    public func createCustomCategory(name: String, emoji: String) async -> Bool {
        do {
            // Validate category name first
            let isValid = try await validateCategoryName.execute(name: name)
            guard isValid else {
                return false
            }
            
            // Create new category with unique ID
            let newCategory = Category(
                id: UUID().uuidString,
                name: name.lowercased(),
                displayName: name,
                emoji: emoji,
                order: categories.count,
                isActive: true
            )
            
            try await createCustomCategory.execute(newCategory)
            
            // Reload categories and select the new one
            await loadCategories()
            selectedCategory = newCategory
            
            return true
        } catch {
            return false
        }
    }
    
    public func validateForDuplicates() async {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            isDuplicateHabit = false
            return
        }
        
        isValidatingDuplicate = true
        
        do {
            let categoryId = selectedCategory?.id
            let isUnique = try await validateHabitUniqueness.execute(
                name: name,
                categoryId: categoryId,
                excludeId: originalHabit?.id
            )
            isDuplicateHabit = !isUnique
        } catch {
            // If validation fails, assume no duplicate to avoid blocking the user
            isDuplicateHabit = false
        }
        
        isValidatingDuplicate = false
    }
    
    private func loadHabitData(_ habit: Habit) {
        name = habit.name
        selectedKind = habit.kind
        unitLabel = habit.unitLabel ?? ""
        dailyTarget = habit.dailyTarget ?? 1.0
        selectedEmoji = habit.emoji ?? "⭐"
        selectedColorHex = habit.colorHex
        reminders = habit.reminders
        isActive = habit.isActive
        
        // Parse schedule
        switch habit.schedule {
        case .daily:
            selectedSchedule = .daily
        case .daysOfWeek(let days):
            selectedSchedule = .daysOfWeek
            selectedDaysOfWeek = days
        case .timesPerWeek(let times):
            selectedSchedule = .timesPerWeek
            timesPerWeek = times
        }
    }
    
    private func createHabitFromForm() -> Habit {
        let schedule: HabitSchedule
        switch selectedSchedule {
        case .daily:
            schedule = .daily
        case .daysOfWeek:
            schedule = .daysOfWeek(selectedDaysOfWeek)
        case .timesPerWeek:
            schedule = .timesPerWeek(timesPerWeek)
        }
        
        // Handle category logic:
        // - For new habits: use selected category ID if available
        // - For edited habits from suggestions: preserve original categoryId 
        // - For edited habits with custom categories: use selected category ID
        let finalCategoryId: String?
        if isEditMode, let originalHabit = originalHabit, originalHabit.suggestionId != nil {
            // Preserve category ID for habits from suggestions
            finalCategoryId = originalHabit.categoryId
        } else {
            // Use selected category ID for new habits or edited custom habits
            finalCategoryId = selectedCategory?.id
        }
        
        return Habit(
            id: originalHabit?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: selectedColorHex,
            emoji: selectedEmoji,
            kind: selectedKind,
            unitLabel: selectedKind == .numeric ? unitLabel : nil,
            dailyTarget: selectedKind == .numeric ? dailyTarget : nil,
            schedule: schedule,
            reminders: reminders,
            startDate: originalHabit?.startDate ?? Date(),
            endDate: originalHabit?.endDate,
            isActive: isActive,
            categoryId: finalCategoryId,
            suggestionId: originalHabit?.suggestionId
        )
    }
}
