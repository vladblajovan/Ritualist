import SwiftUI

/// Custom button style that scales the button on press
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public struct ScaleButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// Convenience extension for applying the scale button style
@available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
public extension View {
    /// Applies a scale animation to the button when pressed
    func scaleButtonStyle() -> some View {
        self.buttonStyle(ScaleButtonStyle())
    }
}
