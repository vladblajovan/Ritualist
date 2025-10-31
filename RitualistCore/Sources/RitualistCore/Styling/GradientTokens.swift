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

    // MARK: - Chart Gradients

    /// Gradient for chart area fill (used in Dashboard analytics)
    ///
    /// Performance: Static allocation, reused across all chart instances
    /// Usage: DashboardView chart AreaMark fills
    public static let chartAreaFill = LinearGradient(
        colors: [AppColors.brand.opacity(0.3), AppColors.brand.opacity(0.1)],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Paywall Gradients

    /// Premium crown icon gradient (orange to yellow)
    ///
    /// Usage: PaywallView header crown icon
    public static let premiumCrown = LinearGradient(
        colors: [.orange, .yellow],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Purchase button gradient (blue to purple)
    ///
    /// Usage: PaywallView purchase button background
    public static let purchaseButton = LinearGradient(
        colors: [.blue, .purple],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Profile/Personality Gradients

    /// Profile icon gradient (blue to purple diagonal)
    ///
    /// Usage: PersonalityInsightsView profile icon
    public static let profileIcon = LinearGradient(
        colors: [.blue, .purple],
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

    // MARK: - Inspiration Card Gradients (Context-Aware)

    /// Perfect day celebration gradient (green tones)
    ///
    /// Used when completion percentage >= 100%
    /// Conveys achievement and success
    public static let inspirationPerfect = LinearGradient(
        colors: [Color.green.opacity(0.2), Color.mint.opacity(0.15)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Strong progress gradient (blue tones)
    ///
    /// Used when completion percentage >= 75%
    /// Conveys momentum and strong performance
    public static let inspirationStrong = LinearGradient(
        colors: [Color.blue.opacity(0.18), Color.cyan.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Midway encouragement gradient (orange/yellow tones)
    ///
    /// Used when completion percentage >= 50%
    /// Conveys energy and encouragement
    public static let inspirationMidway = LinearGradient(
        colors: [Color.orange.opacity(0.16), Color.yellow.opacity(0.12)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Morning motivation gradient (pink/orange tones)
    ///
    /// Used during morning time period (< 50% completion)
    /// Conveys fresh start and sunrise energy
    public static let inspirationMorning = LinearGradient(
        colors: [Color.pink.opacity(0.15), Color.orange.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Noon motivation gradient (indigo/blue tones)
    ///
    /// Used during noon time period (< 50% completion)
    /// Conveys midday focus and clarity
    public static let inspirationNoon = LinearGradient(
        colors: [Color.indigo.opacity(0.15), Color.blue.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Evening motivation gradient (purple/indigo tones)
    ///
    /// Used during evening time period (< 50% completion)
    /// Conveys calm reflection and winding down
    public static let inspirationEvening = LinearGradient(
        colors: [Color.purple.opacity(0.15), Color.indigo.opacity(0.1)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
