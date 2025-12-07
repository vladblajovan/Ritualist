import SwiftUI
import Observation

// MARK: - Protocol

/// Protocol for toast notification service, enabling testability via mocking
@MainActor
public protocol ToastServiceProtocol: AnyObject {
    /// Active toasts, ordered by creation time (newest first)
    var toasts: [ToastService.Toast] { get }

    /// Convenience for checking if any toast is active
    var hasActiveToasts: Bool { get }

    /// Show a toast notification
    /// - Parameters:
    ///   - type: The type of toast to show
    ///   - persistent: If true, toast won't auto-dismiss and must be dismissed manually
    func show(_ type: ToastService.ToastType, persistent: Bool)

    /// Dismiss a specific toast by ID
    func dismiss(_ id: UUID)

    /// Dismiss a toast by its message content
    func dismiss(message: String)

    /// Dismiss all toasts
    func dismissAll()

    // Convenience methods
    func success(_ message: String, icon: String)
    func error(_ message: String, icon: String)
    func warning(_ message: String, icon: String)
    func info(_ message: String, icon: String)
    func infoPersistent(_ message: String, icon: String)
}

// MARK: - Default Parameter Extensions

public extension ToastServiceProtocol {
    func show(_ type: ToastService.ToastType) { show(type, persistent: false) }
    func success(_ message: String) { success(message, icon: "checkmark.circle.fill") }
    func error(_ message: String) { error(message, icon: "xmark.circle.fill") }
    func warning(_ message: String) { warning(message, icon: "exclamationmark.triangle.fill") }
    func info(_ message: String) { info(message, icon: "info.circle.fill") }
    func infoPersistent(_ message: String) { infoPersistent(message, icon: "info.circle.fill") }
}

// MARK: - Implementation

/// Centralized toast service for showing notifications anywhere in the app
/// Supports stacking multiple toasts with the latest on top
/// Usage: toastService.show(.success("Saved!"))
@MainActor @Observable
public final class ToastService: ToastServiceProtocol {

    // MARK: - Constants

    /// Maximum number of toasts visible at once
    public static let maxVisibleToasts = 3

    /// Maximum time a toast can remain in the queue (seconds)
    /// Safety net if onDismiss callback fails - prevents unbounded memory growth
    private static let maxToastLifetime: TimeInterval = 10

    // MARK: - Toast Model

    public struct Toast: Equatable, Identifiable {
        public let id: UUID
        public let type: ToastType
        public let createdAt: Date
        /// If true, toast won't auto-dismiss after maxToastLifetime - must be dismissed manually
        public let persistent: Bool

        public init(id: UUID = UUID(), type: ToastType, createdAt: Date = Date(), persistent: Bool = false) {
            self.id = id
            self.type = type
            self.createdAt = createdAt
            self.persistent = persistent
        }

        public static func == (lhs: Toast, rhs: Toast) -> Bool {
            lhs.id == rhs.id
        }
    }

    public enum ToastType: Equatable {
        case success(String, icon: String = "checkmark.circle.fill")
        case error(String, icon: String = "xmark.circle.fill")
        case warning(String, icon: String = "exclamationmark.triangle.fill")
        case info(String, icon: String = "info.circle.fill")

        public var message: String {
            switch self {
            case .success(let msg, _), .error(let msg, _),
                 .warning(let msg, _), .info(let msg, _):
                return msg
            }
        }

        public var icon: String {
            switch self {
            case .success(_, let icon), .error(_, let icon),
                 .warning(_, let icon), .info(_, let icon):
                return icon
            }
        }

        public var style: ToastStyle {
            switch self {
            case .success: return .success
            case .error: return .error
            case .warning: return .warning
            case .info: return .info
            }
        }
    }

    // MARK: - State

    /// Active toasts, ordered by creation time (newest first for display)
    public private(set) var toasts: [Toast] = []

    /// Convenience for checking if any toast is active
    public var hasActiveToasts: Bool {
        !toasts.isEmpty
    }

    // MARK: - Init

    public init() {}

    // MARK: - Public API

    /// Show a toast notification (adds to stack)
    /// Deduplicates: won't add a toast if one with the same message already exists
    /// - Parameters:
    ///   - type: The type of toast to show
    ///   - persistent: If true, toast won't auto-dismiss and must be dismissed manually
    public func show(_ type: ToastType, persistent: Bool = false) {
        // First, purge any stale toasts (safety net for failed onDismiss callbacks)
        purgeExpiredToasts()

        // Prevent duplicate toasts with the same message
        guard !toasts.contains(where: { $0.type.message == type.message }) else {
            return
        }

        let toast = Toast(type: type, persistent: persistent)

        // Trigger haptic feedback based on toast type
        triggerHapticFeedback(for: type)

        // Insert at beginning (newest first)
        toasts.insert(toast, at: 0)

        // Trim to max visible
        if toasts.count > Self.maxVisibleToasts {
            toasts = Array(toasts.prefix(Self.maxVisibleToasts))
        }
    }

    /// Trigger appropriate haptic feedback for toast type
    private func triggerHapticFeedback(for type: ToastType) {
        switch type {
        case .success:
            HapticFeedbackService.shared.trigger(.success)
        case .error:
            HapticFeedbackService.shared.trigger(.error)
        case .warning:
            HapticFeedbackService.shared.trigger(.warning)
        case .info:
            HapticFeedbackService.shared.trigger(.light)
        }
    }

    /// Remove toasts that have exceeded their maximum lifetime
    /// Safety net to prevent unbounded memory growth if onDismiss callbacks fail
    /// Persistent toasts are excluded from auto-purge - they must be dismissed manually
    private func purgeExpiredToasts() {
        let now = Date()
        toasts.removeAll { toast in
            !toast.persistent && now.timeIntervalSince(toast.createdAt) > Self.maxToastLifetime
        }
    }

    /// Dismiss a specific toast by ID
    public func dismiss(_ id: UUID) {
        toasts.removeAll { $0.id == id }
    }

    /// Dismiss a toast by its message content
    public func dismiss(message: String) {
        toasts.removeAll { $0.type.message == message }
    }

    /// Dismiss all toasts
    public func dismissAll() {
        toasts.removeAll()
    }

    // MARK: - Convenience Methods

    public func success(_ message: String, icon: String = "checkmark.circle.fill") {
        show(.success(message, icon: icon))
    }

    public func error(_ message: String, icon: String = "xmark.circle.fill") {
        show(.error(message, icon: icon))
    }

    public func warning(_ message: String, icon: String = "exclamationmark.triangle.fill") {
        show(.warning(message, icon: icon))
    }

    public func info(_ message: String, icon: String = "info.circle.fill") {
        show(.info(message, icon: icon))
    }

    /// Show a persistent info toast that won't auto-dismiss
    /// Must be dismissed manually using dismiss(message:) or dismiss(_:)
    public func infoPersistent(_ message: String, icon: String = "info.circle.fill") {
        show(.info(message, icon: icon), persistent: true)
    }
}
