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

/// Single source of truth for geofence event handling
///
/// ARCHITECTURE: This UseCase handles ALL business logic for geofence events:
/// - Fetches authoritative configuration from database (not in-memory state)
/// - Checks trigger type matching and frequency rules
/// - Sends notifications
/// - Updates trigger dates in database
///
/// The LocationMonitoringService is a thin pass-through that forwards events here.
/// This ensures reliability even when app was killed and iOS relaunched it.
public struct HandleGeofenceEventUseCaseImpl: HandleGeofenceEventUseCase {
    private let habitRepository: HabitRepository
    private let notificationService: NotificationService
    private let logger: DebugLogger

    public init(
        habitRepository: HabitRepository,
        notificationService: NotificationService,
        logger: DebugLogger
    ) {
        self.habitRepository = habitRepository
        self.notificationService = notificationService
        self.logger = logger
    }

    public func execute(event: GeofenceEvent) async throws {
        logger.log(
            "🔔 Processing geofence event",
            level: .info,
            category: .location,
            metadata: ["habitId": event.habitId.uuidString, "eventType": String(describing: event.eventType)]
        )

        // STEP 1: Fetch habit from database (source of truth)
        guard var habit = try await habitRepository.fetchHabit(by: event.habitId) else {
            logger.log(
                "⚠️ Geofence event for missing habit",
                level: .warning,
                category: .location,
                metadata: ["habitId": event.habitId.uuidString]
            )
            return
        }

        // STEP 2: Verify habit is active and has enabled location configuration
        guard habit.isActive,
              var locationConfig = habit.locationConfiguration,
              locationConfig.isEnabled else {
            logger.log(
                "⚠️ Geofence event for inactive/disabled habit",
                level: .warning,
                category: .location,
                metadata: ["habitName": habit.name, "isActive": habit.isActive]
            )
            return
        }

        // STEP 3: Check if trigger type matches event type (using DATABASE config)
        let triggerMatches: Bool
        switch locationConfig.triggerType {
        case .entry:
            triggerMatches = event.eventType == .entry
        case .exit:
            triggerMatches = event.eventType == .exit
        case .both:
            triggerMatches = true
        }

        guard triggerMatches else {
            logger.log(
                "⏭️ Skipping - trigger type mismatch",
                level: .debug,
                category: .location,
                metadata: [
                    "habitName": habit.name,
                    "configuredTrigger": String(describing: locationConfig.triggerType),
                    "eventType": String(describing: event.eventType)
                ]
            )
            return
        }

        // STEP 4: Check frequency rules using DATABASE config (has authoritative trigger dates)
        guard locationConfig.shouldTriggerNotification(for: event.eventType, now: event.timestamp) else {
            logger.log(
                "⏭️ Skipping - frequency rules (cooldown active)",
                level: .debug,
                category: .location,
                metadata: ["habitName": habit.name]
            )
            return
        }

        // STEP 5: Send location-triggered notification
        // Create event with database config for notification service
        let enrichedEvent = GeofenceEvent(
            habitId: event.habitId,
            eventType: event.eventType,
            timestamp: event.timestamp,
            configuration: locationConfig,
            detectedLocation: event.detectedLocation
        )

        try await notificationService.sendLocationTriggeredNotification(
            for: habit.id,
            habitName: habit.name,
            event: enrichedEvent
        )

        // STEP 6: Update appropriate trigger date based on event type
        switch event.eventType {
        case .entry:
            locationConfig.lastEntryTriggerDate = event.timestamp
        case .exit:
            locationConfig.lastExitTriggerDate = event.timestamp
        }
        habit.locationConfiguration = locationConfig

        // STEP 7: Save updated habit to database
        try await habitRepository.update(habit)

        logger.log(
            "✅ Geofence notification sent",
            level: .info,
            category: .location,
            metadata: ["habitName": habit.name, "eventType": String(describing: event.eventType)]
        )
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

// MARK: - Restore Geofence Monitoring UseCase

/// Restore geofence monitoring for all habits with enabled location configurations
/// This should be called on app launch to restore geofences after app restart/kill
public protocol RestoreGeofenceMonitoringUseCase {
    func execute() async throws
}

public struct RestoreGeofenceMonitoringUseCaseImpl: RestoreGeofenceMonitoringUseCase {
    private let habitRepository: HabitRepository
    private let locationMonitoringService: LocationMonitoringService
    private let logger: DebugLogger

    public init(
        habitRepository: HabitRepository,
        locationMonitoringService: LocationMonitoringService,
        logger: DebugLogger
    ) {
        self.habitRepository = habitRepository
        self.locationMonitoringService = locationMonitoringService
        self.logger = logger
    }

    public func execute() async throws {
        logger.log("Starting geofence restoration on app launch", level: .info, category: .location)

        // Check if location services are available
        let authStatus = await locationMonitoringService.getAuthorizationStatus()
        guard authStatus.canMonitorGeofences else {
            logger.log("Location permission not granted - skipping geofence restoration", level: .warning, category: .location)
            return
        }

        // Get all habits from repository
        let allHabits = try await habitRepository.fetchAllHabits()

        // Filter habits with enabled location configurations
        let habitsWithLocation = allHabits.filter { habit in
            guard let config = habit.locationConfiguration else { return false }
            return config.isEnabled && habit.isActive
        }

        logger.log("Found \(habitsWithLocation.count) habits with enabled location monitoring", level: .info, category: .location)

        // Restore monitoring for each habit
        var restoredCount = 0
        var failedCount = 0

        for habit in habitsWithLocation {
            guard let configuration = habit.locationConfiguration else { continue }

            do {
                try await locationMonitoringService.startMonitoring(
                    habitId: habit.id,
                    configuration: configuration
                )
                restoredCount += 1
                logger.log("Restored geofence monitoring for habit: \(habit.name)", level: .debug, category: .location)
            } catch {
                failedCount += 1
                logger.log("Failed to restore monitoring for habit '\(habit.name)': \(error)", level: .error, category: .location)
            }
        }

        // Clean up orphaned geofences (regions iOS is monitoring but app no longer needs)
        let validHabitIds = Set(habitsWithLocation.map { $0.id })
        let systemMonitoredHabitIds = await locationMonitoringService.getSystemMonitoredHabitIds()
        let orphanedHabitIds = systemMonitoredHabitIds.filter { !validHabitIds.contains($0) }

        if !orphanedHabitIds.isEmpty {
            logger.log("Cleaning up \(orphanedHabitIds.count) orphaned geofences", level: .info, category: .location)
            for orphanedId in orphanedHabitIds {
                await locationMonitoringService.stopMonitoring(habitId: orphanedId)
                logger.log("Removed orphaned geofence: \(orphanedId)", level: .debug, category: .location)
            }
        }

        logger.log("Geofence restoration complete - Restored: \(restoredCount), Failed: \(failedCount), Cleaned: \(orphanedHabitIds.count)", level: .info, category: .location)
    }
}
