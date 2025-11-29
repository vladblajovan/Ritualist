//
//  SyncConstants.swift
//  RitualistCore
//
//  Configuration constants for iCloud sync and data synchronization behavior.
//

import Foundation

// MARK: - iCloud Configuration

/// CloudKit and iCloud container identifiers.
public enum iCloudConstants {
    /// CloudKit container identifier for iCloud sync
    public static let containerIdentifier = "iCloud.com.vladblajovan.Ritualist"
}

// MARK: - Sync Configuration

/// Configuration constants for iCloud sync retry behavior.
/// Used when waiting for CloudKit data to become available after detecting a returning user.
public enum SyncConstants {
    /// Maximum number of retry attempts when waiting for sync data (30 × 2s = 60 seconds)
    public static let maxRetries = 30

    /// Interval between retry attempts in seconds
    public static let retryIntervalSeconds: UInt64 = 2

    /// Total timeout duration in seconds (convenience for documentation)
    public static let totalTimeoutSeconds: TimeInterval = 60
}
