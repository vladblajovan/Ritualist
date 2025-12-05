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

    /// Check if device has network connectivity.
    /// - Returns: `true` if network is available, `false` otherwise
    /// - Note: This reads cached system state (nearly instant), not an actual network ping.
    ///         Includes a safety timeout that rarely triggers.
    public static func hasNetworkConnectivity() async -> Bool {
        await withCheckedContinuation { continuation in
            let monitor = NWPathMonitor()
            let queue = DispatchQueue(label: DispatchQueueLabels.networkMonitor)
            var hasResumed = false
            let lock = NSLock()

            monitor.pathUpdateHandler = { path in
                lock.lock()
                defer { lock.unlock() }

                guard !hasResumed else { return }
                hasResumed = true

                let isConnected = path.status == .satisfied
                monitor.cancel()
                continuation.resume(returning: isConnected)
            }

            monitor.start(queue: queue)

            // Safety timeout (rarely needed - NWPathMonitor usually responds instantly)
            DispatchQueue.global().asyncAfter(deadline: .now() + NetworkTimeouts.connectivityCheck) {
                lock.lock()
                defer { lock.unlock() }

                guard !hasResumed else { return }
                hasResumed = true

                monitor.cancel()
                continuation.resume(returning: false)
            }
        }
    }
}
