//
//  CloudSyncErrorHandler.swift
//  RitualistCore
//
//  Handles CloudKit sync errors with retry logic and error classification
//

import Foundation
import CloudKit

/// Handles CloudKit sync errors with intelligent retry logic and error classification
public actor CloudSyncErrorHandler {

    private let errorHandler: ErrorHandler?
    private let maxRetries: Int
    private let baseDelay: TimeInterval

    /// Initialize error handler with retry configuration
    /// - Parameters:
    ///   - errorHandler: Optional general error handler for logging
    ///   - maxRetries: Maximum number of retry attempts (default: 3)
    ///   - baseDelay: Base delay for exponential backoff in seconds (default: 1.0)
    public init(
        errorHandler: ErrorHandler? = nil,
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0
    ) {
        self.errorHandler = errorHandler
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
    }

    // MARK: - Public Interface

    /// Execute CloudKit operation with automatic retry on transient failures
    /// - Parameters:
    ///   - operation: Async operation to execute
    ///   - operationName: Name of operation for logging
    /// - Returns: Result of the operation
    /// - Throws: Error if all retries exhausted or non-retryable error
    public func executeWithRetry<T>(
        operation: @escaping () async throws -> T,
        operationName: String
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<maxRetries {
            do {
                // Execute the operation
                let result = try await operation()

                // Log success if this was a retry
                if attempt > 0 {
                    await errorHandler?.logError(
                        RetrySuccess(attemptNumber: attempt + 1),
                        context: ErrorContext.sync + "_retry_success",
                        additionalProperties: [
                            "operation": operationName,
                            "attempt": String(attempt + 1)
                        ]
                    )
                }

                return result

            } catch {
                lastError = error

                // Classify the error
                let classification = classifyError(error)

                // Log the error
                await errorHandler?.logError(
                    error,
                    context: ErrorContext.sync + "_\(classification.category)",
                    additionalProperties: [
                        "operation": operationName,
                        "attempt": String(attempt + 1),
                        "retryable": String(classification.isRetryable),
                        "suggested_delay": String(classification.suggestedDelay ?? 0)
                    ]
                )

                // Check if error is retryable
                guard classification.isRetryable else {
                    throw error  // Non-retryable error - fail immediately
                }

                // Check if we have more retries left
                guard attempt < maxRetries - 1 else {
                    break  // No more retries - will throw below
                }

                // Calculate delay with exponential backoff
                let delay = calculateDelay(
                    attempt: attempt,
                    suggestedDelay: classification.suggestedDelay
                )

                // Wait before retrying
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
        }

        // All retries exhausted - throw the last error
        throw CloudKitRetryError.retriesExhausted(
            underlying: lastError!,
            attempts: maxRetries,
            operationName: operationName
        )
    }

    /// Check if user is signed into iCloud
    /// - Returns: Account status
    /// - Throws: CloudKitAvailabilityError if CloudKit is not configured or unavailable
    public func checkiCloudAccountStatus() async throws -> CKAccountStatus {
        do {
            let container = CKContainer(identifier: "iCloud.com.vladblajovan.Ritualist")
            return try await container.accountStatus()
        } catch {
            // If we can't access CloudKit container (e.g., entitlements not configured),
            // throw a specific error indicating CloudKit is unavailable
            throw CloudKitAvailabilityError.entitlementsNotConfigured(underlying: error)
        }
    }

    /// Validate that CloudKit is available and user is signed in
    /// - Throws: CloudKitAvailabilityError if CloudKit unavailable
    public func validateCloudKitAvailability() async throws {
        let status = try await checkiCloudAccountStatus()

        switch status {
        case .available:
            return  // All good

        case .noAccount:
            throw CloudKitAvailabilityError.notSignedIn

        case .restricted:
            throw CloudKitAvailabilityError.restricted

        case .couldNotDetermine:
            throw CloudKitAvailabilityError.couldNotDetermine

        case .temporarilyUnavailable:
            throw CloudKitAvailabilityError.temporarilyUnavailable

        @unknown default:
            throw CloudKitAvailabilityError.unknown
        }
    }

    // MARK: - Error Classification

    /// Classify CloudKit error for retry decision
    /// - Parameter error: Error to classify
    /// - Returns: Error classification with retry recommendation
    private func classifyError(_ error: Error) -> ErrorClassification {
        // Check if it's a CKError
        guard let ckError = error as? CKError else {
            // Unknown error type - don't retry
            return ErrorClassification(
                category: "unknown",
                isRetryable: false,
                suggestedDelay: nil
            )
        }

        // Classify based on CKError code
        switch ckError.code {
        // Network-related errors - retryable
        case .networkUnavailable, .networkFailure:
            return ErrorClassification(
                category: "network",
                isRetryable: true,
                suggestedDelay: ckError.retryAfterSeconds ?? baseDelay
            )

        // Service temporarily unavailable - retryable
        case .serviceUnavailable, .requestRateLimited:
            return ErrorClassification(
                category: "service_unavailable",
                isRetryable: true,
                suggestedDelay: ckError.retryAfterSeconds ?? (baseDelay * 2)
            )

        // Zone/record busy - retryable
        case .zoneBusy, .serverRecordChanged:
            return ErrorClassification(
                category: "busy",
                isRetryable: true,
                suggestedDelay: ckError.retryAfterSeconds ?? baseDelay
            )

        // Quota exceeded - not retryable (needs user action)
        case .quotaExceeded:
            return ErrorClassification(
                category: "quota_exceeded",
                isRetryable: false,
                suggestedDelay: nil
            )

        // Authentication errors - not retryable
        case .notAuthenticated, .permissionFailure:
            return ErrorClassification(
                category: "authentication",
                isRetryable: false,
                suggestedDelay: nil
            )

        // Record not found - not retryable (expected for first use)
        case .unknownItem:
            return ErrorClassification(
                category: "not_found",
                isRetryable: false,
                suggestedDelay: nil
            )

        // Asset file errors - retryable with longer delay
        case .assetFileNotFound, .assetFileModified:
            return ErrorClassification(
                category: "asset_error",
                isRetryable: true,
                suggestedDelay: baseDelay * 3
            )

        // Server errors - retryable
        case .internalError, .serverResponseLost:
            return ErrorClassification(
                category: "server_error",
                isRetryable: true,
                suggestedDelay: ckError.retryAfterSeconds ?? (baseDelay * 2)
            )

        // Other errors - not retryable by default
        default:
            return ErrorClassification(
                category: "other",
                isRetryable: false,
                suggestedDelay: nil
            )
        }
    }

    /// Calculate exponential backoff delay
    /// - Parameters:
    ///   - attempt: Current attempt number (0-indexed)
    ///   - suggestedDelay: CloudKit-suggested delay (if available)
    /// - Returns: Delay in seconds
    private func calculateDelay(attempt: Int, suggestedDelay: TimeInterval?) -> TimeInterval {
        // If CloudKit suggests a delay, use it
        if let suggested = suggestedDelay {
            return suggested
        }

        // Otherwise, use exponential backoff: baseDelay * 2^attempt
        // With jitter to avoid thundering herd
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.3) * exponentialDelay

        return exponentialDelay + jitter
    }
}

