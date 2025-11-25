import Foundation
import FactoryKit
import RitualistCore

// MARK: - Location Services Container Extensions

extension Container {

    // MARK: - Location Services

    @MainActor
    var locationMonitoringService: Factory<LocationMonitoringService> {
        self { @MainActor in
            let logger = self.debugLogger()
            let service = DefaultLocationMonitoringService(logger: logger)

            // CRITICAL: Set event handler SYNCHRONOUSLY before returning the service.
            // This prevents a race condition where geofence events could fire before
            // the handler is registered. Since we're already on MainActor and
            // setEventHandler just sets a property, we can call it directly.
            // The closure itself is async and will be called later when events fire.
            service.setEventHandler { [weak self] event in
                guard let self = self else {
                    logger.log("Container deallocated, cannot handle geofence event", level: .warning, category: .location)
                    return
                }
                do {
                    logger.log("Processing geofence event for habit: \(event.habitId)", level: .debug, category: .location)
                    try await self.handleGeofenceEvent().execute(event: event)
                } catch {
                    logger.log("Failed to handle geofence event: \(error)", level: .error, category: .location)
                }
            }
            logger.log("Geofence event handler registered successfully", level: .info, category: .location)

            return service
        }
        .singleton
    }

    @MainActor
    var locationPermissionService: Factory<LocationPermissionService> {
        self { @MainActor in
            DefaultLocationPermissionService()
        }
        .singleton
    }
}
