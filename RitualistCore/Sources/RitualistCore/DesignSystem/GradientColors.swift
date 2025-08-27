import SwiftUI

// MARK: - Gradient Colors for Ritualist

/// Beautiful gradient colors adapted for Ritualist's habit tracking context
/// Shared between main app and widget targets
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension Color {
    // Warm morning colors (sunrise energy)
    static let ritualistWarmPeach = Color(hex: 0xF7C58B)
    static let ritualistSoftRose = Color(hex: 0xF2A6B3)
    
    // Focus/productivity colors (midday clarity)
    static let ritualistLilacMist = Color(hex: 0xC3AEE6)
    static let ritualistPurpleHaze = Color(hex: 0xB8A9E8)
    
    // Evening calm colors (peaceful completion)
    static let ritualistSkyAqua = Color(hex: 0x9ED7D5)
    static let ritualistMintGlow = Color(hex: 0xBDE7DF)
    
    // Dark mode variants
    static let ritualistDarkNavy = Color(hex: 0x1A1B2E)
    static let ritualistDarkPurple = Color(hex: 0x2D1B3D)
    static let ritualistDarkTeal = Color(hex: 0x1B3A3B)
}

@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}