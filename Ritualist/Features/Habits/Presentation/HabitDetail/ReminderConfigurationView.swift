import SwiftUI
import RitualistCore

// MARK: - Reminder Configuration Components

public struct ReminderSection: View {
    @Bindable var vm: HabitDetailViewModel
    @State private var showingAddReminder = false

    public var body: some View {
        Section(Strings.Habits.sectionReminders) {
            if vm.reminders.isEmpty {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.secondary)
                    Text(Strings.Habits.noRemindersSet)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, Spacing.small)
            } else {
                ForEach(Array(vm.reminders.enumerated()), id: \.element) { index, reminder in
                    ReminderTimeRow(
                        reminder: reminder,
                        onDelete: {
                            vm.removeReminder(at: index)
                        }
                    )
                }
            }

            Button {
                HapticFeedbackService.shared.trigger(.light)
                if vm.isPremiumUser {
                    showingAddReminder = true
                } else {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await vm.showPaywall()
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text(Strings.Habits.addReminder)
                        .foregroundColor(.blue)
                    if !vm.isPremiumUser {
                        Spacer()
                        CrownProBadge()
                    }
                }
            }
            .sheet(isPresented: $showingAddReminder) {
                AddReminderSheet(vm: vm)
            }
        }
    }
}

public struct ReminderTimeRow: View {
    let reminder: ReminderTime
    let onDelete: () -> Void

    public var body: some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(.blue)
                .frame(width: 20)

            Text(formatTime(reminder))
                .font(.body)

            Spacer()

            Button {
                HapticFeedbackService.shared.trigger(.medium)
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 2)
    }

    private func formatTime(_ reminder: ReminderTime) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let date = CalendarUtils.currentLocalCalendar.date(
            from: DateComponents(hour: reminder.hour, minute: reminder.minute)
        ) ?? Date()
        return formatter.string(from: date)
    }
}

public struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: HabitDetailViewModel
    
    @State private var selectedTime = Date()
    
    public var body: some View {
        NavigationView {
            VStack(spacing: Spacing.large) {
                Text(Strings.Habits.addReminder)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top)

                DatePicker(
                    "Reminder Time",
                    selection: $selectedTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
                .padding(.horizontal)

                Text(Strings.Habits.reminderFooter)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Habits.add) {
                        let components = CalendarUtils.currentLocalCalendar.dateComponents([.hour, .minute], from: selectedTime)
                        if let hour = components.hour, let minute = components.minute {
                            vm.addReminder(hour: hour, minute: minute)
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

