// swiftlint:disable file_length

import Foundation
import RitualistCore
import FactoryKit

// MARK: - Test Data Population Types
public struct TestDataPopulationError: LocalizedError {
    public let message: String
    
    public var errorDescription: String? { message }
    
    public init(_ message: String) {
        self.message = message
    }
}

// MARK: - Habit Use Case Implementations
public final class CreateHabit: CreateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws -> Habit { 
        // Business logic: Set display order to be last
        let existingHabits = try await repo.fetchAllHabits()
        let maxOrder = existingHabits.map(\.displayOrder).max() ?? -1
        
        let habitWithOrder = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: habit.endDate,
            isActive: habit.isActive,
            displayOrder: maxOrder + 1,
            categoryId: habit.categoryId,
            suggestionId: habit.suggestionId
        )
        
        try await repo.create(habitWithOrder)
        return habitWithOrder
    }
}


public final class GetAllHabits: GetAllHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] { 
        let habits = try await repo.fetchAllHabits()
        return habits.sorted { $0.displayOrder < $1.displayOrder }
    }
}

public final class UpdateHabit: UpdateHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habit: Habit) async throws { try await repo.update(habit) }
}

public final class DeleteHabit: DeleteHabitUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws { 
        // SwiftData cascade delete will automatically remove associated logs
        try await repo.delete(id: id) 
    }
}

public final class ToggleHabitActiveStatus: ToggleHabitActiveStatusUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Habit {
        let allHabits = try await repo.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == id }) else {
            throw HabitError.habitNotFound(id: id)
        }
        
        let updatedHabit = Habit(
            id: habit.id,
            name: habit.name,
            colorHex: habit.colorHex,
            emoji: habit.emoji,
            kind: habit.kind,
            unitLabel: habit.unitLabel,
            dailyTarget: habit.dailyTarget,
            schedule: habit.schedule,
            reminders: habit.reminders,
            startDate: habit.startDate,
            endDate: habit.endDate,
            isActive: !habit.isActive,
            displayOrder: habit.displayOrder,
            categoryId: habit.categoryId,
            suggestionId: habit.suggestionId
        )
        
        try await repo.update(updatedHabit)
        return updatedHabit
    }
}

public final class ReorderHabits: ReorderHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(_ habits: [Habit]) async throws {
        // Business logic: Update display order for each habit
        var updatedHabits: [Habit] = []
        for (index, habit) in habits.enumerated() {
            let updatedHabit = Habit(
                id: habit.id,
                name: habit.name,
                colorHex: habit.colorHex,
                emoji: habit.emoji,
                kind: habit.kind,
                unitLabel: habit.unitLabel,
                dailyTarget: habit.dailyTarget,
                schedule: habit.schedule,
                reminders: habit.reminders,
                startDate: habit.startDate,
                endDate: habit.endDate,
                isActive: habit.isActive,
                displayOrder: index,
                categoryId: habit.categoryId,
                suggestionId: habit.suggestionId
            )
            updatedHabits.append(updatedHabit)
        }
        
        // Update all habits with new order
        for habit in updatedHabits {
            try await repo.update(habit)
        }
    }
}

public final class ValidateHabitUniqueness: ValidateHabitUniquenessUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute(name: String, categoryId: String?, excludeId: UUID?) async throws -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allHabits = try await repo.fetchAllHabits()
        
        // Check for duplicate: same name AND same categoryId
        let isDuplicate = allHabits.contains { habit in
            // Skip the habit being edited (if any)
            if let excludeId = excludeId, habit.id == excludeId {
                return false
            }
            
            // Check if name matches
            let nameMatches = habit.name.lowercased() == trimmedName
            
            // Check if category matches (both nil, or both have same value)
            let categoryMatches = (habit.categoryId == categoryId)
            
            return nameMatches && categoryMatches
        }
        
        return !isDuplicate  // Return true if unique (no duplicate found)
    }
}

public final class GetHabitsByCategory: GetHabitsByCategoryUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute(categoryId: String) async throws -> [Habit] {
        let allHabits = try await repo.fetchAllHabits()
        return allHabits.filter { $0.categoryId == categoryId }
    }
}

public final class OrphanHabitsFromCategory: OrphanHabitsFromCategoryUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    
    public func execute(categoryId: String) async throws {
        let habitsInCategory = try await GetHabitsByCategory(repo: repo).execute(categoryId: categoryId)
        
        // Set categoryId to nil for all habits in the deleted category
        for habit in habitsInCategory {
            let orphanedHabit = Habit(
                id: habit.id,
                name: habit.name,
                colorHex: habit.colorHex,
                emoji: habit.emoji,
                kind: habit.kind,
                unitLabel: habit.unitLabel,
                dailyTarget: habit.dailyTarget,
                schedule: habit.schedule,
                reminders: habit.reminders,
                startDate: habit.startDate,
                endDate: habit.endDate,
                isActive: habit.isActive,
                displayOrder: habit.displayOrder,
                categoryId: nil, // Remove category reference
                suggestionId: habit.suggestionId
            )
            try await repo.update(orphanedHabit)
        }
    }
}

public final class CleanupOrphanedHabits: CleanupOrphanedHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> Int {
        return try await repo.cleanupOrphanedHabits()
    }
}

// MARK: - Profile Use Case Implementations
public final class LoadProfile: LoadProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute() async throws -> UserProfile { try await repo.loadProfile() }
}

public final class SaveProfile: SaveProfileUseCase {
    private let repo: ProfileRepository
    public init(repo: ProfileRepository) { self.repo = repo }
    public func execute(_ profile: UserProfile) async throws { try await repo.saveProfile(profile) }
}

