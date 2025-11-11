import SwiftUI
import RitualistCore

struct InspirationCard: View {
    let message: String
    let slogan: String
    let timeOfDay: TimeOfDay
    let completionPercentage: Double
    let shouldShow: Bool
    let onDismiss: () -> Void

    // PERFORMANCE OPTIMIZATION: Cache computed style to prevent recomputation on every render
    // This eliminates repeated gradient creation and branching logic evaluation
    @State private var cachedStyle: InspirationStyleViewLogic.Style?

    init(message: String, slogan: String, timeOfDay: TimeOfDay, completionPercentage: Double = 0.0, shouldShow: Bool = true, onDismiss: @escaping () -> Void) {
        self.message = message
        self.slogan = slogan
        self.timeOfDay = timeOfDay
        self.completionPercentage = completionPercentage
        self.shouldShow = shouldShow
        self.onDismiss = onDismiss
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

            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 0) {
                    // Header with icon and title
                    HStack(alignment: .top, spacing: 12) {
                        // Time-based icon with fixed frame for consistency
                        Image(systemName: style.iconName)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(style.accentColor)
                            .frame(width: 24, height: 24)

                        // Main message on same line as icon
                        Text(message)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // Show original slogan as subtitle when message and slogan are different
                    if message != slogan && !slogan.isEmpty {
                        Text(slogan)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3)
                            .italic()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }

                    Spacer(minLength: 16)
                }
                .padding(.bottom, 20)

                // Dismiss button in bottom-right
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(.secondary.opacity(0.15))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.trailing, 16)
                .padding(.bottom, 16)
            }
            .background(
                style.gradient
            )
            .clipShape(RoundedRectangle(cornerRadius: CardDesign.cornerRadius))
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
            onDismiss: { }
        )
        
        InspirationCard(
            message: "Amazing progress! You're at the halfway mark. Your consistency is paying off! 🎯",
            slogan: "Midday momentum, unstoppable force.",
            timeOfDay: .noon,
            completionPercentage: 0.6,
            shouldShow: true,
            onDismiss: { }
        )
        
        InspirationCard(
            message: "🎊 Perfect day complete! You've shown incredible dedication and consistency!",
            slogan: "End strong, dream bigger.",
            timeOfDay: .evening,
            completionPercentage: 1.0,
            shouldShow: true,
            onDismiss: { }
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}