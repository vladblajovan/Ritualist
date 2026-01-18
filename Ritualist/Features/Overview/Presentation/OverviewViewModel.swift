import SwiftUI
import Foundation
import FactoryKit
import RitualistCore
import TipKit

// MARK: - ViewModel

@MainActor
@Observable
public final class OverviewViewModel {
    // MARK: - ViewModels

    /// Handles inspiration card display and trigger evaluation
    public let inspirationVM = InspirationCardViewModel()

    /// Handles personality insights and premium feature management
    public let personalityVM = PersonalityInsightsCardViewModel()

    // MARK: - Observable Properties
    public var todaysSummary: TodaysSummary?
    public var activeStreaks: [StreakInfo] = []
    public var selectedDate = Date()
    public var viewingDate = CalendarUtils.startOfDayLocal(for: Date())

    public var isLoading: Bool = false
    public var error: Error?

    // Shared sheet state
    public var selectedHabitForSheet: Habit?
    public var showingNumericSheet = false

    // Notification-triggered sheet state
    public var pendingNumericHabitFromNotification: Habit?
    public var pendingBinaryHabitFromNotification: Habit?
    public var showingCompleteHabitSheet = false

    // Track if pending habit has been processed to prevent double-processing
    @ObservationIgnored var hasPendingHabitBeenProcessed: Bool = false
    @ObservationIgnored var hasPendingBinaryHabitBeenProcessed: Bool = false

    // Track view visibility to handle immediate processing when habit is set
    public var isViewVisible: Bool = false

    // Single source of truth for all overview data
    public var overviewData: OverviewData?

    // MARK: - Cache Invalidation State

    /// Track previous migration state to detect completion
    @ObservationIgnored var wasMigrating = false

    /// Track if initial data has been loaded to prevent duplicate loads
    @ObservationIgnored var hasLoadedInitialData = false
    @ObservationIgnored var hasEverLoadedData = false // True first load flag, never reset

    /// Track if a refresh was requested while a load was in progress
    /// When true, loadData() will re-run after current load completes
    @ObservationIgnored var needsRefreshAfterLoad = false

    /// Tracks child VM configuration task to prevent Task storms
    @ObservationIgnored var childVMConfigTask: Task<Void, Never>?

    /// Tracks personality insights loading task to prevent Task storms
    @ObservationIgnored var personalityInsightsTask: Task<Void, Never>?

    /// Public accessor for view to check if initial load has completed
    public var hasInitialDataLoaded: Bool {
        hasLoadedInitialData
    }

    /// Track if view has disappeared at least once (to distinguish initial appear from tab switch)
    @ObservationIgnored var viewHasDisappearedOnce = false

    /// Mark that the view has disappeared (called from onDisappear)
    public func markViewDisappeared() {
        viewHasDisappearedOnce = true
    }

    /// Check if this is a tab switch (view returning after having left)
    /// Returns false on initial appear, true on subsequent appears after disappearing
    public var isReturningFromTabSwitch: Bool {
        viewHasDisappearedOnce
    }

    // MARK: - Computed Properties
    public var incompleteHabits: [Habit] {
        todaysSummary?.incompleteHabits ?? []
    }

    public var completedHabits: [Habit] {
        todaysSummary?.completedHabits ?? []
    }

    public var shouldShowQuickActions: Bool {
        // Only show QuickActions when there are incomplete habits (completed habits now shown in Today's card)
        !incompleteHabits.isEmpty
    }

    public var shouldShowActiveStreaks: Bool {
        !activeStreaks.isEmpty
    }

