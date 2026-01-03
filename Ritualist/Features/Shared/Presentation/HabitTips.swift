import TipKit
import SwiftUI

/// Tip to inform users about the circular progress indicator in the header
/// Shows on app start to explain the avatar circle tracks daily progress
struct CircleProgressTip: Tip {
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
/// Shows when: user has at least 1 incomplete habit (no other conditions)
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
}

/// Tip to inform users they can tap completed habits to adjust progress
/// Shows when: user has at least 1 completed habit AND (first tip dismissed OR habit completed)
struct TapCompletedHabitTip: Tip {
    /// Event triggered when user completes a habit OR dismisses the first tip
    /// We use a single event that gets donated in both cases to achieve OR logic
    static let shouldShowCompletedTip = Tips.Event(id: "shouldShowCompletedTip")

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
