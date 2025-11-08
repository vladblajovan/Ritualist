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
    private let userBusinessService: UserBusinessService

    public init(userBusinessService: UserBusinessService) {
        self.userBusinessService = userBusinessService
    }

    public func execute() async throws {
        try await userBusinessService.syncWithiCloud()
    }
}

// MARK: - Check iCloud Status UseCase

public protocol CheckiCloudStatusUseCase {
    func execute() async throws -> iCloudSyncStatus
}

public final class DefaultCheckiCloudStatusUseCase: CheckiCloudStatusUseCase {
    private let syncErrorHandler: CloudSyncErrorHandler

    public init(syncErrorHandler: CloudSyncErrorHandler) {
        self.syncErrorHandler = syncErrorHandler
    }

    public func execute() async throws -> iCloudSyncStatus {
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
            return "iCloud is available"
        case .notSignedIn:
            return "Not signed in to iCloud"
        case .restricted:
            return "iCloud is restricted"
        case .temporarilyUnavailable:
            return "iCloud temporarily unavailable"
        case .unknown:
            return "iCloud status unknown"
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
