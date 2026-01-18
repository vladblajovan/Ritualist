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

    public var displayCategories: [HabitCategory] {
        guard let selected = selectedCategory else { return categories }
        var reordered = categories
        if let selectedIndex = reordered.firstIndex(where: { $0.id == selected.id }) { reordered.insert(reordered.remove(at: selectedIndex), at: 0) }
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
    
    public init(
        habit: Habit? = nil,
        getEarliestLogDate: GetEarliestLogDateUseCase? = nil,
        validateHabitUniqueness: ValidateHabitUniquenessUseCase? = nil,
        getActiveCategories: GetActiveCategoriesUseCase? = nil,
        permissionCoordinator: PermissionCoordinatorProtocol? = nil
    ) {
        self.getEarliestLogDate = getEarliestLogDate ?? Container.shared.getEarliestLogDate()
        self.validateHabitUniqueness = validateHabitUniqueness ?? Container.shared.validateHabitUniqueness()
        self.getActiveCategories = getActiveCategories ?? Container.shared.getActiveCategories()
        self.permissionCoordinator = permissionCoordinator ?? Container.shared.permissionCoordinator()
        self.originalHabit = habit
        self.isEditMode = habit != nil
        if let habit = habit {
            loadHabitData(habit)
        }
        Task { @MainActor in
            await loadInitialData()
        }
    }

    public func loadInitialData() async {
        async let categoriesLoad: () = loadCategories()
        async let locationLoad: () = checkLocationAuthStatus()
        async let earliestLogLoad: () = loadEarliestLogDate()
        async let premiumLoad: () = loadPremiumStatus()
        _ = await (categoriesLoad, locationLoad, earliestLogLoad, premiumLoad)
    }

    private func loadPremiumStatus() async {
        cachedPremiumStatus = await checkPremiumStatus.execute()
    }

    public func showPaywall() async {
        await paywallViewModel.load()
        paywallViewModel.trackPaywallShown(source: "habit_detail", trigger: "premium_feature")
        paywallItem = PaywallItem(viewModel: paywallViewModel)
    }
    
    public var isFormValid: Bool {
        let isTargetValid = selectedKind == .binary || (dailyTarget > 0 && isUnitLabelValid)
        let isCategorySelected = isEditMode || selectedCategory != nil
        let isNotDuplicate = !isDuplicateHabit && !duplicateValidationFailed
        let isEarliestLogDateReady = !isLoadingEarliestLogDate && !earliestLogDateLoadFailed

        return isNameValid
            && isTargetValid
            && isScheduleValid
            && isCategorySelected
            && isNotDuplicate
            && isEarliestLogDateReady
            && isStartDateValid
    }

    public var isNameValid: Bool { !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isUnitLabelValid: Bool { selectedKind == .binary || !unitLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var isDailyTargetValid: Bool { selectedKind == .binary || dailyTarget > 0 }
    public var isScheduleValid: Bool { selectedSchedule != .daysOfWeek || !selectedDaysOfWeek.isEmpty }
    public var isCategoryValid: Bool { selectedCategory != nil }
    public var isStartDateValid: Bool {
        guard let earliestLog = earliestLogDate else { return true }
        return CalendarUtils.startOfDayLocal(for: startDate, timezone: displayTimezone) <= CalendarUtils.startOfDayLocal(for: earliestLog, timezone: displayTimezone)
    }

    public var didMakeChanges = false

    public func save() async -> Bool {
        guard isFormValid else {
            return false
        }

        isSaving = true
        error = nil

        do {
            let habit = createHabitFromForm()

            if isEditMode {
                try await updateHabit.execute(habit)
            } else {
                _ = try await createHabit.execute(habit)
                await TapHabitTip.firstHabitAdded.donate()
            }

            try await scheduleHabitReminders.execute(habit: habit)
            try await configureHabitLocation.execute(habitId: habit.id, configuration: locationConfiguration)

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
        guard let habitId = originalHabit?.id else {
            return false
        }

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
        guard let habitId = originalHabit?.id else {
            return false
        }

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
        error = nil
    }
    
    // MARK: - Reminder Management

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
    
    // MARK: - Category Management

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

        switch habit.schedule {
        case .daily:
            selectedSchedule = .daily
        case .daysOfWeek(let days):
            selectedSchedule = .daysOfWeek
            selectedDaysOfWeek = days
        }
    }

    private func createHabitFromForm() -> Habit {
        let schedule: HabitSchedule = selectedSchedule == .daily
            ? .daily
            : .daysOfWeek(selectedDaysOfWeek)

        // For habits created from suggestions, preserve the original category
        let finalCategoryId = (isEditMode && originalHabit?.suggestionId != nil)
            ? originalHabit?.categoryId
            : selectedCategory?.id

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

    public func handleMapPickerDismiss() {
        if mapPickerDismissResult == .savedValidLocation {
            mapPickerDismissResult = .none
            return
        }

        guard let config = locationConfiguration else {
            return
        }

        let isDefaultCoordinate = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
        if isDefaultCoordinate {
            locationConfiguration = nil
        }
    }

    public func updateLocationConfiguration(_ config: LocationConfiguration?) {
        locationConfiguration = config
    }

    public func toggleLocationEnabled(_ enabled: Bool) {
        guard enabled else {
            locationConfiguration = nil
            return
        }

        mapPickerDismissResult = .none

        if locationConfiguration != nil {
            var config = locationConfiguration!
            config.isEnabled = true
            locationConfiguration = config
        } else {
            locationConfiguration = LocationConfiguration.create(
                from: CLLocationCoordinate2D(latitude: 0, longitude: 0),
                radius: LocationConfiguration.defaultRadius,
                triggerType: .entry,
                frequency: .oncePerDay,
                isEnabled: true
            )

            Task { @MainActor in
                await checkLocationAuthStatus()

                if locationAuthStatus == .notDetermined || locationAuthStatus == .authorizedWhenInUse {
                    let result = await requestLocationPermission(requestAlways: true)
                    if result.canMonitorGeofences {
                        showMapPicker = true
                    } else {
                        locationConfiguration = nil
                    }
                } else if locationAuthStatus.canMonitorGeofences {
                    showMapPicker = true
                } else {
                    locationConfiguration = nil
                }
            }
        }
    }
}

