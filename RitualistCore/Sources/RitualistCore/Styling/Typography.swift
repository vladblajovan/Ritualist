import Foundation

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
    
    // Widget-specific font sizes
    public static let widgetTitle: CGFloat = 16
    public static let widgetBody: CGFloat = 14
    public static let widgetCaption: CGFloat = 12
    public static let widgetLarge: CGFloat = 20
    
    // Watch-specific font sizes
    public static let watchTitle: CGFloat = 18
    public static let watchBody: CGFloat = 16
    public static let watchCaption: CGFloat = 14
    public static let watchSmall: CGFloat = 12
}

public enum ScaleFactors {
    public static let tiny: CGFloat = 0.6
    public static let small: CGFloat = 0.7
    public static let smallMedium: CGFloat = 0.8
    public static let large: CGFloat = 1.2
    public static let extraLarge: CGFloat = 1.4
}

public enum FontWeights {
    // System font weight approximations (for cross-platform compatibility)
    public static let ultraLight: String = "UltraLight"
    public static let thin: String = "Thin"
    public static let light: String = "Light"
    public static let regular: String = "Regular"
    public static let medium: String = "Medium"
    public static let semibold: String = "Semibold"
    public static let bold: String = "Bold"
    public static let heavy: String = "Heavy"
    public static let black: String = "Black"
    
    // Numeric weight values (for programmatic use)
    public enum NumericWeights {
        public static let ultraLight: CGFloat = 100
        public static let thin: CGFloat = 200
        public static let light: CGFloat = 300
        public static let regular: CGFloat = 400
        public static let medium: CGFloat = 500
        public static let semibold: CGFloat = 600
        public static let bold: CGFloat = 700
        public static let heavy: CGFloat = 800
        public static let black: CGFloat = 900
    }
}