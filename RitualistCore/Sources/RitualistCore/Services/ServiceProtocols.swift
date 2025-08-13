import Foundation

// MARK: - Feature Gating Services

public enum FeatureType: String, CaseIterable {
    case unlimitedHabits = "unlimited_habits"
    case advancedAnalytics = "advanced_analytics"
    case customReminders = "custom_reminders"
    case dataExport = "data_export"
    case premiumThemes = "premium_themes"
    case prioritySupport = "priority_support"
    
    public var displayName: String {
        switch self {
        case .unlimitedHabits: return "Unlimited Habits"
        case .advancedAnalytics: return "Advanced Analytics"
        case .customReminders: return "Custom Reminders"
        case .dataExport: return "Data Export"
        case .premiumThemes: return "Premium Themes"
        case .prioritySupport: return "Priority Support"
        }
    }
}

public protocol FeatureGatingService {
    /// Maximum number of habits allowed for the current user
    var maxHabitsAllowed: Int { get }
    
    /// Whether the user can create more habits
    func canCreateMoreHabits(currentCount: Int) -> Bool
    
    /// Whether advanced analytics are available
    var hasAdvancedAnalytics: Bool { get }
    
    /// Whether custom reminders are available
    var hasCustomReminders: Bool { get }
    
    /// Whether data export is available
    var hasDataExport: Bool { get }
    
    /// Whether premium themes are available
    var hasPremiumThemes: Bool { get }
    
    /// Whether priority support is available
    var hasPrioritySupport: Bool { get }
    
    /// Get a user-friendly message when a feature is blocked
    func getFeatureBlockedMessage(for feature: FeatureType) -> String
    
    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: FeatureType) -> Bool
}

/// Thread-agnostic business logic for feature gating
public protocol FeatureGatingBusinessService {
    /// Maximum number of habits allowed for the current user
    var maxHabitsAllowed: Int { get async }
    
    /// Whether the user can create more habits
    func canCreateMoreHabits(currentCount: Int) async -> Bool
    
    /// Whether advanced analytics are available
    var hasAdvancedAnalytics: Bool { get async }
    
    /// Whether custom reminders are available
    var hasCustomReminders: Bool { get async }
    
    /// Whether data export is available
    var hasDataExport: Bool { get async }
    
    /// Whether premium themes are available
    var hasPremiumThemes: Bool { get async }
    
    /// Whether priority support is available
    var hasPrioritySupport: Bool { get async }
    
    /// Get a user-friendly message when a feature is blocked
    func getFeatureBlockedMessage(for feature: FeatureType) -> String
    
    /// Check if a specific feature is available
    func isFeatureAvailable(_ feature: FeatureType) async -> Bool
}

// MARK: - User Services

/// Thread-agnostic business logic for user profile operations
public protocol UserBusinessService {
    /// Get current user profile - delegates to ProfileRepository
    func getCurrentProfile() async throws -> UserProfile
    
    /// Check if user has premium features
    func isPremiumUser() async throws -> Bool
    
    /// Update user profile - syncs to both local and cloud
    func updateProfile(_ profile: UserProfile) async throws
    
    /// Update subscription after purchase - syncs to both local and cloud
    func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws
    
    /// Sync with iCloud (future implementation)
    func syncWithiCloud() async throws
}

/// Simplified user service that manages the single UserProfile entity
/// No authentication required - designed for iCloud sync
/// Acts as a bridge between local ProfileRepository and cloud storage
public protocol UserService {
    /// Current user profile (includes subscription info) - delegates to ProfileRepository
    var currentProfile: UserProfile { get }
    
    /// Check if user has premium features
    var isPremiumUser: Bool { get }
    
    /// Update user profile - syncs to both local and cloud
    func updateProfile(_ profile: UserProfile) async throws
    
    /// Update subscription after purchase - syncs to both local and cloud
    func updateSubscription(plan: SubscriptionPlan, expiryDate: Date?) async throws
    
    /// Sync with iCloud (future implementation)
    func syncWithiCloud() async throws
}

// MARK: - Paywall Services

public protocol PaywallBusinessService {
    /// Load available products from the App Store
    func loadProducts() async throws -> [Product]
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool
    
