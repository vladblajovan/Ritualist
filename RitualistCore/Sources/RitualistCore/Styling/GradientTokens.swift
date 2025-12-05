import SwiftUI

/// Centralized gradient definitions for optimal performance
///
/// All gradients are pre-computed static constants to eliminate runtime allocations.
/// Using enum as namespace prevents accidental instantiation.
///
/// Performance characteristics:
/// - Static let: Computed once on first access, cached forever
/// - Shared instances: All views reference same gradient object
/// - Zero runtime overhead: No dynamic computation
@available(iOS 13.0, *)
public enum GradientTokens {

    // MARK: - Chart Gradients (Icon-Inspired)

    /// Gradient for chart area fill (used in Dashboard analytics)
    ///
    /// Performance: Static allocation, reused across all chart instances
    /// Design: Uses icon blue gradient for brand consistency
    /// Usage: DashboardView chart AreaMark fills
    public static let chartAreaFill = LinearGradient(
        colors: [Color.ritualistBlue.opacity(0.3), Color.ritualistCyan.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Paywall Gradients (Icon-Inspired)

    /// Premium crown icon gradient (yellow-lime to orange - dark mode checkmark)
    ///
    /// Design: Uses dark mode checkmark gradient for premium feel
    /// Usage: PaywallView header crown icon
    public static let premiumCrown = LinearGradient(
        colors: [Color.ritualistYellowLime, Color.ritualistOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Purchase button gradient (cyan to blue - icon background)
    ///
    /// Design: Uses light mode icon background gradient for trust
    /// Usage: PaywallView purchase button background
    public static let purchaseButton = LinearGradient(
        colors: [Color.ritualistCyan, Color.ritualistBlue],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Disabled button gradient (gray tones)
    ///
    /// Design: Muted gray gradient for disabled state
    /// Usage: PaywallView purchase button when disabled
    public static let disabledButton = LinearGradient(
        colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Profile/Personality Gradients (Icon-Inspired)

    /// Profile icon gradient (cyan to blue - icon background)
    ///
    /// Design: Uses icon background gradient for consistency
    /// Usage: PersonalityInsightsView profile icon
    public static let profileIcon = LinearGradient(
        colors: [Color.ritualistCyan, Color.ritualistBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - UI Effect Gradients

    /// Horizontal edge fade for carousels (masks scroll overflow)
    ///
    /// Creates smooth fade at leading/trailing edges for better visual flow.
    /// Usage: TipsCarouselView, HorizontalCarousel edge masks
    public static let horizontalEdgeFade = LinearGradient(
        gradient: Gradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: .black, location: 0.05),
            .init(color: .black, location: 0.95),
            .init(color: .clear, location: 1)
        ]),
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Inspiration Card Gradients (Context-Aware, Icon-Inspired)

    /// Perfect day celebration gradient (yellow-lime to orange - checkmark gradient!)
    ///
    /// Used when completion percentage >= 100%
    /// Design: Uses dark mode checkmark gradient for ultimate success
    /// Conveys achievement and completion
    public static let inspirationPerfect = LinearGradient(
        colors: [Color.ritualistYellowLime.opacity(0.25), Color.ritualistOrange.opacity(0.2)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Strong progress gradient (cyan to blue - icon background!)
    ///
    /// Used when completion percentage >= 75%
    /// Design: Uses light mode icon background gradient
    /// Conveys momentum and strong performance
    public static let inspirationStrong = LinearGradient(
        colors: [Color.ritualistCyan.opacity(0.18), Color.ritualistBlue.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Midway encouragement gradient (gold accent)
    ///
    /// Used when completion percentage >= 50%
    /// Design: Uses light mode checkmark gold for encouragement
    /// Conveys energy and progress
    public static let inspirationMidway = LinearGradient(
        colors: [Color.ritualistGold.opacity(0.20), Color.ritualistOrange.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Morning motivation gradient (cyan tint)
    ///
    /// Used during morning time period (< 50% completion)
    /// Design: Light cyan for fresh start energy
    /// Conveys sunrise and new beginnings
    public static let inspirationMorning = LinearGradient(
        colors: [Color.ritualistLightCyan.opacity(0.18), Color.ritualistCyan.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Noon motivation gradient (blue focus)
    ///
    /// Used during noon time period (< 50% completion)
    /// Design: Uses icon blue for midday clarity
    /// Conveys focus and determination
    public static let inspirationNoon = LinearGradient(
        colors: [Color.ritualistBlue.opacity(0.18), Color.ritualistLightBlue.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Evening motivation gradient (deep navy calm)
    ///
    /// Used during evening time period (< 50% completion)
    /// Design: Uses dark mode navy for evening reflection
    /// Conveys calm and winding down
    public static let inspirationEvening = LinearGradient(
        colors: [Color.ritualistMidNavy.opacity(0.20), Color.ritualistDarkNavy.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
