import Foundation
import UIKit

public final class SystemPreferences {
    
    /// Gets the first day of week from system calendar settings
    /// Returns 1 for Sunday, 2 for Monday, etc. matching our UserProfile format
    public static func getSystemFirstDayOfWeek() -> Int {
        let calendar = Calendar.current
        // Calendar.firstWeekday returns 1 for Sunday, 2 for Monday, etc.
        // This matches our UserProfile format perfectly
        return calendar.firstWeekday
    }
    
    /// Gets the system appearance preference
    /// Returns 0 for follow system, 1 for light, 2 for dark
    public static func getSystemAppearance() -> Int {
        // In iOS, we default to "follow system" since individual apps
        // don't have access to the system-wide appearance setting
        // The actual appearance is determined by UITraitCollection
        0 // Always return "follow system" as default
    }
    
    /// Gets the current active appearance based on system settings
    public static func getCurrentAppearance() -> UIUserInterfaceStyle {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            return windowScene.traitCollection.userInterfaceStyle
        }
        return .unspecified
    }
}