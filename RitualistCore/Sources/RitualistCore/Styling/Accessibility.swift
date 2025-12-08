import SwiftUI
import UIKit

// MARK: - Accessibility Configuration

/// Centralized accessibility utilities for App Store compliance
/// Supports VoiceOver, Dynamic Type, Reduce Motion, and other iOS accessibility features
public enum AccessibilityConfig {
    /// Minimum touch target size per Apple HIG (44x44 points)
    public static let minimumTouchTarget: CGFloat = 44

    /// WCAG 2.1 minimum contrast ratio for normal text
    public static let minimumContrastRatio: CGFloat = 4.5

    /// WCAG 2.1 minimum contrast ratio for large text (18pt+)
    public static let minimumLargeTextContrastRatio: CGFloat = 3.0
}

// MARK: - Dynamic Type Scaled Spacing

/// Spacing values that scale with Dynamic Type
/// Use these for padding/margins that should grow with text size
public struct ScaledSpacing {
    @ScaledMetric(relativeTo: .body) public var xxsmall: CGFloat = 4
    @ScaledMetric(relativeTo: .body) public var xsmall: CGFloat = 6
    @ScaledMetric(relativeTo: .body) public var small: CGFloat = 8
    @ScaledMetric(relativeTo: .body) public var medium: CGFloat = 12
    @ScaledMetric(relativeTo: .body) public var large: CGFloat = 16
    @ScaledMetric(relativeTo: .body) public var xlarge: CGFloat = 24
    @ScaledMetric(relativeTo: .body) public var xxlarge: CGFloat = 32

    public init() {}
}

/// Scaled icon sizes that grow with Dynamic Type
public struct ScaledIconSize {
    @ScaledMetric(relativeTo: .body) public var xsmall: CGFloat = 12
    @ScaledMetric(relativeTo: .body) public var small: CGFloat = 16
    @ScaledMetric(relativeTo: .body) public var medium: CGFloat = 20
    @ScaledMetric(relativeTo: .body) public var large: CGFloat = 24
    @ScaledMetric(relativeTo: .body) public var xlarge: CGFloat = 32
    @ScaledMetric(relativeTo: .body) public var xxlarge: CGFloat = 40

    public init() {}
}

// MARK: - Environment Keys

/// Environment key for accessibility-aware layout mode
private struct AccessibilityLayoutModeKey: EnvironmentKey {
    static let defaultValue: AccessibilityLayoutMode = .standard
}

public enum AccessibilityLayoutMode {
    case standard
    case accessible  // For larger accessibility text sizes
}

public extension EnvironmentValues {
    var accessibilityLayoutMode: AccessibilityLayoutMode {
        get { self[AccessibilityLayoutModeKey.self] }
        set { self[AccessibilityLayoutModeKey.self] = newValue }
    }
}

// MARK: - Accessibility State Checks

/// Checks if user has enabled large accessibility text sizes
/// Use this to switch to accessible layouts (e.g., vertical instead of horizontal)
public var prefersAccessibilityLayout: Bool {
    let category = UIApplication.shared.preferredContentSizeCategory
    return category >= .accessibilityMedium
}

/// Checks if user has enabled any large text sizes (including non-accessibility)
/// Use this for minor layout adjustments
public var prefersLargerText: Bool {
    let category = UIApplication.shared.preferredContentSizeCategory
    return category >= .extraExtraLarge
}

/// Checks if VoiceOver is currently running
public var isVoiceOverRunning: Bool {
    UIAccessibility.isVoiceOverRunning
}

/// Checks if Switch Control is enabled
public var isSwitchControlRunning: Bool {
    UIAccessibility.isSwitchControlRunning
}

/// Checks if the user prefers reduced transparency
public var prefersReducedTransparency: Bool {
    UIAccessibility.isReduceTransparencyEnabled
}

/// Checks if Bold Text is enabled
public var prefersBoldText: Bool {
    UIAccessibility.isBoldTextEnabled
}

/// Checks if the user prefers reduced motion
/// Use this to disable or simplify animations
public var isReduceMotionEnabled: Bool {
    UIAccessibility.isReduceMotionEnabled
}