// MARK: - Log Use Case Implementations
public final class GetLogs: GetLogsUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] {
        // Get all logs from repository (no filtering in repository layer)
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Filter by date range
        return allLogs.filter { log in
            let calendar = Calendar.current
            if let since {
                let sinceStart = calendar.startOfDay(for: since)
                let logStart = calendar.startOfDay(for: log.date)
                if logStart < sinceStart { return false }
            }
            if let until {
                let untilStart = calendar.startOfDay(for: until)
                let logStart = calendar.startOfDay(for: log.date)
                if logStart > untilStart { return false }
            }
            return true
        }
    }
}

public final class GetBatchLogs: GetBatchLogsUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(for habitIDs: [UUID], since: Date?, until: Date?) async throws -> [UUID: [HabitLog]] {
        // TRUE batch query - single database call instead of N calls
        let allLogs = try await repo.logs(for: habitIDs)
        
        // Group logs by habitID and apply date filtering
        var result: [UUID: [HabitLog]] = [:]
        
        // Initialize empty arrays for all requested habitIDs
        for habitID in habitIDs {
            result[habitID] = []
        }
        
        // Group and filter logs
        for log in allLogs {
            // Apply same date filtering logic as single GetLogs UseCase
            let calendar = Calendar.current
            var includeLog = true
            
            if let since {
                let sinceStart = calendar.startOfDay(for: since)
                let logStart = calendar.startOfDay(for: log.date)
                if logStart < sinceStart { includeLog = false }
            }
            if let until {
                let untilStart = calendar.startOfDay(for: until)
                let logStart = calendar.startOfDay(for: log.date)
                if logStart > untilStart { includeLog = false }
            }
            
            if includeLog {
                result[log.habitID, default: []].append(log)
            }
        }
        
        return result
    }
}

public final class GetSingleHabitLogs: GetSingleHabitLogsUseCase {
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(getBatchLogs: GetBatchLogsUseCase) {
        self.getBatchLogs = getBatchLogs
    }
    
    public func execute(for habitID: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        // Use batch loading with single habit ID for consistency and potential caching benefits
        let logsByHabitId = try await getBatchLogs.execute(
            for: [habitID],
            since: startDate,
            until: endDate
        )
        
        return logsByHabitId[habitID] ?? []
    }
}

public final class LogHabit: LogHabitUseCase {
    private let repo: LogRepository
    private let habitRepo: HabitRepository
    private let validateSchedule: ValidateHabitScheduleUseCase
    
    public init(repo: LogRepository, habitRepo: HabitRepository, validateSchedule: ValidateHabitScheduleUseCase) { 
        self.repo = repo
        self.habitRepo = habitRepo
        self.validateSchedule = validateSchedule
    }
    
    public func execute(_ log: HabitLog) async throws {
        // Fetch the habit to validate schedule
        let allHabits = try await habitRepo.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == log.habitID }) else {
            throw HabitScheduleValidationError.habitUnavailable(habitName: "Unknown Habit")
        }
        
        // Check if habit is active
        guard habit.isActive else {
            throw HabitScheduleValidationError.habitUnavailable(habitName: habit.name)
        }
        
        // For timesPerWeek habits, validate that user hasn't already logged today
        if case .timesPerWeek = habit.schedule {
            let dayStart = Calendar.current.startOfDay(for: log.date)
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
            
            let existingLogs = try await repo.logs(for: habit.id)
            let logsForToday = existingLogs.filter { existingLog in
                existingLog.date >= dayStart && existingLog.date < dayEnd
            }
            
            if !logsForToday.isEmpty {
                throw HabitScheduleValidationError.alreadyLoggedToday(habitName: habit.name)
            }
        }
        
        // Validate schedule before logging
        let validationResult = try await validateSchedule.execute(habit: habit, date: log.date)
        
        // If validation fails, throw descriptive error
        if !validationResult.isValid {
            throw HabitScheduleValidationError.fromValidationResult(validationResult, habitName: habit.name)
        }
        
        // If validation passes, proceed with logging
        try await repo.upsert(log)
    }
}

public final class DeleteLog: DeleteLogUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(id: UUID) async throws {
        try await repo.deleteLog(id: id)
    }
}

public final class GetLogForDate: GetLogForDateUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(habitID: UUID, date: Date) async throws -> HabitLog? {
        // Get all logs for the habit
        let allLogs = try await repo.logs(for: habitID)

        // Business logic: Find log for specific date (comparing day only)
        let calendar = Calendar.current
        return allLogs.first { log in
            calendar.isDate(log.date, inSameDayAs: date)
        }
    }
}

// MARK: - Tip Use Case Implementations
public final class GetAllTips: GetAllTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] { try await repo.getAllTips() }
}

public final class GetFeaturedTips: GetFeaturedTipsUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute() async throws -> [Tip] {
        // Business logic: Get featured tips and sort by order
        let featuredTips = try await repo.getFeaturedTips()
        return featuredTips.sorted { $0.order < $1.order }
    }
}

public final class GetTipById: GetTipByIdUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Tip? { try await repo.getTip(by: id) }
}

public final class GetTipsByCategory: GetTipsByCategoryUseCase {
    private let repo: TipRepository
    public init(repo: TipRepository) { self.repo = repo }
    public func execute(category: TipCategory) async throws -> [Tip] { try await repo.getTips(by: category) }
}

// MARK: - Category Use Case Implementations
public final class GetAllCategories: GetAllCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getAllCategories() }
}

