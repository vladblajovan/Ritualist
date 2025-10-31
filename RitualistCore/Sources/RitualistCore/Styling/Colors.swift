import Foundation

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

public enum AppColors {
    // Brand color names (for Asset Catalog lookup)
    public static let brandColorName = "Brand"
    public static let accentYellowColorName = "AccentYellow"
    public static let surfaceColorName = "Surface"
    public static let textPrimaryColorName = "TextPrimary"

    #if canImport(SwiftUI)
    // SwiftUI Color objects (when SwiftUI is available)
    // UPDATED: Icon-based brand colors for visual consistency
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public static let brand = Color(hex: 0x0D6EFD)  // Icon blue (primary brand)
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public static let accentYellow = Color(hex: 0xFF9500)  // Icon orange (dark mode checkmark)
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public static let accentCyan = Color(hex: 0x17A2B8)  // Icon cyan (secondary brand)
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public static let surface = Color("Surface")
    #if canImport(UIKit)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let background = Color(UIColor.systemBackground)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let secondaryBackground = Color(UIColor.secondarySystemBackground)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let textPrimary = Color("TextPrimary")
    @available(iOS 13.0, watchOS 6.0, *)
    public static let textSecondary = Color(UIColor.secondaryLabel)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let separator = Color(UIColor.separator)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let systemGray = Color(UIColor.systemGray)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let systemGray2 = Color(UIColor.systemGray2)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let systemGray3 = Color(UIColor.systemGray3)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let systemGray4 = Color(UIColor.systemGray4)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let systemGray5 = Color(UIColor.systemGray5)
    @available(iOS 13.0, watchOS 6.0, *)
    public static let systemGray6 = Color(UIColor.systemGray6)
    #elseif canImport(AppKit)
    @available(macOS 10.15, *)
    public static let background = Color(NSColor.windowBackgroundColor)
    @available(macOS 10.15, *)
    public static let secondaryBackground = Color(NSColor.controlBackgroundColor)
    @available(macOS 10.15, *)
    public static let textPrimary = Color("TextPrimary")
    @available(macOS 10.15, *)
    public static let textSecondary = Color(NSColor.secondaryLabelColor)
    @available(macOS 10.15, *)
    public static let separator = Color(NSColor.separatorColor)
    @available(macOS 10.15, *)
    public static let systemGray = Color(NSColor.systemGray)
    @available(macOS 10.15, *)
    public static let systemGray2 = Color(NSColor.systemGray)
    @available(macOS 10.15, *)
    public static let systemGray3 = Color(NSColor.systemGray)
    @available(macOS 10.15, *)
    public static let systemGray4 = Color(NSColor.systemGray)
    @available(macOS 10.15, *)
    public static let systemGray5 = Color(NSColor.systemGray)
    @available(macOS 10.15, *)
    public static let systemGray6 = Color(NSColor.systemGray)
    #else
    // Fallback colors for other platforms
    public static let background = Color.white
    public static let secondaryBackground = Color.gray.opacity(0.1)
    public static let textPrimary = Color("TextPrimary")
    public static let textSecondary = Color.gray
    public static let separator = Color.gray.opacity(0.3)
    public static let systemGray = Color.gray
    public static let systemGray2 = Color.gray
    public static let systemGray3 = Color.gray
    public static let systemGray4 = Color.gray
    public static let systemGray5 = Color.gray
    public static let systemGray6 = Color.gray
    #endif
    #endif
    
    // RGB color values for widgets/watch (when Asset Catalog not available)
    public enum RGB {
        // Brand colors
        public static let brand = (red: 0.0, green: 0.478, blue: 1.0) // #007AFF
        public static let accentYellow = (red: 1.0, green: 0.8, blue: 0.0) // #FFCC00
        
        // Surface colors
        public static let surface = (red: 0.98, green: 0.98, blue: 1.0) // #F9F9FF
        public static let background = (red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
        public static let secondaryBackground = (red: 0.949, green: 0.949, blue: 0.969) // #F2F2F7
        
        // Text colors
        public static let textPrimary = (red: 0.0, green: 0.0, blue: 0.0) // #000000
        public static let textSecondary = (red: 0.235, green: 0.235, blue: 0.263) // #3C3C43
        
        // System grays
        public static let separator = (red: 0.235, green: 0.235, blue: 0.263, alpha: 0.29) // #3C3C43 at 29%
        public static let systemGray = (red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
        public static let systemGray2 = (red: 0.682, green: 0.682, blue: 0.698) // #AEAEB2
        public static let systemGray3 = (red: 0.780, green: 0.780, blue: 0.800) // #C7C7CC
        public static let systemGray4 = (red: 0.820, green: 0.820, blue: 0.839) // #D1D1D6
        public static let systemGray5 = (red: 0.898, green: 0.898, blue: 0.918) // #E5E5EA
        public static let systemGray6 = (red: 0.949, green: 0.949, blue: 0.969) // #F2F2F7
    }
    
    // Dark mode RGB values
    public enum DarkRGB {
        // Brand colors (same in dark mode)
        public static let brand = RGB.brand
        public static let accentYellow = RGB.accentYellow
        
        // Surface colors
        public static let surface = (red: 0.0, green: 0.0, blue: 0.0) // #000000
        public static let background = (red: 0.0, green: 0.0, blue: 0.0) // #000000
        public static let secondaryBackground = (red: 0.110, green: 0.110, blue: 0.118) // #1C1C1E
        
        // Text colors
        public static let textPrimary = (red: 1.0, green: 1.0, blue: 1.0) // #FFFFFF
        public static let textSecondary = (red: 0.922, green: 0.922, blue: 0.961) // #EBEBF5
        
        // System grays (dark mode)
        public static let separator = (red: 0.329, green: 0.329, blue: 0.345, alpha: 0.6) // #545458 at 60%
        public static let systemGray = (red: 0.557, green: 0.557, blue: 0.576) // #8E8E93
        public static let systemGray2 = (red: 0.388, green: 0.388, blue: 0.400) // #636366
        public static let systemGray3 = (red: 0.282, green: 0.282, blue: 0.290) // #48484A
        public static let systemGray4 = (red: 0.227, green: 0.227, blue: 0.235) // #3A3A3C
        public static let systemGray5 = (red: 0.173, green: 0.173, blue: 0.180) // #2C2C2E
        public static let systemGray6 = (red: 0.110, green: 0.110, blue: 0.118) // #1C1C1E
    }
    
    // Hex color utilities
    public static func hexToRGB(_ hex: String) -> (red: Double, green: Double, blue: Double)? {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        switch hex.count {
        case 6: // RGB (24-bit)
            let r = Double((int >> 16) & 0xFF) / 255.0
            let g = Double((int >> 8) & 0xFF) / 255.0
            let b = Double(int & 0xFF) / 255.0
            return (red: r, green: g, blue: b)
        default:
            return nil
        }
    }
}