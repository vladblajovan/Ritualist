import SwiftUI
import RitualistCore

/// A compact sheet that confirms marking a binary habit as completed.
/// Shown when tapping a notification for a binary habit to give clear feedback.
public struct CompleteHabitSheet: View {
    let habit: Habit
    let onComplete: () -> Void
    let onCancel: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }

    public init(
        habit: Habit,
        onComplete: @escaping () -> Void,
        onCancel: @escaping () -> Void = {}
    ) {
        self.habit = habit
        self.onComplete = onComplete
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

                Text(Strings.CompleteHabitSheet.notCompleted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.top, Spacing.medium)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Strings.CompleteHabitSheet.headerAccessibilityLabel(habit.name))

            Spacer()

            // Action buttons
            VStack(spacing: Spacing.medium) {
                Button {
                    HapticFeedbackService.shared.trigger(.medium)
                    dismiss()
                    onComplete()
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .accessibilityHidden(true) // Decorative icon
                        Text(Strings.CompleteHabitSheet.markAsCompleted)
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.medium)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(CornerRadius.xlarge)
                }
                .accessibilityIdentifier(AccessibilityID.Sheet.completeHabitConfirmButton)
                .accessibilityHint(Strings.CompleteHabitSheet.markAsCompletedHint)

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
                .accessibilityIdentifier(AccessibilityID.Sheet.completeHabitCancelButton)
                .accessibilityHint(Strings.CompleteHabitSheet.cancelHint)
            }
            .padding(.horizontal)
            .padding(.bottom, Spacing.medium)
        }
        .accessibilityIdentifier(AccessibilityID.Sheet.completeHabit)
        .background(.clear)
        .presentationDetents(isIPad ? [.medium] : [.height(280)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.ultraThinMaterial)
        .onAppear {
            // Announce sheet to VoiceOver for focus management
            DispatchQueue.main.asyncAfter(deadline: .now() + AccessibilityConfig.voiceOverAnnouncementDelay) {
                UIAccessibility.post(
                    notification: .screenChanged,
                    argument: Strings.CompleteHabitSheet.screenChangedAnnouncement(habit.name)
                )
            }
        }
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            CompleteHabitSheet(
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
                onComplete: { print("Completed") },
                onCancel: { print("Cancelled") }
            )
        }
}
