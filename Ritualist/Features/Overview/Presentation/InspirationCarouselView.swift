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
        VStack(spacing: Spacing.small) {
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
                        }
                    )
                    .padding(.horizontal, Spacing.small) // Visual separation between carousel cards
                    .padding(.top, CardDesign.shadowRadius) // Room for shadow above
                    .padding(.bottom, CardDesign.shadowRadius + 4) // Extra room for shadow + y-offset below
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.horizontal, -Spacing.small) // Extend carousel to compensate for card padding
            .frame(minHeight: 120)
            .sensoryFeedback(.selection, trigger: currentIndex) // Haptic on page snap
            .onChange(of: items.count) { _, newCount in
                if currentIndex >= newCount {
                    animateIfAllowed(.easeInOut(duration: 0.2)) {
                        currentIndex = max(0, newCount - 1)
                    }
                }
            }

            // Page indicators and dismiss button - below the carousel
            if items.count > 1 {
                HStack(spacing: 8) {
                    // Page indicators
                    HStack(spacing: 6) {
                        ForEach(0..<items.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentIndex ? Color.primary : Color.primary.opacity(0.3))
                                .frame(width: 6, height: 6)
                                .reduceMotionAnimation(.easeInOut(duration: 0.2), value: currentIndex)
                        }
                    }
                    // Accessibility: Group indicators and announce as single element
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Page \(currentIndex + 1) of \(items.count)")
                    .accessibilityIdentifier(AccessibilityID.InspirationCarousel.pageIndicators)

                    // Dismiss all button (X icon in circle)
                    Button {
                        onDismissAll()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 22, height: 22)
                            .background(
                                Circle()
                                    .fill(Color.secondary.opacity(0.15))
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss all")
                    .accessibilityIdentifier(AccessibilityID.InspirationCarousel.dismissAllButton)
                }
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
