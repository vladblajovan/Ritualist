import Foundation

// MARK: - Habit Use Cases
public protocol CreateHabitUseCase { func execute(_ habit: Habit) async throws -> Habit }
public protocol GetActiveHabitsUseCase { func execute() async throws -> [Habit] }
public protocol GetAllHabitsUseCase { func execute() async throws -> [Habit] }
public protocol UpdateHabitUseCase { func execute(_ habit: Habit) async throws }
public protocol DeleteHabitUseCase { func execute(id: UUID) async throws }
public protocol ToggleHabitActiveStatusUseCase { func execute(id: UUID) async throws -> Habit }
public protocol ReorderHabitsUseCase { func execute(_ habits: [Habit]) async throws }

// MARK: - Log Use Cases
public protocol GetLogsUseCase { func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] }
public protocol LogHabitUseCase { func execute(_ log: HabitLog) async throws }
public protocol DeleteLogUseCase { func execute(id: UUID) async throws }
public protocol GetLogForDateUseCase { func execute(habitID: UUID, date: Date) async throws -> HabitLog? }

// MARK: - Profile Use Cases  
public protocol LoadProfileUseCase { func execute() async throws -> UserProfile }
public protocol SaveProfileUseCase { func execute(_ profile: UserProfile) async throws }

// MARK: - Calendar Use Cases
public protocol GenerateCalendarDaysUseCase { 
    func execute(for month: Date, userProfile: UserProfile?) -> [Date] 
}
public protocol GenerateCalendarGridUseCase { 
    func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] 
}

// MARK: - Habit Logging Use Cases
public protocol ToggleHabitLogUseCase {
    func execute(
        date: Date,
        habit: Habit,
        currentLoggedDates: Set<Date>,
        currentHabitLogValues: [Date: Double]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double])
}

// MARK: - Tip Use Cases
public protocol GetAllTipsUseCase { func execute() async throws -> [Tip] }
public protocol GetFeaturedTipsUseCase { func execute() async throws -> [Tip] }
public protocol GetTipByIdUseCase { func execute(id: UUID) async throws -> Tip? }
public protocol GetTipsByCategoryUseCase { func execute(category: TipCategory) async throws -> [Tip] }

// MARK: - Onboarding Use Cases
public protocol GetOnboardingStateUseCase { func execute() async throws -> OnboardingState }
public protocol SaveOnboardingStateUseCase { func execute(_ state: OnboardingState) async throws }
public protocol CompleteOnboardingUseCase { func execute(userName: String?, hasNotifications: Bool) async throws }

// MARK: - Slogan Use Cases
public protocol GetCurrentSloganUseCase { func execute() -> String }

// MARK: - Notification Use Cases
public protocol RequestNotificationPermissionUseCase { 
    func execute() async throws -> Bool 
}
public protocol CheckNotificationStatusUseCase { 
    func execute() async -> Bool 
}

// MARK: - Feature Gating Use Cases
public protocol CheckFeatureAccessUseCase {
    func execute() -> Bool
}
public protocol CheckHabitCreationLimitUseCase {
    func execute(currentCount: Int) -> Bool
}
public protocol GetPaywallMessageUseCase {
    func execute() -> String
}

// MARK: - User Action Use Cases
public protocol TrackUserActionUseCase {
    func execute(action: UserActionEvent, context: [String: String])
}
public protocol TrackHabitLoggedUseCase {
    func execute(habitId: String, habitName: String, date: Date, logType: String, value: Double?)
}

// MARK: - Auth Use Cases
public protocol SignOutUserUseCase {
    func execute() async throws
}

// MARK: - Paywall Use Cases
public protocol LoadPaywallProductsUseCase {
    func execute() async throws -> [Product]
}
public protocol PurchaseProductUseCase {
    func execute(_ product: Product) async throws -> Bool
}
public protocol RestorePurchasesUseCase {
    func execute() async throws -> Bool
}
public protocol CheckProductPurchasedUseCase {
    func execute(_ productId: String) async -> Bool
}
public protocol ResetPurchaseStateUseCase {
    func execute()
}
public protocol GetPurchaseStateUseCase {
    func execute() -> PurchaseState
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
            displayOrder: maxOrder + 1
        )
        
        try await repo.create(habitWithOrder)
        return habitWithOrder
    }
}

public final class GetActiveHabits: GetActiveHabitsUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute() async throws -> [Habit] {
        // Business logic: Filter only active habits and sort by display order
        let allHabits = try await repo.fetchAllHabits()
        return allHabits.filter { $0.isActive }.sorted { $0.displayOrder < $1.displayOrder }
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
    public func execute(id: UUID) async throws { try await repo.delete(id: id) }
}

public final class ToggleHabitActiveStatus: ToggleHabitActiveStatusUseCase {
    private let repo: HabitRepository
    public init(repo: HabitRepository) { self.repo = repo }
    public func execute(id: UUID) async throws -> Habit {
        let allHabits = try await repo.fetchAllHabits()
        guard let habit = allHabits.first(where: { $0.id == id }) else {
            throw NSError(domain: "ToggleHabitActiveStatus", code: 404, userInfo: [NSLocalizedDescriptionKey: "Habit not found"])
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
            displayOrder: habit.displayOrder
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
                displayOrder: index
            )
            updatedHabits.append(updatedHabit)
        }
        
