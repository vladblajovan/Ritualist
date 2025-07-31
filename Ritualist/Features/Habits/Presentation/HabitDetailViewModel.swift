import Foundation
import Observation

// Helper enum for schedule picker
public enum ScheduleType: CaseIterable {
    case daily
    case daysOfWeek
    case timesPerWeek
}

@MainActor @Observable
public final class HabitDetailViewModel {
    private let createHabit: CreateHabitUseCase
    private let updateHabit: UpdateHabitUseCase
    private let deleteHabit: DeleteHabitUseCase
    private let refreshTrigger: RefreshTrigger
    
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
    
    // State management
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var isDeleting = false
    public private(set) var error: Error?
    public private(set) var isEditMode: Bool
    
    private let originalHabit: Habit?
    
    public init(createHabit: CreateHabitUseCase,
                updateHabit: UpdateHabitUseCase,
                deleteHabit: DeleteHabitUseCase,
                refreshTrigger: RefreshTrigger,
                habit: Habit?) {
        self.createHabit = createHabit
        self.updateHabit = updateHabit
        self.deleteHabit = deleteHabit
        self.refreshTrigger = refreshTrigger
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
        (selectedSchedule != .daysOfWeek || !selectedDaysOfWeek.isEmpty)
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
                try await createHabit.execute(habit)
            }
            
            // Trigger reactive refresh for OverviewViewModel
            refreshTrigger.triggerOverviewRefresh()
            
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
            
            // Trigger reactive refresh for OverviewViewModel
            refreshTrigger.triggerOverviewRefresh()
            
            isDeleting = false
            return true
        } catch {
            self.error = error
            isDeleting = false
            return false
        }
    }
    
    public func retry() async {
        // No specific retry logic needed for form
        error = nil
    }
    
    private func loadHabitData(_ habit: Habit) {
        name = habit.name
        selectedKind = habit.kind
        unitLabel = habit.unitLabel ?? ""
        dailyTarget = habit.dailyTarget ?? 1.0
        selectedEmoji = habit.emoji ?? "⭐"
        selectedColorHex = habit.colorHex
        
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
        
        return Habit(
            id: originalHabit?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            colorHex: selectedColorHex,
            emoji: selectedEmoji,
            kind: selectedKind,
            unitLabel: selectedKind == .numeric ? unitLabel : nil,
            dailyTarget: selectedKind == .numeric ? dailyTarget : nil,
            schedule: schedule,
            reminders: originalHabit?.reminders ?? [],
            startDate: originalHabit?.startDate ?? Date(),
            endDate: originalHabit?.endDate,
            isActive: originalHabit?.isActive ?? true
        )
    }
}