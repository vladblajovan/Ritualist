import Testing
import Foundation
import UserNotifications
@testable import RitualistCore

/// Infrastructure validation tests (Phase 0)
///
/// **Purpose:** Meta-tests that validate test infrastructure behavior before using it in Phase 1-3
///
/// **Why These Tests Matter:**
/// - Ensures InMemoryNotificationCenter behaves like UNUserNotificationCenter
/// - Validates UserProfileBuilder creates valid test data
/// - Prevents building 133-154 tests on unreliable infrastructure
/// - Early validation of "NO MOCKS" protocol abstraction approach
///
/// **Test Philosophy:**
/// These are NOT unit tests of production code - they test our test infrastructure.
/// Think of them as "meta-tests" that give us confidence the tools we built for testing are reliable.
@Suite("Infrastructure Validation Tests")
@MainActor
struct InfrastructureValidationTests {

    // MARK: - NotificationCenterProtocol Validation

    @Test("InMemoryNotificationCenter stores and retrieves requests")
    func notificationCenterBasicBehavior() async throws {
        let center = InMemoryNotificationCenter()

        // Create a test notification request
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Testing basic behavior"

        let request = UNNotificationRequest(
            identifier: "test-notification-1",
            content: content,
            trigger: nil
        )

        // Add the request
        try await center.add(request)

        // Retrieve pending requests
        let pending = await center.pendingNotificationRequests()

        // Verify
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "test-notification-1")
        #expect(pending.first?.content.title == "Test Notification")
    }

    @Test("InMemoryNotificationCenter removes requests by identifier")
    func notificationCenterRemoval() async throws {
        let center = InMemoryNotificationCenter()

        // Add two requests
        let request1 = UNNotificationRequest(
            identifier: "test-1",
            content: UNMutableNotificationContent(),
            trigger: nil
        )
        let request2 = UNNotificationRequest(
            identifier: "test-2",
            content: UNMutableNotificationContent(),
            trigger: nil
        )

        try await center.add(request1)
        try await center.add(request2)

        // Verify both added
        var pending = await center.pendingNotificationRequests()
        #expect(pending.count == 2)

        // Remove one by identifier
        await center.removePendingNotificationRequests(withIdentifiers: ["test-1"])

        // Verify only one remains
        pending = await center.pendingNotificationRequests()
        #expect(pending.count == 1)
        #expect(pending.first?.identifier == "test-2")

        // Verify removal was tracked
        let removed = await center.removedIdentifiers
        #expect(removed.contains("test-1"))
    }

    @Test("InMemoryNotificationCenter isolates multiple requests")
    func notificationCenterMultipleRequests() async throws {
        let center = InMemoryNotificationCenter()

        // Add multiple distinct requests
        for i in 1...5 {
            let content = UNMutableNotificationContent()
            content.title = "Notification \(i)"

            let request = UNNotificationRequest(
                identifier: "test-\(i)",
                content: content,
                trigger: nil
            )
            try await center.add(request)
        }

        // Verify all stored correctly
        let pending = await center.pendingNotificationRequests()
        #expect(pending.count == 5)

        // Verify identifiers are unique and correct
        let identifiers = pending.map { $0.identifier }
        #expect(Set(identifiers).count == 5) // All unique
        #expect(identifiers.contains("test-1"))
        #expect(identifiers.contains("test-5"))
    }

    @Test("InMemoryNotificationCenter handles duplicate identifiers correctly")
    func notificationCenterDuplicateHandling() async throws {
        let center = InMemoryNotificationCenter()

        // Add initial request
        let content1 = UNMutableNotificationContent()
        content1.title = "First Version"
        let request1 = UNNotificationRequest(
            identifier: "duplicate-test",
            content: content1,
            trigger: nil
        )
        try await center.add(request1)

        // Add request with same identifier (should replace)
        let content2 = UNMutableNotificationContent()
        content2.title = "Second Version"
        let request2 = UNNotificationRequest(
            identifier: "duplicate-test",
            content: content2,
            trigger: nil
        )
        try await center.add(request2)

        // Verify: should only have ONE request, with updated content
        let pending = await center.pendingNotificationRequests()
        #expect(pending.count == 1, "Duplicate identifier should replace, not add")
        #expect(pending.first?.identifier == "duplicate-test")
        #expect(pending.first?.content.title == "Second Version", "Content should be from second request")
    }

    @Test("InMemoryNotificationCenter removeAll clears all requests")
    func notificationCenterRemoveAll() async throws {
        let center = InMemoryNotificationCenter()

        // Add multiple requests
        for i in 1...3 {
            let request = UNNotificationRequest(
                identifier: "test-\(i)",
                content: UNMutableNotificationContent(),
                trigger: nil
            )
            try await center.add(request)
        }

        // Verify added
        var pending = await center.pendingNotificationRequests()
        #expect(pending.count == 3)

        // Remove all
        await center.removeAllPendingNotificationRequests()

        // Verify empty
        pending = await center.pendingNotificationRequests()
        #expect(pending.isEmpty)
    }

    @Test("InMemoryNotificationCenter reset clears state")
    func notificationCenterReset() async throws {
        let center = InMemoryNotificationCenter()

        // Add request and remove it
        let request = UNNotificationRequest(
            identifier: "test",
            content: UNMutableNotificationContent(),
            trigger: nil
        )
        try await center.add(request)
        await center.removePendingNotificationRequests(withIdentifiers: ["test"])

        // Verify state before reset
        var pending = await center.pendingNotificationRequests()
        var removed = await center.removedIdentifiers
        #expect(pending.isEmpty)
        #expect(!removed.isEmpty)

        // Reset
        await center.reset()

        // Verify complete reset
        pending = await center.pendingNotificationRequests()
        removed = await center.removedIdentifiers
        #expect(pending.isEmpty)
        #expect(removed.isEmpty)
    }

    // MARK: - UserProfileBuilder Validation

    @Test("UserProfileBuilder creates profile with home timezone")
    func userProfileBuilderHomeTimezone() throws {
        let newYorkTZ = TimeZone(identifier: "America/New_York")!

        let profile = UserProfileBuilder.standard(
            homeTimezone: newYorkTZ
        )

        // Verify timezone is set correctly
        #expect(profile.homeTimezoneIdentifier == "America/New_York")
        #expect(profile.currentTimezoneIdentifier == TimeZone.current.identifier, "Current timezone should default to system")
    }

    @Test("UserProfileBuilder creates profile with display timezone mode")
    func userProfileBuilderDisplayMode() throws {
        let profile = UserProfileBuilder.standard(
            displayMode: .home
        )

        // Verify display mode is set correctly
        #expect(profile.displayTimezoneMode == .home)
    }

    @Test("UserProfileBuilder creates profile for travel status")
    func userProfileBuilderTravelScenario() throws {
        let tokyoTZ = TimeZone(identifier: "Asia/Tokyo")!
        let laTZ = TimeZone(identifier: "America/Los_Angeles")!

        let profile = UserProfileBuilder.traveling(
            currentTimezone: tokyoTZ,
            homeTimezone: laTZ,
            displayMode: .home
        )

        // Verify travel scenario setup
        #expect(profile.currentTimezoneIdentifier == "Asia/Tokyo")
        #expect(profile.homeTimezoneIdentifier == "America/Los_Angeles")
        #expect(profile.displayTimezoneMode == .home)

        // Verify timezone change history is recorded
        #expect(!profile.timezoneChangeHistory.isEmpty, "Travel scenario should include timezone change history")
        #expect(profile.timezoneChangeHistory.first?.fromTimezone == "America/Los_Angeles")
        #expect(profile.timezoneChangeHistory.first?.toTimezone == "Asia/Tokyo")
    }
}
