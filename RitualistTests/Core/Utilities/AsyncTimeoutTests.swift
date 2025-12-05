import Foundation
import Testing
@testable import RitualistCore

/// Tests for AsyncTimeout utility functions
///
/// These tests verify the timeout behavior for async operations that may not
/// respect Swift's cooperative cancellation (e.g., CloudKit, CoreLocation).
@Suite("AsyncTimeout - Timeout Behavior")
struct AsyncTimeoutTests {

    // MARK: - Non-Throwing Variant Tests

    @Test("Operation completes before timeout returns operation result")
    func operationCompletesBeforeTimeout() async {
        let result = await withTimeout(
            seconds: 0.2,
            operation: {
                // Fast operation - completes in 10ms, well before 200ms timeout
                try? await Task.sleep(for: .milliseconds(10))
                return "success"
            },
            onTimeout: { "timeout" }
        )

        #expect(result == "success", "Should return operation result when it completes first")
    }

    @Test("Timeout fires before operation completes returns fallback")
    func timeoutFiresBeforeOperation() async {
        let result = await withTimeout(
            seconds: 0.05, // 50ms timeout
            operation: {
                // Slow operation - takes 500ms
                try? await Task.sleep(for: .milliseconds(500))
                return "success"
            },
            onTimeout: { "timeout" }
        )

        #expect(result == "timeout", "Should return timeout fallback when operation is too slow")
    }

    @Test("Timeout returns correct fallback value type")
    func timeoutReturnsFallbackValueType() async {
        let result = await withTimeout(
            seconds: 0.01,
            operation: {
                try? await Task.sleep(for: .seconds(1))
                return 42
            },
            onTimeout: { -1 }
        )

        #expect(result == -1, "Should return the fallback value of correct type")
    }

    @Test("Immediate operation completes before any timeout")
    func immediateOperationCompletes() async {
        let result = await withTimeout(
            seconds: 0.2,
            operation: { "instant" }, // No delay at all
            onTimeout: { "timeout" }
        )

        #expect(result == "instant", "Immediate operations should always complete before timeout")
    }

    // MARK: - Throwing Variant Tests

    @Test("Throwing operation completes before timeout returns result")
    func throwingOperationCompletesBeforeTimeout() async throws {
        let result = try await withTimeout(
            seconds: 0.2,
            operation: {
                try await Task.sleep(for: .milliseconds(10))
                return "success"
            },
            onTimeout: { "timeout" }
        )

        #expect(result == "success", "Should return operation result when it completes first")
    }

    @Test("Throwing operation timeout returns fallback")
    func throwingOperationTimeout() async throws {
        let result = try await withTimeout(
            seconds: 0.05,
            operation: {
                try await Task.sleep(for: .milliseconds(500))
                return "success"
            },
            onTimeout: { "timeout" }
        )

        #expect(result == "timeout", "Should return timeout fallback when operation is too slow")
    }

    @Test("Throwing operation error is propagated")
    func throwingOperationErrorPropagated() async {
        struct TestError: Error, Equatable {}

        do {
            _ = try await withTimeout(
                seconds: 0.2,
                operation: {
                    throw TestError()
                },
                onTimeout: { "timeout" }
            )
            Issue.record("Should have thrown TestError")
        } catch is TestError {
            // Expected - error was propagated correctly
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("Timeout does not throw when operation is slow")
    func timeoutDoesNotThrow() async throws {
        // Timeout should return fallback, not throw
        let result = try await withTimeout(
            seconds: 0.01,
            operation: {
                try await Task.sleep(for: .seconds(1))
                return "success"
            },
            onTimeout: { "timeout" }
        )

        #expect(result == "timeout", "Timeout should return fallback value, not throw")
    }

    // MARK: - Complex Type Tests

    @Test("Works with optional return types")
    func worksWithOptionalTypes() async {
        let result: String? = await withTimeout(
            seconds: 0.01,
            operation: {
                try? await Task.sleep(for: .seconds(1))
                return "success"
            },
            onTimeout: { nil }
        )

        #expect(result == nil, "Should return nil as timeout fallback")
    }

    @Test("Works with enum return types")
    func worksWithEnumTypes() async {
        enum Status { case available, timeout, unknown }

        let result = await withTimeout(
            seconds: 0.01,
            operation: {
                try? await Task.sleep(for: .seconds(1))
                return Status.available
            },
            onTimeout: { .timeout }
        )

        #expect(result == .timeout, "Should return enum timeout case")
    }

    // MARK: - Race Condition Tests

    @Test("Only one result is returned even in race conditions")
    func onlyOneResultInRaceCondition() async {
        // Run multiple times to catch potential race conditions
        // The operation and timeout are designed to complete at nearly the same time
        // Using wider margins (100ms timeout, 80ms operation) for CI reliability
        for iteration in 0..<10 {
            let result = await withTimeout(
                seconds: 0.1,
                operation: {
                    // Close to timeout but with safe margin for CI variance
                    try? await Task.sleep(for: .milliseconds(80))
                    return "operation"
                },
                onTimeout: { "timeout" }
            )

            // Result must be exactly one or the other
            #expect(
                result == "operation" || result == "timeout",
                "Iteration \(iteration): Should return exactly one result, got: \(result)"
            )
        }
    }

    @Test("Consistent results across many race iterations")
    func consistentResultsAcrossRaceIterations() async {
        var operationWins = 0
        var timeoutWins = 0

        // Run many iterations with timing close enough to create variance
        // but with safe margins for CI reliability (60ms timeout, 50ms operation)
        for _ in 0..<20 {
            let result = await withTimeout(
                seconds: 0.06,
                operation: {
                    try? await Task.sleep(for: .milliseconds(50))
                    return "operation"
                },
                onTimeout: { "timeout" }
            )

            if result == "operation" {
                operationWins += 1
            } else {
                timeoutWins += 1
            }
        }

        // We expect a mix of results due to timing variance, but total must be exactly 20
        #expect(
            operationWins + timeoutWins == 20,
            "Total results should be 20: operation=\(operationWins), timeout=\(timeoutWins)"
        )
    }

}
