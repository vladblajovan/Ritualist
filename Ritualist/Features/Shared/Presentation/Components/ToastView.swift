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
    @State private var isDismissed = false

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

            Button {
                dismissToast()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss")
        }
        .padding(.leading, Spacing.medium)
        .padding(.trailing, Spacing.small)
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

            // Auto-dismiss after duration (unless manually dismissed)
            try? await Task.sleep(for: .seconds(duration))
            if !isDismissed {
                dismissToast()
            }
        }
    }

    private func dismissToast() {
        guard !isDismissed else { return }
        isDismissed = true

        withAnimation {
            isVisible = false
        }

        // Call dismiss after animation completes
        Task {
            try? await Task.sleep(for: .milliseconds(400))
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

// MARK: - Toast View Modifier

/// Configuration for toast presentation
struct ToastConfiguration {
    var alignment: Alignment = .top
    var padding: CGFloat = 4
    var transition: AnyTransition = .move(edge: .top).combined(with: .opacity)
    var animation: Animation = .spring(response: 0.4, dampingFraction: 0.8)

    static let `default` = ToastConfiguration()
    static let bottom = ToastConfiguration(alignment: .bottom, padding: 100, transition: .move(edge: .bottom).combined(with: .opacity))
}

/// View modifier for presenting toasts with centralized animation and positioning
struct ToastModifier<Item: Equatable, ToastContent: View>: ViewModifier {
    @Binding var item: Item?
    let configuration: ToastConfiguration
    let content: (Item) -> ToastContent

    func body(content: Content) -> some View {
        content
            .overlay(alignment: configuration.alignment) {
                if let item = item {
                    self.content(item)
                        .padding(.top, configuration.alignment == .top ? configuration.padding : 0)
                        .padding(.bottom, configuration.alignment == .bottom ? configuration.padding : 0)
                        .transition(configuration.transition)
                }
            }
            .animation(configuration.animation, value: item != nil)
    }
}

extension View {
    /// Present a toast with centralized animation and positioning
    /// - Parameters:
    ///   - item: Binding to the optional toast item (nil = hidden)
    ///   - configuration: Toast presentation configuration (default: top with spring animation)
    ///   - content: View builder that creates the toast content from the item
    func toast<Item: Equatable, Content: View>(
        item: Binding<Item?>,
        configuration: ToastConfiguration = .default,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(ToastModifier(item: item, configuration: configuration, content: content))
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
