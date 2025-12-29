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
    /// Progress bar height for brand header
    public static let progressBarHeight: CGFloat = 8
    /// Glow radius for completion animations
    public static let glowRadius: CGFloat = 8
    /// Glow opacity for completion animations
    public static let glowOpacity: Double = 0.6

    // MARK: - Progress Colors
    public static let progressGreen = Color(hex: "#4CAF50") ?? .green
    public static let progressOrange = Color(hex: "#FF9800") ?? .orange
    public static let progressRed = Color(hex: "#F44336") ?? .red
    
    // MARK: - Progress Color Logic
    public static func progressColor(for percentage: Double) -> Color {
        if percentage >= 0.8 {
            return progressGreen
        } else if percentage >= 0.5 {
            return progressOrange
        } else {
            return progressRed
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
