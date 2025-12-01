import Foundation

// MARK: - Migration Use Cases

/// UseCase for checking if a migration is currently in progress
public protocol GetMigrationStatusUseCase {
    var isMigrating: Bool { get }
    var migrationDetails: MigrationDetails? { get }
}

// MARK: - Habit Use Cases

public protocol CreateHabitUseCase { 
    func execute(_ habit: Habit) async throws -> Habit 
}

public protocol GetActiveHabitsUseCase { 
    func execute() async throws -> [Habit] 
}

public protocol GetAllHabitsUseCase { 
    func execute() async throws -> [Habit] 
}

public protocol UpdateHabitUseCase { 
    func execute(_ habit: Habit) async throws 
}

public protocol DeleteHabitUseCase { 
    func execute(id: UUID) async throws 
}

public protocol ToggleHabitActiveStatusUseCase { 
    func execute(id: UUID) async throws -> Habit 
}

public protocol ReorderHabitsUseCase { 
    func execute(_ habits: [Habit]) async throws 
}

public protocol ValidateHabitUniquenessUseCase { 
    func execute(name: String, categoryId: String?, excludeId: UUID?) async throws -> Bool 
}

public protocol GetHabitsByCategoryUseCase { 
    func execute(categoryId: String) async throws -> [Habit] 
}

public protocol OrphanHabitsFromCategoryUseCase { 
    func execute(categoryId: String) async throws 
}

public protocol CleanupOrphanedHabitsUseCase { 
    func execute() async throws -> Int 
}

public protocol GetHabitCountUseCase {
    func execute() async -> Int
}

public protocol IsHabitCompletedUseCase {
    func execute(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool
}

public protocol CalculateDailyProgressUseCase {
    func execute(habit: Habit, logs: [HabitLog], for date: Date) -> Double
}

public protocol IsScheduledDayUseCase {
    func execute(habit: Habit, date: Date) -> Bool
}

public protocol ClearPurchasesUseCase {
    func execute()
}

public protocol CreateHabitFromSuggestionUseCase {
    func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult
}

public protocol RemoveHabitFromSuggestionUseCase {
    func execute(suggestionId: String, habitId: UUID) async -> Bool
}

// MARK: - Log Use Cases

public protocol GetLogsUseCase { 
    func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog] 
}

public protocol GetBatchLogsUseCase { 
    func execute(for habitIDs: [UUID], since: Date?, until: Date?) async throws -> [UUID: [HabitLog]] 
}

