import SwiftUI

struct OnboardingPremiumComparisonView: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: adaptiveSpacing(for: geometry.size.height)) {
                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)

                    // Sparkles icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    VStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        Text("Power Up Your Journey")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Start free with everything you need. Upgrade anytime for unlimited habits and advanced features.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, adaptivePadding(for: geometry.size.width))
                    }

                    // Free vs Pro comparison
                    HStack(spacing: adaptiveSpacing(for: geometry.size.height) / 2) {
                        // Free tier
                        TierCard(
                            title: "Start Free",
                            features: [
                                TierFeature(icon: "checkmark.circle.fill", text: "5 Habits", color: .green),
                                TierFeature(icon: "checkmark.circle.fill", text: "Daily Tracking", color: .green),
                                TierFeature(icon: "checkmark.circle.fill", text: "Basic Notifications", color: .green),
                                TierFeature(icon: "checkmark.circle.fill", text: "Tips & Insights", color: .green)
                            ],
                            isPro: false,
                            geometry: geometry
                        )

                        // Pro tier
                        TierCard(
                            title: "Go Pro",
                            features: [
                                TierFeature(icon: "infinity.circle.fill", text: "Unlimited Habits", color: .orange),
                                TierFeature(icon: "chart.line.uptrend.xyaxis.circle.fill", text: "Advanced Analytics", color: .orange),
                                TierFeature(icon: "bell.badge.circle.fill", text: "Custom Reminders", color: .orange),
                                TierFeature(icon: "square.and.arrow.up.circle.fill", text: "Data Export", color: .orange)
                            ],
                            isPro: true,
                            geometry: geometry
                        )
                    }
                    .padding(.horizontal, adaptivePadding(for: geometry.size.width))

                    // Footer text
                    Text("Start free. Upgrade when you're ready.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, adaptiveSpacing(for: geometry.size.height) / 4)

                    Spacer(minLength: adaptiveSpacing(for: geometry.size.height) / 2)
                }
                .frame(minHeight: geometry.size.height)
                .padding(.horizontal, adaptivePadding(for: geometry.size.width))
            }
        }
    }

    private func adaptiveSpacing(for height: CGFloat) -> CGFloat {
        switch height {
        case 0..<600: return 16  // Small screens - compact spacing
        case 600..<750: return 24  // Medium screens
        default: return 32  // Large screens - original spacing
        }
    }

    private func adaptivePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case 0..<350: return 16  // Small screens
        case 350..<400: return 20  // Medium screens
        default: return 24  // Large screens - original padding
        }
    }
}

struct TierFeature: Identifiable {
    let id = UUID()
    let icon: String
    let text: String
    let color: Color
}

private struct TierCard: View {
    let title: String
    let features: [TierFeature]
    let isPro: Bool
    let geometry: GeometryProxy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon
            HStack(spacing: 8) {
                if isPro {
                    Image(systemName: "crown.fill")
                        .font(.title3)
                        .foregroundColor(.orange)
                }

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isPro ? .orange : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Features list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(features) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: feature.icon)
                            .font(.caption)
                            .foregroundColor(feature.color)
                            .frame(width: 16)

                        Text(feature.text)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPro ? Color.orange.opacity(0.1) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isPro ? Color.orange.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

#Preview {
    OnboardingPremiumComparisonView()
}