// MARK: - Error Classification

/// Classification result for an error
private struct ErrorClassification {
    let category: String
    let isRetryable: Bool
    let suggestedDelay: TimeInterval?
}

// MARK: - Retry Errors

/// Errors related to retry logic
public enum CloudKitRetryError: LocalizedError {
    case retriesExhausted(underlying: Error, attempts: Int, operationName: String)

    public var errorDescription: String? {
        switch self {
        case .retriesExhausted(let underlying, let attempts, let operationName):
            return "CloudKit operation '\(operationName)' failed after \(attempts) retry attempts. Last error: \(underlying.localizedDescription)"
        }
    }

    public var recoverySuggestion: String? {
        "Check network connection and iCloud status. Try again later."
    }
}

/// Success marker for retry operations (for logging)
private struct RetrySuccess: Error {
    let attemptNumber: Int

    var localizedDescription: String {
        "Operation succeeded on retry attempt \(attemptNumber)"
    }
}

// MARK: - Availability Errors

/// Errors related to CloudKit availability
public enum CloudKitAvailabilityError: LocalizedError {
    case notSignedIn
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable
    case unknown
    case entitlementsNotConfigured(underlying: Error)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            return "iCloud account not signed in. Sign in to enable sync across devices."
        case .restricted:
            return "iCloud is restricted. Check Screen Time or parental controls."
        case .couldNotDetermine:
            return "Could not determine iCloud account status. Try again."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable. Try again in a few moments."
        case .unknown:
            return "Unknown iCloud account status."
        case .entitlementsNotConfigured:
            return "iCloud sync is not configured. CloudKit entitlements are not enabled."
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notSignedIn:
            return "Go to Settings → Sign in to your iPhone to enable iCloud sync."
        case .restricted:
            return "Check Settings → Screen Time → Content & Privacy Restrictions."
        case .couldNotDetermine, .temporarilyUnavailable:
            return "Wait a moment and try again. Check network connection."
        case .unknown:
            return "Restart the app and try again."
        case .entitlementsNotConfigured:
            return "iCloud sync will be available in a future update. Contact support for more information."
        }
    }
}

// MARK: - CKError Extension

extension CKError {
    /// Extract retry delay from CloudKit error if available
    var retryAfterSeconds: TimeInterval? {
        guard let retryAfter = userInfo[CKErrorRetryAfterKey] as? NSNumber else {
            return nil
        }
        return retryAfter.doubleValue
    }
}
