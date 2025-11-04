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
            if let config = vm.locationConfiguration, config.isEnabled {
                // Use AsyncMapSnapshot - loads asynchronously without blocking UI
                VStack(spacing: 0) {
                    AsyncMapSnapshot(
                        coordinate: config.coordinate,
                        radius: config.radius,
                        locationLabel: config.locationLabel
                    ) {
                        vm.showMapPicker = true
                    }
                    .padding(.horizontal, 16)

                    // Configuration details below map
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.dashed")
                                .font(.caption)
                            Text("\(Int(config.radius))m")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: triggerIcon(for: config.triggerType))
                                .font(.caption)
                            Text(config.triggerType.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(config.frequency.displayName)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
                .sheet(isPresented: $vm.showMapPicker) {
                    MapLocationPickerView(vm: vm)
                }
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
                Text("Alerts when \(config.triggerType.displayName.lowercased()) within \(Int(config.radius))m")
                    .font(.caption)
            }
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
            EmptyView()
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
