import Foundation
import FactoryKit
import RitualistCore

// MARK: - Location UseCases Container Extensions

extension Container {

    // MARK: - Location Configuration UseCases

    var configureHabitLocation: Factory<ConfigureHabitLocationUseCase> {
        self {
            ConfigureHabitLocationUseCaseImpl(
                habitRepository: self.habitRepository(),
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }

    var enableLocationMonitoring: Factory<EnableLocationMonitoringUseCase> {
        self {
            EnableLocationMonitoringUseCaseImpl(
                habitRepository: self.habitRepository(),
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }

    var disableLocationMonitoring: Factory<DisableLocationMonitoringUseCase> {
        self {
            DisableLocationMonitoringUseCaseImpl(
                habitRepository: self.habitRepository(),
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }

    var handleGeofenceEvent: Factory<HandleGeofenceEventUseCase> {
        self {
            HandleGeofenceEventUseCaseImpl(
                habitRepository: self.habitRepository(),
                notificationService: self.notificationService()
            )
        }
    }

    // MARK: - Location Permission UseCases

    var requestLocationPermissions: Factory<RequestLocationPermissionsUseCase> {
        self {
            RequestLocationPermissionsUseCaseImpl(
                locationPermissionService: self.locationPermissionService()
            )
        }
    }

    var getLocationAuthStatus: Factory<GetLocationAuthStatusUseCase> {
        self {
            GetLocationAuthStatusUseCaseImpl(
                locationPermissionService: self.locationPermissionService()
            )
        }
    }

    var getMonitoredHabits: Factory<GetMonitoredHabitsUseCase> {
        self {
            GetMonitoredHabitsUseCaseImpl(
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }
}
