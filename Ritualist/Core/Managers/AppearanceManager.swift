import SwiftUI
import RitualistCore

@Observable
public final class AppearanceManager {
    public var currentAppearance: Int = 0 {
        didSet {
            updateColorScheme()
        }
    }
    
    public var colorScheme: ColorScheme? {
        switch currentAppearance {
        case 0: return nil // Follow system
        case 1: return .light
        case 2: return .dark
        default: return nil
        }
    }
    
    public init() {}
    
    private func updateColorScheme() {
        // This will trigger a view update due to @Observable
    }
    
    public func updateFromProfile(_ profile: UserProfile) {
        currentAppearance = profile.appearance
    }
    
    // MARK: - System Preferences
    
    /// Gets the system appearance preference
    /// Returns 0 for follow system (default for new profiles)
    public static func getSystemAppearance() -> Int {
        0 // Always default to "follow system"
    }
}