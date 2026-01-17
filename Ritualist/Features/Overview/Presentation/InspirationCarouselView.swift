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

    var body: some View {
        ZStack(alignment: .bottom) {
            // Carousel - negative margins extend container, card padding brings it back to match other cards
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    InspirationCard(
                        message: item.message,
                        slogan: item.slogan,
                        timeOfDay: timeOfDay,
                        completionPercentage: completionPercentage,
                        shouldShow: true,
                        onDismiss: {
                            animateIfAllowed(SpringAnimation.interactive) {
                                onDismiss(item)
                            }
                        },
                        onDismissAll: {
                            animateIfAllowed(SpringAnimation.interactive) {
                                onDismissAll()
                            }
                        }
                    )
                    .padding(.horizontal, Spacing.small) // Visual separation between carousel cards
                    .padding(.top, CardDesign.shadowRadius + 8) // Room for shadow above + extra breathing room
                    .padding(.bottom, CardDesign.shadowRadius + 24) // Extra room for shadow + page indicators
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.horizontal, -Spacing.small) // Extend carousel to compensate for card padding
            .frame(minHeight: 170)
            .sensoryFeedback(.selection, trigger: currentIndex) // Haptic on page snap
            .onChange(of: items.count) { _, newCount in
                if currentIndex >= newCount {
                    animateIfAllowed(.easeInOut(duration: 0.2)) {
                        currentIndex = max(0, newCount - 1)
                    }
                }
            }

            // Sticky page indicators - overlaid at bottom center
            if items.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<items.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.3))
                            .frame(width: 6, height: 6)
                            .reduceMotionAnimation(.easeInOut(duration: 0.2), value: currentIndex)
                    }
                }
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .padding(.bottom, 8)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Page \(currentIndex + 1) of \(items.count)")
                .accessibilityIdentifier(AccessibilityID.InspirationCarousel.pageIndicators)
            }
        }
        .accessibilityIdentifier(AccessibilityID.InspirationCarousel.carousel)
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
        onDismissAll: { }
    )
    .padding(.horizontal)
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
        onDismissAll: { }
    )
    .padding(.horizontal)
    .background(Color(.systemGroupedBackground))
}