// MARK: - Reduce Motion Helpers

/// Executes animation only if user hasn't enabled Reduce Motion
/// Falls back to instant state change when Reduce Motion is enabled
public func animateIfAllowed<T>(
    _ animation: Animation? = .default,
    _ body: () throws -> T
) rethrows -> T {
    if isReduceMotionEnabled {
        return try body()
    } else {
        return try withAnimation(animation, body)
    }
}

/// Returns the animation or nil based on Reduce Motion preference
public func reduceMotionSafe(_ animation: Animation) -> Animation? {
    isReduceMotionEnabled ? nil : animation
}

// MARK: - View Modifiers

/// Modifier to ensure minimum touch target size
public struct MinimumTouchTargetModifier: ViewModifier {
    let minSize: CGFloat

    public init(minSize: CGFloat = AccessibilityConfig.minimumTouchTarget) {
        self.minSize = minSize
    }

    public func body(content: Content) -> some View {
        content
            .frame(minWidth: minSize, minHeight: minSize)
    }
}

/// Modifier to hide decorative content from VoiceOver
public struct DecorativeModifier: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        content
            .accessibilityHidden(true)
    }
}

/// Modifier to group related content for VoiceOver
public struct AccessibilityGroupModifier: ViewModifier {
    let label: String
    let hint: String?
    let traits: AccessibilityTraits

    public init(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) {
        self.label = label
        self.hint = hint
        self.traits = traits
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
}

/// Modifier for buttons with custom accessibility
public struct AccessibleButtonModifier: ViewModifier {
    let label: String
    let hint: String?
    let identifier: String?

    public init(
        label: String,
        hint: String? = nil,
        identifier: String? = nil
    ) {
        self.label = label
        self.hint = hint
        self.identifier = identifier
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(identifier ?? "")
    }
}

/// Modifier for header elements
public struct AccessibleHeaderModifier: ViewModifier {
    let label: String
    let level: Int  // 1-6 for heading levels

