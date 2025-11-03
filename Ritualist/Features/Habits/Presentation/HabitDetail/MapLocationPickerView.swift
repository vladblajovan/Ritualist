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
    @Bindable var vm: HabitDetailViewModel
    @Environment(\.dismiss) var dismiss

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var searchText = ""
    @State private var isSearching = false

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
            }
            .navigationTitle("Select Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveLocation()
                        dismiss()
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
        }
    }

    // MARK: - Helper Methods

    private func loadExistingLocation() {
        if let config = vm.locationConfiguration {
            // Only load if this is a real coordinate (not the placeholder 0,0)
            let isPlaceholder = config.coordinate.latitude == 0 && config.coordinate.longitude == 0
            if !isPlaceholder {
                selectedCoordinate = config.coordinate
                position = .region(MKCoordinateRegion(
                    center: config.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
            // If placeholder, keep position as .automatic to show user's location
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
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    }

    private func saveLocation() {
        guard let coordinate = selectedCoordinate else { return }

        if var config = vm.locationConfiguration {
            // Update existing configuration with new coordinates
            config.latitude = coordinate.latitude
            config.longitude = coordinate.longitude
            Task {
                await vm.updateLocationConfiguration(config)
            }
        } else {
            // Create new configuration
            let newConfig = LocationConfiguration.create(
                from: coordinate,
                radius: LocationConfiguration.defaultRadius,
                triggerType: .entry,
                frequency: .oncePerDay,
                isEnabled: true
            )
            Task {
                await vm.updateLocationConfiguration(newConfig)
            }
        }
    }

    @ViewBuilder
    private func configureButton() -> some View {
        Button {
            vm.showGeofenceSettings = true
        } label: {
            HStack {
                Image(systemName: "gear")
                Text("Configure Geofence Settings")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
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
                        .stroke(Color.blue, lineWidth: 2)
                }
            }
            .mapStyle(.standard)
            .onTapGesture { screenLocation in
                // Convert screen tap location to map coordinate
                if let coordinate = proxy.convert(screenLocation, from: .local) {
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

                TextField("Search for a location", text: $searchText)
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
