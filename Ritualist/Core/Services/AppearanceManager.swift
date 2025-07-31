import SwiftUI
import Combine

public final class AppearanceManager: ObservableObject {
    @Published public var currentAppearance: Int = 0 {
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
}