public final class GetCategoryById: GetCategoryByIdUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(id: String) async throws -> HabitCategory? { try await repo.getCategory(by: id) }
}

public final class GetActiveCategories: GetActiveCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getActiveCategories() }
}

public final class GetPredefinedCategories: GetPredefinedCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getPredefinedCategories() }
}

public final class GetCustomCategories: GetCustomCategoriesUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute() async throws -> [HabitCategory] { try await repo.getCustomCategories() }
}

public final class CreateCustomCategory: CreateCustomCategoryUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(_ category: HabitCategory) async throws {
        // Business logic: Validate category doesn't already exist
        let existsByName = try await repo.categoryExists(name: category.name)
        let existsById = try await repo.categoryExists(id: category.id)
        
        guard !existsByName && !existsById else {
            throw CategoryError.categoryAlreadyExists
        }
        
        try await repo.createCustomCategory(category)
    }
}

public final class UpdateCategory: UpdateCategoryUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(_ category: HabitCategory) async throws {
        try await repo.updateCategory(category)
    }
}

public final class DeleteCategory: DeleteCategoryUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(id: String) async throws {
        try await repo.deleteCategory(id: id)
    }
}

public final class ValidateCategoryName: ValidateCategoryNameUseCase {
    private let repo: CategoryRepository
    public init(repo: CategoryRepository) { self.repo = repo }
    public func execute(name: String) async throws -> Bool {
        // Business logic: Check if category name is unique
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return false }
        
        let exists = try await repo.categoryExists(name: trimmedName)
        return !exists
    }
}

public final class LoadHabitsData: LoadHabitsDataUseCase {
    private let habitRepo: HabitRepository
    private let categoryRepo: CategoryRepository
    
    public init(habitRepo: HabitRepository, categoryRepo: CategoryRepository) {
        self.habitRepo = habitRepo
        self.categoryRepo = categoryRepo
    }
    
    public func execute() async throws -> HabitsData {
        // Batch load both habits and categories concurrently for performance
        async let habitsResult = habitRepo.fetchAllHabits()
        async let categoriesResult = categoryRepo.getActiveCategories()
        
        do {
            let habits = try await habitsResult.sorted { $0.displayOrder < $1.displayOrder }
            let categories = try await categoriesResult
            
            return HabitsData(habits: habits, categories: categories)
        } catch {
            throw error
        }
    }
}

// MARK: - Onboarding Use Case Implementations
public final class GetOnboardingState: GetOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute() async throws -> OnboardingState { try await repo.getOnboardingState() }
}

public final class SaveOnboardingState: SaveOnboardingStateUseCase {
    private let repo: OnboardingRepository
    public init(repo: OnboardingRepository) { self.repo = repo }
    public func execute(_ state: OnboardingState) async throws { try await repo.saveOnboardingState(state) }
}

public final class CompleteOnboarding: CompleteOnboardingUseCase {
    private let onboardingRepo: OnboardingRepository
    private let profileRepo: ProfileRepository
    
    public init(repo: OnboardingRepository, profileRepo: ProfileRepository) { 
        self.onboardingRepo = repo 
        self.profileRepo = profileRepo
    }
    
    public func execute(userName: String?, hasNotifications: Bool) async throws {
        // Mark onboarding as completed
        try await onboardingRepo.markOnboardingCompleted(userName: userName, hasNotifications: hasNotifications)
        
        // Update user profile with the name if provided
        if let userName = userName, !userName.isEmpty {
            var profile = try await profileRepo.loadProfile()
            profile.name = userName
            profile.updatedAt = Date()
            try await profileRepo.saveProfile(profile)
            
            // No need to sync to UserService - it uses ProfileRepository as single source of truth
        }
    }
}

// MARK: - User Management Use Cases

// UserService-based subscription update

public final class UpdateProfileSubscription: UpdateProfileSubscriptionUseCase {
    private let userService: UserService
    private let paywallService: PaywallService
    
    public init(userService: UserService, paywallService: PaywallService) {
        self.userService = userService
        self.paywallService = paywallService
    }
    
    public func execute(product: Product) async throws {
        // Calculate expiry date based on product duration
        let calendar = Calendar.current
        let expiryDate: Date?
        
        switch product.duration {
        case .monthly:
            expiryDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case .annual:
            expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        }
        
        // Update subscription through user service (single source of truth)
        try await userService.updateSubscription(plan: product.subscriptionPlan, expiryDate: expiryDate)
        
        // Update purchase state in paywall service
        if let mockService = paywallService as? MockPaywallService {
            mockService.purchaseState = .success(product)
        }
    }
}

// MARK: - Calendar Use Case Implementations

public final class GenerateCalendarDays: GenerateCalendarDaysUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [Date] {
        let calendar = DateUtils.userCalendar()
        
        // Ensure we start with a normalized date (start of day)
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        // Generate current month days, ensuring we work with start of day
        var days: [Date] = []
        var date = calendar.startOfDay(for: monthInterval.start)
        let endOfMonth = monthInterval.end
        
        while date < endOfMonth {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }
        
        return days
    }
}

public final class GenerateCalendarGrid: GenerateCalendarGridUseCase {
    public init() {}
    
