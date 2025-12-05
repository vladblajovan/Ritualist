import SwiftUI
import RitualistCore

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
                                withAnimation(SpringAnimation.interactive) {
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
                // Uses .task for automatic cancellation when view disappears
                .task(id: hasShownPeekHint) {
                    await showPeekHintIfNeeded()
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
                    // Accessibility: Group indicators and announce as single element
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Page \(currentIndex + 1) of \(items.count)")
                    .accessibilityIdentifier(AccessibilityID.InspirationCarousel.pageIndicators)
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
                .accessibilityIdentifier(AccessibilityID.InspirationCarousel.dismissAllButton)
            }
        }
        .accessibilityIdentifier(AccessibilityID.InspirationCarousel.carousel)
    }

    // MARK: - Peek Hint Animation

    /// Shows a subtle "peek" animation to hint that the carousel is swipeable.
    /// Only triggers once when carousel first appears with multiple items.
    /// Uses structured concurrency for automatic cancellation when view disappears.
    @MainActor
    private func showPeekHintIfNeeded() async {
        guard items.count > 1, !hasShownPeekHint else { return }
        hasShownPeekHint = true

        // Delay before starting the peek animation
        try? await Task.sleep(for: .milliseconds(600))
        guard !Task.isCancelled else { return }

        // First bounce
        await performPeekBounce()
        guard !Task.isCancelled else { return }

        // Brief pause between bounces
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        // Second bounce
        await performPeekBounce()
    }

    /// Performs a single peek-bounce animation.
    /// Returns when the animation completes or is cancelled.
    @MainActor
    private func performPeekBounce() async {
        // Peek left to reveal edge of next card
        withAnimation(.easeOut(duration: 0.2)) {
            peekOffset = -25
        }

        // Wait for peek animation
        try? await Task.sleep(for: .milliseconds(200))
        guard !Task.isCancelled else {
            // Reset offset if cancelled mid-animation
            peekOffset = 0
            return
        }

        // Bounce back to original position
        withAnimation(SpringAnimation.interactive) {
            peekOffset = 0
        }

        // Wait for bounce to settle
        try? await Task.sleep(for: .milliseconds(300))
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
        ].compactMap { $0 },
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
        ].compactMap { $0 },
        timeOfDay: .morning,
        completionPercentage: 0.0,
        onDismiss: { _ in },
        onDismissAll: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}
