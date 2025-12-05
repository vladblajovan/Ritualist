//
//  ToastView.swift
//  Ritualist
//
//  Reusable toast notification component for confirmations and alerts
//

import SwiftUI
import RitualistCore

/// Toast style presets for common use cases
public enum ToastStyle {
    case info      // Blue - general information
    case success   // Green - successful actions
    case warning   // Orange - warnings
    case error     // Red - errors
    case custom(Color)

    public var color: Color {
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
    let isPersistent: Bool
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var dismissTask: Task<Void, Never>?
    @State private var dragOffset: CGFloat = 0
    @State private var hasDismissed = false

    init(
        message: String,
        icon: String = "checkmark.circle.fill",
        style: ToastStyle = .info,
        duration: TimeInterval = 3.0,
        isPersistent: Bool = false,
        onDismiss: @escaping () -> Void = {}
    ) {
        self.message = message
        self.icon = icon
        self.style = style
        self.duration = duration
        self.isPersistent = isPersistent
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
            .accessibilityIdentifier(AccessibilityID.Toast.dismissButton)
        }
        .padding(.leading, Spacing.medium)
        .padding(.trailing, Spacing.small)
        .padding(.vertical, Spacing.small)
        .background(
            Capsule()
                .fill(style.color.gradient)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
        // Note: Entry/exit animations are handled by the container (RootTabView overlay)
        // via .transition() and .animation(value: toasts). Only animate drag offset here
        // to avoid conflicting double-animations that cause janky behavior.
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? dragOffset : -20)
        .animation(SpringAnimation.interactive, value: dragOffset)
        // Accessibility: Expose swipe gesture to VoiceOver users
        .accessibilityHint("Swipe up to dismiss")
        .accessibilityAction(.escape) { dismissToast() }
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Only allow upward drag (negative translation)
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    // Dismiss if swiped up more than 30pt or with velocity
                    if value.translation.height < -30 || value.predictedEndTranslation.height < -50 {
                        dismissToast()
                    } else {
                        // Snap back
                        dragOffset = 0
                    }
                }
        )
        .task {
            // Animate in
            withAnimation {
                isVisible = true
            }

            // Auto-dismiss after duration (cancelled if manually dismissed)
            // Persistent toasts skip auto-dismiss - they must be dismissed manually
            guard !isPersistent else { return }
            dismissTask = Task {
                try? await Task.sleep(for: .seconds(duration))
                if !Task.isCancelled {
                    dismissToast()
                }
            }
        }
    }

    private func dismissToast() {
        // Prevent multiple dismiss calls - use dedicated flag for thread-safe check
        // The previous check (dismissTask != nil) had a race condition where multiple
        // calls could pass the guard before dismissTask was set to nil
        guard !hasDismissed else { return }
        hasDismissed = true

        // Haptic feedback for tactile confirmation of dismiss action
        UIImpactFeedbackGenerator(style: .light).impactOccurred()

        // Cancel auto-dismiss timer if still running
        dismissTask?.cancel()
        dismissTask = nil

        withAnimation {
            isVisible = false
        }

        // Call dismiss after animation completes
        // Using DispatchQueue ensures single callback even if view is deallocated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [onDismiss] in
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
    var animation: Animation = SpringAnimation.interactive

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