    public func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] {
        let calendar = DateUtils.userCalendar()
        
        let normalizedCurrentMonth = calendar.startOfDay(for: month)
        guard let monthInterval = calendar.dateInterval(of: .month, for: normalizedCurrentMonth) else { return [] }
        
        let startOfMonth = monthInterval.start
        let endOfMonth = monthInterval.end
        
        // Find the first day to display (might be from previous month)
        let weekdayOfFirst = calendar.component(.weekday, from: startOfMonth)
        // Calculate days to subtract based on calendar's firstWeekday setting
        let daysToSubtract = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let firstDisplayDay = calendar.date(byAdding: .day, value: -daysToSubtract, to: startOfMonth) ?? startOfMonth
        
        // Generate 42 days (6 weeks) for a complete calendar grid
        var calendarDays: [CalendarDay] = []
        var currentDate = firstDisplayDay
        
        for _ in 0..<42 {
            let isCurrentMonth = calendar.isDate(currentDate, equalTo: normalizedCurrentMonth, toGranularity: .month)
            calendarDays.append(CalendarDay(date: currentDate, isCurrentMonth: isCurrentMonth))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return calendarDays
    }
}

// MARK: - Habit Logging Use Case Implementation

public final class ToggleHabitLog: ToggleHabitLogUseCase {
    private let getLogForDate: GetLogForDateUseCase
    private let logHabit: LogHabitUseCase
    private let deleteLog: DeleteLogUseCase
    
    public init(getLogForDate: GetLogForDateUseCase, logHabit: LogHabitUseCase, deleteLog: DeleteLogUseCase) {
        self.getLogForDate = getLogForDate
        self.logHabit = logHabit
        self.deleteLog = deleteLog
    }
    
    public func execute(
        date: Date,
        habit: Habit,
        currentLoggedDates: Set<Date>,
        currentHabitLogValues: [Date: Double]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double]) {
        let existingLog = try await getLogForDate.execute(habitID: habit.id, date: date)
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        var updatedLoggedDates = currentLoggedDates
        var updatedHabitLogValues = currentHabitLogValues
        
        if habit.kind == .binary {
            // Business Logic: Binary habit toggle
            if existingLog != nil {
                // Remove log
                try await deleteLog.execute(id: existingLog!.id)
                updatedLoggedDates.remove(normalizedDate)
                updatedHabitLogValues.removeValue(forKey: normalizedDate)
            } else {
                // Add log
                let newLog = HabitLog(habitID: habit.id, date: date, value: 1.0)
                try await logHabit.execute(newLog)
                updatedLoggedDates.insert(normalizedDate)
                updatedHabitLogValues[normalizedDate] = 1.0
            }
        } else {
            // Count habit: increment value or reset if target is reached
            let currentValue = existingLog?.value ?? 0.0
            
            // If target is already reached, reset to 0
            let newValue: Double
            if let target = habit.dailyTarget, currentValue >= target {
                newValue = 0.0
            } else {
                newValue = currentValue + 1.0
            }
            
            if newValue == 0.0 {
                // Reset to 0: delete the log entry
                if let existingLog = existingLog {
                    try await deleteLog.execute(id: existingLog.id)
                }
                updatedHabitLogValues.removeValue(forKey: normalizedDate)
                updatedLoggedDates.remove(normalizedDate)
            } else {
                // Increment: update or create log
                if let existingLog = existingLog {
                    // Update existing log
                    let updatedLog = HabitLog(id: existingLog.id, habitID: habit.id, date: date, value: newValue)
                    try await logHabit.execute(updatedLog)
                } else {
                    // Create new log
                    let newLog = HabitLog(habitID: habit.id, date: date, value: newValue)
                    try await logHabit.execute(newLog)
                }
                
                updatedHabitLogValues[normalizedDate] = newValue
                
                // Check if target is reached for logged dates tracking
                if let target = habit.dailyTarget, newValue >= target {
                    updatedLoggedDates.insert(normalizedDate)
                } else {
                    updatedLoggedDates.remove(normalizedDate)
                }
            }
        }
        
        return (loggedDates: updatedLoggedDates, habitLogValues: updatedHabitLogValues)
    }
}

// MARK: - Slogan Use Case Implementations

public final class GetCurrentSlogan: GetCurrentSloganUseCase {
    private let slogansService: SlogansServiceProtocol
    
    public init(slogansService: SlogansServiceProtocol) {
        self.slogansService = slogansService
    }
    
    public func execute() -> String {
        slogansService.getCurrentSlogan()
    }
}

// MARK: - Notification Use Case Implementations

public final class RequestNotificationPermission: RequestNotificationPermissionUseCase {
    private let notificationService: NotificationService
    
    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    public func execute() async throws -> Bool {
        try await notificationService.requestAuthorizationIfNeeded()
    }
}

public final class CheckNotificationStatus: CheckNotificationStatusUseCase {
    private let notificationService: NotificationService
    
    public init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    public func execute() async -> Bool {
        await notificationService.checkAuthorizationStatus()
    }
}

// MARK: - Feature Gating Use Case Implementations

public final class CheckFeatureAccess: CheckFeatureAccessUseCase {
    private let featureGatingService: FeatureGatingService
    
    public init(featureGatingService: FeatureGatingService) {
        self.featureGatingService = featureGatingService
    }
    
    public func execute() -> Bool {
        featureGatingService.hasAdvancedAnalytics
    }
}

public final class CheckHabitCreationLimit: CheckHabitCreationLimitUseCase {
    private let featureGatingService: FeatureGatingService
    
    public init(featureGatingService: FeatureGatingService) {
        self.featureGatingService = featureGatingService
    }
    
    public func execute(currentCount: Int) -> Bool {
        featureGatingService.canCreateMoreHabits(currentCount: currentCount)
    }
}

public final class GetPaywallMessage: GetPaywallMessageUseCase {
    private let featureGatingService: FeatureGatingService
    
