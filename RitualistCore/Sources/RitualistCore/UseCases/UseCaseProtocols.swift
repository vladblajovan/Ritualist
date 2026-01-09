import Foundation

// MARK: - Migration Use Cases

/// UseCase for checking if a migration is currently in progress
@MainActor
public protocol GetMigrationStatusUseCase {
    var isMigrating: Bool { get }
    var migrationDetails: MigrationDetails? { get }
}

// MARK: - Habit Use Cases

public protocol CreateHabitUseCase: Sendable {
    func execute(_ habit: Habit) async throws -> Habit
}

public protocol GetActiveHabitsUseCase: Sendable {
    func execute() async throws -> [Habit]
}

public protocol GetAllHabitsUseCase: Sendable {
    func execute() async throws -> [Habit]
}

public protocol UpdateHabitUseCase: Sendable {
    func execute(_ habit: Habit) async throws
}

public protocol DeleteHabitUseCase: Sendable {
    func execute(id: UUID) async throws
}

public protocol ToggleHabitActiveStatusUseCase: Sendable {
    func execute(id: UUID) async throws -> Habit
}

public protocol ReorderHabitsUseCase: Sendable {
    func execute(_ habits: [Habit]) async throws
}

public protocol ValidateHabitUniquenessUseCase: Sendable {
    func execute(name: String, categoryId: String?, excludeId: UUID?) async throws -> Bool
}

public protocol GetHabitsByCategoryUseCase: Sendable {
    func execute(categoryId: String) async throws -> [Habit]
}

public protocol OrphanHabitsFromCategoryUseCase: Sendable {
    func execute(categoryId: String) async throws
}

public protocol CleanupOrphanedHabitsUseCase: Sendable {
    func execute() async throws -> Int
}

public protocol GetHabitCountUseCase: Sendable {
    func execute() async -> Int
}

public protocol IsHabitCompletedUseCase {
    /// Check if habit is completed with explicit timezone
    func execute(habit: Habit, on date: Date, logs: [HabitLog], timezone: TimeZone) -> Bool

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(habit: Habit, on date: Date, logs: [HabitLog]) -> Bool
}

public protocol CalculateDailyProgressUseCase {
    /// Calculate daily progress with explicit timezone
    func execute(habit: Habit, logs: [HabitLog], for date: Date, timezone: TimeZone) -> Double

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(habit: Habit, logs: [HabitLog], for date: Date) -> Double
}

public protocol IsScheduledDayUseCase {
    /// Check if day is scheduled with explicit timezone
    func execute(habit: Habit, date: Date, timezone: TimeZone) -> Bool

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(habit: Habit, date: Date) -> Bool
}

public protocol ClearPurchasesUseCase: Sendable {
    func execute() async throws
}

public protocol CreateHabitFromSuggestionUseCase: Sendable {
    func execute(_ suggestion: HabitSuggestion) async -> CreateHabitFromSuggestionResult
}

public protocol RemoveHabitFromSuggestionUseCase: Sendable {
    func execute(suggestionId: String, habitId: UUID) async -> Bool
}

// MARK: - Log Use Cases

public protocol GetLogsUseCase: Sendable {
    /// Get logs with explicit timezone for date filtering
    func execute(for habitID: UUID, since: Date?, until: Date?, timezone: TimeZone) async throws -> [HabitLog]

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(for habitID: UUID, since: Date?, until: Date?) async throws -> [HabitLog]
}

public protocol GetBatchLogsUseCase: Sendable {
    /// Get batch logs with explicit timezone for date filtering
    func execute(for habitIDs: [UUID], since: Date?, until: Date?, timezone: TimeZone) async throws -> [UUID: [HabitLog]]

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(for habitIDs: [UUID], since: Date?, until: Date?) async throws -> [UUID: [HabitLog]]
}

public protocol GetSingleHabitLogsUseCase: Sendable {
    func execute(for habitID: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
}

public protocol LogHabitUseCase: Sendable {
    func execute(_ log: HabitLog) async throws
}

public protocol DeleteLogUseCase: Sendable {
    func execute(id: UUID) async throws
}

public protocol GetLogForDateUseCase: Sendable {
    /// Get log for date with explicit timezone for day comparison
    func execute(habitID: UUID, date: Date, timezone: TimeZone) async throws -> HabitLog?

