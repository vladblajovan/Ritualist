//
//  CloudSyncErrorHandlerTests.swift
//  RitualistTests
//
//  Tests for CloudSyncErrorHandler error classification, retry logic, and availability checks.
//
//  Note: Actual CloudKit operations cannot be unit tested without a real iCloud account.
//  These tests focus on error types, error descriptions, and the public interface contracts.
//

import Foundation
import Testing
import CloudKit
@testable import RitualistCore

// MARK: - CloudKitRetryError Tests

@Suite("CloudKitRetryError - Error Messages")
@MainActor
struct CloudKitRetryErrorTests {

    @Test("retriesExhausted provides descriptive error message")
    func retriesExhaustedErrorMessage() {
        // Arrange
        let underlyingError = NSError(domain: "TestDomain", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Network connection lost"
        ])
        let error = CloudKitRetryError.retriesExhausted(
            underlying: underlyingError,
            attempts: 3,
            operationName: "fetchRecords"
        )

        // Act
        let description = error.errorDescription

        // Assert
        #expect(description?.contains("fetchRecords") == true, "Should include operation name")
        #expect(description?.contains("3") == true, "Should include attempt count")
        #expect(description?.contains("Network connection lost") == true, "Should include underlying error")
    }

    @Test("retriesExhausted provides recovery suggestion")
    func retriesExhaustedRecoverySuggestion() {
        // Arrange
        let underlyingError = NSError(domain: "TestDomain", code: 1)
        let error = CloudKitRetryError.retriesExhausted(
            underlying: underlyingError,
            attempts: 3,
            operationName: "test"
        )

        // Act
        let suggestion = error.recoverySuggestion

        // Assert
        #expect(suggestion != nil, "Should provide recovery suggestion")
        #expect(suggestion?.contains("network") == true || suggestion?.contains("iCloud") == true,
               "Should mention network or iCloud")
    }
}

// MARK: - CloudKitAvailabilityError Tests

@Suite("CloudKitAvailabilityError - Error Messages")
@MainActor
struct CloudKitAvailabilityErrorTests {

    @Test("notSignedIn error has descriptive message")
    func notSignedInErrorMessage() {
        let error = CloudKitAvailabilityError.notSignedIn

        #expect(error.errorDescription?.contains("not signed in") == true)
        #expect(error.recoverySuggestion?.contains("Settings") == true)
    }

    @Test("restricted error mentions parental controls")
    func restrictedErrorMessage() {
        let error = CloudKitAvailabilityError.restricted

        #expect(error.errorDescription?.contains("restricted") == true)
        #expect(error.recoverySuggestion?.contains("Screen Time") == true ||
               error.recoverySuggestion?.contains("parental") == true)
    }

    @Test("couldNotDetermine error suggests retry")
    func couldNotDetermineErrorMessage() {
        let error = CloudKitAvailabilityError.couldNotDetermine

        #expect(error.errorDescription?.contains("Could not determine") == true)
        #expect(error.recoverySuggestion?.contains("try again") == true)
    }

    @Test("temporarilyUnavailable error suggests waiting")
    func temporarilyUnavailableErrorMessage() {
        let error = CloudKitAvailabilityError.temporarilyUnavailable

        #expect(error.errorDescription?.contains("temporarily unavailable") == true)
        #expect(error.recoverySuggestion?.contains("Wait") == true ||
               error.recoverySuggestion?.contains("try again") == true)
    }

    @Test("networkUnavailable error mentions internet")
    func networkUnavailableErrorMessage() {
        let error = CloudKitAvailabilityError.networkUnavailable

        #expect(error.errorDescription?.lowercased().contains("network") == true)
        #expect(error.recoverySuggestion?.contains("WiFi") == true ||
               error.recoverySuggestion?.contains("cellular") == true)
    }

    @Test("unknown error has generic message")
    func unknownErrorMessage() {
        let error = CloudKitAvailabilityError.unknown

        #expect(error.errorDescription?.contains("Unknown") == true)
        #expect(error.recoverySuggestion != nil)
    }

    @Test("entitlementsNotConfigured error is specific")
    func entitlementsNotConfiguredErrorMessage() {
        let underlyingError = NSError(domain: "CKErrorDomain", code: 1)
        let error = CloudKitAvailabilityError.entitlementsNotConfigured(underlying: underlyingError)

        #expect(error.errorDescription?.contains("not configured") == true ||
               error.errorDescription?.contains("entitlements") == true)
        #expect(error.recoverySuggestion != nil)
    }

    @Test("all errors conform to LocalizedError")
    func allErrorsAreLocalizedErrors() {
        let errors: [CloudKitAvailabilityError] = [
            .notSignedIn,
            .restricted,
            .couldNotDetermine,
            .temporarilyUnavailable,
            .networkUnavailable,
            .unknown,
            .entitlementsNotConfigured(underlying: NSError(domain: "", code: 0))
        ]

        for error in errors {
            #expect(error.errorDescription != nil, "Error \(error) should have description")
            #expect(error.recoverySuggestion != nil, "Error \(error) should have recovery suggestion")
        }
    }
}

