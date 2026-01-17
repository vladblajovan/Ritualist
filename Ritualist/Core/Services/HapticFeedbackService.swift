import UIKit
import SwiftUI

public enum HapticFeedbackType: Sendable {
    case success
    case error
    case warning
    case light
    case medium
    case heavy
    case selection
}

@MainActor
public final class HapticFeedbackService: ObservableObject {
    public static let shared = HapticFeedbackService()

    // MARK: - User Preferences

    private static let hapticEnabledKey = "hapticFeedbackEnabled"

    /// Whether haptic feedback is enabled globally.
    /// Defaults to true. Persisted in UserDefaults.
    @Published public var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Self.hapticEnabledKey)
        }
    }

    private init() {
        // Load saved preference, defaulting to true (enabled)
        if UserDefaults.standard.object(forKey: Self.hapticEnabledKey) != nil {
            self.isEnabled = UserDefaults.standard.bool(forKey: Self.hapticEnabledKey)
        } else {
            self.isEnabled = true
        }
    }

    // MARK: - Haptic Triggering

    public func trigger(_ type: HapticFeedbackType) {
        // Respect global haptic setting
        guard isEnabled else { return }

        switch type {
        case .success:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.success)

        case .error:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.error)

        case .warning:
            let feedback = UINotificationFeedbackGenerator()
            feedback.notificationOccurred(.warning)

        case .light:
            let feedback = UIImpactFeedbackGenerator(style: .light)
            feedback.impactOccurred()

        case .medium:
            let feedback = UIImpactFeedbackGenerator(style: .medium)
            feedback.impactOccurred()

        case .heavy:
            let feedback = UIImpactFeedbackGenerator(style: .heavy)
            feedback.impactOccurred()

        case .selection:
            let feedback = UISelectionFeedbackGenerator()
            feedback.selectionChanged()
        }
    }

    /// Trigger success haptic with optional pattern for different completion types
    public func triggerCompletion(type: CompletionType = .standard) {
        // Respect global haptic setting
        guard isEnabled else { return }

        switch type {
        case .standard:
            trigger(.success)
        case .milestone:
            // Double success for special achievements
            trigger(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.trigger(.success)
            }
        case .perfectDay:
            // Triple success for perfect day
            trigger(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.trigger(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.trigger(.success)
            }
        }
    }

    public enum CompletionType {
        case standard
        case milestone
        case perfectDay
    }
}
