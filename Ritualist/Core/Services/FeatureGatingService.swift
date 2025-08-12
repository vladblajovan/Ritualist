import Foundation
import Observation
import Combine

// MARK: - Feature Gating Service

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

public enum FeatureType: String, CaseIterable {
    case unlimitedHabits = "unlimited_habits"
    case advancedAnalytics = "advanced_analytics"
    case customReminders = "custom_reminders"
    case dataExport = "data_export"
    case premiumThemes = "premium_themes"
    case prioritySupport = "priority_support"
    
    var displayName: String {
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

// MARK: - Business Service Protocol

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

// MARK: - Business Implementation

public final class DefaultFeatureGatingBusinessService: FeatureGatingBusinessService {
    private let userService: UserService
    private let errorHandler: ErrorHandlingActor?
    
    // Free tier limits
    private static let freeMaxHabits = 5
    
    public init(userService: UserService, errorHandler: ErrorHandlingActor? = nil) {
        self.userService = userService
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int {
        get async {
            return await isPremiumUser ? Int.max : Self.freeMaxHabits
        }
    }
    
    public func canCreateMoreHabits(currentCount: Int) async -> Bool {
        return await isPremiumUser || currentCount < Self.freeMaxHabits
    }
    
    public var hasAdvancedAnalytics: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasCustomReminders: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasDataExport: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasPremiumThemes: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    public var hasPrioritySupport: Bool {
        get async {
            return await isPremiumUser
        }
    }
    
    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        switch feature {
        case .unlimitedHabits:
            return "You've reached the limit of \(Self.freeMaxHabits) habits on the free plan. Upgrade to Pro to track unlimited habits."
        case .advancedAnalytics:
            return "Advanced analytics are available with Ritualist Pro. Get detailed insights into your habit patterns."
        case .customReminders:
            return "Custom reminder times are a Pro feature. Upgrade to set personalized notification schedules."
        case .dataExport:
            return "Export your habit data with Ritualist Pro. Download your progress as CSV files."
        case .premiumThemes:
            return "Premium themes and customization options are available with Pro."
        case .prioritySupport:
            return "Get faster support response times with Ritualist Pro."
        }
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        switch feature {
        case .unlimitedHabits:
            return await isPremiumUser
        case .advancedAnalytics:
            return await hasAdvancedAnalytics
        case .customReminders:
            return await hasCustomReminders
        case .dataExport:
            return await hasDataExport
        case .premiumThemes:
            return await hasPremiumThemes
        case .prioritySupport:
            return await hasPrioritySupport
        }
    }
    
    private var isPremiumUser: Bool {
        get async {
            return userService.isPremiumUser
        }
    }
}

// MARK: - UI Service Layer Removed
//
// The FeatureGatingUIService layer has been removed to maintain architectural consistency.
// UI state management now belongs in ViewModels which directly use FeatureGatingBusinessService.
// This follows Clean Architecture: View → ViewModel → BusinessService → Repository

// MARK: - Legacy Default Implementation (Deprecated)

@available(*, deprecated, message: "Use FeatureGatingUIService instead")
@Observable
public final class DefaultFeatureGatingService: FeatureGatingService {
    private let userService: UserService
    private let errorHandler: ErrorHandlingActor?
    
    // Free tier limits
    private static let freeMaxHabits = 5
    
    public init(userService: UserService, errorHandler: ErrorHandlingActor? = nil) {
        self.userService = userService
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int {
        isPremiumUser ? Int.max : Self.freeMaxHabits
    }
    
    public func canCreateMoreHabits(currentCount: Int) -> Bool {
        isPremiumUser || currentCount < Self.freeMaxHabits
    }
    
    public var hasAdvancedAnalytics: Bool {
        isPremiumUser
    }
    
    public var hasCustomReminders: Bool {
        isPremiumUser
    }
    
    public var hasDataExport: Bool {
        isPremiumUser
    }
    
    public var hasPremiumThemes: Bool {
        isPremiumUser
    }
    
    public var hasPrioritySupport: Bool {
        isPremiumUser
    }
    
    nonisolated public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        switch feature {
        case .unlimitedHabits:
            return "You've reached the limit of \(Self.freeMaxHabits) habits on the free plan. Upgrade to Pro to track unlimited habits."
        case .advancedAnalytics:
            return "Advanced analytics are available with Ritualist Pro. Get detailed insights into your habit patterns."
        case .customReminders:
            return "Custom reminder times are a Pro feature. Upgrade to set personalized notification schedules."
        case .dataExport:
            return "Export your habit data with Ritualist Pro. Download your progress as CSV files."
        case .premiumThemes:
            return "Premium themes and customization options are available with Pro."
        case .prioritySupport:
            return "Get faster support response times with Ritualist Pro."
        }
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) -> Bool {
        switch feature {
        case .unlimitedHabits:
            return isPremiumUser
        case .advancedAnalytics:
            return hasAdvancedAnalytics
        case .customReminders:
            return hasCustomReminders
        case .dataExport:
            return hasDataExport
        case .premiumThemes:
            return hasPremiumThemes
        case .prioritySupport:
            return hasPrioritySupport
        }
    }
    
    private var isPremiumUser: Bool {
        userService.isPremiumUser
    }
}

// MARK: - Mock Business Service (Always Premium)

public final class MockFeatureGatingBusinessService: FeatureGatingBusinessService {
    private let errorHandler: ErrorHandlingActor?
    
    public init(errorHandler: ErrorHandlingActor? = nil) {
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int {
        get async { Int.max }
    }
    
    public func canCreateMoreHabits(currentCount: Int) async -> Bool { true }
    
    public var hasAdvancedAnalytics: Bool {
        get async { true }
    }
    
    public var hasCustomReminders: Bool {
        get async { true }
    }
    
    public var hasDataExport: Bool {
        get async { true }
    }
    
    public var hasPremiumThemes: Bool {
        get async { true }
    }
    
    public var hasPrioritySupport: Bool {
        get async { true }
    }
    
    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        "This feature is always available in mock mode."
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) async -> Bool {
        true
    }
}

// MARK: - Mock Feature Gating Service (Legacy - Always Premium)

@available(*, deprecated, message: "Use FeatureGatingUIService with MockFeatureGatingBusinessService instead")
public final class MockFeatureGatingService: FeatureGatingService {
    private let errorHandler: ErrorHandlingActor?
    
    public init(errorHandler: ErrorHandlingActor? = nil) {
        self.errorHandler = errorHandler
    }
    
    public var maxHabitsAllowed: Int { Int.max }
    
    public func canCreateMoreHabits(currentCount: Int) -> Bool { true }
    
    public var hasAdvancedAnalytics: Bool { true }
    
    public var hasCustomReminders: Bool { true }
    
    public var hasDataExport: Bool { true }
    
    public var hasPremiumThemes: Bool { true }
    
    public var hasPrioritySupport: Bool { true }
    
    public func getFeatureBlockedMessage(for feature: FeatureType) -> String {
        "This feature is always available in mock mode."
    }
    
    public func isFeatureAvailable(_ feature: FeatureType) -> Bool {
        true
    }
}

// MARK: - Feature Gating Helper

public struct FeatureGating {
    /// Standard messaging for when users hit the habit limit
    public static func habitLimitReachedMessage(current: Int, limit: Int) -> String {
        "You've created \(current) of \(limit) habits available on the free plan. Upgrade to Ritualist Pro for unlimited habits and more features."
    }
    
    /// Check if we should show paywall based on habit count and build configuration
    public static func shouldShowPaywallForHabits(currentCount: Int, maxAllowed: Int) -> Bool {
        // Don't show paywall if all features are enabled at build time
        guard BuildConfig.shouldShowPaywalls else { return false }
        return currentCount >= maxAllowed
    }
    
    /// Check if we should show any paywall UI based on build configuration
    public static func shouldShowPaywallUI() -> Bool {
        BuildConfig.shouldShowPaywalls
    }
    
    /// Features included in premium subscription
    public static let premiumFeatures: [String] = [
        "Unlimited habits",
        "Advanced analytics and insights",
        "Custom reminder schedules",
        "Data export to CSV",
        "Premium themes and customization",
        "Priority customer support",
        "Future Pro features included"
    ]
}