    public var canGoToPreviousDay: Bool {
        let today = Date()
        let thirtyDaysAgo = CalendarUtils.addDaysLocal(-30, to: today, timezone: displayTimezone)
        let viewingDayStart = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone)
        let boundaryStart = CalendarUtils.startOfDayLocal(for: thirtyDaysAgo, timezone: displayTimezone)
        return viewingDayStart > boundaryStart
    }

    public var canGoToNextDay: Bool {
        let today = Date()
        let viewingDayStart = CalendarUtils.startOfDayLocal(for: viewingDate, timezone: displayTimezone)
        let todayStart = CalendarUtils.startOfDayLocal(for: today, timezone: displayTimezone)
        return viewingDayStart < todayStart
    }

    public var isViewingToday: Bool {
        CalendarUtils.areSameDayLocal(viewingDate, Date(), timezone: displayTimezone)
    }

    public var currentSlogan: String {
        getCurrentSlogan.execute()
    }

    public var currentTimeOfDay: TimeOfDay {
        TimeOfDay.current()
    }

    public var monthlyCompletionData: [Date: Double] = [:]

    // MARK: - Child ViewModel Accessors (Convenience)

    /// Whether to show the inspiration card (delegates to child VM)
    /// Note: Guards on isViewingToday to prevent showing on past/future dates
    /// even before the async configureChildViewModels() Task completes
    public var shouldShowInspirationCard: Bool {
        guard isViewingToday else { return false }
        return inspirationVM.shouldShowInspirationCard
    }

    /// Inspiration items for carousel (delegates to child VM)
    public var inspirationItems: [InspirationItem] {
        inspirationVM.inspirationItems
    }

    /// Whether to show personality insights card (delegates to child VM)
    public var shouldShowPersonalityInsights: Bool {
        personalityVM.shouldShowPersonalityInsights
    }

    /// Personality insights (delegates to child VM)
    public var personalityInsights: [OverviewPersonalityInsight] {
        personalityVM.personalityInsights
    }

    /// Dominant personality trait (delegates to child VM)
    public var dominantPersonalityTrait: String? {
        personalityVM.dominantPersonalityTrait
    }

    /// Is personality data sufficient (delegates to child VM)
    public var isPersonalityDataSufficient: Bool {
        personalityVM.isPersonalityDataSufficient
    }

    /// Personality threshold requirements (delegates to child VM)
    public var personalityThresholdRequirements: [ThresholdRequirement] {
        personalityVM.personalityThresholdRequirements
    }

    /// Whether to show personality upsell card (free users with sufficient data)
    public var showPersonalityUpsell: Bool {
        personalityVM.showPersonalityUpsell
    }

    /// Paywall item for personality insights upsell (binding for sheet presentation)
    public var personalityPaywallItem: PaywallItem? {
        get { personalityVM.paywallItem }
        set { personalityVM.paywallItem = newValue }
    }

    /// Show paywall for personality insights upsell
    public func showPersonalityPaywall() {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await personalityVM.showPaywall()
        }
    }

    /// Handle personality paywall dismissal
    public func handlePersonalityPaywallDismissal() {
        personalityVM.handlePaywallDismissal()
    }

    /// Immediately hide personality upsell (in case user purchased elsewhere)
    public func hidePersonalityUpsell() {
        personalityVM.hideUpsell()
    }

    // MARK: - Migration State (exposed via UseCase)

    /// Whether a migration is currently in progress
    public var isMigrating: Bool {
        getMigrationStatus.isMigrating
    }

    /// Current migration details (from version → to version)
    public var migrationDetails: MigrationDetails? {
        getMigrationStatus.migrationDetails
    }

    // MARK: - Habit Limit State

    /// Whether to show the "deactivate habits" banner for users over the free tier limit
    public var showDeactivateHabitsBanner = false

    /// Number of active habits (for banner display)
    public var activeHabitsCount = 0

    // MARK: - Dependencies
    @ObservationIgnored @Injected(\.featureGatingService) var featureGating
    @ObservationIgnored @Injected(\.getActiveHabits) var getActiveHabits
    @ObservationIgnored @Injected(\.getLogs) var getLogs
    @ObservationIgnored @Injected(\.getBatchLogs) var getBatchLogs
    @ObservationIgnored @Injected(\.logHabit) var logHabit
    @ObservationIgnored @Injected(\.deleteLog) var deleteLog
    @ObservationIgnored @Injected(\.getCurrentSlogan) var getCurrentSlogan
    @ObservationIgnored @Injected(\.getCurrentUserProfile) var getCurrentUserProfile
    @ObservationIgnored @Injected(\.calculateCurrentStreak) var calculateCurrentStreakUseCase
    @ObservationIgnored @Injected(\.getStreakStatus) var getStreakStatusUseCase
    @ObservationIgnored @Injected(\.isHabitCompleted) var isHabitCompleted
    @ObservationIgnored @Injected(\.calculateDailyProgress) var calculateDailyProgress
    @ObservationIgnored @Injected(\.isScheduledDay) var isScheduledDay
    @ObservationIgnored @Injected(\.validateHabitSchedule) var validateHabitScheduleUseCase
    @ObservationIgnored @Injected(\.refreshWidget) var refreshWidget
    @ObservationIgnored @Injected(\.getMigrationStatus) var getMigrationStatus
    @ObservationIgnored @Injected(\.timezoneService) var timezoneService
    @ObservationIgnored @Injected(\.debugLogger) var logger

    /// Cached display timezone for use in synchronous calculations.
    /// Updated on loadData() and when timezone settings change.
    /// Exposed publicly for UI components that need timezone-aware date calculations.
    /// NOT marked @ObservationIgnored - allows SwiftUI to observe direct changes.
    /// Currently, timezone changes trigger full reload via iCloudDidSyncRemoteChanges notification,
    /// but keeping this observable provides a safeguard for future direct timezone updates.
    public internal(set) var displayTimezone: TimeZone = .current

    private func getUserId() async -> UUID {
        await getCurrentUserProfile.execute().id
    }

    public init() {
        // Child VMs handle their own initialization
    }
}