    public init(featureGatingService: FeatureGatingService) {
        self.featureGatingService = featureGatingService
    }
    
    public func execute() -> String {
        featureGatingService.getFeatureBlockedMessage(for: .advancedAnalytics)
    }
}

// MARK: - User Action Use Case Implementations

public final class TrackUserAction: TrackUserActionUseCase {
    private let userActionTracker: UserActionTrackerService
    
    public init(userActionTracker: UserActionTrackerService) {
        self.userActionTracker = userActionTracker
    }
    
    public func execute(action: UserActionEvent, context: [String: String]) {
        userActionTracker.track(action, context: context)
    }
}

public final class TrackHabitLogged: TrackHabitLoggedUseCase {
    private let userActionTracker: UserActionTrackerService
    
    public init(userActionTracker: UserActionTrackerService) {
        self.userActionTracker = userActionTracker
    }
    
    public func execute(habitId: String, habitName: String, date: Date, logType: String, value: Double?) {
        userActionTracker.track(.habitLogged(
            habitId: habitId,
            habitName: habitName,
            date: date,
            logType: logType,
            value: value
        ))
    }
}


// MARK: - Paywall Use Case Implementations

public final class LoadPaywallProducts: LoadPaywallProductsUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() async throws -> [Product] {
        try await paywallService.loadProducts()
    }
}

public final class PurchaseProduct: PurchaseProductUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute(_ product: Product) async throws -> Bool {
        try await paywallService.purchase(product)
    }
}

public final class RestorePurchases: RestorePurchasesUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() async throws -> Bool {
        try await paywallService.restorePurchases()
    }
}

public final class CheckProductPurchased: CheckProductPurchasedUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute(_ productId: String) async -> Bool {
        await paywallService.isProductPurchased(productId)
    }
}

public final class ResetPurchaseState: ResetPurchaseStateUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() {
        paywallService.resetPurchaseState()
    }
}

public final class GetPurchaseState: GetPurchaseStateUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() -> PurchaseState {
        paywallService.purchaseState
    }
}


public final class GetHabitCount: GetHabitCountUseCase {
    private let habitRepository: HabitRepository
    
    public init(habitRepository: HabitRepository) {
        self.habitRepository = habitRepository
    }
    
    public func execute() async -> Int {
        do {
            let habits = try await habitRepository.fetchAllHabits()
            return habits.count
        } catch {
            // If we can't fetch habits, assume 0 count for safety
            return 0
        }
    }
}


public final class CreateHabitFromSuggestion: CreateHabitFromSuggestionUseCase {
    private let createHabit: CreateHabitUseCase
    private let getHabitCount: GetHabitCountUseCase
    private let checkHabitCreationLimit: CheckHabitCreationLimitUseCase
    private let featureGatingService: FeatureGatingService
    
    public init(createHabit: CreateHabitUseCase,
                getHabitCount: GetHabitCountUseCase,
                checkHabitCreationLimit: CheckHabitCreationLimitUseCase,
                featureGatingService: FeatureGatingService) {
        self.createHabit = createHabit
        self.getHabitCount = getHabitCount
        self.checkHabitCreationLimit = checkHabitCreationLimit
        self.featureGatingService = featureGatingService
    }
    
    public func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult {
        // First get current habit count
        let currentCount = await getHabitCount.execute()
        
        // Check if user can create more habits
        let canCreate = checkHabitCreationLimit.execute(currentCount: currentCount)
        
        if !canCreate {
            let message = featureGatingService.getFeatureBlockedMessage(for: .unlimitedHabits)
            return .limitReached(message: message)
        }
        
        // If they can create, proceed with habit creation using CreateHabit use case
        // This ensures proper displayOrder is set (habit will be added to the end of the list)
        do {
            let habit = suggestion.toHabit()
            let createdHabit = try await createHabit.execute(habit)
            return .success(habitId: createdHabit.id)
        } catch {
            return .error("Failed to create habit: \(error.localizedDescription)")
        }
    }
}

public final class RemoveHabitFromSuggestion: RemoveHabitFromSuggestionUseCase {
    private let deleteHabit: DeleteHabitUseCase
    
    public init(deleteHabit: DeleteHabitUseCase) {
        self.deleteHabit = deleteHabit
    }
    
    public func execute(suggestionId: String, habitId: UUID) async -> Bool {
        do {
            try await deleteHabit.execute(id: habitId)
            return true
        } catch {
            return false
        }
    }
}

// MARK: - User Use Case Implementations

public final class CheckPremiumStatus: CheckPremiumStatusUseCase {
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute() async -> Bool {
        userService.isPremiumUser
    }
}

public final class GetCurrentUserProfile: GetCurrentUserProfileUseCase {
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute() async -> UserProfile {
        userService.currentProfile
    }
}

public final class UpdateUserSubscription: UpdateUserSubscriptionUseCase {
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute(plan: SubscriptionPlan, expiryDate: Date?) async throws {
        try await userService.updateSubscription(plan: plan, expiryDate: expiryDate)
    }
}

// MARK: - Habit Schedule Use Case Implementations

public final class ValidateHabitSchedule: ValidateHabitScheduleUseCase {
    private let habitCompletionService: HabitCompletionService
    
