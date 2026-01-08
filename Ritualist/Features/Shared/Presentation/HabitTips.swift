import TipKit
import SwiftUI

// MARK: - Tip Event Identifiers

/// Centralized identifiers for TipKit events to prevent accidental changes.
/// TipKit persists state using these IDs - changing them will reset tip state for users.
public enum RitualistTipEvents {
    /// Event ID for when user closes Habits Assistant after onboarding
    public static let habitsAssistantClosed = "habitsAssistantClosedAfterOnboarding"

    /// Event ID for when user adds their first habit
    public static let firstHabitAdded = "userAddedFirstHabit"

    /// Event ID for when user completes a habit for the first time
    public static let firstHabitCompleted = "userCompletedFirstHabit"

    /// Event ID for when the completed habit tip is dismissed
    public static let completedHabitTipDismissed = "completedHabitTipDismissed"

    /// Event ID for when user should see the long-press tip
    public static let shouldShowLongPressTip = "shouldShowLongPressTip"

    /// Event ID for when long-press tip is dismissed - gates the avatar tip
    public static let longPressTipDismissed = "longPressTipDismissed"
}

// MARK: - Tips

/// Tip to inform users they can tap a habit to log progress or complete it
/// Shows FIRST: after user closes Habits Assistant post-onboarding AND has added first habit
struct TapHabitTip: Tip {
    /// Event triggered when Habits Assistant is closed after onboarding
    static let habitsAssistantClosed = Tips.Event(id: RitualistTipEvents.habitsAssistantClosed)

    /// Event triggered when user adds their first habit
    static let firstHabitAdded = Tips.Event(id: RitualistTipEvents.firstHabitAdded)

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
            // Only show after user closes Habits Assistant (post-onboarding)
            #Rule(Self.habitsAssistantClosed) { $0.donations.count >= 1 },
            // AND only after user has added their first habit
            #Rule(Self.firstHabitAdded) { $0.donations.count >= 1 }
        ]
    }
}

/// Tip to inform users they can tap completed habits to adjust progress
/// Shows SECOND: after user completes a habit for the first time
struct TapCompletedHabitTip: Tip {
    /// Event triggered when user completes a habit
    static let firstHabitCompleted = Tips.Event(id: RitualistTipEvents.firstHabitCompleted)

    /// Event triggered when this tip is dismissed - gates the long-press tip
    static let wasDismissed = Tips.Event(id: RitualistTipEvents.completedHabitTipDismissed)

    /// Action ID for the "Got it" button
    static let gotItActionId = "tapCompletedHabitTip.gotIt"

    var title: Text {
        Text("Adjust Completed Habits")
    }

    var message: Text? {
        Text("Tap completed habits to adjust progress or undo completion.")
    }

    var image: Image? {
        Image(systemName: "arrow.uturn.backward.circle.fill")
    }

    var actions: [Action] {
        [
            Action(id: Self.gotItActionId, title: "Got it")
        ]
    }

    var rules: [Rule] {
        [
            // Show only after user completes their first habit
            #Rule(Self.firstHabitCompleted) { $0.donations.count >= 1 }
        ]
    }
}

/// Tip to inform users they can long-press habits to quick-log without showing a sheet
/// Shows THIRD: after TapCompletedHabitTip is dismissed
struct LongPressLogTip: Tip {
    /// Event triggered when user should see this tip
    static let shouldShowLongPressTip = Tips.Event(id: RitualistTipEvents.shouldShowLongPressTip)

    /// Event triggered when this tip is dismissed - gates the avatar tip
    static let wasDismissed = Tips.Event(id: RitualistTipEvents.longPressTipDismissed)

    /// Action ID for the "Got it" button
    static let gotItActionId = "longPressLogTip.gotIt"

    var title: Text {
        Text("Quick Log with Long-Press")
    }

    var message: Text? {
        Text("Press and hold any habit to instantly log it without opening a sheet.")
    }

    var image: Image? {
        Image(systemName: "hand.tap.fill")
    }

    var actions: [Action] {
        [
            Action(id: Self.gotItActionId, title: "Got it")
        ]
    }

    var rules: [Rule] {
        [
            // Show when TapCompletedHabitTip is dismissed
            #Rule(Self.shouldShowLongPressTip) { $0.donations.count >= 1 }
        ]
    }
}

/// Tip to inform users about the circular progress indicator in the header
/// Shows LAST: after LongPressLogTip is dismissed
struct CircleProgressTip: Tip {
    /// Event triggered when LongPressLogTip is dismissed
    static let longPressTipDismissed = Tips.Event(id: RitualistTipEvents.longPressTipDismissed)

    var title: Text {
        Text("Daily Progress")
    }

    var message: Text? {
        Text("This circle shows your overall habit completion for today. It fills up as you complete habits.")
    }

    var image: Image? {
        Image(systemName: "circle.dashed")
    }

    var rules: [Rule] {
        [
            // Only show after LongPressLogTip has been dismissed
            #Rule(Self.longPressTipDismissed) { $0.donations.count >= 1 }
        ]
    }
}
