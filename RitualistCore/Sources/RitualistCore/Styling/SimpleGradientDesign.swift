import Foundation

#if canImport(SwiftUI)
import SwiftUI

/// Simple gradient design system for Ritualist app
/// Provides beautiful background gradients and basic enhancements
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct SimpleGradientDesign {
    
    // MARK: - Colors
    
    /// Background gradient colors
    public enum BackgroundColors {
        // Light mode colors
        public static let warmPeach = Color(red: 1.0, green: 0.89, blue: 0.77)
        public static let softLavender = Color(red: 0.91, green: 0.85, blue: 1.0)
        public static let coolAqua = Color(red: 0.85, green: 0.95, blue: 1.0)
        
        // Dark mode colors
        public static let darkNavy = Color(red: 0.08, green: 0.12, blue: 0.20)
        public static let darkPurple = Color(red: 0.15, green: 0.08, blue: 0.20)
        public static let darkTeal = Color(red: 0.08, green: 0.20, blue: 0.20)
    }
    
    // MARK: - Gradients
    
    /// Main background gradient
    public static func backgroundGradient(for colorScheme: ColorScheme) -> LinearGradient {
        switch colorScheme {
        case .dark:
            return LinearGradient(
                colors: [
                    BackgroundColors.darkNavy,
                    BackgroundColors.darkPurple,
                    BackgroundColors.darkTeal
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        default:
            return LinearGradient(
                colors: [
                    BackgroundColors.warmPeach,
                    BackgroundColors.softLavender,
                    BackgroundColors.coolAqua
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Simple gradient background view
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public struct SimpleGradientBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    
    public init() {}
    
    public var body: some View {
        SimpleGradientDesign.backgroundGradient(for: colorScheme)
            .ignoresSafeArea()
    }
}

// MARK: - View Extensions

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension View {
    /// Add simple gradient background
    func simpleGradientBackground() -> some View {
        ZStack {
            SimpleGradientBackground()
            self
        }
    }
}

#endif