        // Update all habits with new order
        for habit in updatedHabits {
            try await repo.update(habit)
        }
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
            if let since, log.date < since { return false }
            if let until, log.date > until { return false }
            return true
        }
    }
}

public final class LogHabit: LogHabitUseCase {
    private let repo: LogRepository
    public init(repo: LogRepository) { self.repo = repo }
    public func execute(_ log: HabitLog) async throws {
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

public protocol UpdateUserUseCase {
    func execute(_ user: User) async throws -> User
}

public protocol UpdateUserSubscriptionUseCase {
    func execute(user: User, product: Product) async throws -> User
}

// New UserService-based subscription update
public protocol UpdateProfileSubscriptionUseCase {
    func execute(product: Product) async throws
}

public final class UpdateUser: UpdateUserUseCase {
    private let userSession: any UserSessionProtocol
    
    public init(userSession: any UserSessionProtocol) {
        self.userSession = userSession
    }
    
    public func execute(_ user: User) async throws -> User {
        try await userSession.updateUser(user)
        return user
    }
}

public final class UpdateUserSubscription: UpdateUserSubscriptionUseCase {
    private let userSession: any UserSessionProtocol
    private let paywallService: PaywallService
    
    public init(userSession: any UserSessionProtocol, paywallService: PaywallService) {
        self.userSession = userSession
        self.paywallService = paywallService
    }
    
    public func execute(user: User, product: Product) async throws -> User {
        // Business logic: Create updated user with subscription details
        var updatedUser = user
        updatedUser.subscriptionPlan = product.subscriptionPlan
        
        // Calculate expiry date based on product duration
        let calendar = Calendar.current
        switch product.duration {
        case .monthly:
            updatedUser.subscriptionExpiryDate = calendar.date(byAdding: .month, value: 1, to: Date())
        case .annual:
            updatedUser.subscriptionExpiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        }
        
        // Update user through user session
        _ = try await userSession.updateUser(updatedUser)
        
        // Update purchase state in paywall service
        if let mockService = paywallService as? MockPaywallService {
            await MainActor.run {
                mockService.purchaseState = .success(product)
            }
        }
        
        return updatedUser
    }
}

@MainActor
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
        let calendar = DateUtils.userCalendar(firstDayOfWeek: userProfile?.firstDayOfWeek)
        
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
        let calendar = DateUtils.userCalendar(firstDayOfWeek: userProfile?.firstDayOfWeek)
        
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
    private let userActionTracker: UserActionTracker
    
    public init(userActionTracker: UserActionTracker) {
        self.userActionTracker = userActionTracker
    }
    
    public func execute(action: UserActionEvent, context: [String: String]) {
        userActionTracker.track(action, context: context)
    }
}

public final class TrackHabitLogged: TrackHabitLoggedUseCase {
    private let userActionTracker: UserActionTracker
    
    public init(userActionTracker: UserActionTracker) {
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

// MARK: - Auth Use Case Implementations

public final class SignOutUser: SignOutUserUseCase {
    private let userSession: any UserSessionProtocol
    
    public init(userSession: any UserSessionProtocol) {
        self.userSession = userSession
    }
    
    public func execute() async throws {
        try await userSession.signOut()
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
    
    @MainActor
    public func execute() {
        paywallService.resetPurchaseState()
    }
}

public final class GetPurchaseState: GetPurchaseStateUseCase {
    private let paywallService: PaywallService
    
    public init(paywallService: PaywallService) {
        self.paywallService = paywallService
    }
    
    @MainActor
    public func execute() -> PurchaseState {
        paywallService.purchaseState
    }
}

// MARK: - Habit Count UseCase

public protocol GetHabitCountUseCase {
    func execute() async -> Int
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

// MARK: - Habit Suggestion UseCase

public protocol CreateHabitFromSuggestionUseCase {
    func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult
}

public enum CreateHabitFromSuggestionResult {
    case success(habitId: UUID)
    case limitReached(message: String)
    case error(String)
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
        let canCreate = await checkHabitCreationLimit.execute(currentCount: currentCount)
        
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

// MARK: - User Use Cases

public protocol CheckPremiumStatusUseCase {
    func execute() async -> Bool
}

public protocol GetCurrentUserProfileUseCase {
    func execute() async -> UserProfile
}

// MARK: - User Use Case Implementations

@MainActor
public final class CheckPremiumStatus: CheckPremiumStatusUseCase {
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute() async -> Bool {
        userService.isPremiumUser
    }
}

@MainActor
public final class GetCurrentUserProfile: GetCurrentUserProfileUseCase {
    private let userService: UserService
    
    public init(userService: UserService) {
        self.userService = userService
    }
    
    public func execute() async -> UserProfile {
        userService.currentProfile
    }
}
