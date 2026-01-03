//
//  LocationConfigurationSection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 03.11.2025.
//

import SwiftUI
import RitualistCore
import MapKit

public struct LocationConfigurationSection: View {
    @Bindable var vm: HabitDetailViewModel

    public var body: some View {
        Section {
            // Enable/Disable Toggle (Premium Feature)
            Toggle(isOn: Binding(
                get: { vm.locationConfiguration?.isEnabled ?? false },
                set: { newValue in
                    if newValue && !vm.isPremiumUser {
                        // Show paywall when non-premium user tries to enable
                        Task {
                            await vm.showPaywall()
                        }
                    } else {
                        vm.toggleLocationEnabled(newValue)
                    }
                }
            )) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.purple)
                        .accessibilityHidden(true) // Decorative icon
                    Text("Location Reminders")
                    if !vm.isPremiumUser {
                        Spacer()
                        CrownProBadge()
                    }
                }
            }
            .accessibilityLabel("Location Reminders")
            .accessibilityHint((vm.locationConfiguration?.isEnabled ?? false) ? "Currently enabled. Double tap to disable location-based reminders." : "Currently disabled. Double tap to enable reminders when you arrive at or leave a location.")

            // Show configuration UI when enabled
            if let config = vm.locationConfiguration, config.isEnabled {
                // Use interactive Map instead of static snapshot
                VStack(spacing: 0) {
                    InteractiveMapPreview(
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
                .sheet(
                    isPresented: $vm.showMapPicker,
                    onDismiss: {
                        vm.handleMapPickerDismiss()
                    },
                    content: {
                        MapLocationPickerView(vm: vm)
                    }
                )
            } else if vm.locationConfiguration == nil || vm.locationConfiguration?.isEnabled == false {
                Text("Get reminded when you arrive at or leave a specific location")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if vm.locationConfiguration?.isEnabled == true {
                LocationPermissionStatus(vm: vm)
            }
        } header: {
            Text("Location-Based")
        } footer: {
            if vm.locationConfiguration?.isEnabled == true {
                Text("Notifications are automatically skipped if the habit is already completed.")
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
            RequestPermissionRow(
                vm: vm,
                message: "Grant 'Always' permission for background monitoring",
                requestAlways: true
            )

        case .authorizedWhenInUse:
            RequestPermissionRow(
                vm: vm,
                message: "Upgrade to 'Always' for background monitoring",
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
                        await vm.openLocationSettings()
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
                    .foregroundColor(.purple)
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

// MARK: - Interactive Map Preview

private struct InteractiveMapPreview: View {
    let coordinate: CLLocationCoordinate2D
    let radius: Double
    let locationLabel: String?
    let onTap: () -> Void

    @State private var position: MapCameraPosition

    init(coordinate: CLLocationCoordinate2D, radius: Double, locationLabel: String?, onTap: @escaping () -> Void) {
        self.coordinate = coordinate
        self.radius = radius
        self.locationLabel = locationLabel
        self.onTap = onTap
        // Calculate appropriate zoom level based on radius
        // We want the radius circle to be visible, so set span to show ~3x the radius
        let metersPerDegree = 111_000.0 // Approximate meters per degree of latitude
        let radiusInDegrees = (radius * 3) / metersPerDegree // 3x multiplier for padding
        let span = MKCoordinateSpan(
            latitudeDelta: max(radiusInDegrees, 0.002), // Minimum span for very small radii
            longitudeDelta: max(radiusInDegrees, 0.002)
        )
        // Initialize position with the coordinate
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: coordinate,
            span: span
        )))
    }

    var body: some View {
        Map(position: $position, interactionModes: [], selection: .constant(nil)) {
            // Pin marker
            Annotation("", coordinate: coordinate) {
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
            MapCircle(center: coordinate, radius: radius)
                .foregroundStyle(Color.blue.opacity(0.2))
                .stroke(Color.blue, lineWidth: 1)
        }
        .frame(height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            // Location name overlay
            if let label = locationLabel {
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.6))
                    )
                    .padding(.top, 12)
                    .padding(.trailing, 12)
                    .allowsHitTesting(false)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onAppear {
            updatePosition()
        }
        .onChange(of: coordinate.latitude) { _, _ in
            updatePosition()
        }
        .onChange(of: coordinate.longitude) { _, _ in
            updatePosition()
        }
        .onChange(of: radius) { _, _ in
            updatePosition()
        }
    }

    private func updatePosition() {
        // Calculate appropriate zoom level based on radius
        let metersPerDegree = 111_000.0 // Approximate meters per degree of latitude
        let radiusInDegrees = (radius * 3) / metersPerDegree // 3x multiplier for padding
        let span = MKCoordinateSpan(
            latitudeDelta: max(radiusInDegrees, 0.002), // Minimum span for very small radii
            longitudeDelta: max(radiusInDegrees, 0.002)
        )
        position = .region(MKCoordinateRegion(
            center: coordinate,
            span: span
        ))
    }
}
