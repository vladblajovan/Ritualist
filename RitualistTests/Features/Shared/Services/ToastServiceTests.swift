import Foundation
import Testing
@testable import Ritualist

/// Tests for ToastService
///
/// Verifies toast stacking, deduplication, max size limits, and expiration behavior.
@Suite("ToastService - Toast Management")
@MainActor
struct ToastServiceTests {

    // MARK: - Basic Operations

    @Test("Show adds toast to stack")
    func showAddsToast() {
        let service = ToastService()

        service.show(.success("Test message"))

        #expect(service.toasts.count == 1)
        #expect(service.toasts.first?.type.message == "Test message")
        #expect(service.hasActiveToasts == true)
    }

    @Test("Multiple toasts are stacked newest first")
    func toastsStackedNewestFirst() {
        let service = ToastService()

        service.show(.success("First"))
        service.show(.info("Second"))
        service.show(.warning("Third"))

        #expect(service.toasts.count == 3)
        #expect(service.toasts[0].type.message == "Third")
        #expect(service.toasts[1].type.message == "Second")
        #expect(service.toasts[2].type.message == "First")
    }

    @Test("Dismiss removes specific toast")
    func dismissRemovesSpecificToast() {
        let service = ToastService()

        service.show(.success("Keep me"))
        service.show(.info("Remove me"))

        let toastToRemove = service.toasts.first { $0.type.message == "Remove me" }!

        service.dismiss(toastToRemove.id)

        #expect(service.toasts.count == 1)
        #expect(service.toasts.first?.type.message == "Keep me")
    }

    @Test("DismissAll clears all toasts")
    func dismissAllClearsAllToasts() {
        let service = ToastService()

        service.show(.success("One"))
        service.show(.info("Two"))
        service.show(.warning("Three"))

        service.dismissAll()

        #expect(service.toasts.isEmpty)
        #expect(service.hasActiveToasts == false)
    }

    // MARK: - Deduplication

    @Test("Duplicate messages are not added")
    func duplicateMessagesNotAdded() {
        let service = ToastService()

        service.show(.success("Same message"))
        service.show(.success("Same message"))
        service.show(.error("Same message")) // Different type, same message

        #expect(service.toasts.count == 1, "Should only have one toast despite multiple show calls with same message")
    }

    @Test("Different messages are all added")
    func differentMessagesAllAdded() {
        let service = ToastService()

        service.show(.success("Message A"))
        service.show(.success("Message B"))
        service.show(.success("Message C"))

        #expect(service.toasts.count == 3)
    }

    @Test("After dismissing, same message can be shown again")
    func canShowSameMessageAfterDismiss() {
        let service = ToastService()

        service.show(.success("Repeatable"))
        let toastId = service.toasts.first!.id
        service.dismiss(toastId)

        service.show(.success("Repeatable"))

        #expect(service.toasts.count == 1)
        #expect(service.toasts.first?.type.message == "Repeatable")
    }

    // MARK: - Max Stack Size

    @Test("Stack is limited to maxVisibleToasts")
    func stackLimitedToMaxVisible() {
        let service = ToastService()

        // Add more than max (3)
        service.show(.success("Toast 1"))
        service.show(.success("Toast 2"))
        service.show(.success("Toast 3"))
        service.show(.success("Toast 4"))
        service.show(.success("Toast 5"))

        #expect(service.toasts.count == ToastService.maxVisibleToasts)
    }

    @Test("Newest toasts are kept when exceeding max")
    func newestToastsKeptWhenExceedingMax() {
        let service = ToastService()

        service.show(.success("Old 1"))
        service.show(.success("Old 2"))
        service.show(.success("New 1"))
        service.show(.success("New 2"))
        service.show(.success("New 3"))

        // Should keep the 3 newest
        let messages = service.toasts.map { $0.type.message }
        #expect(messages.contains("New 3"))
        #expect(messages.contains("New 2"))
        #expect(messages.contains("New 1"))
        #expect(!messages.contains("Old 1"))
        #expect(!messages.contains("Old 2"))
    }

    // MARK: - Toast Types

    @Test("All toast types work correctly")
    func allToastTypesWork() {
        let service = ToastService()

        service.success("Success msg")
        service.error("Error msg")
        service.warning("Warning msg")
        service.info("Info msg")

        // Only 3 will be kept due to max limit
        #expect(service.toasts.count == 3)

        // Verify messages are present (newest 3 kept)
        let messages = service.toasts.map { $0.type.message }
        #expect(messages.contains("Info msg"))
        #expect(messages.contains("Warning msg"))
        #expect(messages.contains("Error msg"))
    }

    @Test("Toast type provides correct icon")
    func toastTypeProvideCorrectIcon() {
        let successType = ToastService.ToastType.success("Test")
        let errorType = ToastService.ToastType.error("Test")
        let warningType = ToastService.ToastType.warning("Test")
        let infoType = ToastService.ToastType.info("Test")

        #expect(successType.icon == "checkmark.circle.fill")
        #expect(errorType.icon == "xmark.circle.fill")
        #expect(warningType.icon == "exclamationmark.triangle.fill")
        #expect(infoType.icon == "info.circle.fill")
    }

    @Test("Custom icons are preserved")
    func customIconsPreserved() {
        let service = ToastService()

        service.success("Test", icon: "star.fill")

        #expect(service.toasts.first?.type.icon == "star.fill")
    }

    // MARK: - Edge Cases

    // Note: Expiration purge (purgeExpiredToasts) is an internal safety mechanism
    // that cannot be unit tested without exposing internal state or waiting 10+ seconds.
    // The mechanism exists as a safety net for failed onDismiss callbacks.

    @Test("Empty service has no active toasts")
    func emptyServiceHasNoActiveToasts() {
        let service = ToastService()

        #expect(service.toasts.isEmpty)
        #expect(service.hasActiveToasts == false)
    }

    @Test("Dismissing non-existent ID does nothing")
    func dismissingNonExistentIdDoesNothing() {
        let service = ToastService()

        service.show(.success("Test"))
        let originalCount = service.toasts.count

        service.dismiss(UUID()) // Random ID that doesn't exist

        #expect(service.toasts.count == originalCount)
    }

    @Test("Toast equality is based on ID only")
    func toastEqualityBasedOnId() {
        let id = UUID()
        let toast1 = ToastService.Toast(id: id, type: .success("Message 1"))
        let toast2 = ToastService.Toast(id: id, type: .error("Message 2"))

        #expect(toast1 == toast2, "Toasts with same ID should be equal regardless of content")
    }

    @Test("Different IDs make toasts unequal")
    func differentIdsMakeToastsUnequal() {
        let toast1 = ToastService.Toast(type: .success("Same"))
        let toast2 = ToastService.Toast(type: .success("Same"))

        #expect(toast1 != toast2, "Toasts with different IDs should not be equal")
    }
}
