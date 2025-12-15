//
//  MapLocationPickerView.swift
//  Ritualist
//
//  Full-screen map for selecting geofence center location with inline configuration.
//

import SwiftUI
import MapKit
import RitualistCore

public struct MapLocationPickerView: View {
    // MARK: - Constants

    private enum MapConstants {
        static let defaultSpanDelta: Double = 0.01
        static let minimumSpanDelta: Double = 0.002
    }

    @Bindable var vm: HabitDetailViewModel
    @Environment(\.dismiss) var dismiss

    // Map state
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var isSearching = false

    // Configuration state (local, synced on Done)
    @State private var radius: Double = LocationConfiguration.defaultRadius
    @State private var triggerType: GeofenceTrigger = .entry
    @State private var frequencyPreset: FrequencyPreset = .oncePerDay
    @State private var locationLabel: String = ""

    // Bottom card state
    @State private var showConfigCard = false

    private let locationManager = CLLocationManager()

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map View - uses radius binding for real-time circle updates
                MapView(
                    selectedCoordinate: $selectedCoordinate,
                    position: $position,
                    radius: radius,
                    onCoordinateSelected: { coordinate in
                        handleLocationSelected(coordinate)
                    }
                )
                .ignoresSafeArea()

                // Search Bar Overlay
                VStack {
                    SearchBarOverlay(searchText: $searchText, isSearching: $isSearching, onSearch: handleSearch)
                        .padding()

                    Spacer()

                    // Instructional banner when no location is selected
                    if selectedCoordinate == nil {
                        instructionalBanner()
                            .padding()
                    }
                }

                // Current Location Button (floating, top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            selectCurrentLocation()
                        } label: {
                            Image(systemName: "location.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.blue)
                                .clipShape(Circle())
                                .shadow(radius: 4)
                        }
                        .padding(.trailing)
                    }
                    .padding(.top, 80) // Below search bar
                    Spacer()
                }
            }
            .navigationTitle(Strings.Location.selectLocation)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Button.cancel) {
                        handleCancel()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.Button.done) {
                        saveConfiguration()
                        dismiss()
                    }
                    .disabled(selectedCoordinate == nil)
                }
            }
            .sheet(isPresented: $showConfigCard) {
                LocationConfigCard(
                    radius: $radius,
                    triggerType: $triggerType,
                    frequencyPreset: $frequencyPreset,
                    locationLabel: $locationLabel,
                    onDone: {
                        showConfigCard = false
                    }
                )
                .presentationDetents([.fraction(0.4), .fraction(0.75)])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .interactiveDismissDisabled(false)
            }
            .onAppear {
                loadExistingConfiguration()
            }
        }
    }

    // MARK: - Location Selection

    private func handleLocationSelected(_ coordinate: CLLocationCoordinate2D) {
        // Sync coordinate to config immediately
        syncCoordinateToConfig(coordinate)

        // Show config card if not already showing
        if !showConfigCard {
            showConfigCard = true
        }
    }

    private func selectCurrentLocation() {
        guard let location = locationManager.location else {
            position = .userLocation(followsHeading: false, fallback: .automatic)
            return
        }

        let coordinate = location.coordinate
        selectedCoordinate = coordinate
        handleLocationSelected(coordinate)

        position = .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(
                latitudeDelta: MapConstants.defaultSpanDelta,
                longitudeDelta: MapConstants.defaultSpanDelta
            )
        ))
    }

    // MARK: - Configuration Management

    private func loadExistingConfiguration() {
        guard let config = vm.locationConfiguration else {
            position = .userLocation(followsHeading: false, fallback: .automatic)
            return
        }

        // Load configuration values into local state
        radius = config.radius
        triggerType = config.triggerType
        frequencyPreset = FrequencyPreset.from(config.frequency)
        locationLabel = config.locationLabel ?? ""

        // Load location if not placeholder
        let isPlaceholder = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
        if !isPlaceholder {
            selectedCoordinate = config.coordinate
            position = .region(MKCoordinateRegion(
                center: config.coordinate,
                span: MKCoordinateSpan(
                    latitudeDelta: MapConstants.defaultSpanDelta,
                    longitudeDelta: MapConstants.defaultSpanDelta
                )
            ))
            // Show config card for existing location
            showConfigCard = true
        } else {
            position = .userLocation(followsHeading: false, fallback: .automatic)
        }
    }

    private func syncCoordinateToConfig(_ coordinate: CLLocationCoordinate2D) {
        if var config = vm.locationConfiguration {
            config.latitude = coordinate.latitude
            config.longitude = coordinate.longitude
            vm.updateLocationConfiguration(config)
        } else {
            let newConfig = LocationConfiguration.create(
                from: coordinate,
                radius: radius,
                triggerType: triggerType,
                frequency: frequencyPreset.toNotificationFrequency,
                isEnabled: true,
                locationLabel: locationLabel.isEmpty ? nil : locationLabel
            )
            vm.updateLocationConfiguration(newConfig)
        }
    }

    private func saveConfiguration() {
        guard let coordinate = selectedCoordinate else { return }

        let config = LocationConfiguration.create(
            from: coordinate,
            radius: radius,
            triggerType: triggerType,
            frequency: frequencyPreset.toNotificationFrequency,
            isEnabled: true,
            locationLabel: locationLabel.isEmpty ? nil : locationLabel
        )
        vm.updateLocationConfiguration(config)
    }

    private func handleCancel() {
        if let config = vm.locationConfiguration {
            let isPlaceholder = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
            if isPlaceholder {
                vm.locationConfiguration = nil
            }
        }
    }

    // MARK: - Search

    private func handleSearch(_ query: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(query) { placemarks, error in
            if let placemark = placemarks?.first, let location = placemark.location {
                selectedCoordinate = location.coordinate
                position = .region(MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: MapConstants.defaultSpanDelta,
                        longitudeDelta: MapConstants.defaultSpanDelta
                    )
                ))
                handleLocationSelected(location.coordinate)
            }
        }
    }

    // MARK: - UI Components

    @ViewBuilder
    private func instructionalBanner() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "hand.tap.fill")
                .font(.title2)
                .foregroundColor(.blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(Strings.Location.tapOnMap)
                    .font(.headline)
                Text(Strings.Location.selectCenterInstruction)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

// MARK: - Map View

private struct MapView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var position: MapCameraPosition
    let radius: Double
    var onCoordinateSelected: ((CLLocationCoordinate2D) -> Void)?

    var body: some View {
        MapReader { proxy in
            Map(position: $position, interactionModes: .all) {
                if let coordinate = selectedCoordinate {
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

                    // Radius circle - updates in real-time as slider changes
                    MapCircle(center: coordinate, radius: radius)
                        .foregroundStyle(Color.blue.opacity(0.2))
                        .stroke(Color.blue, lineWidth: 1)
                }
            }
            .mapStyle(.standard)
            .onTapGesture { location in
                if let coordinate = proxy.convert(location, from: .local) {
                    selectedCoordinate = coordinate
                    onCoordinateSelected?(coordinate)
                }
            }
        }
    }
}

// MARK: - Search Bar Overlay

private struct SearchBarOverlay: View {
    @Binding var searchText: String
    @Binding var isSearching: Bool
    let onSearch: (String) -> Void

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)

                TextField(Strings.Location.searchPlaceholder, text: $searchText)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        if !searchText.isEmpty {
                            onSearch(searchText)
                        }
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(8)
            .background(Color(.systemBackground))
            .cornerRadius(10)
            .shadow(radius: 2)
        }
    }
}
