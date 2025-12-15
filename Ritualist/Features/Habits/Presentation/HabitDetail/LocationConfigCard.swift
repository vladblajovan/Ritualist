//
//  LocationConfigCard.swift
//  Ritualist
//
//  Modern bottom card overlay for location configuration.
//  Inspired by Apple Maps with refined visual design.
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

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header with location name
                LocationHeader(
                    locationLabel: $locationLabel
                )

                // Quick stats summary
                QuickStatsSummary(
                    radius: radius,
                    triggerType: triggerType,
                    frequency: frequencyPreset
                )

                // Configuration sections
                VStack(spacing: 20) {
                    // Radius control
                    RadiusControl(radius: $radius)

                    // Trigger type selection
                    TriggerSelection(selection: $triggerType)

                    // Frequency selection
                    FrequencySelection(selection: $frequencyPreset)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Location Header

private struct LocationHeader: View {
    @Binding var locationLabel: String
    @FocusState private var isLabelFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Location pin icon
            ZStack {
                Circle()
                    .fill(AppColors.brand.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.brand)
            }

            // Editable location name
            TextField("Name this location", text: $locationLabel)
                .font(.title3.weight(.semibold))
                .focused($isLabelFocused)
                .submitLabel(.done)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(.systemGray6).opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(AppColors.brand.opacity(isLabelFocused ? 0.5 : 0), lineWidth: 1.5)
                )
                .animation(.easeInOut(duration: 0.2), value: isLabelFocused)
        }
        .padding(.top, 8)
    }
}

// MARK: - Quick Stats Summary

private struct QuickStatsSummary: View {
    let radius: Double
    let triggerType: GeofenceTrigger
    let frequency: FrequencyPreset

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                StatPill(
                    icon: "circle.dashed",
                    value: "\(Int(radius))m",
                    color: .orange
                )

                StatPill(
                    icon: triggerIcon,
                    value: triggerShortName,
                    color: .green
                )

                StatPill(
                    icon: "clock",
                    value: frequency.shortName,
                    color: .purple
                )
            }
            .padding(.horizontal, 2)
        }
    }

    private var triggerIcon: String {
        switch triggerType {
        case .entry: return "arrow.down.circle"
        case .exit: return "arrow.up.circle"
        case .both: return "arrow.up.arrow.down.circle"
        }
    }

    private var triggerShortName: String {
        switch triggerType {
        case .entry: return "Arriving"
        case .exit: return "Leaving"
        case .both: return "Arriving & Leaving"
        }
    }
}

private struct StatPill: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(color)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Radius Control

private struct RadiusControl: View {
    @Binding var radius: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            SectionHeader(title: Strings.Location.detectionArea)

            VStack(spacing: 8) {
                // Radius value display
                HStack {
                    Text("\(Int(radius))")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("meters")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 2)
                }
                .frame(maxWidth: .infinity, alignment: .center)

                // Custom slider
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track background
                        Capsule()
                            .fill(Color(.systemGray5))
                            .frame(height: 8)

                        // Filled track
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [AppColors.brand.opacity(0.7), AppColors.brand],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: sliderPosition(in: geometry.size.width), height: 8)

                        // Thumb
                        Circle()
                            .fill(.white)
                            .frame(width: 28, height: 28)
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                            .overlay(
                                Circle()
                                    .fill(AppColors.brand)
                                    .frame(width: 12, height: 12)
                            )
                            .offset(x: sliderPosition(in: geometry.size.width) - 14)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateRadius(from: value.location.x, in: geometry.size.width)
                            }
                    )
                }
                .frame(height: 28)

                // Min/Max labels
                HStack {
                    Text("\(Int(LocationConfiguration.minimumRadius))m")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    Text("\(Int(LocationConfiguration.maximumRadius))m")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Detection radius")
        .accessibilityValue("\(Int(radius)) meters")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                radius = min(radius + 10, LocationConfiguration.maximumRadius)
            case .decrement:
                radius = max(radius - 10, LocationConfiguration.minimumRadius)
            @unknown default:
                break
            }
        }
    }

    private func sliderPosition(in width: CGFloat) -> CGFloat {
        let range = LocationConfiguration.maximumRadius - LocationConfiguration.minimumRadius
        let percentage = (radius - LocationConfiguration.minimumRadius) / range
        return CGFloat(percentage) * width
    }

    private func updateRadius(from x: CGFloat, in width: CGFloat) {
        let percentage = max(0, min(1, x / width))
        let range = LocationConfiguration.maximumRadius - LocationConfiguration.minimumRadius
        let newValue = LocationConfiguration.minimumRadius + (range * Double(percentage))
        radius = (newValue / 10).rounded() * 10 // Snap to 10m increments
    }
}

// MARK: - Trigger Selection

private struct TriggerSelection: View {
    @Binding var selection: GeofenceTrigger

    private let triggers: [(GeofenceTrigger, String, String)] = [
        (.entry, "arrow.down.to.line", "Arriving"),
        (.exit, "arrow.up.to.line", "Leaving"),
        (.both, "arrow.up.arrow.down", "Arriving & Leaving")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: Strings.Location.whenToNotify)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(triggers, id: \.0) { trigger, icon, label in
                        TriggerChip(
                            icon: icon,
                            label: label,
                            isSelected: selection == trigger,
                            action: { selection = trigger }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

private struct TriggerChip: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(label)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? AppColors.brand : Color(.secondarySystemGroupedBackground))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Frequency Selection

private struct FrequencySelection: View {
    @Binding var selection: FrequencyPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: Strings.Location.notificationFrequency)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FrequencyPreset.allCases) { preset in
                        FrequencyChip(
                            preset: preset,
                            isSelected: selection == preset,
                            action: { selection = preset }
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }
}

private struct FrequencyChip: View {
    let preset: FrequencyPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(preset.shortName)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? AppColors.brand : Color(.secondarySystemGroupedBackground))
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : Color(.separator).opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
