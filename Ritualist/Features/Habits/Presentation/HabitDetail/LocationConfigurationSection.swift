//
//  LocationConfigurationSection.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//

import SwiftUI
import RitualistCore
import MapKit

public struct LocationConfigurationSection: View {
    @Bindable var vm: HabitDetailViewModel

    public var body: some View {
        Section {
            // Enable/Disable Toggle
            Toggle(isOn: Binding(
                get: { vm.locationConfiguration?.isEnabled ?? false },
                set: { vm.toggleLocationEnabled($0) }
            )) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text("Location Reminders")
                }
            }

            // Show configuration UI when enabled
            if vm.locationConfiguration != nil && vm.locationConfiguration?.isEnabled == true {
                LocationSummaryRow(vm: vm)
                ConfigureLocationButton(vm: vm)
            } else if vm.locationConfiguration == nil || vm.locationConfiguration?.isEnabled == false {
                // Show explanation when disabled
                Text("Get reminded when you arrive at or leave a specific location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Show permission status if needed
            if vm.locationConfiguration?.isEnabled == true {
                LocationPermissionStatus(vm: vm)
            }
        } header: {
            Text("Location-Based")
        } footer: {
            if let config = vm.locationConfiguration, config.isEnabled {
                Text("Notifications will be sent when you \(config.triggerType.displayName.lowercased()) within \(Int(config.radius))m of the location.")
                    .font(.caption)
            }
        }
    }
}

// MARK: - Location Summary Row

private struct LocationSummaryRow: View {
    let vm: HabitDetailViewModel

    var body: some View {
        if let config = vm.locationConfiguration {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.red)
                    Text(config.locationLabel ?? "Selected Location")
                        .font(.body)
                }

                HStack(spacing: 12) {
                    Label("\(Int(config.radius))m", systemImage: "circle.dashed")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(config.triggerType.displayName, systemImage: triggerIcon(for: config.triggerType))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Label(config.frequency.displayName, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func triggerIcon(for trigger: GeofenceTrigger) -> String {
        switch trigger {
        case .entry: return "arrow.down.circle"
        case .exit: return "arrow.up.circle"
        case .both: return "arrow.up.arrow.down.circle"
        }
    }
}

// MARK: - Configure Location Button

private struct ConfigureLocationButton: View {
    @Bindable var vm: HabitDetailViewModel

    var body: some View {
        Button {
            vm.showMapPicker = true
        } label: {
            HStack {
                Image(systemName: "map")
                Text(vm.locationConfiguration == nil ? "Set Location" : "Change Location")
            }
        }
        .sheet(isPresented: $vm.showMapPicker) {
            MapLocationPickerView(vm: vm)
        }
    }
}

// MARK: - Location Permission Status

private struct LocationPermissionStatus: View {
    let vm: HabitDetailViewModel

    var body: some View {
        switch vm.locationAuthStatus {
        case .notDetermined:
            RequestPermissionRow(vm: vm, message: "Location permission required")

        case .authorizedWhenInUse:
            RequestPermissionRow(
                vm: vm,
                message: "Grant 'Always' permission for background monitoring",
                requestAlways: true
            )

        case .denied, .restricted:
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("Location permission denied")
                    .font(.caption)

                Spacer()

                Button("Settings") {
                    Task {
                        await vm.requestLocationPermission(requestAlways: false)
                    }
                }
                .font(.caption)
            }

        case .authorizedAlways:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Location access granted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Request Permission Row

private struct RequestPermissionRow: View {
    let vm: HabitDetailViewModel
    let message: String
    var requestAlways: Bool = false

    var body: some View {
        Button {
            Task {
                _ = await vm.requestLocationPermission(requestAlways: requestAlways)
            }
        } label: {
            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(.blue)
                Text(message)
                    .font(.caption)

                Spacer()

                if vm.isRequestingLocationPermission {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
