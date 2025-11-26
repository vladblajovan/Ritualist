//
//  ToastView.swift
//  Ritualist
//
//  Reusable toast notification component for confirmations and alerts
//

import SwiftUI
import RitualistCore

/// Toast style presets for common use cases
enum ToastStyle {
    case info      // Blue - general information
    case success   // Green - successful actions
    case warning   // Orange - warnings
    case error     // Red - errors
    case custom(Color)

    var color: Color {
        switch self {
        case .info: return .blue
        case .success: return .green
        case .warning: return .orange
        case .error: return .red
        case .custom(let color): return color
        }
    }
}

/// A reusable toast notification that auto-dismisses
/// Use for confirmations, sync notifications, and brief alerts
struct ToastView: View {
    let message: String
    let icon: String
    let style: ToastStyle
    let duration: TimeInterval
    let onDismiss: () -> Void

    @State private var isVisible = false

    init(
        message: String,
        icon: String = "checkmark.circle.fill",
        style: ToastStyle = .info,
        duration: TimeInterval = 3.0,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.message = message
        self.icon = icon
        self.style = style
        self.duration = duration
        self.onDismiss = onDismiss
    }

    var body: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .background(
            Capsule()
                .fill(style.color.gradient)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : -20)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isVisible)
        .task {
            // Animate in
            withAnimation {
                isVisible = true
            }

            // Auto-dismiss after duration
            try? await Task.sleep(for: .seconds(duration))
            withAnimation {
                isVisible = false
            }

            // Call dismiss after animation completes
            try? await Task.sleep(for: .milliseconds(500))
            onDismiss()
        }
    }
}

// MARK: - Convenience Initializers

extension ToastView {
    /// Quick toast for success messages
    static func success(_ message: String, onDismiss: @escaping () -> Void = {}) -> ToastView {
        ToastView(message: message, icon: "checkmark.circle.fill", style: .success, onDismiss: onDismiss)
    }

    /// Quick toast for error messages
    static func error(_ message: String, onDismiss: @escaping () -> Void = {}) -> ToastView {
        ToastView(message: message, icon: "xmark.circle.fill", style: .error, onDismiss: onDismiss)
    }

    /// Quick toast for info messages
    static func info(_ message: String, icon: String = "info.circle.fill", onDismiss: @escaping () -> Void = {}) -> ToastView {
        ToastView(message: message, icon: icon, style: .info, onDismiss: onDismiss)
    }

    /// Quick toast for warning messages
    static func warning(_ message: String, onDismiss: @escaping () -> Void = {}) -> ToastView {
        ToastView(message: message, icon: "exclamationmark.triangle.fill", style: .warning, onDismiss: onDismiss)
    }
}

// MARK: - Previews

#Preview("Toast Styles") {
    VStack(spacing: 20) {
        ToastView.info("Synced from iCloud", icon: "icloud.fill")
        ToastView.success("Habit completed!")
        ToastView.warning("No internet connection")
        ToastView.error("Failed to save")
        ToastView(message: "Custom purple", icon: "star.fill", style: .custom(.purple))
    }
    .padding()
}
