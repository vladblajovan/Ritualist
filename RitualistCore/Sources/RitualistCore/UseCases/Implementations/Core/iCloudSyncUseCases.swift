//
//  iCloudSyncUseCases.swift
//  RitualistCore
//
//  Use cases for iCloud sync operations
//

import Foundation
import CloudKit

// MARK: - Sync with iCloud UseCase

public protocol SyncWithiCloudUseCase {
    func execute() async throws
}

public final class DefaultSyncWithiCloudUseCase: SyncWithiCloudUseCase {
    private let checkiCloudStatus: CheckiCloudStatusUseCase

    public init(checkiCloudStatus: CheckiCloudStatusUseCase) {
        self.checkiCloudStatus = checkiCloudStatus
    }

    public func execute() async throws {
        // SwiftData automatically syncs all models to iCloud (see PersistenceContainer.swift:68-69)
        // This method validates CloudKit availability before claiming sync succeeded

        let status = await checkiCloudStatus.execute()

        guard status == .available else {
            throw iCloudSyncError.syncNotAvailable(status: status)
        }

        // If we reach here, iCloud is available and SwiftData will sync automatically
        // Return success so the timestamp updates
    }
}

// MARK: - Check iCloud Status UseCase

public protocol CheckiCloudStatusUseCase {
    func execute() async -> iCloudSyncStatus
}

/// Mock implementation that returns .unknown when CloudKit is disabled
public final class DisabledCheckiCloudStatusUseCase: CheckiCloudStatusUseCase {
    public init() {}

    public func execute() async -> iCloudSyncStatus {
        // CloudKit entitlements are disabled - return unknown status
        return .unknown
    }
}

public final class DefaultCheckiCloudStatusUseCase: CheckiCloudStatusUseCase {
    private let syncErrorHandler: CloudSyncErrorHandler
    private let logger: DebugLogger

    /// Timeout for iCloud status check (in seconds)
    /// CloudKit can hang indefinitely on poor networks - this ensures we always return
    private static let statusCheckTimeout: TimeInterval = 10

    public init(syncErrorHandler: CloudSyncErrorHandler, logger: DebugLogger) {
        self.syncErrorHandler = syncErrorHandler
        self.logger = logger
    }

    public func execute() async -> iCloudSyncStatus {
        // Wrap CloudKit call with timeout to prevent indefinite hangs
        // CloudKit doesn't respect Task cancellation, so we use the shared timeout utility
        let logger = self.logger
        let timeout = Self.statusCheckTimeout

        return await withTimeout(
            seconds: timeout,
            operation: { [self] in
                await performStatusCheck()
            },
            onTimeout: {
                logger.log(
                    "iCloud status check timed out",
                    level: .warning,
                    category: .network,
                    metadata: ["timeout": "\(timeout)s"]
                )
                return .timeout
            }
        )
    }

    /// Performs the actual CloudKit status check without timeout
    private func performStatusCheck() async -> iCloudSyncStatus {
        do {
            let accountStatus = try await syncErrorHandler.checkiCloudAccountStatus()

            switch accountStatus {
            case .available:
                return .available
            case .noAccount:
                return .notSignedIn
            case .restricted:
                return .restricted
            case .couldNotDetermine:
                return .unknown
            case .temporarilyUnavailable:
                return .temporarilyUnavailable
            @unknown default:
                return .unknown
            }
        } catch let error as CloudKitAvailabilityError {
            // Handle CloudKit availability errors gracefully
            switch error {
            case .entitlementsNotConfigured:
                // CloudKit entitlements not configured - return specific status
                // This is expected when iCloud is disabled in entitlements
                return .notConfigured
            case .notSignedIn:
                return .notSignedIn
            case .restricted:
                return .restricted
            case .temporarilyUnavailable, .networkUnavailable:
                return .temporarilyUnavailable
            case .couldNotDetermine, .unknown:
                return .unknown
            }
        } catch {
            // Log unexpected errors for debugging
            logger.log(
                "Unexpected iCloud status check error",
                level: .warning,
                category: .network,
                metadata: ["error": error.localizedDescription]
            )
            return .unknown
        }
    }

}

// MARK: - iCloud Sync Status

public enum iCloudSyncStatus: Equatable {
    case available
    case notSignedIn
    case restricted
    case temporarilyUnavailable
    /// CloudKit status check timed out (likely poor network)
    case timeout
    /// CloudKit entitlements not configured in the app
    case notConfigured
    /// Could not determine status for unknown reason
    case unknown

    public var displayMessage: String {
        switch self {
        case .available:
            return "Enabled"
        case .notSignedIn:
            return "Not signed in"
        case .restricted:
            return "Restricted"
        case .temporarilyUnavailable:
            return "Temporarily unavailable"
        case .timeout:
            return "Connection timed out"
        case .notConfigured:
            return "Not configured"
        case .unknown:
            return "Unknown"
        }
    }

    public var canSync: Bool {
        self == .available
    }
}

// MARK: - Get Last Sync Date UseCase

public protocol GetLastSyncDateUseCase {
    func execute() async -> Date?
}

public final class DefaultGetLastSyncDateUseCase: GetLastSyncDateUseCase {
    public init() {}

    public func execute() async -> Date? {
        return UserDefaults.standard.object(forKey: UserDefaultsKeys.lastSyncDate) as? Date
    }
}

// MARK: - iCloud Sync Error

public enum iCloudSyncError: LocalizedError {
    case syncNotAvailable(status: iCloudSyncStatus)

    public var errorDescription: String? {
        switch self {
        case .syncNotAvailable(let status):
            return "iCloud sync not available: \(status.displayMessage)"
        }
    }
}

// MARK: - Update Last Sync Date UseCase

public protocol UpdateLastSyncDateUseCase {
    func execute(_ date: Date) async
}

public final class DefaultUpdateLastSyncDateUseCase: UpdateLastSyncDateUseCase {
    public init() {}

    public func execute(_ date: Date) async {
        UserDefaults.standard.set(date, forKey: UserDefaultsKeys.lastSyncDate)
    }
}

// MARK: - iCloud Sync Preference UseCases

/// Get the user's iCloud sync preference
public protocol GetICloudSyncPreferenceUseCase {
    func execute() -> Bool
}

public final class DefaultGetICloudSyncPreferenceUseCase: GetICloudSyncPreferenceUseCase {
    private let preferenceService: ICloudSyncPreferenceServiceProtocol

    public init(preferenceService: ICloudSyncPreferenceServiceProtocol) {
        self.preferenceService = preferenceService
    }

    public func execute() -> Bool {
        preferenceService.isICloudSyncEnabled
    }
}

/// Set the user's iCloud sync preference (requires app restart to take effect)
public protocol SetICloudSyncPreferenceUseCase {
    func execute(_ enabled: Bool)
}

public final class DefaultSetICloudSyncPreferenceUseCase: SetICloudSyncPreferenceUseCase {
    private let preferenceService: ICloudSyncPreferenceServiceProtocol

    public init(preferenceService: ICloudSyncPreferenceServiceProtocol) {
        self.preferenceService = preferenceService
    }

    public func execute(_ enabled: Bool) {
        preferenceService.setICloudSyncEnabled(enabled)
    }
}
