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
                LocationMapPreview(vm: vm)
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

// MARK: - Location Map Preview

private struct LocationMapPreview: View {
    @Bindable var vm: HabitDetailViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    var body: some View {
        if let config = vm.locationConfiguration {
            VStack(spacing: 0) {
                // Static map preview
                Button {
                    vm.showMapPicker = true
                } label: {
                    Map(position: $cameraPosition, interactionModes: []) {
                        // Pin marker
                        Annotation("", coordinate: config.coordinate) {
                            ZStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 30, height: 30)

                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            }
                        }

                        // Radius circle
                        MapCircle(center: config.coordinate, radius: config.radius)
                            .foregroundStyle(Color.blue.opacity(0.2))
                            .stroke(Color.blue, lineWidth: 2)
                    }
                    .mapStyle(.standard)
                    .frame(height: 200)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onAppear {
                        // Center map on configured location with appropriate zoom
                        updateCameraPosition(for: config)
                    }
                    .onChange(of: vm.locationConfiguration) { _, newConfig in
                        // Update camera when location config changes
                        if let newConfig = newConfig {
                            updateCameraPosition(for: newConfig)
                        }
                    }
                }
                .buttonStyle(.plain)

                // Location info below map
                VStack(alignment: .leading, spacing: 8) {
                    Text(config.locationLabel ?? "Selected Location")
                        .font(.subheadline)
                        .fontWeight(.medium)

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
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 8)
            }
            .sheet(isPresented: $vm.showMapPicker) {
                MapLocationPickerView(vm: vm)
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

    private func calculateMapSpan(for radius: Double) -> MKCoordinateSpan {
        // Show 4x the radius (2x on each side) to fit the circle nicely in view
        // 1 degree latitude ≈ 111,000 meters
        let displayRadius = radius * 4
        let delta = displayRadius / 111_000.0
        return MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
    }

    private func updateCameraPosition(for config: LocationConfiguration) {
        let span = calculateMapSpan(for: config.radius)
        cameraPosition = .region(MKCoordinateRegion(
            center: config.coordinate,
            span: span
        ))
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
