//
//  TimezoneService.swift
//  RitualistCore
//
//  Created by Claude on 15.11.2025.
//
//  Manages timezone operations for the three-timezone model:
//  - Current (auto-detected device timezone)
//  - Home (user-defined semantic location)
//  - Display (user-chosen viewing perspective)
//

import Foundation

// MARK: - Errors

/// Errors that can occur during timezone operations
public enum TimezoneError: Error, LocalizedError {
    case invalidTimezoneIdentifier(String)

    public var errorDescription: String? {
        switch self {
        case .invalidTimezoneIdentifier(let identifier):
            return "Invalid timezone identifier: '\(identifier)'"
        }
    }
}

// MARK: - Protocol

/// Service for managing timezone operations in the three-timezone model
///
/// ## Three-Timezone Model:
/// - **Current**: Auto-detected device timezone (read-only, informational)
/// - **Home**: User-defined home timezone (editable, semantic meaning)
/// - **Display**: User-chosen viewing mode (controls ALL calculations)
///
/// ## Usage:
/// ```swift
/// let timezoneService: TimezoneService = DefaultTimezoneService(...)
///
/// // Get effective timezone for calculations
/// let displayTz = timezoneService.getDisplayTimezone()
///
/// // Detect if user is traveling
/// if let travel = timezoneService.detectTravelStatus(), travel.isTravel {
///     // Show notification
/// }
/// ```
public protocol TimezoneService {

    // MARK: - Getters

    /// Get current device timezone (auto-detected)
    /// - Returns: Current device timezone
    func getCurrentTimezone() -> TimeZone

    /// Get user's home timezone
    /// - Returns: User's home timezone
    /// - Throws: If unable to retrieve user profile
    func getHomeTimezone() async throws -> TimeZone

    /// Get display timezone mode
    /// - Returns: Current display mode (Current/Home/Custom)
    /// - Throws: If unable to retrieve user profile
    func getDisplayTimezoneMode() async throws -> DisplayTimezoneMode

    /// Get effective timezone for calculations (based on display mode)
    /// - Returns: Timezone to use for all date calculations
    /// - Throws: If unable to retrieve user profile
    func getDisplayTimezone() async throws -> TimeZone

    // MARK: - Setters

    /// Update home timezone
    /// - Parameter timezone: New home timezone
    /// - Throws: If unable to update user profile
    func updateHomeTimezone(_ timezone: TimeZone) async throws

    /// Update display timezone mode
    /// - Parameter mode: New display mode
    /// - Throws: If unable to update user profile
    func updateDisplayTimezoneMode(_ mode: DisplayTimezoneMode) async throws

    // MARK: - Detection & Monitoring

    /// Check if current device timezone differs from stored current timezone
    /// Call this on app launch to detect travel
    /// - Returns: Change detection info if timezone changed, nil otherwise
    /// - Throws: If unable to retrieve user profile
    func detectTimezoneChange() async throws -> TimezoneChangeDetection?

    /// Check if Current ≠ Home (user is traveling)
    /// - Returns: Travel status info, nil if current matches home
    /// - Throws: If unable to retrieve user profile
    func detectTravelStatus() async throws -> TravelStatus?

    /// Update stored current timezone when device timezone changes
    /// - Throws: If unable to update user profile
    func updateCurrentTimezone() async throws
}

// MARK: - Supporting Types

/// Represents detection of a timezone change
public struct TimezoneChangeDetection: Equatable {
    /// Previous timezone identifier
    public let previousTimezone: String

    /// New timezone identifier
    public let newTimezone: String

    /// When the change was detected
    public let detectedAt: Date

    public init(previousTimezone: String, newTimezone: String, detectedAt: Date) {
        self.previousTimezone = previousTimezone
        self.newTimezone = newTimezone
        self.detectedAt = detectedAt
    }
}

/// Represents current travel status (Current vs Home timezone)
public struct TravelStatus: Equatable {
    /// Current device timezone
    public let currentTimezone: TimeZone

    /// User's home timezone
    public let homeTimezone: TimeZone

    /// Whether user is traveling (Current ≠ Home)
    public let isTravel: Bool

