import SwiftUI
import RitualistCore

struct InspirationCard: View {
    let message: String
    let slogan: String
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let shouldShow: Bool
    let onDismiss: () -> Void
    let onDismissAll: () -> Void

    // Dynamic Type support for icon frame
    @ScaledMetric(relativeTo: .title2) private var iconFrameSize: CGFloat = 32

    // PERFORMANCE OPTIMIZATION: Cache computed style to prevent recomputation on every render
    // This eliminates repeated gradient creation and branching logic evaluation
    @State private var cachedStyle: InspirationStyleViewLogic.Style?

    init(
        message: String,
        slogan: String,
        timeOfDay: TimeOfDay,
        completionPercentage: Double = 0.0,
        shouldShow: Bool = true,
        onDismiss: @escaping () -> Void,
        onDismissAll: @escaping () -> Void = {}
    ) {
        self.message = message
        self.slogan = slogan
        self.timeOfDay = timeOfDay
        self.completionPercentage = completionPercentage
        self.shouldShow = shouldShow
        self.onDismiss = onDismiss
        self.onDismissAll = onDismissAll
    }

    // MARK: - Style Computation

    /// Updates the cached style when dependencies change
    private func updateCachedStyle() {
        let context = InspirationStyleViewLogic.StyleContext(
            completionPercentage: completionPercentage,
            timeOfDay: timeOfDay
        )
        cachedStyle = InspirationStyleViewLogic.computeStyle(for: context)
    }

    /// Fallback style for initial render before cache is populated
    private var defaultStyle: InspirationStyleViewLogic.Style {
        InspirationStyleViewLogic.Style(
            gradient: GradientTokens.inspirationMorning,
            gradientType: .morning,
            iconName: "sunrise.fill",
            accentColor: .pink
        )
    }
    
    var body: some View {
        if shouldShow {
            // Use cached style - single access, no recomputation
            let style = cachedStyle ?? defaultStyle

            VStack(spacing: 0) {
                // Header with icon and title
                HStack(alignment: .center, spacing: 12) {
                    // Time-based icon with scaled frame for Dynamic Type
                    Image(systemName: style.iconName)
                        .font(CardDesign.title2.weight(.medium))
                        .foregroundColor(style.accentColor)
                        .frame(width: iconFrameSize, height: iconFrameSize)
                        .accessibilityHidden(true) // Decorative icon

                    // Main message on same line as icon
                    Text(message)
                        .font(CardDesign.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Show original slogan as subtitle when message and slogan are different
                if message != slogan && !slogan.isEmpty {
                    Text(slogan)
                        .font(CardDesign.subheadline.weight(.medium))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 8)
                }

                Spacer(minLength: 12)

                // Bottom row: spacer + dismiss button at right
                HStack {
                    Spacer()

                    // Acknowledgement button - tap to dismiss one, long-press to dismiss all
                    Button(action: onDismiss) {
                        Image(systemName: "checkmark")
                            .font(CardDesign.subheadline.weight(.semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 44, height: 44) // Keep fixed for 44pt touch target
                            .background(
                                Circle()
                                    .fill(.secondary.opacity(0.15))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.5)
                            .onEnded { _ in
                                HapticFeedbackService.shared.trigger(.heavy)
                                onDismissAll()
                            }
                    )
                    .accessibilityLabel("Dismiss inspiration card. Long press to dismiss all.")
                    .accessibilityIdentifier(AccessibilityID.InspirationCarousel.cardDismissButton)
                }
            }
            .padding(CardDesign.cardPadding)
            .background(
                ZStack {
                    CardDesign.cardBackground
                    style.gradient
                }
            )
            .cornerRadius(CardDesign.cornerRadius)
            .shadow(
                color: CardDesign.shadowColor,
                radius: CardDesign.shadowRadius,
                x: 0,
                y: 2
            )
            // PERFORMANCE: Reactive cache updates - only when dependencies change
            .onAppear {
                updateCachedStyle()
            }
            .onChange(of: completionPercentage) { _, _ in
                updateCachedStyle()
            }
            .onChange(of: timeOfDay) { _, _ in
                updateCachedStyle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        InspirationCard(
            message: "Good morning! Ready to make today incredible?",
            slogan: "Rise with purpose, rule your day.",
            timeOfDay: .morning,
            completionPercentage: 0.0,
            shouldShow: true,
            onDismiss: { },
            onDismissAll: { }
        )

        InspirationCard(
            message: "Amazing progress! You're at the halfway mark. Your consistency is paying off! 🎯",
            slogan: "Midday momentum, unstoppable force.",
            timeOfDay: .noon,
            completionPercentage: 0.6,
            shouldShow: true,
            onDismiss: { },
            onDismissAll: { }
        )

        InspirationCard(
            message: "🎊 Perfect day complete! You've shown incredible dedication and consistency!",
            slogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            shouldShow: true,
            onDismiss: { },
            onDismissAll: { }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}