    /// Restore previous purchases
    func restorePurchases() async throws -> Bool
    
    /// Check if a specific product is purchased
    func isProductPurchased(_ productId: String) async -> Bool
    
    /// Clear all purchases for a user (useful when subscription is cancelled)
    func clearPurchases() async throws
}

public protocol PaywallService {
    var purchaseState: PurchaseState { get }
    
    /// Load available products from the App Store
    func loadProducts() async throws -> [Product]
    
    /// Purchase a product
    func purchase(_ product: Product) async throws -> Bool
    
    /// Restore previous purchases
    func restorePurchases() async throws -> Bool
    
    /// Check if a specific product is purchased
    func isProductPurchased(_ productId: String) async -> Bool
    
    /// Reset purchase state to idle (useful for UI state management)
    func resetPurchaseState()
    
    /// Clear all purchases for a user (useful when subscription is cancelled)
    func clearPurchases()
}

// MARK: - Notification Service

public protocol NotificationService {
    func requestAuthorizationIfNeeded() async throws -> Bool
    func checkAuthorizationStatus() async -> Bool
    func schedule(for habitID: UUID, times: [ReminderTime]) async throws
    func scheduleWithActions(for habitID: UUID, habitName: String, times: [ReminderTime]) async throws
    func scheduleRichReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, times: [ReminderTime]) async throws
    func schedulePersonalityTailoredReminders(for habitID: UUID, habitName: String, habitCategory: String?, currentStreak: Int, personalityProfile: PersonalityProfile, times: [ReminderTime]) async throws
    func sendStreakMilestone(for habitID: UUID, habitName: String, streakDays: Int) async throws
    func cancel(for habitID: UUID) async
    func sendImmediate(title: String, body: String) async throws
    func setupNotificationCategories() async
}

// MARK: - User Action Tracking Service

public protocol UserActionTrackerService {
    /// Track a user action event
    func track(_ event: UserActionEvent)
    
    /// Track a user action event with additional context
    func track(_ event: UserActionEvent, context: [String: Any])
    
    /// Set user properties (for analytics segmentation)
    func setUserProperty(key: String, value: Any)
    
    /// Identify the user (when user creates account or logs in)
    func identifyUser(userId: String, properties: [String: Any]?)
    
    /// Reset user identity (on logout)
    func resetUser()
    
    /// Enable/disable tracking (for privacy compliance)
    func setTrackingEnabled(_ enabled: Bool)
    
    /// Flush any pending events (useful before app backgrounding)
    func flush()
}

// MARK: - Slogans Service

public enum TimeOfDay: CaseIterable {
    case morning    // Until 11:00
    case noon       // Between 11:00 and 16:00
    case evening    // After 16:00
}

public protocol SlogansServiceProtocol {
    /// Get a random slogan for the current time of day
    func getCurrentSlogan() -> String
    
    /// Get a random slogan for a specific time of day
    func getSlogan(for timeOfDay: TimeOfDay) -> String
    
    /// Get the current time of day based on current time
    func getCurrentTimeOfDay() -> TimeOfDay
    
    /// Get the current time of day based on a specific date
    func getTimeOfDay(for date: Date) -> TimeOfDay
}

// MARK: - Analytics Services

/// Domain service responsible for habit data access and retrieval
public protocol HabitAnalyticsService {
    
    /// Get all active habits for a user
    func getActiveHabits(for userId: UUID) async throws -> [Habit]
    
    /// Get habit logs for a user within a date range
    func getHabitLogs(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> [HabitLog]
    
    /// Get habit completion statistics for a user within a date range
    func getHabitCompletionStats(for userId: UUID, from startDate: Date, to endDate: Date) async throws -> HabitCompletionStats
}

// MARK: - Schedule Analysis Services

/// Service for analyzing habit schedules and expected completion dates
public protocol HabitScheduleAnalyzerProtocol {
    /// Calculate number of expected days for a habit in a date range
    func calculateExpectedDays(for habit: Habit, from startDate: Date, to endDate: Date) -> Int
    
    /// Check if a habit is expected to be completed on a specific date
    func isHabitExpectedOnDate(habit: Habit, date: Date) -> Bool
}