    public init(currentTimezone: TimeZone, homeTimezone: TimeZone, isTravel: Bool) {
        self.currentTimezone = currentTimezone
        self.homeTimezone = homeTimezone
        self.isTravel = isTravel
    }
}

// MARK: - Default Implementation

/// Default implementation of TimezoneService using UserProfile storage
///
/// ## Thread Safety:
/// This service uses a load-modify-save pattern that is NOT inherently atomic.
/// However, it is safe in practice because:
/// 1. All callers are on MainActor (ViewModels, SwiftUI views, App lifecycle)
/// 2. The underlying ProfileLocalDataSource is a @ModelActor (serialized DB access)
///
/// **Important:** Do not call this service from background threads without proper
/// synchronization. If background access is needed, consider making this an actor.
public final class DefaultTimezoneService: TimezoneService {

    // MARK: - Dependencies

    private let loadProfile: LoadProfileUseCase
    private let saveProfile: SaveProfileUseCase
    private let logger: DebugLogger

    /// Initialize with profile use cases
    /// - Parameters:
    ///   - loadProfile: Use case to load user profile
    ///   - saveProfile: Use case to save user profile
    ///   - logger: Logger for debugging timezone operations
    public init(
        loadProfile: LoadProfileUseCase,
        saveProfile: SaveProfileUseCase,
        logger: DebugLogger = DebugLogger(subsystem: LoggerConstants.appSubsystem, category: "timezone")
    ) {
        self.loadProfile = loadProfile
        self.saveProfile = saveProfile
        self.logger = logger
    }

    // MARK: - Private Helpers

    /// Append a timezone change to history with automatic truncation to prevent unbounded growth.
    ///
    /// The history is trimmed BEFORE appending to ensure atomicity - if the operation is interrupted
    /// after truncation but before append, we lose at most one entry rather than risking data
    /// inconsistency from a partial append operation.
    ///
    /// - Parameters:
    ///   - change: The timezone change to append
    ///   - profile: The user profile to modify (inout)
    private func appendTimezoneChange(_ change: TimezoneChange, to profile: inout UserProfile) {
        if profile.timezoneChangeHistory.count >= TimezoneConstants.maxTimezoneHistoryEntries {
            profile.timezoneChangeHistory = Array(
                profile.timezoneChangeHistory.suffix(TimezoneConstants.maxTimezoneHistoryEntries - 1)
            )
        }
        profile.timezoneChangeHistory.append(change)
    }

    // MARK: - Getters

    public func getCurrentTimezone() -> TimeZone {
        return TimeZone.current
    }

    public func getHomeTimezone() async throws -> TimeZone {
        let profile = try await loadProfile.execute()

        // Attempt to create timezone from identifier
        guard let timezone = TimeZone(identifier: profile.homeTimezoneIdentifier) else {
            // Fallback to current timezone if identifier is invalid
            logger.log(
                "⚠️ Invalid home timezone identifier, falling back to current",
                level: .warning,
                category: .system,
                metadata: [
                    "invalidIdentifier": profile.homeTimezoneIdentifier,
                    "fallback": TimeZone.current.identifier
                ]
            )
            return TimeZone.current
        }

        return timezone
    }

    public func getDisplayTimezoneMode() async throws -> DisplayTimezoneMode {
        let profile = try await loadProfile.execute()
        return profile.displayTimezoneMode
    }

    public func getDisplayTimezone() async throws -> TimeZone {
        let profile = try await loadProfile.execute()

        // Resolve timezone based on display mode
        // IMPORTANT: For .current mode, use the ACTUAL device timezone (TimeZone.current),
        // not the stored currentTimezoneIdentifier. The stored value is for change detection,
        // but the actual display should always use the live device timezone.
        let displayTimezone = profile.displayTimezoneMode.resolveTimezone(
            currentTimezoneIdentifier: TimeZone.current.identifier,
            homeTimezoneIdentifier: profile.homeTimezoneIdentifier
        )

        // Fallback to current timezone if resolution fails
        if displayTimezone == nil {
            logger.log(
                "⚠️ Display timezone resolution failed, falling back to current",
                level: .warning,
                category: .system,
                metadata: [
                    "displayMode": profile.displayTimezoneMode.toLegacyString(),
                    "homeTimezone": profile.homeTimezoneIdentifier,
                    "fallback": TimeZone.current.identifier
                ]
            )
        }
        return displayTimezone ?? TimeZone.current
    }

