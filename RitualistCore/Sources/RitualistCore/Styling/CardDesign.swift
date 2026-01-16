import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Unified design tokens for cards across the entire app
/// Use this instead of duplicating card styling in different features
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct CardDesign {
    // MARK: - Layout
    public static let cornerRadius: CGFloat = {
        if #available(iOS 26.0, *) {
            return 25 // iOS 26 large radius style
        } else {
            return 16 // Classic radius for older iOS
        }
    }()
    /// Smaller corner radius for inner elements (chips, pills, rows) to visually match card corners
    /// Smaller elements need proportionally smaller radii to avoid looking overly rounded
    public static let innerCornerRadius: CGFloat = 12
    public static let cardPadding: CGFloat = 16
    public static let cardSpacing: CGFloat = 16
    public static let shadowRadius: CGFloat = 5

    // MARK: - Animation
    /// Standard duration for quick UI transitions (focus changes, selection)
    public static let quickAnimationDuration: Double = 0.2
    /// Standard duration for medium UI transitions (expansion, collapse)
    public static let mediumAnimationDuration: Double = 0.3

    // MARK: - Sheet Detents
    /// Collapsed/minimized sheet height (bottom card overlays)
    public static let sheetDetentCollapsed: CGFloat = 0.4
    /// Expanded sheet height (bottom card overlays)
    public static let sheetDetentExpanded: CGFloat = 0.75
    
    // MARK: - Colors (Light/Dark Mode Adaptive)
    #if canImport(UIKit)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let cardBackground = Color(uiColor: UIColor.secondarySystemGroupedBackground)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let secondaryBackground = Color(uiColor: UIColor.tertiarySystemGroupedBackground)
    #elseif canImport(AppKit)
    @available(macOS 10.15, *)
    public static let cardBackground = Color(NSColor.controlBackgroundColor)
    @available(macOS 10.15, *)
    public static let secondaryBackground = Color(NSColor.systemGray)
    #else
    // Fallback colors
    public static let cardBackground = Color.gray.opacity(0.1)
    public static let secondaryBackground = Color.gray.opacity(0.2)
    #endif
    
    public static let shadowColor = Color.primary.opacity(0.1)
    
    // MARK: - Brand Header
    /// Font size for app brand header (icon + "Ritualist" text)
    public static let brandHeaderFontSize: CGFloat = 28
    /// Font for app brand header using SF Rounded design (matches launch screen)
    public static let brandHeaderFont: Font = .system(size: brandHeaderFontSize, weight: .bold, design: .rounded)
    /// Progress bar height for brand header
    public static let progressBarHeight: CGFloat = 8

    // MARK: - Rounded Fonts (App-wide consistency)
    /// Large title with rounded design
    public static let largeTitle: Font = .system(.largeTitle, design: .rounded)
    /// Title with rounded design
    public static let title: Font = .system(.title, design: .rounded)
    /// Title2 with rounded design
    public static let title2: Font = .system(.title2, design: .rounded)
    /// Title3 with rounded design
    public static let title3: Font = .system(.title3, design: .rounded)
    /// Headline with rounded design
    public static let headline: Font = .system(.headline, design: .rounded)
    /// Subheadline with rounded design
    public static let subheadline: Font = .system(.subheadline, design: .rounded)
    /// Body with rounded design
    public static let body: Font = .system(.body, design: .rounded)
    /// Callout with rounded design
    public static let callout: Font = .system(.callout, design: .rounded)
    /// Footnote with rounded design
    public static let footnote: Font = .system(.footnote, design: .rounded)
    /// Caption with rounded design
    public static let caption: Font = .system(.caption, design: .rounded)
    /// Caption2 with rounded design
    public static let caption2: Font = .system(.caption2, design: .rounded)
    /// Glow radius for completion animations
    public static let glowRadius: CGFloat = 8
    /// Glow opacity for completion animations
    public static let glowOpacity: Double = 0.6

    // MARK: - Progress Colors
    public static let progressGreen = Color(hex: "#4CAF50") ?? .green
    /// Light green for "almost complete" (80-99%) - distinct from full completion
    public static let progressLightGreen = Color(hex: "#8BC34A") ?? .green.opacity(0.7)
    public static let progressOrange = Color(hex: "#FF9800") ?? .orange
    /// Deep orange/coral for "getting started" (25-49%) - warmer than red
    public static let progressCoral = Color(hex: "#FF7043") ?? .orange.opacity(0.8)
    public static let progressRed = Color(hex: "#F44336") ?? .red
    
    // MARK: - Progress Color Logic
    /// Returns progress color based on completion percentage
    /// - Parameters:
    ///   - percentage: Completion rate (0.0 to 1.0)
    ///   - noProgressColor: Color to use when completion is zero (defaults to secondaryBackground)
    /// - Returns: Color representing progress level
    ///
    /// Color mapping:
    /// - 100%: Full green (complete)
    /// - 80-99%: Light green (almost complete)
    /// - 50-79%: Orange (good progress)
    /// - 25-49%: Coral (getting started)
    /// - 1-24%: Muted red (low progress)
    /// - 0%: No progress color (customizable)
    public static func progressColor(
        for percentage: Double,
        noProgressColor: Color = secondaryBackground
    ) -> Color {
        if percentage >= 1.0 {
            return progressGreen
        } else if percentage >= 0.8 {
            return progressLightGreen
        } else if percentage >= 0.5 {
            return progressOrange
        } else if percentage >= 0.25 {
            return progressCoral
        } else if percentage > 0 {
            return progressRed.opacity(0.6)
        } else {
            return noProgressColor
        }
    }
}

/// Unified card style modifier
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct CardStyle: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .padding(CardDesign.cardPadding)
            .background(CardDesign.cardBackground)
            .cornerRadius(CardDesign.cornerRadius)
            .shadow(
                color: CardDesign.shadowColor,
                radius: CardDesign.shadowRadius,
                x: 0,
                y: 2
            )
    }
}


/// Apple-recommended bounce style for interactive feedback
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct BounceStyle: ButtonStyle {
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.6),
                value: configuration.isPressed
            )
    }
}

@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension View {
    func cardStyle(action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            self.modifier(CardStyle())
        }
        .buttonStyle(BounceStyle())
    }
}

#endif
