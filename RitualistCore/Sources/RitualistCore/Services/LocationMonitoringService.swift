//
//  LocationMonitoringService.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Service for monitoring location and managing geofences using CoreLocation.
//  Wraps CLLocationManager to provide habit-specific geofence monitoring.
//

import Foundation
import CoreLocation

/// Protocol for location monitoring operations
public protocol LocationMonitoringService: AnyObject {
    /// Start monitoring a geofence for a specific habit
    func startMonitoring(habitId: UUID, configuration: LocationConfiguration) async throws

    /// Stop monitoring a geofence for a specific habit
    func stopMonitoring(habitId: UUID) async

    /// Stop monitoring all geofences
    func stopAllMonitoring() async

    /// Get currently monitored habit IDs
    func getMonitoredHabitIds() async -> [UUID]

    /// Get authorization status for location services
    func getAuthorizationStatus() async -> LocationAuthorizationStatus

    /// Set the event handler for geofence events
    func setEventHandler(_ handler: @escaping (GeofenceEvent) async -> Void)
}

/// Implementation of LocationMonitoringService using CoreLocation
@MainActor
public final class DefaultLocationMonitoringService: NSObject, LocationMonitoringService {
    // MARK: - Properties

    private let locationManager: CLLocationManager
    private var monitoredHabits: [UUID: LocationConfiguration] = [:]
    private var eventHandler: ((GeofenceEvent) async -> Void)?

    // MARK: - Initialization

    public override init() {
        self.locationManager = CLLocationManager()
        super.init()
        self.locationManager.delegate = self
        // Use kCLLocationAccuracyHundredMeters for battery efficiency
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // Allow background monitoring
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - LocationMonitoringService Implementation

    public func startMonitoring(habitId: UUID, configuration: LocationConfiguration) async throws {
        // Validate configuration
        guard configuration.isValid else {
            throw LocationError.invalidConfiguration("Invalid coordinates or radius")
        }

        // Check if location services are enabled
        guard CLLocationManager.locationServicesEnabled() else {
            throw LocationError.locationServicesDisabled
        }

        // Check authorization status
        let authStatus = await getAuthorizationStatus()
        guard authStatus.canMonitorGeofences else {
            throw LocationError.permissionDenied
        }

        // Check if we've reached iOS geofence limit (20)
        if monitoredHabits.count >= 20 && monitoredHabits[habitId] == nil {
            throw LocationError.geofenceLimitReached
        }

        // Create geofence region
        let region = CLCircularRegion(
            center: configuration.coordinate,
            radius: configuration.radius,
            identifier: habitId.uuidString
        )

        // Configure region monitoring triggers
        switch configuration.triggerType {
        case .entry:
            region.notifyOnEntry = true
            region.notifyOnExit = false
        case .exit:
            region.notifyOnEntry = false
            region.notifyOnExit = true
        case .both:
            region.notifyOnEntry = true
            region.notifyOnExit = true
        }

        // Stop existing monitoring if already monitoring this habit
        if monitoredHabits[habitId] != nil {
            locationManager.stopMonitoring(for: region)
        }

        // Start monitoring
        locationManager.startMonitoring(for: region)

        // Store configuration
        monitoredHabits[habitId] = configuration
    }

    public func stopMonitoring(habitId: UUID) async {
        guard monitoredHabits[habitId] != nil else { return }

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            radius: 100,
            identifier: habitId.uuidString
        )

        locationManager.stopMonitoring(for: region)
        monitoredHabits.removeValue(forKey: habitId)
    }

    public func stopAllMonitoring() async {
        for monitoredRegion in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: monitoredRegion)
        }
        monitoredHabits.removeAll()
    }

    public func getMonitoredHabitIds() async -> [UUID] {
        return Array(monitoredHabits.keys)
    }

    public func getAuthorizationStatus() async -> LocationAuthorizationStatus {
        return convertAuthorizationStatus(locationManager.authorizationStatus)
    }

    public func setEventHandler(_ handler: @escaping (GeofenceEvent) async -> Void) {
        self.eventHandler = handler
    }

    // MARK: - Private Helpers

    nonisolated private func convertAuthorizationStatus(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorizedWhenInUse:
            return .authorizedWhenInUse
        case .authorizedAlways:
            return .authorizedAlways
        @unknown default:
            return .notDetermined
        }
    }

    nonisolated private func handleGeofenceEvent(
        region: CLRegion,
        eventType: GeofenceEventType,
        location: CLLocation?
    ) {
        guard let circularRegion = region as? CLCircularRegion,
              let habitId = UUID(uuidString: region.identifier) else {
            return
        }

        Task {
            // Get configuration for this habit
            guard let configuration = await monitoredHabits[habitId] else { return }

            // Create geofence event
            let event = GeofenceEvent(
                habitId: habitId,
                eventType: eventType,
                timestamp: Date(),
                configuration: configuration,
                detectedLocation: location?.coordinate
            )

            // Check if event should trigger notification
            guard event.shouldTriggerNotification() else { return }

            // Call event handler
            await eventHandler?(event)

            // Update last trigger date for this specific event type
            var updatedConfig = configuration
            switch eventType {
            case .entry:
                updatedConfig.lastEntryTriggerDate = Date()
            case .exit:
                updatedConfig.lastExitTriggerDate = Date()
            }
            await updateConfiguration(habitId: habitId, configuration: updatedConfig)
        }
    }

    private func updateConfiguration(habitId: UUID, configuration: LocationConfiguration) {
        monitoredHabits[habitId] = configuration
    }
}

// MARK: - CLLocationManagerDelegate

extension DefaultLocationMonitoringService: CLLocationManagerDelegate {
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didEnterRegion region: CLRegion
    ) {
        handleGeofenceEvent(region: region, eventType: .entry, location: manager.location)
    }

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didExitRegion region: CLRegion
    ) {
        handleGeofenceEvent(region: region, eventType: .exit, location: manager.location)
    }

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        monitoringDidFailFor region: CLRegion?,
        withError error: Error
    ) {
        print("❌ [LocationMonitoring] Failed to monitor region \(region?.identifier ?? "unknown"): \(error)")

        // Optionally notify about monitoring failure
        if let region = region,
           let habitId = UUID(uuidString: region.identifier) {
            Task {
                // Remove from monitored habits since monitoring failed
                await stopMonitoring(habitId: habitId)
            }
        }
    }

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didStartMonitoringFor region: CLRegion
    ) {
        print("✅ [LocationMonitoring] Started monitoring region: \(region.identifier)")
    }

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = convertAuthorizationStatus(manager.authorizationStatus)
        print("🔐 [LocationMonitoring] Authorization changed to: \(status)")

        // If permission was revoked, stop all monitoring
        if !status.canMonitorGeofences {
            Task {
                await stopAllMonitoring()
            }
        }
    }
}
