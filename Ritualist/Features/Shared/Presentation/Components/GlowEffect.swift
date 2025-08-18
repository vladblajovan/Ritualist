import SwiftUI
import RitualistCore

public struct GlowEffect: ViewModifier {
    let isGlowing: Bool
    let color: Color
    let radius: CGFloat
    let intensity: Double
    
    public init(
        isGlowing: Bool,
        color: Color = .green,
        radius: CGFloat = 8,
        intensity: Double = 0.8
    ) {
        self.isGlowing = isGlowing
        self.color = color
        self.radius = radius
        self.intensity = intensity
    }
    
    public func body(content: Content) -> some View {
        content
            .shadow(
                color: isGlowing ? color.opacity(intensity) : Color.clear,
                radius: isGlowing ? radius : 0,
                x: 0, y: 0
            )
            .animation(.easeInOut(duration: 0.3), value: isGlowing)
    }
}

public extension View {
    func glowEffect(
        isGlowing: Bool,
        color: Color = .green,
        radius: CGFloat = 8,
        intensity: Double = 0.8
    ) -> some View {
        modifier(GlowEffect(
            isGlowing: isGlowing,
            color: color,
            radius: radius,
            intensity: intensity
        ))
    }
}

// Completion glow effect with predefined success styling
public extension View {
    func completionGlow(isGlowing: Bool) -> some View {
        glowEffect(
            isGlowing: isGlowing,
            color: .green,
            radius: 12,
            intensity: 0.6
        )
    }
    
    func progressGlow(isGlowing: Bool) -> some View {
        glowEffect(
            isGlowing: isGlowing,
            color: AppColors.brand,
            radius: 8,
            intensity: 0.4
        )
    }
}