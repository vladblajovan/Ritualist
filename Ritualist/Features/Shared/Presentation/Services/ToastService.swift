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
    func show(_ type: ToastService.ToastType)

    /// Dismiss a specific toast by ID
    func dismiss(_ id: UUID)

    /// Dismiss all toasts
    func dismissAll()

    // Convenience methods
    func success(_ message: String, icon: String)
    func error(_ message: String, icon: String)
    func warning(_ message: String, icon: String)
    func info(_ message: String, icon: String)
}

// MARK: - Default Parameter Extensions

public extension ToastServiceProtocol {
    func success(_ message: String) { success(message, icon: "checkmark.circle.fill") }
    func error(_ message: String) { error(message, icon: "xmark.circle.fill") }
    func warning(_ message: String) { warning(message, icon: "exclamationmark.triangle.fill") }
    func info(_ message: String) { info(message, icon: "info.circle.fill") }
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

        public init(id: UUID = UUID(), type: ToastType, createdAt: Date = Date()) {
            self.id = id
            self.type = type
            self.createdAt = createdAt
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
    public func show(_ type: ToastType) {
        // First, purge any stale toasts (safety net for failed onDismiss callbacks)
        purgeExpiredToasts()

        // Prevent duplicate toasts with the same message
        guard !toasts.contains(where: { $0.type.message == type.message }) else {
            return
        }

        let toast = Toast(type: type)

        // Insert at beginning (newest first)
        toasts.insert(toast, at: 0)

        // Trim to max visible
        if toasts.count > Self.maxVisibleToasts {
            toasts = Array(toasts.prefix(Self.maxVisibleToasts))
        }
    }

    /// Remove toasts that have exceeded their maximum lifetime
    /// Safety net to prevent unbounded memory growth if onDismiss callbacks fail
    private func purgeExpiredToasts() {
        let now = Date()
        toasts.removeAll { toast in
            now.timeIntervalSince(toast.createdAt) > Self.maxToastLifetime
        }
    }

    /// Dismiss a specific toast by ID
    public func dismiss(_ id: UUID) {
        toasts.removeAll { $0.id == id }
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
}