    /// Convenience method defaulting to device timezone (backward compatibility)
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
public protocol GetEarliestLogDateUseCase: Sendable {
    /// Get earliest log date with explicit timezone for day normalization
    func execute(for habitID: UUID, timezone: TimeZone) async throws -> Date?

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(for habitID: UUID) async throws -> Date?
}

// MARK: - Profile Use Cases  

public protocol LoadProfileUseCase: Sendable {
    func execute() async throws -> UserProfile
}

public protocol SaveProfileUseCase: Sendable {
    func execute(_ profile: UserProfile) async throws
}

public protocol CheckPremiumStatusUseCase: Sendable {
    func execute() async -> Bool
}

public protocol GetCurrentSubscriptionPlanUseCase: Sendable {
    func execute() async -> SubscriptionPlan
}

public protocol GetSubscriptionExpiryDateUseCase: Sendable {
    func execute() async -> Date?
}

public protocol GetIsOnTrialUseCase: Sendable {
    func execute() async -> Bool
}

public protocol GetCurrentUserProfileUseCase: Sendable {
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

public protocol GetAllTipsUseCase: Sendable {
    func execute() async throws -> [Tip]
}

public protocol GetFeaturedTipsUseCase: Sendable {
    func execute() async throws -> [Tip]
}

public protocol GetTipByIdUseCase: Sendable {
    func execute(id: UUID) async throws -> Tip?
}

public protocol GetTipsByCategoryUseCase: Sendable {
    func execute(category: TipCategory) async throws -> [Tip]
}

// MARK: - Category Use Cases

public protocol GetAllCategoriesUseCase: Sendable {
    func execute() async throws -> [HabitCategory]
}

public protocol GetCategoryByIdUseCase: Sendable {
    func execute(id: String) async throws -> HabitCategory?
}

public protocol GetActiveCategoriesUseCase: Sendable {
    func execute() async throws -> [HabitCategory]
}

public protocol GetPredefinedCategoriesUseCase: Sendable {
    func execute() async throws -> [HabitCategory]
}

public protocol GetCustomCategoriesUseCase: Sendable {
    func execute() async throws -> [HabitCategory]
}

public protocol CreateCustomCategoryUseCase: Sendable {
    func execute(_ category: HabitCategory) async throws
}

public protocol UpdateCategoryUseCase: Sendable {
    func execute(_ category: HabitCategory) async throws
}

public protocol DeleteCategoryUseCase: Sendable {
    func execute(id: String) async throws
}

public protocol ValidateCategoryNameUseCase: Sendable {
    func execute(name: String) async throws -> Bool
}

public protocol LoadHabitsDataUseCase: Sendable {
    func execute() async throws -> HabitsData
}

// MARK: - Onboarding Use Cases

public protocol GetOnboardingStateUseCase: Sendable {
    func execute() async throws -> OnboardingState
}

public protocol SaveOnboardingStateUseCase: Sendable {
    func execute(_ state: OnboardingState) async throws
}

public protocol CompleteOnboardingUseCase: Sendable {
    func execute(userName: String?, hasNotifications: Bool, hasLocation: Bool, gender: String?, ageGroup: String?) async throws
}

// MARK: - Slogan Use Cases

public protocol GetCurrentSloganUseCase {
    func execute() -> String
    func getUniqueSlogans(count: Int, for timeOfDay: TimeOfDay) -> [String]
}




// MARK: - Notification Use Cases

public protocol RequestNotificationPermissionUseCase: Sendable {
    func execute() async throws -> Bool
}

public protocol CheckNotificationStatusUseCase: Sendable {
    func execute() async -> Bool
}

public protocol ScheduleHabitRemindersUseCase: Sendable {
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

public protocol CancelHabitRemindersUseCase: Sendable {
    func execute(habitId: UUID) async
}

// MARK: - Feature Gating Use Cases

public protocol CheckFeatureAccessUseCase: Sendable {
    func execute() async -> Bool
}

public protocol CheckHabitCreationLimitUseCase: Sendable {
    func execute(currentCount: Int) async -> Bool
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

public protocol LoadPaywallProductsUseCase: Sendable {
    func execute() async throws -> [Product]
}

public protocol PurchaseProductUseCase: Sendable {
    func execute(_ product: Product) async throws -> PurchaseResult
}

public protocol RestorePurchasesUseCase: Sendable {
    func execute() async throws -> RestoreResult
}

public protocol CheckProductPurchasedUseCase: Sendable {
    func execute(_ productId: String) async -> Bool
}

// MARK: - Habit Schedule Use Cases

public protocol ValidateHabitScheduleUseCase: Sendable {
    func execute(habit: Habit, date: Date) async throws -> HabitScheduleValidationResult
}

public protocol CheckWeeklyTargetUseCase {
    func execute(date: Date, habit: Habit, habitLogValues: [Date: Double], userProfile: UserProfile?) -> Bool
}

// MARK: - Streak Calculation Use Cases

public protocol CalculateCurrentStreakUseCase {
    /// Calculate current streak with explicit timezone
    func execute(habit: Habit, logs: [HabitLog], asOf: Date, timezone: TimeZone) -> Int

