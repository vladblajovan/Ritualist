import SwiftUI
import RitualistCore

/// A compact sheet that allows users to mark a completed binary habit as not completed.
/// This sheet provides a simple interface for reverting a habit's completion status.
public struct UncompleteHabitSheet: View {
    let habit: Habit
    let onUncomplete: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    public init(
        habit: Habit,
        onUncomplete: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.habit = habit
        self.onUncomplete = onUncomplete
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: Spacing.large) {
            // Habit info header
            VStack(spacing: Spacing.small) {
                Spacer()
                
                Text(habit.emoji ?? "")
                    .font(.system(size: 48))
                    .accessibilityHidden(true) // Decorative emoji
                
                Text(habit.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text(Strings.UncompleteHabitSheet.completed)
                    .font(.subheadline)
                    .foregroundColor(.green)
                
                Spacer()
            }
            .padding(.top, Spacing.medium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.UncompleteHabitSheet.headerAccessibilityLabel(habit.name))

            Spacer()

            // Action buttons
            VStack(spacing: Spacing.medium) {
                Button {
                    HapticFeedbackService.shared.trigger(.medium)
                    dismiss()
                    onUncomplete()
                } label: {
                    HStack {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .accessibilityHidden(true)
                        Text(Strings.UncompleteHabitSheet.markAsNotCompleted)
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.medium)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(CornerRadius.xlarge)
                }
                .accessibilityIdentifier(AccessibilityID.Sheet.uncompleteHabitConfirmButton)
                .accessibilityHint(Strings.UncompleteHabitSheet.markAsNotCompletedHint)

                Button {
                    dismiss()
                    onCancel()
                } label: {
                    Text(Strings.Common.cancel)
                        .font(.body.weight(.medium))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.medium)
                }
                .accessibilityIdentifier(AccessibilityID.Sheet.uncompleteHabitCancelButton)
                .accessibilityHint(Strings.UncompleteHabitSheet.cancelHint)
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.medium)
        }
        .accessibilityIdentifier(AccessibilityID.Sheet.uncompleteHabit)
        .background(.clear)
        .presentationDetents(isIPad ? [.medium] : [.height(280)])
        .presentationDragIndicator(.visible)
        .onAppear {
            // Announce sheet to VoiceOver for focus management
            DispatchQueue.main.asyncAfter(deadline: .now() + AccessibilityConfig.voiceOverAnnouncementDelay) {
                UIAccessibility.post(
                    notification: .screenChanged,
                    argument: Strings.UncompleteHabitSheet.screenChangedAnnouncement(habit.name)
                )
            }
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            UncompleteHabitSheet(
                habit: Habit(
                    id: UUID(),
                    name: "Morning Meditation",
                    emoji: "🧘",
                    kind: .binary,
                    unitLabel: nil,
                    dailyTarget: 1.0,
                    schedule: .daily,
                    isActive: true,
                    categoryId: nil,
                    suggestionId: nil
                ),
                onUncomplete: { print("Uncompleted") },
                onCancel: { print("Cancelled") }
            )
        }
}
