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

    public init(syncErrorHandler: CloudSyncErrorHandler) {
        self.syncErrorHandler = syncErrorHandler
    }

    public func execute() async -> iCloudSyncStatus {
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
                // CloudKit entitlements not configured - return unknown status
                // This is expected when iCloud is disabled in entitlements
                return .unknown
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
            // Any other error - return unknown
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
            return "Unavailable"
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
    private static let lastSyncDateKey = "com.ritualist.lastSyncDate"

    public init() {}

    public func execute() async -> Date? {
        return UserDefaults.standard.object(forKey: Self.lastSyncDateKey) as? Date
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
    private static let lastSyncDateKey = "com.ritualist.lastSyncDate"

    public init() {}

    public func execute(_ date: Date) async {
        UserDefaults.standard.set(date, forKey: Self.lastSyncDateKey)
    }
}
