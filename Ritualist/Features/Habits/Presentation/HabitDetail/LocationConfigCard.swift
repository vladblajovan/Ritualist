//
//  LocationConfigCard.swift
//  Ritualist
//
//  Bottom card overlay for location configuration (Apple Maps style).
//  Replaces the nested GeofenceConfigurationSheet with inline configuration.
//

import SwiftUI
import RitualistCore

// MARK: - Frequency Preset

/// Preset options for notification frequency
enum FrequencyPreset: CaseIterable, Identifiable {
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

    var shortName: String {
        switch self {
        case .oncePerDay: return "Once/day"
        case .every15Minutes: return "15 min"
        case .every30Minutes: return "30 min"
        case .everyHour: return "1 hour"
        case .every2Hours: return "2 hours"
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

    static func from(_ frequency: NotificationFrequency) -> FrequencyPreset {
        switch frequency {
        case .oncePerDay:
            return .oncePerDay
        case .everyEntry(let minutes):
            if minutes <= 15 { return .every15Minutes }
            if minutes <= 30 { return .every30Minutes }
            if minutes <= 60 { return .everyHour }
            return .every2Hours
        }
    }
}

// MARK: - Location Config Card

struct LocationConfigCard: View {
    @Binding var radius: Double
    @Binding var triggerType: GeofenceTrigger
    @Binding var frequencyPreset: FrequencyPreset
    @Binding var locationLabel: String

    let onDone: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Location Label
                LocationLabelField(text: $locationLabel)

                // Compact Summary Row (visible in collapsed state)
                CompactSummaryRow(
                    radius: radius,
                    triggerType: triggerType,
                    frequency: frequencyPreset
                )

                Divider()

                // Radius Slider
                RadiusSlider(radius: $radius)

                // Trigger Type Picker
                TriggerTypePicker(selection: $triggerType)

                // Frequency Picker
                FrequencyPicker(selection: $frequencyPreset)

                // Done Button
                Button(action: onDone) {
                    Text(Strings.Button.done)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }
}

// MARK: - Compact Summary Row

private struct CompactSummaryRow: View {
    let radius: Double
    let triggerType: GeofenceTrigger
    let frequency: FrequencyPreset

    var body: some View {
        HStack(spacing: 16) {
            // Radius
            HStack(spacing: 4) {
                Image(systemName: "circle.dashed")
                    .font(.caption)
                Text("\(Int(radius))m")
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)

            // Trigger
            HStack(spacing: 4) {
                Image(systemName: triggerIcon)
                    .font(.caption)
                Text(triggerType.displayName)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)

            // Frequency
            HStack(spacing: 4) {
                Image(systemName: "clock")
                    .font(.caption)
                Text(frequency.shortName)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var triggerIcon: String {
        switch triggerType {
        case .entry: return "arrow.down.circle"
        case .exit: return "arrow.up.circle"
        case .both: return "arrow.up.arrow.down.circle"
        }
    }
}

// MARK: - Location Label Field

private struct LocationLabelField: View {
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(Strings.Location.locationName)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            TextField(Strings.Location.locationNameOptional, text: $text)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.done)
        }
    }
}

// MARK: - Radius Slider

private struct RadiusSlider: View {
    @Binding var radius: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Strings.Location.detectionArea)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Spacer()
                Text("\(Int(radius))m")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }

            Slider(
                value: $radius,
                in: LocationConfiguration.minimumRadius...LocationConfiguration.maximumRadius,
                step: 10
            )
            .tint(.blue)
            .accessibilityLabel("Detection radius")
            .accessibilityValue("\(Int(radius)) meters")

            HStack {
                Text("\(Int(LocationConfiguration.minimumRadius))m")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("\(Int(LocationConfiguration.maximumRadius))m")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Trigger Type Picker

private struct TriggerTypePicker: View {
    @Binding var selection: GeofenceTrigger

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Location.whenToNotify)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            HStack(spacing: 8) {
                ForEach([GeofenceTrigger.entry, .exit, .both], id: \.self) { trigger in
                    TriggerButton(
                        trigger: trigger,
                        isSelected: selection == trigger,
                        action: { selection = trigger }
                    )
                }
            }
        }
    }
}

private struct TriggerButton: View {
    let trigger: GeofenceTrigger
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: iconName)
                    .font(.title3)
                Text(trigger.displayName)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray6))
            .foregroundColor(isSelected ? .blue : .primary)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        switch trigger {
        case .entry: return "arrow.down.circle"
        case .exit: return "arrow.up.circle"
        case .both: return "arrow.up.arrow.down.circle"
        }
    }
}

// MARK: - Frequency Picker

private struct FrequencyPicker: View {
    @Binding var selection: FrequencyPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Strings.Location.notificationFrequency)
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                ForEach(FrequencyPreset.allCases) { preset in
                    FrequencyRow(
                        preset: preset,
                        isSelected: selection == preset,
                        action: { selection = preset }
                    )

                    if preset != FrequencyPreset.allCases.last {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
    }
}

private struct FrequencyRow: View {
    let preset: FrequencyPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(preset.displayName)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
