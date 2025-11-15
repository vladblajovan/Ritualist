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
    private let logger: DebugLogger

    // MARK: - Initialization

    public init(logger: DebugLogger) {
        self.locationManager = CLLocationManager()
        self.logger = logger
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
        logger.log(
            "📍 Starting geofence monitoring",
            level: .info,
            category: .location,
            metadata: ["habitId": habitId.uuidString]
        )

        // Validate configuration
        guard configuration.isValid else {
            logger.log(
                "❌ Invalid configuration",
                level: .error,
                category: .location,
                metadata: ["habitId": habitId.uuidString]
            )
            throw LocationError.invalidConfiguration("Invalid coordinates or radius")
        }

        // Check authorization status (includes location services enabled check)
        let authStatus = await getAuthorizationStatus()
        guard authStatus.canMonitorGeofences else {
            logger.log(
                "❌ Permission denied for geofence monitoring",
                level: .error,
                category: .location,
                metadata: ["habitId": habitId.uuidString, "status": String(describing: authStatus)]
            )
            throw LocationError.permissionDenied
        }

        // Check if we've reached iOS geofence limit (20)
        if monitoredHabits.count >= 20 && monitoredHabits[habitId] == nil {
            logger.log(
                "❌ Geofence limit reached",
                level: .error,
                category: .location,
                metadata: ["habitId": habitId.uuidString, "limit": 20, "current": monitoredHabits.count]
            )
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
            logger.log(
                "🔄 Updating existing geofence monitoring",
                level: .info,
                category: .location,
                metadata: ["habitId": habitId.uuidString]
            )
            locationManager.stopMonitoring(for: region)
        }

        // Start monitoring
        locationManager.startMonitoring(for: region)

        // Store configuration in memory
        monitoredHabits[habitId] = configuration

        logger.log(
            "✅ Geofence monitoring active",
            level: .info,
            category: .location,
            metadata: ["habitCount": monitoredHabits.count]
        )

        // Request initial state for logging/debugging purposes
        // Note: This does NOT trigger notifications - only actual boundary crossings do
        // Delayed by 500ms to avoid race condition with iOS's automatic state determination
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            locationManager.requestState(for: region)
            logger.log(
                "🔍 Requested initial state check",
                level: .debug,
                category: .location,
                metadata: ["habitId": habitId.uuidString]
            )
        }
    }

    public func stopMonitoring(habitId: UUID) async {
        guard monitoredHabits[habitId] != nil else {
            logger.log(
                "⚠️ Habit not currently monitored",
                level: .warning,
                category: .location,
                metadata: ["habitId": habitId.uuidString]
            )
            return
        }

        logger.log(
            "🛑 Stopping geofence monitoring",
            level: .info,
            category: .location,
            metadata: ["habitId": habitId.uuidString]
        )

        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            radius: 100,
            identifier: habitId.uuidString
        )

        locationManager.stopMonitoring(for: region)
        monitoredHabits.removeValue(forKey: habitId)

        logger.log(
            "✅ Geofence monitoring stopped",
            level: .info,
            category: .location,
            metadata: ["habitCount": monitoredHabits.count]
        )
    }

    public func stopAllMonitoring() async {
        logger.log(
            "🛑 Stopping all geofence monitoring",
            level: .info,
            category: .location,
            metadata: ["regionCount": locationManager.monitoredRegions.count]
        )

        for monitoredRegion in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: monitoredRegion)
        }
        monitoredHabits.removeAll()

        logger.log(
            "✅ All geofence monitoring stopped",
            level: .info,
            category: .location
        )
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

        logger.log(
            "📋 System monitoring status",
            level: .debug,
            category: .location,
            metadata: ["regionCount": habitIds.count]
        )
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
            Task { @MainActor in
                logger.log(
                    "⚠️ Invalid region or habit ID in geofence event",
                    level: .warning,
                    category: .location
                )
            }
            return
        }

        Task { @MainActor in
            logger.log(
                "📍 Geofence event detected",
                level: .info,
                category: .location,
                metadata: ["habitId": habitId.uuidString, "eventType": String(describing: eventType)]
            )

            // Get configuration for this habit
            guard let configuration = await monitoredHabits[habitId] else {
                logger.log(
                    "⚠️ No configuration found for habit",
                    level: .warning,
                    category: .location,
                    metadata: ["habitId": habitId.uuidString]
                )
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
                logger.log(
                    "⏭️ Skipping notification - frequency rules",
                    level: .debug,
                    category: .location,
                    metadata: ["habitId": habitId.uuidString]
                )
                return
            }

            logger.log(
                "🔔 Triggering geofence notification",
                level: .info,
                category: .location,
                metadata: ["habitId": habitId.uuidString, "eventType": String(describing: eventType)]
            )

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

            logger.log(
                "✅ Geofence event handled",
                level: .info,
                category: .location,
                metadata: ["habitId": habitId.uuidString]
            )
        }
    }

    private func updateConfiguration(habitId: UUID, configuration: LocationConfiguration) {
        monitoredHabits[habitId] = configuration
        logger.log(
            "🔄 Configuration updated",
            level: .debug,
            category: .location,
            metadata: ["habitId": habitId.uuidString]
        )
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
        Task { @MainActor in
            logger.log(
                "❌ Geofence monitoring failed",
                level: .error,
                category: .location,
                metadata: [
                    "region": region?.identifier ?? "unknown",
                    "error": error.localizedDescription
                ]
            )
        }

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
        Task { @MainActor in
            logger.log(
                "✅ Geofence monitoring started",
                level: .info,
                category: .location,
                metadata: ["region": region.identifier]
            )
        }
    }

    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = convertAuthorizationStatus(manager.authorizationStatus)
        Task { @MainActor in
            logger.log(
                "🔐 Location authorization changed",
                level: .info,
                category: .location,
                metadata: ["status": String(describing: status)]
            )
        }

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
        let stateDescription: String
        let stateLevel: LogLevel

        switch state {
        case .inside:
            stateDescription = "🏠 Device inside region - waiting for boundary crossing"
            stateLevel = .debug
        case .outside:
            stateDescription = "🌍 Device outside region - ready for entry event"
            stateLevel = .debug
        case .unknown:
            stateDescription = "❓ Region state unknown - waiting for location update"
            stateLevel = .debug
        @unknown default:
            stateDescription = "⚠️ Unknown region state"
            stateLevel = .warning
        }

        Task { @MainActor in
            logger.log(
                stateDescription,
                level: stateLevel,
                category: .location,
                metadata: ["region": region.identifier, "state": state.rawValue]
            )
        }
    }
}
