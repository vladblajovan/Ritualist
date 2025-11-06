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

    /// Get currently monitored habit IDs (from in-memory tracking)
    func getMonitoredHabitIds() async -> [UUID]

    /// Get habit IDs that iOS CLLocationManager is actively monitoring (from system-level geofences)
    func getSystemMonitoredHabitIds() async -> [UUID]

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
        // This provides optimal balance between accuracy and battery consumption for geofences
        self.locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters

        // REQUIRED for background geofence monitoring
        // Must be paired with UIBackgroundModes "location" in Info.plist
        // Allows geofence events to fire even when app is backgrounded/killed
        self.locationManager.allowsBackgroundLocationUpdates = true

        // For region monitoring, this setting has minimal impact since we use geofences
        // Set to false to ensure consistent behavior across all scenarios
        self.locationManager.pausesLocationUpdatesAutomatically = false
    }

    // MARK: - LocationMonitoringService Implementation

    public func startMonitoring(habitId: UUID, configuration: LocationConfiguration) async throws {
        print("📍 [LocationMonitoring] Starting monitoring for habit \(habitId)")

        // Validate configuration
        guard configuration.isValid else {
            print("❌ [LocationMonitoring] Invalid configuration for habit \(habitId)")
            throw LocationError.invalidConfiguration("Invalid coordinates or radius")
        }

        // Check authorization status (includes location services enabled check)
        let authStatus = await getAuthorizationStatus()
        guard authStatus.canMonitorGeofences else {
            print("❌ [LocationMonitoring] Permission denied for habit \(habitId)")
            throw LocationError.permissionDenied
        }

        // Check if we've reached iOS geofence limit (20)
        if monitoredHabits.count >= 20 && monitoredHabits[habitId] == nil {
            print("❌ [LocationMonitoring] Geofence limit reached (20), cannot add habit \(habitId)")
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
            print("🔄 [LocationMonitoring] Updating existing monitoring for habit \(habitId)")
            locationManager.stopMonitoring(for: region)
        }

        // Start monitoring
        locationManager.startMonitoring(for: region)

        // Store configuration in memory
        monitoredHabits[habitId] = configuration

        print("✅ [LocationMonitoring] Now monitoring \(monitoredHabits.count) habit(s)")

        // Request initial state for logging/debugging purposes
        // Note: This does NOT trigger notifications - only actual boundary crossings do
        // Delayed by 500ms to avoid race condition with iOS's automatic state determination
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            locationManager.requestState(for: region)
            print("🔍 [LocationMonitoring] Requested state check for region: \(habitId)")
        }
    }

    public func stopMonitoring(habitId: UUID) async {
        guard monitoredHabits[habitId] != nil else {
            print("⚠️  [LocationMonitoring] Habit \(habitId) not currently monitored")
            return
        }

        print("🛑 [LocationMonitoring] Stopping monitoring for habit \(habitId)")

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            radius: 100,
            identifier: habitId.uuidString
        )

        locationManager.stopMonitoring(for: region)
        monitoredHabits.removeValue(forKey: habitId)

        print("✅ [LocationMonitoring] Now monitoring \(monitoredHabits.count) habit(s)")
    }

    public func stopAllMonitoring() async {
        print("🛑 [LocationMonitoring] Stopping all monitoring (\(locationManager.monitoredRegions.count) regions)")

        for monitoredRegion in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: monitoredRegion)
        }
        monitoredHabits.removeAll()

        print("✅ [LocationMonitoring] All monitoring stopped")
    }

    public func getMonitoredHabitIds() async -> [UUID] {
        return Array(monitoredHabits.keys)
    }

    public func getSystemMonitoredHabitIds() async -> [UUID] {
        // Get all regions iOS CLLocationManager is actively monitoring
        let monitoredRegions = locationManager.monitoredRegions

        // Convert region identifiers to UUIDs (our habit IDs)
        let habitIds = monitoredRegions.compactMap { region -> UUID? in
            return UUID(uuidString: region.identifier)
        }

        print("📋 [LocationMonitoring] iOS is monitoring \(habitIds.count) geofence regions")
        return habitIds
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
            print("⚠️  [LocationMonitoring] Invalid region or habit ID in geofence event")
            return
        }

        Task {
            print("📍 [LocationMonitoring] Geofence event: \(eventType) for habit \(habitId)")

            // Get configuration for this habit
            guard let configuration = await monitoredHabits[habitId] else {
                print("⚠️  [LocationMonitoring] No configuration found for habit \(habitId)")
                return
            }

            // Create geofence event
            let event = GeofenceEvent(
                habitId: habitId,
                eventType: eventType,
                timestamp: Date(),
                configuration: configuration,
                detectedLocation: location?.coordinate
            )

            // Check if event should trigger notification
            guard event.shouldTriggerNotification() else {
                print("⏭️  [LocationMonitoring] Skipping notification due to frequency rules")
                return
            }

            print("🔔 [LocationMonitoring] Triggering notification for habit \(habitId)")

            // Call event handler (which will update the database with new trigger dates)
            // The event handler (HandleGeofenceEventUseCase) will update the database
            await eventHandler?(event)

            // IMPORTANT: After the event handler updates the database, we need to sync
            // our in-memory state. However, the event handler updates the database,
            // so we update our in-memory state here to match.
            var updatedConfig = configuration
            switch eventType {
            case .entry:
                updatedConfig.lastEntryTriggerDate = Date()
            case .exit:
                updatedConfig.lastExitTriggerDate = Date()
            }
            await updateConfiguration(habitId: habitId, configuration: updatedConfig)

            print("✅ [LocationMonitoring] Event handled and configuration updated")
        }
    }

    private func updateConfiguration(habitId: UUID, configuration: LocationConfiguration) {
        monitoredHabits[habitId] = configuration
        print("🔄 [LocationMonitoring] Updated in-memory configuration for habit \(habitId)")
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

    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didDetermineState state: CLRegionState,
        for region: CLRegion
    ) {
        // State determination is ONLY for informational purposes
        // Do NOT trigger notifications - only actual boundary crossings (didEnter/didExit) should notify
        // This prevents false positives when app restarts while user is already inside a region
        print("📍 [LocationMonitoring] Determined initial state for region \(region.identifier): \(state.rawValue == 1 ? "inside" : state.rawValue == 2 ? "outside" : "unknown")")

        switch state {
        case .inside:
            print("🏠 [LocationMonitoring] Device is currently inside region (no notification - waiting for actual boundary crossing)")
        case .outside:
            print("🌍 [LocationMonitoring] Device is currently outside region (ready for entry event)")
        case .unknown:
            print("❓ [LocationMonitoring] Region state unknown - waiting for location update")
        @unknown default:
            print("⚠️  [LocationMonitoring] Unknown region state: \(state.rawValue)")
        }
    }
}
