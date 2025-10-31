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
    @State private var cachedStyle: (gradient: LinearGradient, icon: String, color: Color)?

    init(message: String, slogan: String, timeOfDay: TimeOfDay, completionPercentage: Double = 0.0, shouldShow: Bool = true, onDismiss: @escaping () -> Void) {
        self.message = message
        self.slogan = slogan
        self.timeOfDay = timeOfDay
        self.completionPercentage = completionPercentage
        self.shouldShow = shouldShow
        self.onDismiss = onDismiss
    }

    // MARK: - Style Computation

    /// Computes the appropriate style based on completion and time
    /// Uses pre-cached gradients from GradientTokens for optimal performance
    /// Only called when dependencies change (not on every render)
    private func computeStyle(
        completionPercentage: Double,
        timeOfDay: TimeOfDay
    ) -> (gradient: LinearGradient, icon: String, color: Color) {

        // Progress-based styling (takes priority)
        if completionPercentage >= 1.0 {
            // Perfect day celebration
            return (
                GradientTokens.inspirationPerfect,
                "party.popper.fill",
                .green
            )
        } else if completionPercentage >= 0.75 {
            // Strong progress celebration
            return (
                GradientTokens.inspirationStrong,
                "flame.fill",
                .blue
            )
        } else if completionPercentage >= 0.5 {
            // Midway encouragement
            return (
                GradientTokens.inspirationMidway,
                "bolt.fill",
                .orange
            )
        } else {
            // Time-based motivation
            switch timeOfDay {
            case .morning:
                return (
                    GradientTokens.inspirationMorning,
                    "sunrise.fill",
                    .pink
                )
            case .noon:
                return (
                    GradientTokens.inspirationNoon,
                    "sun.max.fill",
                    .indigo
                )
            case .evening:
                return (
                    GradientTokens.inspirationEvening,
                    "moon.stars.fill",
                    .purple
                )
            }
        }
    }

    /// Updates the cached style when dependencies change
    private func updateCachedStyle() {
        cachedStyle = computeStyle(
            completionPercentage: completionPercentage,
            timeOfDay: timeOfDay
        )
    }

    /// Fallback style for initial render before cache is populated
    private var defaultStyle: (gradient: LinearGradient, icon: String, color: Color) {
        (GradientTokens.inspirationMorning, "sunrise.fill", .pink)
    }
    
    var body: some View {
        if shouldShow {
            // Use cached style - single access, no recomputation
            let style = cachedStyle ?? defaultStyle

            VStack(spacing: 0) {
                HStack {
                    // Time-based icon
                    Image(systemName: style.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(style.color)

                    Spacer()

                    // Dismiss button
                    Button(action: onDismiss) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(style.color)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Main content
                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 16)

                    // Show original slogan as subtitle when message and slogan are different
                    if message != slogan && !slogan.isEmpty {
                        Text(slogan)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(style.color)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .italic()
                            .padding(.horizontal, 20)
                    }

                    // PERFORMANCE: Removed infinite animations - caused constant GPU work during scrolling
                    // Static dots instead of animated ones for smooth scrolling
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { _ in
                            Circle()
                                .fill(style.color.opacity(0.6))
                                .frame(width: 6, height: 6)
                        }
                    }
                    .padding(.bottom, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                style.gradient
                    .clipShape(RoundedRectangle(cornerRadius: CardDesign.cornerRadius))
            )
            .iconRingsOverlay(intensity: 0.25, ringCount: 3)
            .clipShape(RoundedRectangle(cornerRadius: CardDesign.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: CardDesign.cornerRadius)
                    .stroke(style.color.opacity(0.2), lineWidth: 1)
            )
            // PERFORMANCE: Removed colored shadow and animations for smooth scrolling
            .shadow(
                color: .black.opacity(0.05),
                radius: 4,
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