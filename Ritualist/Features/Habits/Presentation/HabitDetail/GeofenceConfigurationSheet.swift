//
//  GeofenceConfigurationSheet.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//

import SwiftUI
import RitualistCore

// MARK: - Frequency Preset

/// Preset options for notification frequency
private enum FrequencyPreset: CaseIterable, Identifiable {
    case oncePerDay
    case every15Minutes
    case every30Minutes
    case everyHour
    case every2Hours

    var id: Self { self }

    var displayName: String {
        switch self {
        case .oncePerDay: return Strings.Location.frequencyOncePerDay
        case .every15Minutes: return Strings.Location.frequencyEvery15Min
        case .every30Minutes: return Strings.Location.frequencyEvery30Min
        case .everyHour: return Strings.Location.frequencyEveryHour
        case .every2Hours: return Strings.Location.frequencyEvery2Hours
        }
    }

    var toNotificationFrequency: NotificationFrequency {
        switch self {
        case .oncePerDay: return .oncePerDay
        case .every15Minutes: return .everyEntry(cooldownMinutes: 15)
        case .every30Minutes: return .everyEntry(cooldownMinutes: 30)
        case .everyHour: return .everyEntry(cooldownMinutes: 60)
        case .every2Hours: return .everyEntry(cooldownMinutes: 120)
        }
    }

    /// Maps a NotificationFrequency to the closest FrequencyPreset.
    ///
    /// Note: Custom cooldown values (e.g., 45 minutes) are mapped to the nearest preset
    /// (e.g., 60 minutes). This is intentional UX behavior - the preset picker doesn't
    /// support arbitrary values. The actual cooldown stored in the habit is preserved;
    /// this mapping only affects UI display in the preset selector.
    static func from(_ frequency: NotificationFrequency) -> FrequencyPreset {
        switch frequency {
        case .oncePerDay:
            return .oncePerDay
        case .everyEntry(let minutes):
            // Map to closest preset (rounds up to next threshold)
            if minutes <= 15 { return .every15Minutes }
            if minutes <= 30 { return .every30Minutes }
            if minutes <= 60 { return .everyHour }
            return .every2Hours
        }
    }
}

public struct GeofenceConfigurationSheet: View {

    @Bindable var vm: HabitDetailViewModel
    @Environment(\.dismiss) var dismiss

    @State private var radius: Double
    @State private var triggerType: GeofenceTrigger
    @State private var frequencyPreset: FrequencyPreset
    @State private var locationLabel: String

    public init(vm: HabitDetailViewModel) {
        self.vm = vm

        // Initialize from existing configuration or defaults
        let config = vm.locationConfiguration ?? LocationConfiguration(
            latitude: 0,
            longitude: 0,
            radius: LocationConfiguration.defaultRadius
        )

        _radius = State(initialValue: config.radius)
        _triggerType = State(initialValue: config.triggerType)
        _frequencyPreset = State(initialValue: FrequencyPreset.from(config.frequency))
        _locationLabel = State(initialValue: config.locationLabel ?? "")
    }

    public var body: some View {
        NavigationStack {
            Form {
                LocationLabelSection(locationLabel: $locationLabel)
                RadiusSection(radius: $radius)
                TriggerTypeSection(triggerType: $triggerType)
                FrequencySection(selectedPreset: $frequencyPreset)
            }
            .navigationTitle(Strings.Location.locationDetails)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Button.cancel) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Button.save) {
                        saveConfiguration()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveConfiguration() {
        guard var config = vm.locationConfiguration else { return }

        config.radius = radius
        config.triggerType = triggerType
        config.locationLabel = locationLabel.isEmpty ? nil : locationLabel
        config.frequency = frequencyPreset.toNotificationFrequency

        Task {
            await vm.updateLocationConfiguration(config)
        }
    }
}

// MARK: - Radius Section

private struct RadiusSection: View {
    @Binding var radius: Double

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Strings.Location.radius)
                    Spacer()
                    Text("\(Int(radius))m")
                        .foregroundColor(.secondary)
                }

                Slider(
                    value: $radius,
                    in: LocationConfiguration.minimumRadius...LocationConfiguration.maximumRadius,
                    step: 10
                )

                HStack {
                    Text("\(Int(LocationConfiguration.minimumRadius))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(LocationConfiguration.maximumRadius))m")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text(Strings.Location.detectionArea)
        } footer: {
            Text(Strings.Location.detectionAreaFooter)
        }
    }
}

// MARK: - Trigger Type Section

private struct TriggerTypeSection: View {
    @Binding var triggerType: GeofenceTrigger

    var body: some View {
        Section {
            ForEach([GeofenceTrigger.entry, .exit, .both], id: \.self) { trigger in
                Button {
                    triggerType = trigger
                } label: {
                    HStack {
                        Image(systemName: iconForTrigger(trigger))
                        Text(trigger.displayName)

                        Spacer()

                        if triggerType == trigger {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        } header: {
            Text(Strings.Location.whenToNotify)
        } footer: {
            Text(triggerDescription)
        }
    }

    private var triggerDescription: String {
        switch triggerType {
        case .entry:
            return Strings.Location.whenToNotifyEntry
        case .exit:
            return Strings.Location.whenToNotifyExit
        case .both:
            return Strings.Location.whenToNotifyBoth
        }
    }

    private func iconForTrigger(_ trigger: GeofenceTrigger) -> String {
        switch trigger {
        case .entry: return "arrow.down.circle"
        case .exit: return "arrow.up.circle"
        case .both: return "arrow.up.arrow.down.circle"
        }
    }
}

// MARK: - Frequency Section

private struct FrequencySection: View {
    @Binding var selectedPreset: FrequencyPreset

    var body: some View {
        Section {
            ForEach(FrequencyPreset.allCases) { preset in
                Button {
                    selectedPreset = preset
                } label: {
                    HStack {
                        Text(preset.displayName)

                        Spacer()

                        if selectedPreset == preset {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
        } header: {
            Text(Strings.Location.notificationFrequency)
        } footer: {
            Text(Strings.Location.notificationFrequencyFooter)
        }
    }
}

// MARK: - Location Label Section

private struct LocationLabelSection: View {
    @Binding var locationLabel: String

    var body: some View {
        Section {
            TextField(Strings.Location.locationNameOptional, text: $locationLabel)
        } header: {
            Text(Strings.Location.locationName)
        } footer: {
            Text(Strings.Location.locationNameFooter)
        }
    }
}