public protocol GetSingleHabitLogsUseCase {
    func execute(for habitID: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
}

public protocol LogHabitUseCase { 
    func execute(_ log: HabitLog) async throws 
}

public protocol DeleteLogUseCase { 
    func execute(id: UUID) async throws 
}

public protocol GetLogForDateUseCase {
    func execute(habitID: UUID, date: Date) async throws -> HabitLog?
}

/// Returns the earliest log date for a habit, used for start date validation.
///
/// This use case queries the log repository to find the oldest log entry for a given habit.
/// It's primarily used to validate start date changes - when editing a habit's start date,
/// the new start date cannot be after any existing logs (to avoid orphaning log entries).
///
/// - Parameter habitID: The unique identifier of the habit to query
/// - Returns: The date of the earliest log entry, or `nil` if no logs exist for this habit
/// - Throws: Repository errors if the database query fails
public protocol GetEarliestLogDateUseCase {
    func execute(for habitID: UUID) async throws -> Date?
}

public protocol ToggleHabitLogUseCase {
    func execute(
        date: Date,
        habit: Habit,
        currentLoggedDates: Set<Date>,
        currentHabitLogValues: [Date: Double]
    ) async throws -> (loggedDates: Set<Date>, habitLogValues: [Date: Double])
}

// MARK: - Profile Use Cases  

public protocol LoadProfileUseCase { 
    func execute() async throws -> UserProfile 
}

public protocol SaveProfileUseCase {
    func execute(_ profile: UserProfile) async throws
}

public protocol CheckPremiumStatusUseCase {
    func execute() async -> Bool
}

public protocol GetCurrentSubscriptionPlanUseCase {
    func execute() async -> SubscriptionPlan
}

public protocol GetSubscriptionExpiryDateUseCase {
    func execute() async -> Date?
}

public protocol GetCurrentUserProfileUseCase {
    func execute() async -> UserProfile
}

// MARK: - Calendar Use Cases

public protocol GenerateCalendarDaysUseCase { 
    func execute(for month: Date, userProfile: UserProfile?) -> [Date] 
}

public protocol GenerateCalendarGridUseCase { 
    func execute(for month: Date, userProfile: UserProfile?) -> [CalendarDay] 
}

// MARK: - Tip Use Cases

public protocol GetAllTipsUseCase { 
    func execute() async throws -> [Tip] 
}

public protocol GetFeaturedTipsUseCase { 
    func execute() async throws -> [Tip] 
}

public protocol GetTipByIdUseCase { 
    func execute(id: UUID) async throws -> Tip? 
}

public protocol GetTipsByCategoryUseCase { 
    func execute(category: TipCategory) async throws -> [Tip] 
}

// MARK: - Category Use Cases

public protocol GetAllCategoriesUseCase { 
    func execute() async throws -> [HabitCategory] 
}

public protocol GetCategoryByIdUseCase { 
    func execute(id: String) async throws -> HabitCategory? 
}

public protocol GetActiveCategoriesUseCase { 
    func execute() async throws -> [HabitCategory] 
}

public protocol GetPredefinedCategoriesUseCase { 
    func execute() async throws -> [HabitCategory] 
}

public protocol GetCustomCategoriesUseCase { 
    func execute() async throws -> [HabitCategory] 
}

public protocol CreateCustomCategoryUseCase { 
    func execute(_ category: HabitCategory) async throws 
}

public protocol UpdateCategoryUseCase { 
    func execute(_ category: HabitCategory) async throws 
}

public protocol DeleteCategoryUseCase { 
    func execute(id: String) async throws 
}

public protocol ValidateCategoryNameUseCase { 
    func execute(name: String) async throws -> Bool 
}

public protocol LoadHabitsDataUseCase {
    func execute() async throws -> HabitsData
}

// MARK: - Onboarding Use Cases

public protocol GetOnboardingStateUseCase { 
    func execute() async throws -> OnboardingState 
}

public protocol SaveOnboardingStateUseCase { 
    func execute(_ state: OnboardingState) async throws 
}

public protocol CompleteOnboardingUseCase {
    func execute(userName: String?, hasNotifications: Bool, hasLocation: Bool, gender: String?, ageGroup: String?) async throws
}

// MARK: - Slogan Use Cases

public protocol GetCurrentSloganUseCase {
    func execute() -> String
    func getUniqueSlogans(count: Int, for timeOfDay: TimeOfDay) -> [String]
}




// MARK: - Notification Use Cases

public protocol RequestNotificationPermissionUseCase { 
    func execute() async throws -> Bool 
}

public protocol CheckNotificationStatusUseCase { 
    func execute() async -> Bool 
}

public protocol ScheduleHabitRemindersUseCase {
    func execute(habit: Habit) async throws
}

public protocol LogHabitFromNotificationUseCase {
    func execute(habitId: UUID, date: Date, value: Double?) async throws
}

public protocol SnoozeHabitReminderUseCase {
    func execute(habitId: UUID, habitName: String, originalTime: ReminderTime) async throws
}

public protocol HandleNotificationActionUseCase {
    func execute(action: NotificationAction, habitId: UUID, habitName: String?, habitKind: HabitKind, reminderTime: ReminderTime?) async throws
}

public protocol CancelHabitRemindersUseCase {
    func execute(habitId: UUID) async
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

// MARK: - Habit Schedule Use Cases

public protocol ValidateHabitScheduleUseCase {
    func execute(habit: Habit, date: Date) async throws -> HabitScheduleValidationResult
}

public protocol CheckWeeklyTargetUseCase {
    func execute(date: Date, habit: Habit, habitLogValues: [Date: Double], userProfile: UserProfile?) -> Bool
}

// MARK: - Streak Calculation Use Cases

public protocol CalculateCurrentStreakUseCase {
    func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> Int
}

/// Analyzes a habit's streak status including current streak, best streak, and whether the streak is at risk.
///
/// This use case provides comprehensive streak information for display in the UI, including:
/// - Current streak count (consecutive days/completions)
/// - Best historical streak
/// - Whether the streak is "at risk" (habit not yet completed today but still within grace period)
/// - Last completion date
///
/// The calculation respects the habit's schedule - only scheduled days count toward streaks.
/// For example, a habit scheduled Mon/Wed/Fri won't break its streak on Tuesday.
///
/// - Parameters:
///   - habit: The habit to analyze
///   - logs: Pre-fetched logs for this habit (avoids N+1 queries when analyzing multiple habits)
///   - asOf: The reference date for streak calculation (typically today)
/// - Returns: A `HabitStreakStatus` containing current streak, best streak, and risk status
public protocol GetStreakStatusUseCase {
    func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> HabitStreakStatus
}

// MARK: - Widget Use Cases

public protocol RefreshWidgetUseCase {
    func execute(habitId: UUID)
}


// MARK: - Dashboard Analytics Use Cases

public protocol GetHabitLogsForAnalyticsUseCase {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
}

public protocol GetHabitCompletionStatsUseCase {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats
}

public protocol AnalyzeWeeklyPatternsUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> WeeklyPatternsResult
}

public protocol CalculateHabitPerformanceUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitPerformanceResult]
}


