//
//  AsyncTimeout.swift
//  RitualistCore
//
//  Utilities for adding timeout behavior to async operations that don't respect
//  Swift's cooperative cancellation (e.g., CloudKit, CoreLocation).
//

import Foundation

// MARK: - Async Timeout
// ============================================================================
//
// WHY THIS EXISTS
// ---------------
// Swift's structured concurrency uses cooperative cancellation - when you call
// `task.cancel()`, it merely sets a flag. The task must voluntarily check
// `Task.isCancelled` and stop itself. Many Apple frameworks (CloudKit,
// CoreLocation, etc.) don't respect this cancellation.
//
// This creates a problem: if CloudKit hangs on a poor network, there's no way
// to "force quit" the operation. Even `withTaskGroup` + `cancelAll()` doesn't
// help because task groups wait for ALL children to complete before returning.
//
// WHAT THIS SOLVES
// ----------------
// The `withTimeout` function provides true timeout behavior by:
// 1. Racing the operation against a timer using unstructured `Task`s
// 2. Using a `FirstWinsCoordinator` actor to ensure only the first result
//    (success or timeout) is used
// 3. Returning immediately when timeout occurs, even if the operation continues
//    running in the background
//
// WHERE IT'S USED
// ---------------
// 1. iCloudSyncUseCases.swift - CheckiCloudStatusUseCase
//    - `CKContainer.accountStatus()` can hang indefinitely on poor networks
//    - 10-second timeout prevents the Settings UI from freezing
//    - Returns `.unknown` status on timeout so the app remains responsive
//
// ALTERNATIVES CONSIDERED
// -----------------------
// - Swift Async Algorithms `race()`: Still relies on cooperative cancellation
// - `withTaskGroup` + timeout task: Waits for ALL tasks, doesn't actually timeout
// - `withTaskCancellationHandler`: Only reacts to cancellation, doesn't provide timeout
// - Apple's built-in timeout parameters: Don't exist for these APIs
//
// ============================================================================

/// Execute an async operation with a timeout, returning a fallback value if timeout occurs.
///
/// Use this for APIs that don't respect Swift's cooperative cancellation (e.g., CloudKit).
/// The operation continues running in the background after timeout, but the caller proceeds
/// with the fallback value.
///
/// ## Example Usage
/// ```swift
/// let status = await withTimeout(
///     seconds: 10,
///     operation: { await cloudKit.accountStatus() },
///     onTimeout: { .unknown }
/// )
/// ```
///
/// - Parameters:
///   - seconds: Maximum time to wait before timing out
///   - operation: The async operation to execute
///   - onTimeout: Closure that returns a fallback value when timeout occurs
/// - Returns: Either the operation result or the timeout fallback value
public func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async -> T,
    onTimeout: @escaping @Sendable () -> T
) async -> T {
    precondition(seconds > 0, "Timeout must be positive")
    let coordinator = FirstWinsCoordinator()

    return await withCheckedContinuation { continuation in
        // Start the actual operation
        let operationTask = Task {
            let result = await operation()
            if await coordinator.tryComplete() {
                continuation.resume(returning: result)
            }
        }

        // Start timeout timer
        Task {
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch is CancellationError {
                // Task was cancelled (e.g., parent task cancelled) - don't trigger timeout
                return
            } catch {
                // Unexpected error - skip timeout (shouldn't happen with Task.sleep)
                return
            }
            if await coordinator.tryComplete() {
                operationTask.cancel() // Request cancellation (may be ignored)
                continuation.resume(returning: onTimeout())
            }
        }
    }
}

/// Execute an async throwing operation with a timeout.
///
/// - Parameters:
///   - seconds: Maximum time to wait before timing out
///   - operation: The async throwing operation to execute
///   - onTimeout: Closure that returns a fallback value when timeout occurs
/// - Returns: Either the operation result or the timeout fallback value
/// - Throws: Rethrows any error from the operation (timeout returns fallback, doesn't throw)
public func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T,
    onTimeout: @escaping @Sendable () -> T
) async throws -> T {
    precondition(seconds > 0, "Timeout must be positive")
    let coordinator = FirstWinsCoordinator()

    return try await withCheckedThrowingContinuation { continuation in
        // Start the actual operation
        let operationTask = Task {
            do {
                let result = try await operation()
                if await coordinator.tryComplete() {
                    continuation.resume(returning: result)
                }
            } catch {
                if await coordinator.tryComplete() {
                    continuation.resume(throwing: error)
                }
            }
        }

        // Start timeout timer
        Task {
            do {
                try await Task.sleep(for: .seconds(seconds))
            } catch is CancellationError {
                // Task was cancelled (e.g., parent task cancelled) - don't trigger timeout
                return
            } catch {
                // Unexpected error - skip timeout (shouldn't happen with Task.sleep)
                return
            }
            if await coordinator.tryComplete() {
                operationTask.cancel() // Request cancellation (may be ignored)
                continuation.resume(returning: onTimeout())
            }
        }
    }
}

// MARK: - First Wins Coordinator

/// Actor to safely coordinate first-wins semantics between concurrent operations.
///
/// Ensures only the first result (success, error, or timeout) is used, preventing
/// multiple continuations from being resumed.
private actor FirstWinsCoordinator {
    private var isComplete = false

    func tryComplete() -> Bool {
        if isComplete { return false }
        isComplete = true
        return true
    }
}
