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
    public static let cardPadding: CGFloat = 16
    public static let cardSpacing: CGFloat = 16
    public static let shadowRadius: CGFloat = 5
    
    // MARK: - Colors (Light/Dark Mode Adaptive)
    #if canImport(UIKit)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let cardBackground = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor.systemGray5 // Lighter gray in dark mode for better visibility
        default:
            return UIColor.secondarySystemGroupedBackground // Keep original for light mode
        }
    })
    @available(iOS 13.0, watchOS 6.0, *)
    public static let secondaryBackground = Color(UIColor.systemGray6)
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

/// Glassmorphic-friendly card style modifier (no background or corner radius)
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct GlassmorphicContentStyle: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
            .padding(CardDesign.cardPadding)
    }
}

/// Optimized glassmorphic style with no padding - maximizes available space
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct GlassmorphicMaximizedContentStyle: ViewModifier {
    public init() {}
    
    public func body(content: Content) -> some View {
        content
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
    
    /// Use this style for content inside glassmorphic cards
    func glassmorphicContentStyle(action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            self.modifier(GlassmorphicContentStyle())
        }
        .buttonStyle(BounceStyle())
    }
    
    /// Optimized glassmorphic style that maximizes available space (no padding)
    func glassmorphicMaximizedContentStyle(action: @escaping () -> Void = {}) -> some View {
        Button(action: action) {
            self.modifier(GlassmorphicMaximizedContentStyle())
        }
        .buttonStyle(BounceStyle())
    }
}

#endif
