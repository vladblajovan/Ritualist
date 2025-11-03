import Foundation
import FactoryKit
import RitualistCore

// MARK: - Location Services Container Extensions

extension Container {

    // MARK: - Location Services

    @MainActor
    var locationMonitoringService: Factory<LocationMonitoringService> {
        self { @MainActor in
            let service = DefaultLocationMonitoringService()

            // Set event handler to process geofence events
            Task {
                await service.setEventHandler { [weak self] event in
                    guard let self = self else { return }
                    do {
                        try await self.handleGeofenceEvent().execute(event: event)
                    } catch {
                        print("❌ [LocationMonitoring] Failed to handle geofence event: \(error)")
                    }
                }
            }

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
