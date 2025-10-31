import SwiftUI

// MARK: - Gradient Colors for Ritualist (Icon-Driven Redesign)

/// Icon-inspired gradient colors for visual consistency
/// Extracted from app icon to create cohesive brand experience
/// Shared between main app and widget targets
@available(iOS 17.0, macOS 14.0, watchOS 10.0, *)
public extension Color {
    // MARK: - Light Mode (Icon Background Gradient: Cyan → Blue)

    /// Primary cyan from light mode icon (left side)
    static let ritualistCyan = Color(hex: 0x17A2B8)

    /// Primary blue from light mode icon (right side)
    static let ritualistBlue = Color(hex: 0x0D6EFD)

    /// Light cyan tint for subtle variations
    static let ritualistLightCyan = Color(hex: 0x5DCDDE)

    /// Light blue tint for subtle variations
    static let ritualistLightBlue = Color(hex: 0x4A90E2)

    // MARK: - Checkmark Gradient (Light Mode: White → Gold)

    /// Checkmark start color (light mode)
    static let ritualistWhite = Color.white

    /// Checkmark end color - gold/yellow (light mode)
    static let ritualistGold = Color(hex: 0xFFC107)

    // MARK: - Dark Mode (Icon Background: Deep Navy)

    /// Primary dark navy from dark mode icon background
    static let ritualistDarkNavy = Color(hex: 0x0A1628)

    /// Deeper navy variant for stronger contrast
    static let ritualistDeepNavy = Color(hex: 0x06101C)

    /// Mid navy variant for layering
    static let ritualistMidNavy = Color(hex: 0x0E1F38)

    // MARK: - Checkmark Gradient (Dark Mode: Yellow-Lime → Orange)

    /// Checkmark start color - yellow-lime (dark mode)
    static let ritualistYellowLime = Color(hex: 0xFFE66D)

    /// Checkmark end color - vibrant orange (dark mode)
    static let ritualistOrange = Color(hex: 0xFF9500)

    // MARK: - Legacy Colors (Deprecated - Will be removed)

    @available(*, deprecated, message: "Use ritualistCyan/ritualistBlue instead")
    static let ritualistWarmPeach = Color(hex: 0xF7C58B)

    @available(*, deprecated, message: "Use ritualistCyan/ritualistBlue instead")
    static let ritualistSoftRose = Color(hex: 0xF2A6B3)

    @available(*, deprecated, message: "Use ritualistCyan/ritualistBlue instead")
    static let ritualistLilacMist = Color(hex: 0xC3AEE6)

    @available(*, deprecated, message: "Use ritualistCyan/ritualistBlue instead")
    static let ritualistPurpleHaze = Color(hex: 0xB8A9E8)

    @available(*, deprecated, message: "Use ritualistCyan/ritualistBlue instead")
    static let ritualistSkyAqua = Color(hex: 0x9ED7D5)

    @available(*, deprecated, message: "Use ritualistCyan/ritualistBlue instead")
    static let ritualistMintGlow = Color(hex: 0xBDE7DF)

    @available(*, deprecated, message: "Use ritualistDarkNavy/ritualistDeepNavy instead")
    static let ritualistDarkPurple = Color(hex: 0x2D1B3D)

    @available(*, deprecated, message: "Use ritualistDarkNavy/ritualistDeepNavy instead")
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