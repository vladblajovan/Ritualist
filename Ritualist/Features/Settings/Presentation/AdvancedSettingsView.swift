import SwiftUI
import RitualistCore

/// Advanced Settings page for niche/technical settings
struct AdvancedSettingsView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var displayTimezoneMode: String

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Picker("Display Mode", selection: $displayTimezoneMode) {
                        Text("Original Time").tag("original")
                        Text("Current Time").tag("current")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: displayTimezoneMode) { _, newValue in
                        Task {
                            vm.profile.displayTimezoneMode = DisplayTimezoneMode.fromLegacyString(newValue)
                            _ = await vm.save()
                        }
                    }

                    Text(timezoneExplanationText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, Spacing.small)
            } header: {
                Text("Time Display")
            } footer: {
                Text("Advanced settings for how the app displays timestamps and dates.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var timezoneExplanationText: String {
        switch displayTimezoneMode {
        case "original":
            return "Show times as they were originally experienced"
        case "current":
            return "Show all times in your current device timezone"
        default:
            return "Choose how to display timestamps in the app"
        }
    }
}

// Preview requires full dependency injection setup
// Use SettingsRoot in app to view this page
