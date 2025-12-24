import Foundation
import FactoryKit
import RitualistCore

// MARK: - Location UseCases Container Extensions

extension Container {

    // MARK: - Location Configuration UseCases

    @MainActor
    var configureHabitLocation: Factory<ConfigureHabitLocationUseCase> {
        self { @MainActor in
            ConfigureHabitLocationUseCaseImpl(
                habitRepository: self.habitRepository(),
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }

    @MainActor
    var enableLocationMonitoring: Factory<EnableLocationMonitoringUseCase> {
        self { @MainActor in
            EnableLocationMonitoringUseCaseImpl(
                habitRepository: self.habitRepository(),
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }

    @MainActor
    var disableLocationMonitoring: Factory<DisableLocationMonitoringUseCase> {
        self { @MainActor in
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
                notificationService: self.notificationService(),
                subscriptionService: self.subscriptionService(),
                habitCompletionCheckService: self.habitCompletionCheckService(),
                logger: self.debugLogger()
            )
        }
    }

    // MARK: - Location Permission UseCases

    @MainActor
    var requestLocationPermissions: Factory<RequestLocationPermissionsUseCase> {
        self { @MainActor in
            RequestLocationPermissionsUseCaseImpl(
                locationPermissionService: self.locationPermissionService()
            )
        }
    }

    @MainActor
    var getLocationAuthStatus: Factory<GetLocationAuthStatusUseCase> {
        self { @MainActor in
            GetLocationAuthStatusUseCaseImpl(
                locationPermissionService: self.locationPermissionService()
            )
        }
    }

    @MainActor
    var getMonitoredHabits: Factory<GetMonitoredHabitsUseCase> {
        self { @MainActor in
            GetMonitoredHabitsUseCaseImpl(
                locationMonitoringService: self.locationMonitoringService()
            )
        }
    }

    @MainActor
    var restoreGeofenceMonitoring: Factory<RestoreGeofenceMonitoringUseCase> {
        self { @MainActor in
            RestoreGeofenceMonitoringUseCaseImpl(
                habitRepository: self.habitRepository(),
                locationMonitoringService: self.locationMonitoringService(),
                subscriptionService: self.subscriptionService(),
                logger: self.debugLogger()
            )
        }
    }
}