    /// Convenience method defaulting to device timezone (backward compatibility)
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
///   - timezone: The timezone to use for day boundary calculations (defaults to device timezone)
/// - Returns: A `HabitStreakStatus` containing current streak, best streak, and risk status
public protocol GetStreakStatusUseCase {
    /// Get streak status with explicit timezone
    func execute(habit: Habit, logs: [HabitLog], asOf: Date, timezone: TimeZone) -> HabitStreakStatus

    /// Convenience method defaulting to device timezone (backward compatibility)
    func execute(habit: Habit, logs: [HabitLog], asOf: Date) -> HabitStreakStatus
}

// MARK: - Widget Use Cases

public protocol RefreshWidgetUseCase {
    func execute(habitId: UUID)
}


// MARK: - Stats Analytics Use Cases

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
    func execute(habits: [Habit], logs: [HabitLog], from startDate: Date, to endDate: Date, timezone: TimeZone) -> StreakAnalysisResult
}

// MARK: - Default Implementation for Backward Compatibility
public extension CalculateStreakAnalysisUseCase {
    /// Convenience method that uses the current device timezone
    func execute(habits: [Habit], logs: [HabitLog], from startDate: Date, to endDate: Date) -> StreakAnalysisResult {
        execute(habits: habits, logs: logs, from: startDate, to: endDate, timezone: .current)
    }
}

public protocol GetConsistencyHeatmapDataUseCase: Sendable {
    func execute(habitId: UUID, period: TimePeriod, timezone: TimeZone) async throws -> ConsistencyHeatmapData
}

// MARK: - Personality Analysis Use Cases

public protocol AnalyzePersonalityUseCase: Sendable {
    func execute(for userId: UUID) async throws -> PersonalityProfile
}

public protocol GetPersonalityInsightsUseCase: Sendable {
    func execute(for userId: UUID) async throws -> PersonalityProfile?
    func getAllInsights(for profile: PersonalityProfile) -> PersonalityInsightCollection
}

public protocol IsPersonalityAnalysisEnabledUseCase: Sendable {
    func execute(for userId: UUID) async throws -> Bool
}

public protocol GetPersonalityProfileUseCase: Sendable {
    func execute(for userId: UUID) async throws -> PersonalityProfile?
}

public protocol UpdatePersonalityAnalysisUseCase: Sendable {
    func execute(for userId: UUID) async throws -> PersonalityProfile
    func regenerateAnalysis(for userId: UUID) async throws -> PersonalityProfile
    func shouldUpdateAnalysis(for userId: UUID) async throws -> Bool
}

public protocol ValidateAnalysisDataUseCase: Sendable {
    func execute(for userId: UUID) async throws -> AnalysisEligibility
    func getProgressDetails(for userId: UUID) async throws -> [ThresholdRequirement]
    func getEstimatedDaysToEligibility(for userId: UUID) async throws -> Int?
}

// MARK: - Personality Analysis Preferences Use Cases

public protocol GetAnalysisPreferencesUseCase: Sendable {
    func execute(for userId: UUID) async throws -> PersonalityAnalysisPreferences?
}

public protocol SaveAnalysisPreferencesUseCase: Sendable {
    func execute(_ preferences: PersonalityAnalysisPreferences) async throws
}

public protocol DeletePersonalityDataUseCase: Sendable {
    func execute(for userId: UUID) async throws
}

// MARK: - Personality Analysis Scheduler Use Cases

public protocol StartAnalysisSchedulingUseCase: Sendable {
    func execute(for userId: UUID) async
}

public protocol UpdateAnalysisSchedulingUseCase: Sendable {
    func execute(for userId: UUID, preferences: PersonalityAnalysisPreferences) async
}

public protocol GetNextScheduledAnalysisUseCase: Sendable {
    func execute(for userId: UUID) async -> Date?
}

public protocol TriggerAnalysisCheckUseCase: Sendable {
    func execute(for userId: UUID) async
}

public protocol ForceManualAnalysisUseCase: Sendable {
    func execute(for userId: UUID) async
}

// MARK: - Personality Analysis Data Use Cases

public protocol GetHabitAnalysisInputUseCase: Sendable {
    func execute(for userId: UUID) async throws -> HabitAnalysisInput
}

public protocol GetSelectedHabitSuggestionsUseCase: Sendable {
    func execute(from habits: [Habit]) async throws -> [HabitSuggestion]
}

public protocol EstimateDaysToEligibilityUseCase {
    func execute(from unmetRequirements: [ThresholdRequirement]) -> Int?
}

// MARK: - Debug Use Cases

#if DEBUG
public protocol GetDatabaseStatsUseCase: Sendable {
    func execute() async throws -> DebugDatabaseStats
}

public protocol ClearDatabaseUseCase: Sendable {
    func execute() async throws
}

public protocol PopulateTestDataUseCase: Sendable {
    func execute(scenario: TestDataScenario) async throws
    var progressUpdate: (@Sendable (String, Double) -> Void)? { get set }
}

#endif
