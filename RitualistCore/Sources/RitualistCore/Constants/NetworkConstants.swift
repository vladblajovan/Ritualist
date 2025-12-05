//
//  NetworkConstants.swift
//  RitualistCore
//
//  Network-related constants for dispatch queues, timeouts, and connectivity checks.
//

import Foundation

// MARK: - Dispatch Queue Labels

/// Centralized dispatch queue labels for network operations.
public enum DispatchQueueLabels {
    /// Queue for network connectivity monitoring
    public static let networkMonitor = "com.ritualist.networkmonitor"
}

// MARK: - Network Timeouts

/// Timeout values for network operations.
public enum NetworkTimeouts {
    /// Timeout for network connectivity check in seconds.
    /// NWPathMonitor usually responds instantly; this is a safety fallback.
    public static let connectivityCheck: TimeInterval = 2.0
}