    public init(label: String, level: Int = 1) {
        self.label = label
        self.level = max(1, min(6, level))
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Modifier for progress/stat values
public struct AccessibleValueModifier: ViewModifier {
    let label: String
    let value: String
    let hint: String?

    public init(label: String, value: String, hint: String? = nil) {
        self.label = label
        self.value = value
        self.hint = hint
    }

    public func body(content: Content) -> some View {
        content
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(label): \(value)")
            .accessibilityHint(hint ?? "")
    }
}

// MARK: - View Extensions

public extension View {
    /// Ensures the view meets minimum touch target requirements
    func minimumTouchTarget(_ size: CGFloat = AccessibilityConfig.minimumTouchTarget) -> some View {
        modifier(MinimumTouchTargetModifier(minSize: size))
    }

    /// Marks view as decorative (hidden from VoiceOver)
    func decorative() -> some View {
        modifier(DecorativeModifier())
    }

    /// Groups children for VoiceOver with combined label
    func accessibilityGroup(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        modifier(AccessibilityGroupModifier(label: label, hint: hint, traits: traits))
    }

    /// Configures accessibility for a button
    func accessibleButton(
        label: String,
        hint: String? = nil,
        identifier: String? = nil
    ) -> some View {
        modifier(AccessibleButtonModifier(label: label, hint: hint, identifier: identifier))
    }

    /// Marks as a header for VoiceOver navigation
    func accessibleHeader(_ label: String, level: Int = 1) -> some View {
        modifier(AccessibleHeaderModifier(label: label, level: level))
    }

    /// Provides accessible label for stat/value displays
    func accessibleValue(label: String, value: String, hint: String? = nil) -> some View {
        modifier(AccessibleValueModifier(label: label, value: value, hint: hint))
    }

    /// Conditionally applies accessibility layout mode based on text size
    func accessibilityLayoutAware() -> some View {
        environment(\.accessibilityLayoutMode, prefersAccessibilityLayout ? .accessible : .standard)
    }

    /// Applies animation only when Reduce Motion is not enabled
    /// Use this instead of .animation() for accessibility compliance
    func reduceMotionAnimation<V: Equatable>(
        _ animation: Animation?,
        value: V
    ) -> some View {
        self.animation(isReduceMotionEnabled ? nil : animation, value: value)
    }

    /// Applies transaction that respects Reduce Motion preference
    func reduceMotionTransaction(_ body: @escaping (inout Transaction) -> Void) -> some View {
        self.transaction { transaction in
            if isReduceMotionEnabled {
                transaction.animation = nil
                transaction.disablesAnimations = true
            } else {
                body(&transaction)
            }
        }
    }
}

// MARK: - Accessibility Announcements

/// Service for posting VoiceOver announcements
public enum AccessibilityAnnouncement {
    /// Post an announcement to VoiceOver
    public static func post(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        guard isVoiceOverRunning else { return }
        UIAccessibility.post(notification: priority, argument: message)
    }

    /// Announce a screen change
    public static func screenChanged(to screenName: String) {
        post(screenName, priority: .screenChanged)
    }

    /// Announce layout change
    public static func layoutChanged(focus element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

// MARK: - Accessibility Identifiers (RitualistCore)

/// Accessibility identifier constants for RitualistCore components.
///
/// - Note: For app-level UI testing identifiers, use `AccessibilityID` from
///   `Ritualist/Core/Utilities/AccessibilityIdentifiers.swift` which provides
///   comprehensive coverage with dot-notation (e.g., "tab.overview").
///   This enum uses underscore notation and is primarily for RitualistCore internal use.
public enum AccessibilityIdentifiers {
    // MARK: - Navigation
    public enum Navigation {
        public static let tabBar = "main_tab_bar"
        public static let overviewTab = "overview_tab"
        public static let dashboardTab = "dashboard_tab"
        public static let settingsTab = "settings_tab"
    }

    // MARK: - Overview
    public enum Overview {
        public static let screen = "overview_screen"
        public static let dateSelector = "overview_date_selector"
        public static let previousDayButton = "overview_previous_day"
        public static let nextDayButton = "overview_next_day"
        public static let todayButton = "overview_today_button"
        public static let habitList = "overview_habit_list"
        public static let addHabitButton = "overview_add_habit"
        public static let emptyState = "overview_empty_state"
    }

    // MARK: - Dashboard
    public enum Dashboard {
        public static let screen = "dashboard_screen"
        public static let scrollView = "dashboard_scroll_view"
        public static let streaksCard = "dashboard_streaks_card"
        public static let statsCard = "dashboard_stats_card"
        public static let calendarCard = "dashboard_calendar_card"
        public static let insightsCard = "dashboard_insights_card"
    }

    // MARK: - Habit Cards
    public enum HabitCard {
        public static func card(habitId: String) -> String {
            "habit_card_\(habitId)"
        }
        public static func checkbox(habitId: String) -> String {
            "habit_checkbox_\(habitId)"
        }
        public static func title(habitId: String) -> String {
            "habit_title_\(habitId)"
        }
        public static func progress(habitId: String) -> String {
            "habit_progress_\(habitId)"
        }
    }

    // MARK: - Settings
    public enum Settings {
        public static let screen = "settings_screen"
        public static let notificationsSection = "settings_notifications"
        public static let appearanceSection = "settings_appearance"
        public static let dataSection = "settings_data"
        public static let aboutSection = "settings_about"
    }

    // MARK: - Common
    public enum Common {
        public static let loadingIndicator = "loading_indicator"
        public static let errorView = "error_view"
        public static let retryButton = "retry_button"
        public static let closeButton = "close_button"
        public static let saveButton = "save_button"
        public static let cancelButton = "cancel_button"
        public static let deleteButton = "delete_button"
    }
}

// MARK: - Content Size Category Extensions

public extension ContentSizeCategory {
    /// Returns true if this is an accessibility size category
    var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }

    /// Returns true if this is larger than the default
    var isLargerThanDefault: Bool {
        switch self {
        case .extraLarge, .extraExtraLarge, .extraExtraExtraLarge,
             .accessibilityMedium, .accessibilityLarge, .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge, .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}