    // MARK: - Setters

    public func updateHomeTimezone(_ timezone: TimeZone) async throws {
        var profile = try await loadProfile.execute()
        let oldHomeTimezone = profile.homeTimezoneIdentifier
        let newHomeTimezone = timezone.identifier

        // Validate timezone identifier can be recreated (defensive check)
        guard TimeZone(identifier: newHomeTimezone) != nil else {
            throw TimezoneError.invalidTimezoneIdentifier(newHomeTimezone)
        }

        // Update home timezone
        profile.homeTimezoneIdentifier = newHomeTimezone

        // Log timezone change with automatic history truncation
        let change = TimezoneChange(
            timestamp: Date(),
            fromTimezone: oldHomeTimezone,
            toTimezone: newHomeTimezone,
            trigger: .userUpdate
        )
        appendTimezoneChange(change, to: &profile)

        // Update timestamps
        profile.updatedAt = Date()

        // Save updated profile
        _ = try await saveProfile.execute(profile)
    }

    public func updateDisplayTimezoneMode(_ mode: DisplayTimezoneMode) async throws {
        var profile = try await loadProfile.execute()
        let oldMode = profile.displayTimezoneMode

        // Update display mode
        profile.displayTimezoneMode = mode

        // Log change if mode actually changed (with automatic history truncation)
        if oldMode != mode {
            let change = TimezoneChange(
                timestamp: Date(),
                fromTimezone: oldMode.toLegacyString(),
                toTimezone: mode.toLegacyString(),
                trigger: .displayModeChange
            )
            appendTimezoneChange(change, to: &profile)
        }

        // Update timestamps
        profile.updatedAt = Date()

        // Save updated profile
        _ = try await saveProfile.execute(profile)
    }

    // MARK: - Detection & Monitoring

    public func detectTimezoneChange() async throws -> TimezoneChangeDetection? {
        let profile = try await loadProfile.execute()
        let deviceTimezone = TimeZone.current.identifier
        let storedCurrentTimezone = profile.currentTimezoneIdentifier

        // Check if device timezone differs from stored current
        guard deviceTimezone != storedCurrentTimezone else {
            return nil
        }

        return TimezoneChangeDetection(
            previousTimezone: storedCurrentTimezone,
            newTimezone: deviceTimezone,
            detectedAt: Date()
        )
    }

    public func detectTravelStatus() async throws -> TravelStatus? {
        let profile = try await loadProfile.execute()
        let currentTz = TimeZone(identifier: profile.currentTimezoneIdentifier) ?? TimeZone.current
        let homeTz = TimeZone(identifier: profile.homeTimezoneIdentifier) ?? TimeZone.current

        let isTravel = profile.currentTimezoneIdentifier != profile.homeTimezoneIdentifier

        // Only return status if user is actually traveling
        guard isTravel else {
            return nil
        }

        return TravelStatus(
            currentTimezone: currentTz,
            homeTimezone: homeTz,
            isTravel: isTravel
        )
    }

    public func updateCurrentTimezone() async throws {
        var profile = try await loadProfile.execute()
        let oldCurrentTimezone = profile.currentTimezoneIdentifier
        let newCurrentTimezone = TimeZone.current.identifier

        // Only update if timezone actually changed
        guard oldCurrentTimezone != newCurrentTimezone else {
            return
        }

        // Update current timezone
        profile.currentTimezoneIdentifier = newCurrentTimezone

        // Log timezone change with automatic history truncation
        let change = TimezoneChange(
            timestamp: Date(),
            fromTimezone: oldCurrentTimezone,
            toTimezone: newCurrentTimezone,
            trigger: .deviceChange
        )
        appendTimezoneChange(change, to: &profile)

        // Update timestamps
        profile.updatedAt = Date()

        // Save updated profile
        _ = try await saveProfile.execute(profile)
    }
}
