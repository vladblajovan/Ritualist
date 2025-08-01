import SwiftUI

/// A reusable view that wraps content and adds swipe navigation gestures
public struct SwipeNavigationView<Content: View>: View {
    private let content: Content
    private let onSwipeLeft: () async -> Void
    private let onSwipeRight: () async -> Void
    private let minimumSwipeDistance: CGFloat
    private let minimumSwipeVelocity: CGFloat
    
    /// Current drag state for visual feedback
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    /// Haptic feedback generator
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)
    
    public init(
        minimumSwipeDistance: CGFloat = 100,
        minimumSwipeVelocity: CGFloat = 300,
        onSwipeLeft: @escaping () async -> Void,
        onSwipeRight: @escaping () async -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.minimumSwipeDistance = minimumSwipeDistance
        self.minimumSwipeVelocity = minimumSwipeVelocity
    }
    
    public var body: some View {
        content
            .offset(x: dragOffset)
            .opacity(isDragging ? 0.95 : 1.0)
            .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: dragOffset)
            .animation(.easeInOut(duration: 0.2), value: isDragging)
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.9)) {
                            dragOffset = value.translation.width * 0.3 // Dampen the visual feedback
                            isDragging = true
                        }
                    }
                    .onEnded { value in
                        let swipeDistance = abs(value.translation.width)
                        let swipeVelocity = abs(value.velocity.width)
                        let isValidSwipe = swipeDistance >= minimumSwipeDistance || swipeVelocity >= minimumSwipeVelocity
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            dragOffset = 0
                            isDragging = false
                        }
                        
                        if isValidSwipe {
                            // Trigger haptic feedback
                            impactFeedback.impactOccurred(intensity: 0.6)
                            
                            // Determine swipe direction and trigger callback
                            if value.translation.width > 0 {
                                // Swipe right - go to previous month
                                Task {
                                    await onSwipeRight()
                                }
                            } else {
                                // Swipe left - go to next month
                                Task {
                                    await onSwipeLeft()
                                }
                            }
                        }
                    }
            )
            .accessibilityHint("Swipe left for next month, swipe right for previous month")
    }
}

#if DEBUG
#Preview {
    SwipeNavigationView(
        onSwipeLeft: { print("Swiped left") },
        onSwipeRight: { print("Swiped right") },
        content: {
            Rectangle()
                .fill(Color.blue.opacity(0.3))
                .frame(height: 200)
                .overlay(
                    Text("Swipe me left or right")
                        .font(.title2)
                        .foregroundColor(.primary)
                )
        }
    )
    .padding()
}
#endif