    public init(habitCompletionService: HabitCompletionService = DefaultHabitCompletionService()) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, date: Date) async throws -> HabitScheduleValidationResult {
        // Use HabitCompletionService to check if the habit is scheduled for this date
        let isScheduled = habitCompletionService.isScheduledDay(habit: habit, date: date)
        
        if isScheduled {
            return .valid()
        } else {
            let reason = generateUserFriendlyReason(for: habit, date: date)
            return .invalid(reason: reason)
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func generateUserFriendlyReason(for habit: Habit, date: Date) -> String {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        let formattedDate = dateFormatter.string(from: date)
        let weekdayName = calendar.weekdaySymbols[calendar.component(.weekday, from: date) - 1]
        
        switch habit.schedule {
        case .daily:
            // This shouldn't happen since daily habits are always valid, but provide a fallback
            return "This habit is not scheduled for \(formattedDate)."
            
        case .daysOfWeek(let scheduledDays):
            let dayNames = scheduledDays.sorted().compactMap { dayNum in
                let calWeekday = DateUtils.habitWeekdayToCalendarWeekday(dayNum)
                return calendar.weekdaySymbols[calWeekday - 1]
            }
            
            if dayNames.count == 1 {
                return "This habit is only scheduled for \(dayNames[0])s."
            } else if dayNames.count == 2 {
                return "This habit is only scheduled for \(dayNames[0])s and \(dayNames[1])s."
            } else {
                let lastDay = dayNames.last!
                let otherDays = dayNames.dropLast().joined(separator: ", ")
                return "This habit is only scheduled for \(otherDays), and \(lastDay)s."
            }
            
        case .timesPerWeek:
            // This shouldn't happen since timesPerWeek habits can be logged any day, but provide a fallback
            return "This habit is not available for logging on \(formattedDate)."
        }
    }
}

public final class CheckWeeklyTarget: CheckWeeklyTargetUseCase {
    public init() {}
    
    public func execute(date: Date, habit: Habit, habitLogValues: [Date: Double], userProfile: UserProfile?) -> Bool {
        switch habit.schedule {
        case .timesPerWeek(let target):
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: Calendar.current.firstWeekday)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = DateUtils.weekKey(for: logDate, firstWeekday: Calendar.current.firstWeekday)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week && value > 0
            }
            return logsInWeek.count >= target
        case .daysOfWeek(let requiredDays):
            let weekKey = DateUtils.weekKey(for: date, firstWeekday: Calendar.current.firstWeekday)
            let logsInWeek = habitLogValues.filter { (logDate, value) in
                let logWeekKey = DateUtils.weekKey(for: logDate, firstWeekday: Calendar.current.firstWeekday)
                return logWeekKey.year == weekKey.year && logWeekKey.week == weekKey.week && value > 0
            }
            // Check if all required days for this week are logged
            let loggedDaysInWeek = Set(logsInWeek.keys.map { logDate in
                let calendarWeekday = Calendar.current.component(.weekday, from: logDate)
                return calendarWeekday == 1 ? 7 : calendarWeekday - 1 // Convert to habit weekday format
            })
            return requiredDays.isSubset(of: loggedDaysInWeek)
        default:
            return false
        }
    }
}

// MARK: - New UseCase Implementations (Phase 0)

public final class IsHabitCompleted: IsHabitCompletedUseCase {
    private let habitCompletionService: HabitCompletionServiceProtocol
    
    public init(habitCompletionService: HabitCompletionServiceProtocol) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool {
        habitCompletionService.isCompleted(habit: habit, on: date, logs: logs)
    }
}

public final class CalculateDailyProgress: CalculateDailyProgressUseCase {
    private let habitCompletionService: HabitCompletionServiceProtocol
    
    public init(habitCompletionService: HabitCompletionServiceProtocol) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, logs: [HabitLog], for date: Date) -> Double {
        habitCompletionService.calculateDailyProgress(habit: habit, logs: logs, for: date)
    }
}

public final class IsScheduledDay: IsScheduledDayUseCase {
    private let habitCompletionService: HabitCompletionServiceProtocol
    
    public init(habitCompletionService: HabitCompletionServiceProtocol) {
        self.habitCompletionService = habitCompletionService
    }
    
    public func execute(habit: Habit, date: Date) -> Bool {
        habitCompletionService.isScheduledDay(habit: habit, date: date)
    }
}

public final class ClearPurchases: ClearPurchasesUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    public func execute() {
        paywallService.clearPurchases()
    }
}


// MARK: - Analytics Use Case Implementations

public final class GetActiveHabits: GetActiveHabitsUseCase {
    private let habitRepository: HabitRepository
    
    public init(habitRepository: HabitRepository) {
        self.habitRepository = habitRepository
    }
    
    public func execute() async throws -> [Habit] {
        // Business logic: Get all habits and filter active ones
        let allHabits = try await habitRepository.fetchAllHabits()
        return allHabits.filter { $0.isActive }
    }
}

public final class CalculateStreakAnalysis: CalculateStreakAnalysisUseCase {
    private let performanceAnalysisService: PerformanceAnalysisService
    
    public init(performanceAnalysisService: PerformanceAnalysisService) {
        self.performanceAnalysisService = performanceAnalysisService
    }
    
    public func execute(habits: [Habit], logs: [HabitLog], from startDate: Date, to endDate: Date) -> StreakAnalysisResult {
        performanceAnalysisService.calculateStreakAnalysis(habits: habits, logs: logs, from: startDate, to: endDate)
    }
}

public final class RefreshWidget: RefreshWidgetUseCase {
    private let widgetRefreshService: WidgetRefreshServiceProtocol
    
    public init(widgetRefreshService: WidgetRefreshServiceProtocol) {
        self.widgetRefreshService = widgetRefreshService
    }
    