public protocol GenerateProgressChartDataUseCaseProtocol {
    func execute(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [ProgressChartDataPoint]
}

public protocol CalculateStreakAnalysisUseCase {
    func execute(habits: [Habit], logs: [HabitLog], from startDate: Date, to endDate: Date) -> StreakAnalysisResult
}

// MARK: - Personality Analysis Use Cases

public protocol AnalyzePersonalityUseCase {
    func execute(for userId: UUID) async throws -> PersonalityProfile
}

public protocol GetPersonalityInsightsUseCase {
    func execute(for userId: UUID) async throws -> PersonalityProfile?
    func getAllInsights(for profile: PersonalityProfile) -> PersonalityInsightCollection
}

public protocol IsPersonalityAnalysisEnabledUseCase {
    func execute(for userId: UUID) async throws -> Bool
}

public protocol GetPersonalityProfileUseCase {
    func execute(for userId: UUID) async throws -> PersonalityProfile?
}

public protocol UpdatePersonalityAnalysisUseCase {
    func execute(for userId: UUID) async throws -> PersonalityProfile
    func regenerateAnalysis(for userId: UUID) async throws -> PersonalityProfile
    func shouldUpdateAnalysis(for userId: UUID) async throws -> Bool
}

public protocol ValidateAnalysisDataUseCase {
    func execute(for userId: UUID) async throws -> AnalysisEligibility
    func getProgressDetails(for userId: UUID) async throws -> [ThresholdRequirement]
    func getEstimatedDaysToEligibility(for userId: UUID) async throws -> Int?
}

// MARK: - Personality Analysis Preferences Use Cases

public protocol GetAnalysisPreferencesUseCase {
    func execute(for userId: UUID) async throws -> PersonalityAnalysisPreferences?
}

public protocol SaveAnalysisPreferencesUseCase {
    func execute(_ preferences: PersonalityAnalysisPreferences) async throws
}

public protocol DeletePersonalityDataUseCase {
    func execute(for userId: UUID) async throws
}

// MARK: - Personality Analysis Scheduler Use Cases

public protocol StartAnalysisSchedulingUseCase {
    func execute(for userId: UUID) async
}

public protocol UpdateAnalysisSchedulingUseCase {
    func execute(for userId: UUID, preferences: PersonalityAnalysisPreferences) async
}

public protocol GetNextScheduledAnalysisUseCase {
    func execute(for userId: UUID) async -> Date?
}

public protocol TriggerAnalysisCheckUseCase {
    func execute(for userId: UUID) async
}

public protocol ForceManualAnalysisUseCase {
    func execute(for userId: UUID) async
}

// MARK: - Personality Analysis Data Use Cases

public protocol GetHabitAnalysisInputUseCase {
    func execute(for userId: UUID) async throws -> HabitAnalysisInput
}

public protocol GetSelectedHabitSuggestionsUseCase {
    func execute(from habits: [Habit]) async throws -> [HabitSuggestion]
}

public protocol EstimateDaysToEligibilityUseCase {
    func execute(from unmetRequirements: [ThresholdRequirement]) -> Int?
}

// MARK: - Debug Use Cases

#if DEBUG
public protocol GetDatabaseStatsUseCase {
    func execute() async throws -> DebugDatabaseStats
}

public protocol ClearDatabaseUseCase {
    func execute() async throws
}

public protocol PopulateTestDataUseCase {
    func execute(scenario: TestDataScenario) async throws
    var progressUpdate: ((String, Double) -> Void)? { get set }
}

#endif
