import Foundation
import UserNotifications
@testable import RitualistCore

// MARK: - NotificationCenterProtocol

/// Protocol abstraction for UNUserNotificationCenter
///
/// **NOT A MOCK** - This is a protocol abstraction that enables testability
/// while maintaining the "NO MOCKS" philosophy:
///
/// - `SystemNotificationCenter`: Real wrapper around UNUserNotificationCenter (production)
/// - `InMemoryNotificationCenter`: Real in-memory implementation (testing)
///
/// Both implementations provide real behavior - no mocking, no test doubles.
/// This is the ONLY acceptable exception to the "NO MOCKS" rule because
/// UNUserNotificationCenter is a system framework that cannot be instantiated in tests.
///
/// **Why This Is Not Mocking:**
/// - Protocol represents the actual interface we need
/// - Both implementations have real, observable behavior
/// - No fake return values or stubbed responses
/// - InMemoryNotificationCenter actually stores and manages notifications
protocol NotificationCenterProtocol {

    /// Add a notification request to be scheduled
    func add(_ request: UNNotificationRequest) async throws

    /// Get all pending notification requests
    func pendingNotificationRequests() async -> [UNNotificationRequest]

    /// Remove pending notification requests by identifiers
    func removePendingNotificationRequests(withIdentifiers: [String]) async

    /// Remove all pending notification requests
    func removeAllPendingNotificationRequests() async
}

// MARK: - SystemNotificationCenter (Production)

/// Production wrapper for UNUserNotificationCenter
///
/// **Purpose:** Provides real notification scheduling in production app
///
/// **Usage:**
/// ```swift
/// let notificationCenter: NotificationCenterProtocol = SystemNotificationCenter()
/// try await notificationCenter.add(request)
/// ```
final class SystemNotificationCenter: NotificationCenterProtocol {

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    func add(_ request: UNNotificationRequest) async throws {
        try await center.add(request)
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    func removeAllPendingNotificationRequests() async {
        center.removeAllPendingNotificationRequests()
    }
}

// MARK: - InMemoryNotificationCenter (Testing)

/// In-memory notification center for testing
///
/// **Purpose:** Provides real in-memory notification management without system dependencies
///
/// **Behavior:**
/// - Actually stores notification requests in memory
/// - Handles duplicate identifiers correctly (replaces existing)
/// - Supports removal by identifier
/// - Thread-safe with actor isolation
///
/// **This Is NOT A Mock:**
/// - Has real, observable state (pendingRequests array)
/// - Implements actual notification management logic
/// - Can be queried and verified after operations
/// - Behavior matches UNUserNotificationCenter semantics
///
/// **Usage:**
/// ```swift
/// let center = InMemoryNotificationCenter()
/// try await center.add(request)
/// let pending = await center.pendingNotificationRequests()
/// #expect(pending.count == 1)
/// ```
actor InMemoryNotificationCenter: NotificationCenterProtocol {

    // MARK: - State

    /// In-memory storage for pending notification requests
    private(set) var pendingRequests: [UNNotificationRequest] = []

    /// Identifiers of removed requests (for debugging/verification)
    private(set) var removedIdentifiers: [String] = []

    // MARK: - NotificationCenterProtocol

    func add(_ request: UNNotificationRequest) async throws {
        // Mimic UNUserNotificationCenter behavior: if identifier exists, replace it
        if let existingIndex = pendingRequests.firstIndex(where: { $0.identifier == request.identifier }) {
            pendingRequests[existingIndex] = request
        } else {
            pendingRequests.append(request)
        }
    }

    func pendingNotificationRequests() async -> [UNNotificationRequest] {
        return pendingRequests
    }

    func removePendingNotificationRequests(withIdentifiers identifiers: [String]) async {
        pendingRequests.removeAll { request in
            identifiers.contains(request.identifier)
        }
        removedIdentifiers.append(contentsOf: identifiers)
    }

    func removeAllPendingNotificationRequests() async {
        let allIds = pendingRequests.map { $0.identifier }
        pendingRequests.removeAll()
        removedIdentifiers.append(contentsOf: allIds)
    }

    // MARK: - Test Utilities

    /// Reset state between tests
    func reset() {
        pendingRequests.removeAll()
        removedIdentifiers.removeAll()
    }

    /// Get request by identifier (for test verification)
    func request(withIdentifier identifier: String) -> UNNotificationRequest? {
        return pendingRequests.first { $0.identifier == identifier }
    }
}
