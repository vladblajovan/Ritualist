import SwiftUI
import Observation

/// Centralized toast service for showing notifications anywhere in the app
/// Usage: toastService.show(.success("Saved!"))
@MainActor @Observable
public final class ToastService {

    // MARK: - Toast Types

    public enum Toast: Equatable {
        case success(String, icon: String = "checkmark.circle.fill")
        case error(String, icon: String = "xmark.circle.fill")
        case warning(String, icon: String = "exclamationmark.triangle.fill")
        case info(String, icon: String = "info.circle.fill")

        var message: String {
            switch self {
            case .success(let msg, _), .error(let msg, _),
                 .warning(let msg, _), .info(let msg, _):
                return msg
            }
        }

        var icon: String {
            switch self {
            case .success(_, let icon), .error(_, let icon),
                 .warning(_, let icon), .info(_, let icon):
                return icon
            }
        }

        var style: ToastStyle {
            switch self {
            case .success: return .success
            case .error: return .error
            case .warning: return .warning
            case .info: return .info
            }
        }
    }

    // MARK: - State

    public private(set) var currentToast: Toast?

    // MARK: - Init

    public init() {}

    // MARK: - Public API

    /// Show a toast notification
    public func show(_ toast: Toast) {
        currentToast = toast
    }

    /// Dismiss the current toast
    public func dismiss() {
        currentToast = nil
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
