import SwiftUI
import RitualistCore

public struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let showPercentage: Bool
    let strokeStyle: StrokeStyle

    // Support both single color and gradient
    private let color: Color?
    private let gradient: LinearGradient?

    /// Creates a circular progress view with a single color (backward compatible)
    public init(progress: Double, color: Color, lineWidth: CGFloat = 8, showPercentage: Bool = false) {
        self.progress = progress
        self.color = color
        self.gradient = nil
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    /// Creates a circular progress view with icon-inspired gradient (cyan → blue)
    public init(progress: Double, lineWidth: CGFloat = 8, showPercentage: Bool = false, useIconGradient: Bool = true) {
        self.progress = progress
        self.color = nil
        self.gradient = useIconGradient ? LinearGradient(
            colors: [Color.ritualistCyan, Color.ritualistBlue],
            startPoint: .leading,
            endPoint: .trailing
        ) : nil
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    /// Creates a circular progress view with custom gradient
    public init(progress: Double, gradient: LinearGradient, lineWidth: CGFloat = 8, showPercentage: Bool = false) {
        self.progress = progress
        self.color = nil
        self.gradient = gradient
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
    }

    public var body: some View {
        ZStack {
            // Background circle (always uses color or default)
            Circle()
                .stroke(backgroundStroke, lineWidth: lineWidth)

            // Progress circle (uses color or gradient)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    foregroundStroke,
                    style: strokeStyle
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)

            // Percentage text (optional)
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
            }
        }
    }

    // MARK: - Computed Properties

    private var backgroundStroke: some ShapeStyle {
        if let color = color {
            return AnyShapeStyle(color.opacity(0.2))
        }
        return AnyShapeStyle(Color.ritualistBlue.opacity(0.15))
    }

    private var foregroundStroke: some ShapeStyle {
        if let gradient = gradient {
            return AnyShapeStyle(gradient)
        }
        if let color = color {
            return AnyShapeStyle(color)
        }
        return AnyShapeStyle(Color.ritualistBlue)
    }

    private var textColor: Color {
        color ?? .ritualistBlue
    }
}

#Preview {
    VStack(spacing: 20) {
        CircularProgressView(
            progress: 0.75,
            color: .blue,
            lineWidth: 8,
            showPercentage: true
        )
        .frame(width: 80, height: 80)
        
        CircularProgressView(
            progress: 0.45,
            color: .green,
            lineWidth: 6
        )
        .frame(width: 60, height: 60)
        
        CircularProgressView(
            progress: 0.92,
            color: .orange,
            lineWidth: 10,
            showPercentage: true
        )
        .frame(width: 100, height: 100)
    }
    .padding()
}