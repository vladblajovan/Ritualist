//
//  IconVisibilitySettingsView.swift
//  Ritualist
//
//  Dedicated settings page for configuring which icons appear on habit rows.
//

import SwiftUI
import RitualistCore

/// Icon visibility settings page for controlling habit row indicator icons
struct IconVisibilitySettingsView: View {
    // Icon visibility settings (persisted in UserDefaults)
    @AppStorage(UserDefaultsKeys.showTimeReminderIcon) private var showTimeReminderIcon = true
    @AppStorage(UserDefaultsKeys.showLocationIcon) private var showLocationIcon = true
    @AppStorage(UserDefaultsKeys.showScheduleIcon) private var showScheduleIcon = true
    @AppStorage(UserDefaultsKeys.showStreakAtRiskIcon) private var showStreakAtRiskIcon = true

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $showStreakAtRiskIcon) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Settings.showStreakAtRiskIcon)
                            Text(Strings.Components.streakAtRiskDesc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Text("🔥")
                            .font(.system(size: 18))
                    }
                }

                Toggle(isOn: $showTimeReminderIcon) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Settings.showTimeReminderIcon)
                            Text(Strings.Components.timeRemindersDesc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.orange)
                    }
                }

                Toggle(isOn: $showLocationIcon) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Settings.showLocationIcon)
                            Text(Strings.Components.locationRemindersDesc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "location.fill")
                            .foregroundColor(.purple)
                    }
                }

                Toggle(isOn: $showScheduleIcon) {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.Settings.showScheduleIcon)
                            Text(Strings.Components.scheduleIndicatorDesc)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } icon: {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundColor(.blue)
                    }
                }
            } footer: {
                Text(Strings.Settings.iconVisibilityFooter)
            }
        }
        .navigationTitle(Strings.Settings.sectionIconVisibility)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        IconVisibilitySettingsView()
    }
}
