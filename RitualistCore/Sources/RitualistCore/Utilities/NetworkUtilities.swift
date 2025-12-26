//
//  NetworkUtilities.swift
//  RitualistCore
//
//  Shared network connectivity utilities.
//

import Foundation
import Network

/// Network connectivity utilities shared across the app.
public enum NetworkUtilities {

    /// Thread-safe continuation state tracker for Swift 6 concurrency compliance
    private final class ContinuationState: @unchecked Sendable {
        private var hasResumed = false
        private let lock = NSLock()

        func tryResume() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            guard !hasResumed else { return false }
            hasResumed = true
            return true
        }
    }

    /// Check if device has network connectivity.
    /// - Returns: `true` if network is available, `false` otherwise
    /// - Note: This reads cached system state (nearly instant), not an actual network ping.
    ///         Includes a safety timeout that rarely triggers.
    public static func hasNetworkConnectivity() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: DispatchQueueLabels.networkMonitor)
            let state = ContinuationState()

            monitor.pathUpdateHandler = { path in
                guard state.tryResume() else { return }
                let isConnected = path.status == .satisfied
                monitor.cancel()
                continuation.resume(returning: isConnected)
            }

            monitor.start(queue: queue)

            // Safety timeout (rarely needed - NWPathMonitor usually responds instantly)
            DispatchQueue.global().asyncAfter(deadline: .now() + NetworkTimeouts.connectivityCheck) {
                guard state.tryResume() else { return }
                monitor.cancel()
                continuation.resume(returning: false)
            }
        }
    }
}
