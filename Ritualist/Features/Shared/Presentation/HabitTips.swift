import TipKit
import SwiftUI

// MARK: - Tip Event Identifiers

/// Centralized identifiers for TipKit events to prevent accidental changes.
/// TipKit persists state using these IDs - changing them will reset tip state for users.
public enum RitualistTipEvents {
    /// Event ID for when the avatar/progress circle tip is dismissed
    public static let avatarTipDismissed = "userWasShownAvatarTip"

    /// Event ID for when user should see the completed habit tip
    /// Donated when: TapHabitTip dismissed OR user completes a habit
    public static let shouldShowCompletedTip = "shouldShowCompletedTip"

    /// Event ID for when the completed habit tip is dismissed
    /// Reserved for future tip chaining
    public static let completedHabitTipDismissed = "completedHabitTipDismissed"
}

// MARK: - Tips

/// Tip to inform users about the circular progress indicator in the header
/// Shows FIRST on app start to explain the avatar circle tracks daily progress
struct CircleProgressTip: Tip {
    /// Event triggered when this tip is dismissed - gates the next tip in the flow
    static let userWasShownAvatarTip = Tips.Event(id: RitualistTipEvents.avatarTipDismissed)

    var title: Text {
        Text("Daily Progress")
    }

    var message: Text? {
        Text("This circle shows your overall habit completion for today. It fills up as you complete habits.")
    }

    var image: Image? {
        Image(systemName: "circle.dashed")
    }
}

/// Tip to inform users they can tap a habit to log progress or complete it
/// Shows SECOND: after CircleProgressTip is dismissed
struct TapHabitTip: Tip {
    var title: Text {
        Text("Tap to Log Progress")
    }

    var message: Text? {
        Text("Tap any habit to quickly log your progress or mark it complete.")
    }

    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }

    var rules: [Rule] {
        [
            // Only show after CircleProgressTip has been shown/dismissed
            #Rule(CircleProgressTip.userWasShownAvatarTip) { $0.donations.count >= 1 }
        ]
    }
}

/// Tip to inform users they can tap completed habits to adjust progress
/// Shows THIRD: after TapHabitTip is dismissed OR user completes a habit
struct TapCompletedHabitTip: Tip {
    /// Event triggered when user completes a habit OR TapHabitTip is dismissed
    static let shouldShowCompletedTip = Tips.Event(id: RitualistTipEvents.shouldShowCompletedTip)

    /// Event triggered when this tip is dismissed - reserved for future tip chaining
    static let wasDismissed = Tips.Event(id: RitualistTipEvents.completedHabitTipDismissed)

    var title: Text {
        Text("Adjust Completed Habits")
    }

    var message: Text? {
        Text("Tap completed habits to adjust progress or undo completion.")
    }

    var image: Image? {
        Image(systemName: "arrow.uturn.backward.circle.fill")
    }

    var rules: [Rule] {
        [
            // Show when event is donated (either from completing habit OR dismissing first tip)
            #Rule(Self.shouldShowCompletedTip) { $0.donations.count >= 1 }
        ]
    }
}