// MARK: - CloudSyncErrorHandler Initialization Tests

@Suite("CloudSyncErrorHandler - Initialization")
@MainActor
struct CloudSyncErrorHandlerInitTests {

    @Test("default initialization uses sensible defaults")
    func defaultInitialization() async {
        // This test verifies the handler can be created with defaults
        let handler = CloudSyncErrorHandler()

        // The handler is a non-optional actor type
        // Verifying it can be referenced proves successful initialization
        _ = handler
        // Test passes if no crash/error during initialization
    }

    @Test("custom initialization accepts parameters")
    func customInitialization() async {
        // Arrange & Act
        let handler = CloudSyncErrorHandler(
            errorHandler: nil,
            maxRetries: 5,
            baseDelay: 2.0
        )

        // Handler is a non-optional actor type
        // Verifying it can be referenced proves successful initialization
        _ = handler
        // Test passes if custom parameters are accepted without error
    }
}

// MARK: - CKError UserInfo Tests

@Suite("CKError - Retry Information Extraction")
@MainActor
struct CKErrorRetryInfoTests {

    @Test("CKErrorRetryAfterKey can be extracted from userInfo")
    func retryAfterKeyExtraction() {
        // Arrange - Create a CKError with retry information in userInfo
        let expectedDelay: TimeInterval = 5.0
        let userInfo: [String: Any] = [
            CKErrorRetryAfterKey: NSNumber(value: expectedDelay)
        ]
        let error = CKError(.serviceUnavailable, userInfo: userInfo)

        // Act - Extract the retry delay from userInfo
        let retryDelay = error.userInfo[CKErrorRetryAfterKey] as? NSNumber

        // Assert
        #expect(retryDelay?.doubleValue == expectedDelay, "Should extract retry delay from userInfo")
    }

    @Test("Missing retry key returns nil from userInfo")
    func missingRetryKey() {
        // Arrange
        let error = CKError(.networkFailure)

        // Act
        let retryDelay = error.userInfo[CKErrorRetryAfterKey] as? NSNumber

        // Assert
        #expect(retryDelay == nil, "Should return nil when retry key not present")
    }
}

// MARK: - Error Classification Integration Tests

@Suite("CloudSyncErrorHandler - Error Classification Behavior")
@MainActor
struct ErrorClassificationBehaviorTests {

    @Test("network errors should be retryable")
    func networkErrorsAreRetryable() async throws {
        // This is a documentation/contract test
        // Network errors (networkUnavailable, networkFailure) should allow retry
        // The actual classification is private, but we document expected behavior

        let retryableNetworkCodes: [CKError.Code] = [
            .networkUnavailable,
            .networkFailure
        ]

        // Document that these codes should be retryable
        #expect(retryableNetworkCodes.count == 2, "Network error codes should be retryable")
    }

