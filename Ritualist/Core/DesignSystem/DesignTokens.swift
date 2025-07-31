import SwiftUI

public enum AppColors {
    // Brand colors
    public static let brand = Color("Brand")
    public static let accentYellow = Color("AccentYellow")
    
    // Surface colors
    public static let surface = Color("Surface")
    public static let background = Color(.systemBackground)
    public static let secondaryBackground = Color(.secondarySystemBackground)
    
    // Text colors
    public static let textPrimary = Color("TextPrimary")
    public static let textSecondary = Color(.secondaryLabel)
    
    // System colors with automatic dark mode support
    public static let separator = Color(.separator)
    public static let systemGray = Color(.systemGray)
    public static let systemGray2 = Color(.systemGray2)
    public static let systemGray3 = Color(.systemGray3)
    public static let systemGray4 = Color(.systemGray4)
    public static let systemGray5 = Color(.systemGray5)
    public static let systemGray6 = Color(.systemGray6)
}

public enum Spacing {
    public static let none: CGFloat = 0
    public static let xxsmall: CGFloat = 4
    public static let xsmall: CGFloat = 6
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let extraLarge: CGFloat = 20  // Common 20px spacing
    public static let xlarge: CGFloat = 24
    public static let xxlarge: CGFloat = 32
    public static let xxxlarge: CGFloat = 40
    public static let xxxxlarge: CGFloat = 48
}

public enum CornerRadius {
    public static let none: CGFloat = 0
    public static let xsmall: CGFloat = 2.5
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 10
    public static let xlarge: CGFloat = 12
    public static let xxlarge: CGFloat = 16
    public static let xxxlarge: CGFloat = 20
}

public enum IconSize {
    public static let xsmall: CGFloat = 12
    public static let small: CGFloat = 16
    public static let medium: CGFloat = 20
    public static let large: CGFloat = 24
    public static let xlarge: CGFloat = 32
    public static let xxlarge: CGFloat = 40
    public static let xxxlarge: CGFloat = 48
    public static let xxxxlarge: CGFloat = 60
}

public enum ComponentSize {
    // Interactive elements
    public static let touchTarget: CGFloat = 44
    public static let buttonHeight: CGFloat = 44
    public static let textFieldHeight: CGFloat = 44
    
    // Calendar
    public static let calendarDay: CGFloat = 40
    
    // Avatar
    public static let avatarSmall: CGFloat = 32
    public static let avatarMedium: CGFloat = 48
    public static let avatarLarge: CGFloat = 64
    
    // Cards and components
    public static let tipCardWidth: CGFloat = 200
    public static let tipCardHeight: CGFloat = 100
    public static let drawerHandle: CGFloat = 36
    public static let drawerHandleHeight: CGFloat = 5
    public static let iconMedium: CGFloat = 28  // Common 28x28 icons
    
    // Indicators
    public static let progressIndicator: CGFloat = 8
    public static let badgeIndicator: CGFloat = 6
    public static let smallIndicator: CGFloat = 12  // 12x12 indicators
    
    // Separators
    public static let separatorThin: CGFloat = 1
    public static let separatorThick: CGFloat = 2
    public static let separatorHairline: CGFloat = 0.5
    
    // Loading states
    public static let progressHeight: CGFloat = 200
}

public enum Typography {
    // Custom font sizes for specific use cases
    public static let heroIcon: CGFloat = 60
    public static let largeIcon: CGFloat = 50
    public static let mediumIcon: CGFloat = 48
    
    // Calendar specific
    public static let calendarDayNumber: CGFloat = 16
    public static let calendarDaySmall: CGFloat = 14
    public static let calendarProgress: CGFloat = 11
    public static let calendarTiny: CGFloat = 10
    
    // Form elements
    public static let formLabel: CGFloat = 14
    
    // Badge text
    public static let badgeText: CGFloat = 14
}

public enum ScaleFactors {
    public static let tiny: CGFloat = 0.6
    public static let small: CGFloat = 0.7
    public static let smallMedium: CGFloat = 0.8
    public static let large: CGFloat = 1.2
}

public enum AnimationDuration {
    public static let fast: Double = 0.2
    public static let medium: Double = 0.3
    public static let slow: Double = 0.5
    public static let verySlow: Double = 1.0
}

public enum SpringAnimation {
    public static let fastResponse: Double = 0.3
    public static let slowResponse: Double = 0.5
    public static let standardDamping: Double = 0.8
}

public enum ShadowTokens {
    // Light shadows
    public static let lightRadius: CGFloat = 2
    public static let lightOffset = CGSize(width: 0, height: 1)
    
    // Medium shadows  
    public static let mediumRadius: CGFloat = 4
    public static let mediumOffset = CGSize(width: 0, height: 2)
    
    // Large shadows
    public static let largeRadius: CGFloat = 10
    public static let largeOffset = CGSize(width: 0, height: 5)
}

// MARK: - RTL Support
public enum RTLSupport {
    /// Returns the appropriate system image name for RTL-aware icons
    public static func chevronLeading(_ isRTL: Bool = false) -> String {
        isRTL ? "chevron.right" : "chevron.left"
    }
    
    public static func chevronTrailing(_ isRTL: Bool = false) -> String {
        isRTL ? "chevron.left" : "chevron.right"
    }
}

// MARK: - SwiftUI Extensions for RTL
extension View {
    /// Automatically flips layout for RTL languages
    public func rtlAware() -> some View {
        self.environment(\.layoutDirection, Locale.current.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight)
    }
    
    /// Provides RTL-aware leading alignment
    public func leadingAlignment(_ isRTL: Bool = Locale.current.language.characterDirection == .rightToLeft) -> some View {
        self.multilineTextAlignment(isRTL ? .trailing : .leading)
    }
}
