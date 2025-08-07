import SwiftUI

public struct CircularProgressView: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat
    let showPercentage: Bool
    
    public init(progress: Double, color: Color, lineWidth: CGFloat = 8, showPercentage: Bool = false) {
        self.progress = progress
        self.color = color
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
    }
    
    public var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: progress)
            
            // Percentage text (optional)
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(color)
            }
        }
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