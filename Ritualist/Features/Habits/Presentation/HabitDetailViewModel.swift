import Foundation
import Observation
import FactoryKit
import RitualistCore
import CoreLocation
import TipKit

// Helper enum for schedule picker
public enum ScheduleType: CaseIterable {
    case daily
    case daysOfWeek
}

/// Explicit state for map picker dismiss handling.
/// Replaces boolean flag to prevent race condition between SwiftUI sheet dismissal
/// and @Observable state propagation timing.
public enum MapPickerDismissResult {
    /// No pending dismiss action (initial state, or after handling)
    case none
    /// User saved a valid location before dismissing
    case savedValidLocation
}

@MainActor @Observable
public final class HabitDetailViewModel {
    // Testable dependencies (constructor injected)
    private let getEarliestLogDate: GetEarliestLogDateUseCase
    private let validateHabitUniqueness: ValidateHabitUniquenessUseCase
    private let getActiveCategories: GetActiveCategoriesUseCase
    private let permissionCoordinator: PermissionCoordinatorProtocol

    // Infrastructure dependencies (property injected - don't need mocking in tests)
    @ObservationIgnored @Injected(\.createHabit) var createHabit
    @ObservationIgnored @Injected(\.updateHabit) var updateHabit
    @ObservationIgnored @Injected(\.deleteHabit) var deleteHabit
    @ObservationIgnored @Injected(\.toggleHabitActiveStatus) var toggleHabitActiveStatus
    @ObservationIgnored @Injected(\.createCustomCategory) var createCustomCategory
    @ObservationIgnored @Injected(\.validateCategoryName) var validateCategoryName
    @ObservationIgnored @Injected(\.scheduleHabitReminders) var scheduleHabitReminders
    @ObservationIgnored @Injected(\.configureHabitLocation) var configureHabitLocation
    @ObservationIgnored @Injected(\.timezoneService) var timezoneService
    @ObservationIgnored @Injected(\.debugLogger) var logger
    @ObservationIgnored @Injected(\.checkPremiumStatus) var checkPremiumStatus
    @ObservationIgnored @Injected(\.paywallViewModel) var paywallViewModel

    /// Cached display timezone for synchronous calculations
    @ObservationIgnored private var displayTimezone: TimeZone = .current

    /// Cached premium status for synchronous UI checks
    private var cachedPremiumStatus = false

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
    public var startDate = Date()
    
    // Category state
    public var selectedCategory: HabitCategory?
    public private(set) var categories: [HabitCategory] = []
    public private(set) var isLoadingCategories = false
    public private(set) var categoriesError: Error?

    /// Display categories with selected category moved to first position
    public var displayCategories: [HabitCategory] {
        guard let selected = selectedCategory else {
            return categories
        }
        var reordered = categories
        if let selectedIndex = reordered.firstIndex(where: { $0.id == selected.id }) {
            let selectedCategory = reordered.remove(at: selectedIndex)
            reordered.insert(selectedCategory, at: 0)
        }
        return reordered
    }
    
    // Validation state
    public private(set) var isDuplicateHabit = false
    public private(set) var isValidatingDuplicate = false
    public private(set) var duplicateValidationFailed = false

    // Start date validation state (for edit mode)
    public private(set) var earliestLogDate: Date?
    public private(set) var isLoadingEarliestLogDate = false
    public private(set) var earliestLogDateLoadFailed = false

    // Location state
    public var locationConfiguration: LocationConfiguration?
    public var locationAuthStatus: LocationAuthorizationStatus = .notDetermined
    public private(set) var isCheckingLocationAuth = false
    public private(set) var isRequestingLocationPermission = false
    public var showMapPicker = false
    /// Tracks the result of map picker dismissal to handle race condition with @Observable timing
    public var mapPickerDismissResult: MapPickerDismissResult = .none

    // Premium/Paywall state
    public var paywallItem: PaywallItem?

    /// Whether user has premium subscription (for feature gating)
    public var isPremiumUser: Bool {
        cachedPremiumStatus
    }

    // State management
    public private(set) var isLoading = false
    public private(set) var isSaving = false
    public private(set) var isDeleting = false
    public private(set) var didDelete = false
    public private(set) var error: Error?
    public private(set) var isEditMode: Bool
    
    public let originalHabit: Habit?
    
