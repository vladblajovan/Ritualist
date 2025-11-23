//
//  GeofenceConfigurationSheet.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//

import SwiftUI
import RitualistCore

// MARK: - Constants

private enum CooldownConstants {
    static let minimumCooldown: Int = 5
    static let maximumCooldown: Int = 120
    static let cooldownStep: Int = 5
}

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
            // Enforce minimum cooldown
            _cooldownMinutes = State(initialValue: max(minutes, CooldownConstants.minimumCooldown))
        } else {
            _cooldownMinutes = State(initialValue: CooldownConstants.minimumCooldown)
        }
    }

    public var body: some View {
        NavigationStack {
            Form {
                LocationLabelSection(locationLabel: $locationLabel)
                RadiusSection(radius: $radius)
                TriggerTypeSection(triggerType: $triggerType)
                FrequencySection(frequency: $frequency, cooldownMinutes: $cooldownMinutes)
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
                    Text(Strings.Form.unitPlaceholder)
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
            Toggle(Strings.Location.oncePerDay, isOn: $isOncePerDay)
                .onChange(of: isOncePerDay) { _, newValue in
                    frequency = newValue ? .oncePerDay : .everyEntry(cooldownMinutes: cooldownMinutes)
                }

            if !isOncePerDay {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(Strings.Location.cooldownPeriod)
                        Spacer()
                        Text(Strings.Location.cooldownMinutes(cooldownMinutes))
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(cooldownMinutes) },
                            set: { cooldownMinutes = Int($0) }
                        ),
                        in: Double(CooldownConstants.minimumCooldown)...Double(CooldownConstants.maximumCooldown),
                        step: Double(CooldownConstants.cooldownStep)
                    )

                    HStack {
                        Text("\(CooldownConstants.minimumCooldown) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(CooldownConstants.maximumCooldown) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        } header: {
            Text(Strings.Location.notificationFrequency)
        } footer: {
            if isOncePerDay {
                Text(Strings.Location.frequencyOncePerDayFooter)
            } else {
                Text(Strings.Location.frequencyCooldownFooter(cooldownMinutes))
            }
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
