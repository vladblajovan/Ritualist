import SwiftUI
import RitualistCore

/// Model representing an inspiration item in the carousel
public struct InspirationItem: Identifiable, Equatable {
    public let id: UUID
    public let trigger: InspirationTrigger
    public let message: String
    public let slogan: String

    public init(id: UUID = UUID(), trigger: InspirationTrigger, message: String, slogan: String) {
        self.id = id
        self.trigger = trigger
        self.message = message
        self.slogan = slogan
    }

    public static func == (lhs: InspirationItem, rhs: InspirationItem) -> Bool {
        lhs.id == rhs.id
    }
}

/// A swipeable carousel of inspiration cards, sorted by trigger priority
struct InspirationCarouselView: View {
    let items: [InspirationItem]
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let onDismiss: (InspirationItem) -> Void
    let onDismissAll: () -> Void

    @State private var currentIndex: Int = 0
    @State private var peekOffset: CGFloat = 0
    @State private var hasShownPeekHint: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            // Carousel with page indicators inside
            ZStack(alignment: .bottom) {
                TabView(selection: $currentIndex) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        InspirationCard(
                            message: item.message,
                            slogan: item.slogan,
                            timeOfDay: timeOfDay,
                            completionPercentage: completionPercentage,
                            shouldShow: true,
                            onDismiss: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    onDismiss(item)
                                }
                            }
                        )
                        .padding(.horizontal, 4)
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 140)
                .offset(x: peekOffset)
                // Reset to valid index when items change (e.g., after dismissal)
                .onChange(of: items.count) { oldCount, newCount in
                    if currentIndex >= newCount {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentIndex = max(0, newCount - 1)
                        }
                    }
                }
                // Peek hint animation when carousel appears with multiple items
                .onAppear {
                    showPeekHintIfNeeded()
                }

                // Page indicators inside card (bottom-center with contrast backdrop)
                if items.count > 1 {
                    HStack(spacing: 6) {
                        ForEach(0..<items.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                .frame(width: 6, height: 6)
                                .animation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.2))
                    )
                    .padding(.bottom, 12)
                }
            }

            // Dismiss all button (outside carousel, affects all cards)
            if items.count > 1 {
                Button {
                    onDismissAll()
                } label: {
                    Text("Dismiss all")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Peek Hint Animation

    /// Shows a subtle "peek" animation to hint that the carousel is swipeable
    /// Only triggers once when carousel first appears with multiple items
    private func showPeekHintIfNeeded() {
        guard items.count > 1, !hasShownPeekHint else { return }
        hasShownPeekHint = true

        // Delay before starting the peek animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            performPeekBounce {
                // Second bounce after the first one completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    performPeekBounce(completion: nil)
                }
            }
        }
    }

    /// Performs a single peek-bounce animation
    private func performPeekBounce(completion: (() -> Void)?) {
        // Peek left to reveal edge of next card
        withAnimation(.easeOut(duration: 0.2)) {
            peekOffset = -25
        }

        // Bounce back to original position
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                peekOffset = 0
            }

            // Call completion after bounce settles
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                completion?()
            }
        }
    }
}

// MARK: - Preview

#Preview("Multiple Items") {
    InspirationCarouselView(
        items: [
            InspirationItem(
                trigger: .perfectDay,
                message: "Perfect day achieved! Outstanding work!",
                slogan: "Consistency creates extraordinary results."
            ),
            InspirationItem(
                trigger: .strongFinish,
                message: "75%+ achieved. Excellence within reach!",
                slogan: "Excellence becomes your standard."
            ),
            InspirationItem(
                trigger: .halfwayPoint,
                message: "Halfway there! Keep the momentum going!",
                slogan: "Midday momentum, unstoppable force."
            )
        ],
        timeOfDay: .noon,
        completionPercentage: 0.75,
        onDismiss: { _ in },
        onDismissAll: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

#Preview("Single Item") {
    InspirationCarouselView(
        items: [
            InspirationItem(
                trigger: .sessionStart,
                message: "Time to execute your daily plan with precision.",
                slogan: "Your morning sets the entire tone."
            )
        ],
        timeOfDay: .morning,
        completionPercentage: 0.0,
        onDismiss: { _ in },
        onDismissAll: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
