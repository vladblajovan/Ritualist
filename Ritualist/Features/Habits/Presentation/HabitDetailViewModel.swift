import Foundation
import Observation
import FactoryKit
import RitualistCore
import CoreLocation

// Helper enum for schedule picker
public enum ScheduleType: CaseIterable {
    case daily
    case daysOfWeek
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
    @ObservationIgnored @Injected(\.configureHabitLocation) var configureHabitLocation
    @ObservationIgnored @Injected(\.requestLocationPermissions) var requestLocationPermissions
    @ObservationIgnored @Injected(\.getLocationAuthStatus) var getLocationAuthStatus

    // Form state
    public var name = ""
    public var selectedKind: HabitKind = .binary
    public var unitLabel = ""
    public var dailyTarget: Double = 1.0
    public var selectedSchedule: ScheduleType = .daily
    public var selectedDaysOfWeek: Set<Int> = []
    public var selectedEmoji = "⭐"
    public var selectedColorHex = "#2DA9E3"
    public var reminders: [ReminderTime] = []
    public var isActive = true
    
    // Category state
    public var selectedCategory: HabitCategory?
    public private(set) var categories: [HabitCategory] = []
    public private(set) var isLoadingCategories = false
    public private(set) var categoriesError: Error?
    
    // Validation state
    public private(set) var isDuplicateHabit = false
    public private(set) var isValidatingDuplicate = false

    // Location state
    public var locationConfiguration: LocationConfiguration?
    public var locationAuthStatus: LocationAuthorizationStatus = .notDetermined
    public private(set) var isCheckingLocationAuth = false
    public private(set) var isRequestingLocationPermission = false
    public var showMapPicker = false
    public var showGeofenceSettings = false

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
        
        // Load categories and check location status in parallel for faster startup
        Task {
            async let categories: () = loadCategories()
            async let location: () = checkLocationAuthStatus()
            _ = await (categories, location)
        }
    }
    
    public var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedKind == .binary || (dailyTarget > 0 && !unitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) &&
        (selectedSchedule != .daysOfWeek || !selectedDaysOfWeek.isEmpty) &&
        (isEditMode || selectedCategory != nil) &&  // Allow nil category when editing (during async loading)
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
    
    public var isCategoryValid: Bool {
        selectedCategory != nil
    }

    public var didMakeChanges = false

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

            didMakeChanges = true
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
               let categoryId = originalHabit.categoryId {
                // Find the matching category from loaded categories
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
            let newCategory = HabitCategory(
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
        locationConfiguration = habit.locationConfiguration

        // Parse schedule
        switch habit.schedule {
        case .daily:
            selectedSchedule = .daily
        case .daysOfWeek(let days):
            selectedSchedule = .daysOfWeek
            selectedDaysOfWeek = days
        }
    }
    
    private func createHabitFromForm() -> Habit {
        let schedule: HabitSchedule
        switch selectedSchedule {
        case .daily:
            schedule = .daily
        case .daysOfWeek:
            schedule = .daysOfWeek(selectedDaysOfWeek)
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
            suggestionId: originalHabit?.suggestionId,
            locationConfiguration: locationConfiguration
        )
    }
}

// MARK: - Location Management

extension HabitDetailViewModel {
    public func checkLocationAuthStatus() async {
        isCheckingLocationAuth = true
        locationAuthStatus = await getLocationAuthStatus.execute()
        isCheckingLocationAuth = false
    }

    public func requestLocationPermission(requestAlways: Bool) async -> LocationPermissionResult {
        isRequestingLocationPermission = true
        let result = await requestLocationPermissions.execute(requestAlways: requestAlways)
        isRequestingLocationPermission = false

        // Update auth status after request
        await checkLocationAuthStatus()

        return result
    }

    public func openLocationSettings() async {
        @Injected(\.locationPermissionService) var locationPermissionService
        await locationPermissionService.openAppSettings()
    }

