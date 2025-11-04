//
//  LocationUseCases.swift
//  RitualistCore
//
//  Created by Claude on 03.11.2025.
//
//  Use cases for location-aware habit features.
//  Follows Clean Architecture: ViewModels → UseCases → Services/Repositories
//

import Foundation

// MARK: - Configure Habit Location UseCase

/// Configure location settings for a habit
public protocol ConfigureHabitLocationUseCase {
    func execute(habitId: UUID, configuration: LocationConfiguration?) async throws
}

public struct ConfigureHabitLocationUseCaseImpl: ConfigureHabitLocationUseCase {
    private let habitRepository: HabitRepository
    private let locationMonitoringService: LocationMonitoringService

    public init(
        habitRepository: HabitRepository,
        locationMonitoringService: LocationMonitoringService
    ) {
        self.habitRepository = habitRepository
        self.locationMonitoringService = locationMonitoringService
    }

    public func execute(habitId: UUID, configuration: LocationConfiguration?) async throws {
        // Get current habit
        guard var habit = try await habitRepository.fetchHabit(by: habitId) else {
            throw HabitError.habitNotFound(id: habitId)
        }

        // Update location configuration
        habit.locationConfiguration = configuration

        // Save updated habit
        try await habitRepository.update(habit)

        // If configuration is enabled, start monitoring
        if let config = configuration, config.isEnabled {
            try await locationMonitoringService.startMonitoring(habitId: habitId, configuration: config)
        } else {
            // If disabled or nil, stop monitoring
            await locationMonitoringService.stopMonitoring(habitId: habitId)
        }
    }
}

// MARK: - Enable Location Monitoring UseCase

/// Enable location monitoring for a habit
public protocol EnableLocationMonitoringUseCase {
    func execute(habitId: UUID) async throws
}

public struct EnableLocationMonitoringUseCaseImpl: EnableLocationMonitoringUseCase {
    private let habitRepository: HabitRepository
    private let locationMonitoringService: LocationMonitoringService

    public init(
        habitRepository: HabitRepository,
        locationMonitoringService: LocationMonitoringService
    ) {
        self.habitRepository = habitRepository
        self.locationMonitoringService = locationMonitoringService
    }

    public func execute(habitId: UUID) async throws {
        // Get habit with location configuration
        guard var habit = try await habitRepository.fetchHabit(by: habitId),
              var locationConfig = habit.locationConfiguration else {
            throw HabitError.habitNotFound(id: habitId)
        }

        // Enable configuration
        locationConfig.isEnabled = true
        habit.locationConfiguration = locationConfig

        // Save updated habit
        try await habitRepository.update(habit)

        // Start monitoring
        try await locationMonitoringService.startMonitoring(habitId: habitId, configuration: locationConfig)
    }
}

// MARK: - Disable Location Monitoring UseCase

/// Disable location monitoring for a habit
public protocol DisableLocationMonitoringUseCase {
    func execute(habitId: UUID) async throws
}

public struct DisableLocationMonitoringUseCaseImpl: DisableLocationMonitoringUseCase {
    private let habitRepository: HabitRepository
    private let locationMonitoringService: LocationMonitoringService

    public init(
        habitRepository: HabitRepository,
        locationMonitoringService: LocationMonitoringService
    ) {
        self.habitRepository = habitRepository
        self.locationMonitoringService = locationMonitoringService
    }

    public func execute(habitId: UUID) async throws {
        // Get habit with location configuration
        guard var habit = try await habitRepository.fetchHabit(by: habitId),
              var locationConfig = habit.locationConfiguration else {
            throw HabitError.habitNotFound(id: habitId)
        }

        // Disable configuration
        locationConfig.isEnabled = false
        habit.locationConfiguration = locationConfig

        // Save updated habit
        try await habitRepository.update(habit)

        // Stop monitoring
        await locationMonitoringService.stopMonitoring(habitId: habitId)
    }
}

// MARK: - Handle Geofence Event UseCase

/// Handle a geofence event and send appropriate notifications
public protocol HandleGeofenceEventUseCase {
    func execute(event: GeofenceEvent) async throws
}

public struct HandleGeofenceEventUseCaseImpl: HandleGeofenceEventUseCase {
    private let habitRepository: HabitRepository
    private let notificationService: NotificationService

    public init(
        habitRepository: HabitRepository,
        notificationService: NotificationService
    ) {
        self.habitRepository = habitRepository
        self.notificationService = notificationService
    }

    public func execute(event: GeofenceEvent) async throws {
        // Get habit
        guard var habit = try await habitRepository.fetchHabit(by: event.habitId) else {
            print("⚠️  [HandleGeofenceEvent] Habit not found: \(event.habitId)")
            return
        }

        // Verify habit is active and has location configuration
        guard habit.isActive,
              var locationConfig = habit.locationConfiguration,
              locationConfig.isEnabled else {
            print("⚠️  [HandleGeofenceEvent] Habit not active or location disabled: \(habit.name)")
            return
        }

        // Check if notification should be sent based on frequency
        guard event.shouldTriggerNotification() else {
            print("⏭️  [HandleGeofenceEvent] Skipping notification due to frequency rules: \(habit.name)")
            return
        }

        // Send location-triggered notification
        try await notificationService.sendLocationTriggeredNotification(
            for: habit.id,
            habitName: habit.name,
            event: event
        )

        // Update last trigger date in configuration
        locationConfig.lastTriggerDate = event.timestamp
        habit.locationConfiguration = locationConfig

        // Save updated habit
        try await habitRepository.update(habit)

        print("✅ [HandleGeofenceEvent] Notification sent for habit: \(habit.name)")
    }
}

// MARK: - Request Location Permissions UseCase

/// Request location permissions with appropriate level
public protocol RequestLocationPermissionsUseCase {
    func execute(requestAlways: Bool) async -> LocationPermissionResult
}

public struct RequestLocationPermissionsUseCaseImpl: RequestLocationPermissionsUseCase {
    private let locationPermissionService: LocationPermissionService

    public init(locationPermissionService: LocationPermissionService) {
        self.locationPermissionService = locationPermissionService
    }

    public func execute(requestAlways: Bool) async -> LocationPermissionResult {
        if requestAlways {
            return await locationPermissionService.requestAlwaysPermission()
        } else {
            return await locationPermissionService.requestWhenInUsePermission()
        }
    }
}

// MARK: - Get Location Authorization Status UseCase

/// Get current location authorization status
public protocol GetLocationAuthStatusUseCase {
    func execute() async -> LocationAuthorizationStatus
}

public struct GetLocationAuthStatusUseCaseImpl: GetLocationAuthStatusUseCase {
    private let locationPermissionService: LocationPermissionService

    public init(locationPermissionService: LocationPermissionService) {
        self.locationPermissionService = locationPermissionService
    }

    public func execute() async -> LocationAuthorizationStatus {
        return await locationPermissionService.getAuthorizationStatus()
    }
}

// MARK: - Get Monitored Habits UseCase

/// Get list of habits currently being monitored for location
public protocol GetMonitoredHabitsUseCase {
    func execute() async -> [UUID]
}

public struct GetMonitoredHabitsUseCaseImpl: GetMonitoredHabitsUseCase {
    private let locationMonitoringService: LocationMonitoringService

    public init(locationMonitoringService: LocationMonitoringService) {
        self.locationMonitoringService = locationMonitoringService
    }

    public func execute() async -> [UUID] {
        return await locationMonitoringService.getMonitoredHabitIds()
    }
}
