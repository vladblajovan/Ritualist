import SwiftUI

// MARK: - Whisper Bubble View

public struct WhisperBubble: View {
    let text: String
    let bubbleColor: Color
    let textColor: Color
    let tailPosition: TailPosition
    let maxWidth: CGFloat
    
    public enum TailPosition: Sendable {
        case topLeading
        case topTrailing
        case topCenter
        case leadingTop
        case leadingCenter
        case leadingBottom
    }
    
    public init(
        text: String,
        bubbleColor: Color = Color(.systemGray6),
        textColor: Color = .secondary,
        tailPosition: TailPosition = .topLeading,
        maxWidth: CGFloat = 280
    ) {
        self.text = text
        self.bubbleColor = bubbleColor
        self.textColor = textColor
        self.tailPosition = tailPosition
        self.maxWidth = maxWidth
    }
    
    public var body: some View {
        switch tailPosition {
        case .topLeading, .topTrailing, .topCenter:
            VStack(spacing: 0) {
                // Tail pointing up
                WhisperTail(position: tailPosition)
                    .fill(bubbleColor)
                    .frame(width: 20, height: 10)
                    .offset(y: 1) // Slight overlap to connect with bubble
                
                // Bubble content
                bubbleContent
            }
        case .leadingTop, .leadingCenter, .leadingBottom:
            HStack(spacing: 0) {
                // Tail pointing left
                WhisperTail(position: tailPosition)
                    .fill(bubbleColor)
                    .frame(width: 10, height: 20)
                    .offset(x: 1) // Slight overlap to connect with bubble
                
                // Bubble content
                bubbleContent
            }
        }
    }
    
    private var bubbleContent: some View {
        Text(text)
            .font(.subheadline)
            .foregroundColor(textColor)
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .fill(bubbleColor)
            )
    }
}

// MARK: - Whisper Tail Shape

struct WhisperTail: Shape {
    let position: WhisperBubble.TailPosition
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        switch position {
        case .topLeading:
            path.move(to: CGPoint(x: rect.minX + 5, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX + 15, y: rect.maxY))
            
        case .topTrailing:
            path.move(to: CGPoint(x: rect.maxX - 15, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - 5, y: rect.maxY))
            
        case .topCenter:
            path.move(to: CGPoint(x: rect.midX - 10, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX + 10, y: rect.maxY))
            
        case .leadingTop:
            path.move(to: CGPoint(x: rect.maxX, y: rect.minY + 5))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + 15))
            
        case .leadingCenter:
            path.move(to: CGPoint(x: rect.maxX, y: rect.midY - 10))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY + 10))
            
        case .leadingBottom:
            path.move(to: CGPoint(x: rect.maxX, y: rect.maxY - 15))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 5))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Animated Whisper Bubble

public struct AnimatedWhisperBubble: View {
    let text: String
    let bubbleColor: Color
    let textColor: Color
    let tailPosition: WhisperBubble.TailPosition
    let maxWidth: CGFloat
    
    @State private var isVisible = false
    @State private var bounceAnimation = false
    
    public init(
        text: String,
        bubbleColor: Color = Color(.systemGray6),
        textColor: Color = .secondary,
        tailPosition: WhisperBubble.TailPosition = .topLeading,
        maxWidth: CGFloat = 280
    ) {
        self.text = text
        self.bubbleColor = bubbleColor
        self.textColor = textColor
        self.tailPosition = tailPosition
        self.maxWidth = maxWidth
    }
    
    public var body: some View {
        WhisperBubble(
            text: text,
            bubbleColor: bubbleColor,
            textColor: textColor,
            tailPosition: tailPosition,
            maxWidth: maxWidth
        )
        .scaleEffect(bounceAnimation ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0.0)
        .animation(.easeOut(duration: AnimationDuration.medium), value: isVisible)
        .animation(
            .interpolatingSpring(stiffness: 170, damping: 15)
                .repeatCount(1, autoreverses: true),
            value: bounceAnimation
        )
        .onAppear {
            withAnimation(.easeOut(duration: AnimationDuration.medium)) {
                isVisible = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                bounceAnimation = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 40) {
        // Static examples
        VStack(alignment: .leading, spacing: 20) {
            Text("Ritualist")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            WhisperBubble(
                text: "Rise with purpose, rule your day.",
                tailPosition: .topLeading
            )
        }
        .padding()
        
        // Animated example
        VStack(alignment: .leading, spacing: 20) {
            Text("Ritualist")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            AnimatedWhisperBubble(
                text: "Morning rituals, unstoppable momentum.",
                tailPosition: .topLeading
            )
        }
        .padding()
        
        // Different positions
        HStack(spacing: 30) {
            WhisperBubble(
                text: "Left tail",
                tailPosition: .topLeading,
                maxWidth: 100
            )
            
            WhisperBubble(
                text: "Center tail",
                tailPosition: .topCenter,
                maxWidth: 100
            )
            
            WhisperBubble(
                text: "Right tail",
                tailPosition: .topTrailing,
                maxWidth: 100
            )
        }
        .padding()
    }
}