    public func updateLocationConfiguration(_ config: LocationConfiguration?) async {
        // If enabling location config, verify we have "Always" permission
        if let config = config, config.isEnabled {
            await checkLocationAuthStatus()

            // If we don't have "Always" permission, request upgrade
            if !locationAuthStatus.canMonitorGeofences {
                if locationAuthStatus == .authorizedWhenInUse || locationAuthStatus == .notDetermined {
                    let result = await requestLocationPermission(requestAlways: true)
                    if case .denied = result {
                        // Can't enable without "Always" permission
                        return
                    }
                    if case .failed = result {
                        return
                    }
                } else {
                    // Permission denied or restricted - can't enable
                    return
                }
            }
        }

        locationConfiguration = config

        // If we have a saved habit, update it immediately
        if let habitId = originalHabit?.id {
            do {
                try await configureHabitLocation.execute(habitId: habitId, configuration: config)
            } catch {
                self.error = error
            }
        }
    }

    public func toggleLocationEnabled(_ enabled: Bool) {
        guard enabled else {
            // Disabling: clear the configuration (don't preserve potentially stale location data)
            locationConfiguration = nil
            if let habitId = originalHabit?.id {
                Task {
                    try await configureHabitLocation.execute(habitId: habitId, configuration: nil)
                }
            }
            return
        }

        // Enabling location reminders
        if locationConfiguration != nil {
            // Already have configuration - just enable it
            var config = locationConfiguration!
            config.isEnabled = true
            locationConfiguration = config
            if let habitId = originalHabit?.id {
                Task {
                    try await configureHabitLocation.execute(habitId: habitId, configuration: config)
                }
            }
        } else {
            // First time enabling - request permissions and show map picker
            Task {
                // Check current permission status
                await checkLocationAuthStatus()

                // Request permission if needed
                if locationAuthStatus == .notDetermined {
                    // Request "Always" permission for background geofence monitoring
                    let result = await requestLocationPermission(requestAlways: true)

                    // If permission granted, create default config and show map picker
                    switch result {
                    case .granted:
                        // Create default configuration (in-memory only, not saved yet)
                        await MainActor.run {
                            locationConfiguration = LocationConfiguration.create(
                                from: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Placeholder
                                radius: LocationConfiguration.defaultRadius,
                                triggerType: .entry,
                                frequency: .oncePerDay,
                                isEnabled: true
                            )
                            showMapPicker = true
                        }

                        // Note: Config will be saved when user clicks "Done" on map picker
                        // If user cancels, config is discarded and toggle reverts
                    case .denied, .failed:
                        // Permission denied - toggle stays off
                        break
                    }
                } else if locationAuthStatus == .authorizedWhenInUse {
                    // User has "When In Use" but geofences need "Always"
                    // Request upgrade to "Always" permission
                    let result = await requestLocationPermission(requestAlways: true)

                    switch result {
                    case .granted:
                        await MainActor.run {
                            locationConfiguration = LocationConfiguration.create(
                                from: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                                radius: LocationConfiguration.defaultRadius,
                                triggerType: .entry,
                                frequency: .oncePerDay,
                                isEnabled: true
                            )
                            showMapPicker = true
                        }
                    case .denied, .failed:
                        // User declined upgrade - can't use geofences
                        break
                    }
                } else if locationAuthStatus.canMonitorGeofences {
                    // "Always" permission already granted - create default config and show map picker
                    await MainActor.run {
                        locationConfiguration = LocationConfiguration.create(
                            from: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Placeholder
                            radius: LocationConfiguration.defaultRadius,
                            triggerType: .entry,
                            frequency: .oncePerDay,
                            isEnabled: true
                        )
                        showMapPicker = true
                    }

                    // Note: Config will be saved when user clicks "Done" on map picker
                    // If user cancels, config is discarded and toggle reverts
                }
                // If permission is denied/restricted, user will see the permission status UI
            }
        }
    }
}

