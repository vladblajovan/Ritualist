import SwiftUI
import RitualistCore

// MARK: - Reminder Configuration Components

public struct ReminderSection: View {
    @Bindable var vm: HabitDetailViewModel
    @State private var showingAddReminder = false
    
    public var body: some View {
        Section("Reminders") {
            if vm.reminders.isEmpty {
                HStack {
                    Image(systemName: "bell.slash")
                        .foregroundColor(.secondary)
                    Text("No reminders set")
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.vertical, Spacing.small)
            } else {
                ForEach(Array(vm.reminders.enumerated()), id: \.offset) { index, reminder in
                    ReminderTimeRow(
                        reminder: reminder,
                        onDelete: {
                            vm.removeReminder(at: index)
                        }
                    )
                }
            }
            
            Button {
                showingAddReminder = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                    Text("Add Reminder")
                        .foregroundColor(.blue)
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
                Text("Add Reminder")
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
                
                Text("You'll receive a notification at this time with options to log your habit, snooze for 20 minutes, or dismiss. Notifications are automatically skipped if the habit is already completed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
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

