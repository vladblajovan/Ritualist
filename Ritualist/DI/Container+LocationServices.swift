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

            // IMPORTANT: Set event handler SYNCHRONOUSLY to avoid race condition
            // The CLLocationManager delegate is active immediately after init(),
            // so we must set the handler before returning the service.
            // If we use Task here, geofence events can fire before the handler is set
            // and those events would be silently dropped.
            //
            // Memory management notes:
            // - [weak self] prevents retain cycle between Container and the closure
            // - logger is captured strongly but it's a stateless utility without back-references
            // - The service is a singleton, so the closure lives for the app lifetime anyway
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