    /// Creates a HabitDetailViewModel for creating or editing a habit.
    ///
    /// - Parameters:
    ///   - habit: The habit to edit, or nil to create a new habit
    ///   - getEarliestLogDate: Use case for loading earliest log date (defaults to container)
    ///   - validateHabitUniqueness: Use case for validating habit uniqueness (defaults to container)
    ///   - getActiveCategories: Use case for loading categories (defaults to container)
    ///   - permissionCoordinator: Coordinator for permission requests (defaults to container)
    public init(
        habit: Habit? = nil,
        getEarliestLogDate: GetEarliestLogDateUseCase? = nil,
        validateHabitUniqueness: ValidateHabitUniquenessUseCase? = nil,
        getActiveCategories: GetActiveCategoriesUseCase? = nil,
        permissionCoordinator: PermissionCoordinatorProtocol? = nil
    ) {
        // Use provided dependencies or fall back to container
        self.getEarliestLogDate = getEarliestLogDate ?? Container.shared.getEarliestLogDate()
        self.validateHabitUniqueness = validateHabitUniqueness ?? Container.shared.validateHabitUniqueness()
        self.getActiveCategories = getActiveCategories ?? Container.shared.getActiveCategories()
        self.permissionCoordinator = permissionCoordinator ?? Container.shared.permissionCoordinator()

        self.originalHabit = habit
        self.isEditMode = habit != nil

        // Pre-populate form if editing
        if let habit = habit {
            loadHabitData(habit)
        }

        // Load initial data asynchronously (fire-and-forget for production)
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await loadInitialData()
        }
    }

    /// Loads categories, location status, and earliest log date in parallel.
    ///
    /// Called automatically on init for production use.
    /// Can be awaited directly in tests to avoid timing-based waits.
    public func loadInitialData() async {
        async let categories: () = loadCategories()
        async let location: () = checkLocationAuthStatus()
        async let earliestLog: () = loadEarliestLogDate()
        async let premium: () = loadPremiumStatus()
        _ = await (categories, location, earliestLog, premium)
    }

    /// Load and cache premium status for feature gating
    private func loadPremiumStatus() async {
        cachedPremiumStatus = await checkPremiumStatus.execute()
    }

    /// Show the paywall for premium features
    public func showPaywall() async {
        await paywallViewModel.load()
        paywallViewModel.trackPaywallShown(source: "habit_detail", trigger: "premium_feature")
        paywallItem = PaywallItem(viewModel: paywallViewModel)
    }
    
    public var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (selectedKind == .binary || (dailyTarget > 0 && !unitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)) &&
        (selectedSchedule != .daysOfWeek || !selectedDaysOfWeek.isEmpty) &&
        (isEditMode || selectedCategory != nil) &&  // Allow nil category when editing (during async loading)
        !isDuplicateHabit &&
        !duplicateValidationFailed &&  // Block save if duplicate validation failed
        !isLoadingEarliestLogDate &&  // Prevent save while validation data is loading
        !earliestLogDateLoadFailed &&  // Block save if earliest log date load failed
        isStartDateValid
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

    /// Start date is valid if it's not after any existing logs.
    /// If there are logs, start date must be on or before the earliest log date.
    public var isStartDateValid: Bool {
        guard let earliestLog = earliestLogDate else { return true }
        let startDay = CalendarUtils.startOfDayLocal(for: startDate, timezone: displayTimezone)
        let earliestDay = CalendarUtils.startOfDayLocal(for: earliestLog, timezone: displayTimezone)
        return startDay <= earliestDay
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
                // Donate tip event for first habit added (gates TapHabitTip)
                await TapHabitTip.firstHabitAdded.donate()
            }

            // Schedule notifications for the habit
            try await scheduleHabitReminders.execute(habit: habit)

            // Configure geofence monitoring for location-based reminders
            // This starts/stops monitoring based on the location configuration
            try await configureHabitLocation.execute(
                habitId: habit.id,
                configuration: locationConfiguration
            )

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
            didDelete = true
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

        // Load display timezone for date comparisons
        displayTimezone = (try? await timezoneService.getDisplayTimezone()) ?? .current

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
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
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
        duplicateValidationFailed = false

        do {
            let categoryId = selectedCategory?.id
            let isUnique = try await validateHabitUniqueness.execute(
                name: name,
                categoryId: categoryId,
                excludeId: originalHabit?.id
            )
            isDuplicateHabit = !isUnique
        } catch {
            // Block form submission when validation fails to prevent potential duplicates
            logger.log("Failed to validate habit uniqueness for '\(name)': \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            duplicateValidationFailed = true
            isDuplicateHabit = false
        }

        isValidatingDuplicate = false
    }

    /// Loads the earliest log date for the habit being edited.
    /// Used to validate that start date is not set after existing logs.
    public func loadEarliestLogDate() async {
        guard isEditMode, let habitId = originalHabit?.id else { return }

        isLoadingEarliestLogDate = true
        earliestLogDateLoadFailed = false
        do {
            earliestLogDate = try await getEarliestLogDate.execute(for: habitId)
        } catch {
            // Block form submission when validation data fails to load
            logger.log("Failed to load earliest log date for habit \(habitId): \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            earliestLogDateLoadFailed = true
            earliestLogDate = nil
        }
        isLoadingEarliestLogDate = false
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
        startDate = habit.startDate
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
            startDate: startDate,
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
        locationAuthStatus = await permissionCoordinator.checkLocationStatus()
        isCheckingLocationAuth = false
    }

    public func requestLocationPermission(requestAlways: Bool) async -> LocationPermissionOutcome {
        isRequestingLocationPermission = true
        let result = await permissionCoordinator.requestLocationPermission(requestAlways: requestAlways)
        locationAuthStatus = result.status
        isRequestingLocationPermission = false
        return result
    }

    public func openLocationSettings() async {
        @Injected(\.locationPermissionService) var locationPermissionService
        await locationPermissionService.openAppSettings()
    }

    /// Called when map picker sheet is dismissed (via Done, Cancel, or swipe-down)
    /// Clears placeholder config if user didn't save a valid location
    public func handleMapPickerDismiss() {
        // Check explicit dismiss result to avoid race condition with SwiftUI observation timing.
        // On first-time enable, the observation update from saveConfiguration() may not have
        // propagated before this callback runs, causing the coordinate check to see stale (0,0) values.
        if mapPickerDismissResult == .savedValidLocation {
            mapPickerDismissResult = .none
            // User saved a valid location, config is already set correctly
            return
        }

        // User dismissed without saving (Cancel, swipe-down, or Done without selection)
        // Clear the placeholder config if one exists
        guard let config = locationConfiguration else { return }

        let isPlaceholder = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
        if isPlaceholder {
            locationConfiguration = nil
        }
    }

    public func updateLocationConfiguration(_ config: LocationConfiguration?) {
        // Note: Permission checks are handled in toggleLocationEnabled before this is called.
        // Location config is saved when user taps Save on the habit edit sheet.
        locationConfiguration = config
    }

    public func toggleLocationEnabled(_ enabled: Bool) {
        guard enabled else {
            // Disabling: clear the location configuration
            // Changes are saved when user taps Save on the habit edit sheet
            locationConfiguration = nil
            return
        }

        // Reset dismiss result at the start of a new enable flow
        mapPickerDismissResult = .none

        // Enabling location reminders
        if locationConfiguration != nil {
            // Already have configuration - just enable it
            var config = locationConfiguration!
            config.isEnabled = true
            locationConfiguration = config
        } else {
            // First time enabling - set optimistic state immediately to prevent toggle snap-back
            // This placeholder will be cleared if permission is denied
            locationConfiguration = LocationConfiguration.create(
                from: CLLocationCoordinate2D(latitude: 0, longitude: 0), // Placeholder
                radius: LocationConfiguration.defaultRadius,
                triggerType: .entry,
                frequency: .oncePerDay,
                isEnabled: true
            )

            // Request permissions and show map picker async
            // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
            Task { @MainActor in
                // Check current permission status
                await checkLocationAuthStatus()

                // Request permission if needed
                if locationAuthStatus == .notDetermined {
                    let result = await requestLocationPermission(requestAlways: true)

                    if result.canMonitorGeofences {
                        // Permission granted - show map picker
                        showMapPicker = true
                    } else {
                        // Permission denied - clear optimistic state
                        locationConfiguration = nil
                    }
                } else if locationAuthStatus == .authorizedWhenInUse {
                    let result = await requestLocationPermission(requestAlways: true)

                    if result.canMonitorGeofences {
                        showMapPicker = true
                    } else {
                        // User declined upgrade - clear optimistic state
                        locationConfiguration = nil
                    }
                } else if locationAuthStatus.canMonitorGeofences {
                    // "Always" permission already granted - show map picker
                    showMapPicker = true
                } else {
                    // Permission denied/restricted - clear optimistic state
                    locationConfiguration = nil
                }
            }
        }
    }
}