    public func execute(habitId: UUID) {
        Task { @MainActor in
            widgetRefreshService.refreshWidgetsForHabit(habitId)
        }
    }
}

#if DEBUG
public final class GetDatabaseStats: GetDatabaseStatsUseCase {
    private let debugService: DebugServiceProtocol
    
    public init(debugService: DebugServiceProtocol) {
        self.debugService = debugService
    }
    
    public func execute() async throws -> DebugDatabaseStats {
        try await debugService.getDatabaseStats()
    }
}

public final class ClearDatabase: ClearDatabaseUseCase {
    private let debugService: DebugServiceProtocol
    
    public init(debugService: DebugServiceProtocol) {
        self.debugService = debugService
    }
    
    public func execute() async throws {
        try await debugService.clearDatabase()
    }
}

public final class PopulateTestData: PopulateTestDataUseCase {
    // MARK: - Dependencies - UseCases and Repositories, NOT Services
    private let debugService: DebugServiceProtocol
    private let habitSuggestionsService: HabitSuggestionsService
    private let createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase
    private let createCustomCategoryUseCase: CreateCustomCategoryUseCase
    private let logHabitUseCase: LogHabitUseCase
    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let habitCompletionService: HabitCompletionServiceProtocol
    private let testDataUtilities: TestDataPopulationServiceProtocol
    
    // MARK: - Progress Tracking
    public var progressUpdate: ((String, Double) -> Void)?
    
    public init(
        debugService: DebugServiceProtocol,
        habitSuggestionsService: HabitSuggestionsService,
        createHabitFromSuggestionUseCase: CreateHabitFromSuggestionUseCase,
        createCustomCategoryUseCase: CreateCustomCategoryUseCase,
        logHabitUseCase: LogHabitUseCase,
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        habitCompletionService: HabitCompletionServiceProtocol,
        testDataUtilities: TestDataPopulationServiceProtocol
    ) {
        self.debugService = debugService
        self.habitSuggestionsService = habitSuggestionsService
        self.createHabitFromSuggestionUseCase = createHabitFromSuggestionUseCase
        self.createCustomCategoryUseCase = createCustomCategoryUseCase
        self.logHabitUseCase = logHabitUseCase
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.habitCompletionService = habitCompletionService
        self.testDataUtilities = testDataUtilities
    }
    
    public func execute() async throws {
        // Business workflow orchestration belongs in UseCase, not Service
        
        // Step 1: Clear existing data
        progressUpdate?("Clearing existing data...", 0.0)
        try await debugService.clearDatabase()
        
        // Step 2: Create custom categories
        progressUpdate?("Creating custom categories...", 0.15)
        let customCategories = try await createCustomCategories()
        
        // Step 3: Create habits from suggestions (diverse selection)
        progressUpdate?("Creating habits from suggestions...", 0.3)
        let suggestedHabits = try await createSuggestedHabits()
        
        // Step 4: Create custom habits
        progressUpdate?("Creating custom habits...", 0.5)
        let customHabits = try await createCustomHabits(using: customCategories)
        
        // Step 5: Generate historical data
        progressUpdate?("Generating historical data...", 0.7)
        let allHabits = suggestedHabits + customHabits
        try await generateHistoricalData(for: allHabits)
        
        progressUpdate?("Test data population complete!", 1.0)
    }
    
    // MARK: - Private Business Logic Implementation
    
    private func createCustomCategories() async throws -> [HabitCategory] {
        let customCategoryData = testDataUtilities.getCustomCategoryData()
        var createdCategories: [HabitCategory] = []
        
        for (index, categoryData) in customCategoryData.enumerated() {
            let category = HabitCategory(
                id: UUID().uuidString,
                name: categoryData.name,
                displayName: categoryData.displayName,
                emoji: categoryData.emoji,
                order: 100 + index,
                isActive: true,
                isPredefined: false
            )
            try await createCustomCategoryUseCase.execute(category)
            createdCategories.append(category)
        }
        
        return createdCategories
    }
    
    private func createSuggestedHabits() async throws -> [Habit] {
        let allSuggestions = habitSuggestionsService.getSuggestions()
        guard !allSuggestions.isEmpty else {
            throw TestDataPopulationError("No habit suggestions available")
        }
        
        // Select diverse habits from different categories (2-3 per category max)
        let suggestionsByCategory = Dictionary(grouping: allSuggestions) { $0.categoryId }
        var selectedSuggestions: [HabitSuggestion] = []
        
        for (_, suggestions) in suggestionsByCategory {
            let shuffled = suggestions.shuffled()
            let count = min(3, suggestions.count)
            selectedSuggestions.append(contentsOf: Array(shuffled.prefix(count)))
        }
        
        let finalSuggestions = Array(selectedSuggestions.shuffled().prefix(12))
        var createdHabits: [Habit] = []
        
        for suggestion in finalSuggestions {
            let result = await createHabitFromSuggestionUseCase.execute(suggestion)
            
            switch result {
            case .success(let habitId):
                if let habits = try? await habitRepository.fetchAllHabits(),
                   let habit = habits.first(where: { $0.id == habitId }) {
                    createdHabits.append(habit)
                }
            case .error(let error):
                print("Failed to create habit from suggestion '\(suggestion.name)': \(error)")
            case .limitReached:
                throw TestDataPopulationError("Habit creation limit reached while creating suggested habits")
            }
        }
        
        return createdHabits
    }
    
