//
//  MapLocationPickerView.swift
//  Ritualist
//
//  Created by Claude on 03.11.2025.
//

import SwiftUI
import MapKit
import RitualistCore

public struct MapLocationPickerView: View {
    // MARK: - Constants

    private enum MapConstants {
        static let defaultSpanDelta: Double = 0.01
        static let minimumSpanDelta: Double = 0.002
        static let minimumZoomDelta: Double = 0.001
        static let zoomMultiplier: Double = 2.0
        static let paddingMultiplier: CGFloat = 3.0
    }

    @Bindable var vm: HabitDetailViewModel
    @Environment(\.dismiss) var dismiss

    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var currentSpan: MKCoordinateSpan = MKCoordinateSpan(
        latitudeDelta: MapConstants.defaultSpanDelta,
        longitudeDelta: MapConstants.defaultSpanDelta
    )

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Map View
                MapView(
                    selectedCoordinate: $selectedCoordinate,
                    position: $position,
                    radius: vm.locationConfiguration?.radius ?? LocationConfiguration.defaultRadius
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

                    // Configuration Sheet Button
                    if selectedCoordinate != nil {
                        configureButton()
                            .padding()
                    }
                }

                // Current Location Button (floating, top-right)
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            position = .userLocation(followsHeading: false, fallback: .automatic)
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

                // Zoom controls (floating, bottom-right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        VStack(spacing: 0) {
                            Button {
                                zoomIn()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Color(.systemBackground))
                            }

                            Divider()
                                .frame(width: 40)

                            Button {
                                zoomOut()
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .frame(width: 40, height: 40)
                                    .background(Color(.systemBackground))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.2), radius: 4)
                        .padding(.trailing)
                        .padding(.bottom, selectedCoordinate != nil ? 90 : 20) // Above configure button if shown
                    }
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
                        Task {
                            await saveLocation()
                            dismiss()
                        }
                    }
                    .disabled(selectedCoordinate == nil)
                }
            }
            .sheet(isPresented: $vm.showGeofenceSettings) {
                GeofenceConfigurationSheet(vm: vm)
            }
            .onAppear {
                loadExistingLocation()
            }
            .onChange(of: vm.locationConfiguration) { _, newConfig in
                // Sync selectedCoordinate when configuration changes (e.g., from GeofenceConfigurationSheet)
                if let config = newConfig {
                    let isPlaceholder = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
                    if !isPlaceholder {
                        selectedCoordinate = config.coordinate
                    }
                }
            }
        }
    }

    // MARK: - Helper Methods

    private func handleCancel() {
        // If this was a new location (placeholder), clear it to revert the toggle
        if let config = vm.locationConfiguration {
            let isPlaceholder = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
            if isPlaceholder {
                vm.locationConfiguration = nil
            }
        }
    }

    private func loadExistingLocation() {
        if let config = vm.locationConfiguration {
            // Only load if this is a real coordinate (not the placeholder 0,0)
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
            } else {
                // Placeholder config - try to center on user location
                position = .userLocation(followsHeading: false, fallback: .automatic)
            }
        } else {
            // No config - try to center on user location
            position = .userLocation(followsHeading: false, fallback: .automatic)
        }
    }

    private func handleSearch(_ query: String) {
        // Simple geocoding search
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
            }
        }
    }

    private func saveLocation() async {
        guard let coordinate = selectedCoordinate else { return }

        if var config = vm.locationConfiguration {
            // Only update coordinates if they've actually changed
            // This prevents overwriting other config changes (from GeofenceConfigurationSheet)
            // when the user didn't move the pin
            let coordinatesChanged = config.latitude != coordinate.latitude || config.longitude != coordinate.longitude

            if coordinatesChanged {
                config.latitude = coordinate.latitude
                config.longitude = coordinate.longitude
                await vm.updateLocationConfiguration(config)
            }
            // If coordinates haven't changed, no need to save (config already has latest changes from sheet)
        } else {
            // Create new configuration
            let newConfig = LocationConfiguration.create(
                from: coordinate,
                radius: LocationConfiguration.defaultRadius,
                triggerType: .entry,
                frequency: .oncePerDay,
                isEnabled: true
            )
            await vm.updateLocationConfiguration(newConfig)
        }
    }

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

    @ViewBuilder
    private func configureButton() -> some View {
        Button {
            vm.showGeofenceSettings = true
        } label: {
            HStack {
                Image(systemName: "gear")
                Text(Strings.Location.configureLocationDetails)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }

    private func zoomIn() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: max(currentSpan.latitudeDelta / MapConstants.zoomMultiplier, MapConstants.minimumZoomDelta),
            longitudeDelta: max(currentSpan.longitudeDelta / MapConstants.zoomMultiplier, MapConstants.minimumZoomDelta)
        )
        currentSpan = newSpan

        if let center = selectedCoordinate {
            position = .region(MKCoordinateRegion(center: center, span: newSpan))
        }
    }

    private func zoomOut() {
        let newSpan = MKCoordinateSpan(
            latitudeDelta: min(currentSpan.latitudeDelta * MapConstants.zoomMultiplier, 180),
            longitudeDelta: min(currentSpan.longitudeDelta * MapConstants.zoomMultiplier, 180)
        )
        currentSpan = newSpan

        if let center = selectedCoordinate {
            position = .region(MKCoordinateRegion(center: center, span: newSpan))
        }
    }
}

// MARK: - Map View

private struct MapView: View {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var position: MapCameraPosition
    let radius: Double

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

                    // Radius circle
                    MapCircle(center: coordinate, radius: radius)
                        .foregroundStyle(Color.blue.opacity(0.2))
                        .stroke(Color.blue, lineWidth: 1)
                }
            }
            .mapStyle(.standard)
            .onTapGesture { location in
                // Convert screen tap location to map coordinate
                if let coordinate = proxy.convert(location, from: .local) {
                    selectedCoordinate = coordinate
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