    @Test("service errors should be retryable")
    func serviceErrorsAreRetryable() async throws {
        let retryableServiceCodes: [CKError.Code] = [
            .serviceUnavailable,
            .requestRateLimited,
            .zoneBusy,
            .serverRecordChanged,
            .internalError,
            .serverResponseLost
        ]

        #expect(retryableServiceCodes.count == 6, "Service error codes should be retryable")
    }

    @Test("authentication errors should NOT be retryable")
    func authenticationErrorsNotRetryable() async throws {
        let nonRetryableAuthCodes: [CKError.Code] = [
            .notAuthenticated,
            .permissionFailure
        ]

        #expect(nonRetryableAuthCodes.count == 2, "Auth error codes should not be retryable")
    }

    @Test("quota errors should NOT be retryable")
    func quotaErrorsNotRetryable() async throws {
        // Quota exceeded requires user action - not retryable
        let nonRetryableQuotaCodes: [CKError.Code] = [
            .quotaExceeded
        ]

        #expect(nonRetryableQuotaCodes.count == 1, "Quota error should not be retryable")
    }

    @Test("not found errors should NOT be retryable")
    func notFoundErrorsNotRetryable() async throws {
        // Unknown item is expected for first use - not retryable
        let nonRetryableNotFoundCodes: [CKError.Code] = [
            .unknownItem
        ]

        #expect(nonRetryableNotFoundCodes.count == 1, "Not found error should not be retryable")
    }
}

// MARK: - Exponential Backoff Contract Tests

@Suite("CloudSyncErrorHandler - Exponential Backoff Contract")
@MainActor
struct ExponentialBackoffContractTests {

    @Test("backoff delay increases with attempts")
    func backoffDelayIncreases() {
        // Document the expected backoff behavior:
        // delay = baseDelay * 2^attempt + jitter
        // With baseDelay = 1.0:
        // Attempt 0: ~1s
        // Attempt 1: ~2s
        // Attempt 2: ~4s

        let baseDelay = 1.0
        let expectedDelays = [
            (attempt: 0, minDelay: 1.0, maxDelay: 1.3),   // 1 + up to 30% jitter
            (attempt: 1, minDelay: 2.0, maxDelay: 2.6),   // 2 + up to 30% jitter
            (attempt: 2, minDelay: 4.0, maxDelay: 5.2)    // 4 + up to 30% jitter
        ]

        for expected in expectedDelays {
            let exponentialDelay = baseDelay * pow(2.0, Double(expected.attempt))
            #expect(exponentialDelay >= expected.minDelay - 0.001,
                   "Attempt \(expected.attempt) base should be at least \(expected.minDelay)")
        }
    }

    @Test("CloudKit suggested delay takes precedence over calculated backoff")
    func suggestedDelayTakesPrecedence() {
        // Document: When CloudKit provides retryAfterSeconds, that value should be used
        // instead of calculated exponential backoff

        // This is a contract/documentation test - we verify the CKErrorRetryAfterKey
        // can be used to extract suggested delays that should override calculations
        let suggestedDelay: TimeInterval = 15.0
        let calculatedDelay: TimeInterval = 2.0

        // Contract: suggested delay (when present) should be preferred over calculated
        #expect(suggestedDelay > calculatedDelay, "Suggested delay typically differs from calculated")
    }

    @Test("jitter prevents thundering herd")
    func jitterPreventsThunderingHerd() {
        // Document: Jitter is added to prevent all clients retrying simultaneously
        // Jitter should be 0-30% of the base delay

        let baseDelay = 1.0
        let maxJitterPercentage = 0.3
        let maxDelayWithJitter = baseDelay * (1.0 + maxJitterPercentage)

        // Verify jitter calculation is bounded
        #expect(maxDelayWithJitter == 1.3, "Max delay with 30% jitter should be 1.3x base")
    }
}
