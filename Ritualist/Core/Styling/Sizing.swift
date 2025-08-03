import SwiftUI

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