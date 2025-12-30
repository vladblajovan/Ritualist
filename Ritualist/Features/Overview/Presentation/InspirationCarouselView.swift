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

    /// Compute gradient for card background based on time of day and completion
    private var cardGradient: LinearGradient {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: completionPercentage,
            timeOfDay: timeOfDay
        )
        return InspirationStyleViewLogic.computeStyle(for: context).gradient
    }

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
                                animateIfAllowed(SpringAnimation.interactive) {
                                    onDismiss(item)
                                }
                            }
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(minHeight: 100)
                .onChange(of: items.count) { _, newCount in
                    if currentIndex >= newCount {
                        animateIfAllowed(.easeInOut(duration: 0.2)) {
                            currentIndex = max(0, newCount - 1)
                        }
                    }
                }

                // Page indicators and dismiss button (same line)
                if items.count > 1 {
                    HStack(spacing: 8) {
                        // Page indicators
                        HStack(spacing: 6) {
                            ForEach(0..<items.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? Color.white : Color.white.opacity(0.4))
                                    .frame(width: 6, height: 6)
                                    .reduceMotionAnimation(.easeInOut(duration: 0.2), value: currentIndex)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(.secondary.opacity(0.15))
                        )
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
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 22, height: 22)
                                .background(
                                    Circle()
                                        .fill(.secondary.opacity(0.15))
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss all")
                        .accessibilityIdentifier(AccessibilityID.InspirationCarousel.dismissAllButton)
                    }
                }
            }
        }
        .padding(CardDesign.cardPadding)
        .background(
            ZStack {
                CardDesign.cardBackground
                cardGradient
            }
        )
        .cornerRadius(CardDesign.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: CardDesign.shadowColor, radius: CardDesign.shadowRadius, x: 0, y: 2)
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
