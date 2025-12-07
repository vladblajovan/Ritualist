import SwiftUI
import RitualistCore

public struct CircularProgressView: View {
    let progress: Double
    let lineWidth: CGFloat
    let showPercentage: Bool
    let strokeStyle: StrokeStyle

    // Accessibility support - optional label for context
    private let accessibilityLabelText: String?

    // Animation duration constant for consistent timing across all circular progress indicators
    private static let progressAnimationDuration: Double = 1.0

    // Support both single color and gradient
    private let color: Color?
    private let gradient: LinearGradient?

    /// Creates a circular progress view with a single color (backward compatible)
    public init(
        progress: Double,
        color: Color,
        lineWidth: CGFloat = 8,
        showPercentage: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.progress = progress
        self.color = color
        self.gradient = nil
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        self.accessibilityLabelText = accessibilityLabel
    }

    /// Creates a circular progress view with icon-inspired gradient (cyan → blue)
    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        showPercentage: Bool = false,
        useIconGradient: Bool = true,
        accessibilityLabel: String? = nil
    ) {
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
        self.accessibilityLabelText = accessibilityLabel
    }

    /// Creates a circular progress view with adaptive gradient based on completion percentage
    /// Matches MonthlyCalendarViewLogic color thresholds
    public init(
        progress: Double,
        lineWidth: CGFloat = 8,
        showPercentage: Bool = false,
        useAdaptiveGradient: Bool,
        accessibilityLabel: String? = nil
    ) {
        self.progress = progress
        self.color = nil
        self.gradient = useAdaptiveGradient ? Self.adaptiveProgressGradient(for: progress) : nil
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        self.accessibilityLabelText = accessibilityLabel
    }

    /// Creates a circular progress view with custom gradient
    public init(
        progress: Double,
        gradient: LinearGradient,
        lineWidth: CGFloat = 8,
        showPercentage: Bool = false,
        accessibilityLabel: String? = nil
    ) {
        self.progress = progress
        self.color = nil
        self.gradient = gradient
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.strokeStyle = StrokeStyle(lineWidth: lineWidth, lineCap: .round)
        self.accessibilityLabelText = accessibilityLabel
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
                .animation(.easeInOut(duration: Self.progressAnimationDuration), value: progress)

            // Percentage text (optional)
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(textColor)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabelText ?? "\(Int(progress * 100)) percent progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
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

    // MARK: - Static Helpers

    /// Returns adaptive gradient colors based on completion percentage
    /// Matches MonthlyCalendarViewLogic color thresholds:
    /// - 0-50%: Red/Pink (low completion)
    /// - 50-80%: Orange (medium completion)
    /// - 80-100%: Green (high completion)
    /// - 100%: Full green gradient (perfect completion)
    public static func adaptiveProgressColors(for completion: Double) -> [Color] {
        let percentage = min(max(completion, 0.0), 1.0)

        if percentage < 0.5 {
            // Low completion: Cyan → Red gradient
            return [Color.ritualistCyan, CardDesign.progressRed]
        } else if percentage < 0.8 {
            // Medium completion: Cyan → Orange gradient
            return [Color.ritualistCyan, CardDesign.progressOrange]
        } else if percentage < 1.0 {
            // High completion: Cyan → Green gradient
            return [Color.ritualistCyan, CardDesign.progressGreen]
        } else {
            // 100% completion: Cyan → Bright Green gradient
            return [Color.ritualistCyan, CardDesign.progressGreen]
        }
    }

    /// Returns adaptive gradient based on completion percentage
    public static func adaptiveProgressGradient(for completion: Double) -> LinearGradient {
        return LinearGradient(
            colors: adaptiveProgressColors(for: completion),
            startPoint: .leading,
            endPoint: .trailing
        )
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