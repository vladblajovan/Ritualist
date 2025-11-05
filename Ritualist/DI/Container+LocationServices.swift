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

            // IMPORTANT: Set event handler synchronously to avoid race condition
            // The setEventHandler method is async but just sets a property,
            // so we need to ensure it's set before any geofence events fire
            Task { @MainActor in
                // Set event handler immediately to process geofence events
                await service.setEventHandler { [weak self] event in
                    guard let self = self else {
                        print("⚠️  [LocationMonitoring] Container deallocated, cannot handle event")
                        return
                    }
                    do {
                        print("🎯 [LocationMonitoring] Event handler called for habit \(event.habitId)")
                        try await self.handleGeofenceEvent().execute(event: event)
                    } catch {
                        print("❌ [LocationMonitoring] Failed to handle geofence event: \(error)")
                    }
                }
                print("✅ [LocationMonitoring] Event handler registered successfully")
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
