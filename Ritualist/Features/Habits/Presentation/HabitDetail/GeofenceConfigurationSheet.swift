//
//  GeofenceConfigurationSheet.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//

import SwiftUI
import RitualistCore

public struct GeofenceConfigurationSheet: View {
    @Bindable var vm: HabitDetailViewModel
    @Environment(\.dismiss) var dismiss

    @State private var radius: Double
    @State private var triggerType: GeofenceTrigger
    @State private var frequency: NotificationFrequency
    @State private var locationLabel: String
    @State private var cooldownMinutes: Int = NotificationFrequency.defaultCooldown

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
        _frequency = State(initialValue: config.frequency)
        _locationLabel = State(initialValue: config.locationLabel ?? "")

        if case .everyEntry(let minutes) = config.frequency {
            _cooldownMinutes = State(initialValue: minutes)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                RadiusSection(radius: $radius)
                TriggerTypeSection(triggerType: $triggerType)
                FrequencySection(frequency: $frequency, cooldownMinutes: $cooldownMinutes)
                LocationLabelSection(locationLabel: $locationLabel)
            }
            .navigationTitle("Geofence Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
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

        // Update frequency based on selection
        if case .everyEntry = frequency {
            config.frequency = .everyEntry(cooldownMinutes: cooldownMinutes)
        } else {
            config.frequency = frequency
        }

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
                    Text("Radius")
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
            Text("Detection Area")
        } footer: {
            Text("The distance from the location where notifications will trigger.")
        }
    }
}

// MARK: - Trigger Type Section

private struct TriggerTypeSection: View {
    @Binding var triggerType: GeofenceTrigger

    var body: some View {
        Section {
            Picker("Trigger", selection: $triggerType) {
                ForEach([GeofenceTrigger.entry, .exit, .both], id: \.self) { trigger in
                    HStack {
                        Image(systemName: iconForTrigger(trigger))
                        Text(trigger.displayName)
                    }
                    .tag(trigger)
                }
            }
            .pickerStyle(.menu)
        } header: {
            Text("When to Notify")
        } footer: {
            Text(triggerDescription)
        }
    }

    private var triggerDescription: String {
        switch triggerType {
        case .entry:
            return "Notify when you arrive at the location."
        case .exit:
            return "Notify when you leave the location."
        case .both:
            return "Notify when you arrive and when you leave."
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
    @Binding var frequency: NotificationFrequency
    @Binding var cooldownMinutes: Int

    @State private var isOncePerDay: Bool

    init(frequency: Binding<NotificationFrequency>, cooldownMinutes: Binding<Int>) {
        self._frequency = frequency
        self._cooldownMinutes = cooldownMinutes

        // Initialize toggle state
        _isOncePerDay = State(initialValue: {
            switch frequency.wrappedValue {
            case .oncePerDay: return true
            case .everyEntry: return false
            }
        }())
    }

    var body: some View {
        Section {
            Toggle("Once Per Day", isOn: $isOncePerDay)
                .onChange(of: isOncePerDay) { _, newValue in
                    frequency = newValue ? .oncePerDay : .everyEntry(cooldownMinutes: cooldownMinutes)
                }

            if !isOncePerDay {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Cooldown Period")
                        Spacer()
                        Text("\(cooldownMinutes) min")
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(cooldownMinutes) },
                            set: { cooldownMinutes = Int($0) }
                        ),
                        in: 5...120,
                        step: 5
                    )

                    HStack {
                        Text("5 min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("120 min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text("Notification Frequency")
        } footer: {
            if isOncePerDay {
                Text("You'll receive only one notification per day, even if you enter/exit multiple times.")
            } else {
                Text("You'll receive a notification every time you trigger the geofence, with a \(cooldownMinutes)-minute minimum between notifications.")
            }
        }
    }
}

// MARK: - Location Label Section

private struct LocationLabelSection: View {
    @Binding var locationLabel: String

    var body: some View {
        Section {
            TextField("Optional", text: $locationLabel)
        } header: {
            Text("Location Name")
        } footer: {
            Text("Give this location a name (e.g., 'Home', 'Gym', 'Office')")
        }
    }
}