    private func createCustomHabits(using customCategories: [HabitCategory]) async throws -> [Habit] {
        guard customCategories.count >= 3 else {
            throw TestDataPopulationError("Need at least 3 custom categories to create custom habits")
        }
        
        let customHabitData = testDataUtilities.getCustomHabitData()
        var createdHabits: [Habit] = []
        
        for (index, habitData) in customHabitData.enumerated() {
            let category = customCategories[index]
            
            let habit = Habit(
                id: UUID(),
                name: habitData.name,
                colorHex: habitData.colorHex,
                emoji: habitData.emoji,
                kind: habitData.kind,
                unitLabel: habitData.unitLabel,
                dailyTarget: habitData.dailyTarget,
                schedule: habitData.schedule,
                isActive: true,
                categoryId: category.id
            )
            
            try await habitRepository.create(habit)
            createdHabits.append(habit)
        }
        
        return createdHabits
    }
    
    private func generateHistoricalData(for habits: [Habit]) async throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let dateRange = Array((0..<90).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed())
        
        // Use utility service for pattern calculations
        let dailyCompletionRates = testDataUtilities.generateDailyCompletionRates(
            for: dateRange,
            calendar: calendar
        )
        
        for (dayIndex, date) in dateRange.enumerated() {
            guard let dailyCompletionRate = dailyCompletionRates[date] else { continue }
            
            let progressForDate = 0.7 + (Double(dayIndex) / Double(dateRange.count)) * 0.25
            let weekNumber = (dateRange.count - dayIndex - 1) / 7 + 1
            progressUpdate?("Creating 3-month history: Week \(weekNumber)...", progressForDate)
            
            let scheduledHabits = habits.filter { habit in
                habitCompletionService.isScheduledDay(habit: habit, date: date)
            }
            
            guard !scheduledHabits.isEmpty else { continue }
            
            let targetCompletions = Int(round(Double(scheduledHabits.count) * dailyCompletionRate))
            let shuffledHabits = scheduledHabits.shuffled()
            let habitsToComplete = Array(shuffledHabits.prefix(targetCompletions))
            
            for habit in habitsToComplete {
                let logValue: Double?
                
                switch habit.kind {
                case .binary:
                    logValue = 1.0
                    
                case .numeric:
                    if let target = habit.dailyTarget {
                        let variation = Double.random(in: 0.9...1.1)
                        logValue = target * variation
                    } else {
                        logValue = Double.random(in: 1.0...10.0)
                    }
                }
                
                let log = HabitLog(
                    id: UUID(),
                    habitID: habit.id,
                    date: date,
                    value: logValue
                )
                
                try await logHabitUseCase.execute(log)
            }
        }
    }
}
#endif

// MARK: - Analytics UseCases

public final class GetHabitLogsForAnalytics: GetHabitLogsForAnalyticsUseCase {
    private let habitRepository: HabitRepository
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(habitRepository: HabitRepository, getBatchLogs: GetBatchLogsUseCase) {
        self.habitRepository = habitRepository
        self.getBatchLogs = getBatchLogs
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog] {
        // Business logic moved from Service to UseCase
        
        // Get active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabits = allHabits.filter { $0.isActive }
        
        // Use batch loading for efficiency (N+1 query elimination)
        let habitIds = activeHabits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(
            for: habitIds,
            since: startDate,
            until: endDate
        )
        
        // Flatten results
        return logsByHabitId.values.flatMap { $0 }
    }
}

public final class GetHabitCompletionStats: GetHabitCompletionStatsUseCase {
    private let habitRepository: HabitRepository
    private let scheduleAnalyzer: HabitScheduleAnalyzerProtocol
    private let calendar: Calendar
    private let getBatchLogs: GetBatchLogsUseCase
    
    public init(habitRepository: HabitRepository, scheduleAnalyzer: HabitScheduleAnalyzerProtocol, getBatchLogs: GetBatchLogsUseCase, calendar: Calendar = Calendar.current) {
        self.habitRepository = habitRepository
        self.scheduleAnalyzer = scheduleAnalyzer
        self.getBatchLogs = getBatchLogs
        self.calendar = calendar
    }
    
    public func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats {
        // Business logic moved from Service to UseCase
        
        // Get active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let habits = allHabits.filter { $0.isActive }
        
        // Get logs using batch loading
        let habitIds = habits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(
            for: habitIds,
            since: startDate,
            until: endDate
        )
        let logs = logsByHabitId.values.flatMap { $0 }
        
        let totalHabits = habits.count
        let logsByDate = Dictionary(grouping: logs, by: { calendar.startOfDay(for: $0.date) })
        
        var totalExpectedDays = 0
        var totalCompletedDays = 0
        var habitsWithCompletions: Set<UUID> = []
        
        // Calculate expected days based on each habit's schedule
        var currentDate = startDate
        while currentDate <= endDate {
            let dayLogs = logsByDate[calendar.startOfDay(for: currentDate)] ?? []
            
            for habit in habits {
                if scheduleAnalyzer.isHabitExpectedOnDate(habit: habit, date: currentDate) {
                    totalExpectedDays += 1
                    
                    if dayLogs.contains(where: { $0.habitID == habit.id }) {
                        totalCompletedDays += 1
                        habitsWithCompletions.insert(habit.id)
                    }
                }
            }
            
            guard let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
                break
            }
            currentDate = nextDay
        }
        
        let completionRate = totalExpectedDays > 0 ? Double(totalCompletedDays) / Double(totalExpectedDays) : 0.0
        let successfulHabits = habitsWithCompletions.count
        
        return HabitCompletionStats(
            totalHabits: totalHabits,
            completedHabits: successfulHabits,
            completionRate: completionRate
        )
    }
}


