import SwiftUI

struct OnboardingPremiumComparisonView: View {
    // MARK: - Constants
    private enum LayoutConstants {
        // Spacing constants
        static let smallSpacing: CGFloat = 16
        static let mediumSpacing: CGFloat = 24
        static let largeSpacing: CGFloat = 32

        // Padding constants
        static let smallPadding: CGFloat = 16
        static let mediumPadding: CGFloat = 20
        static let largePadding: CGFloat = 24

        // Breakpoints
        static let smallHeightBreakpoint: CGFloat = 600
        static let mediumHeightBreakpoint: CGFloat = 750
        static let smallWidthBreakpoint: CGFloat = 350
        static let mediumWidthBreakpoint: CGFloat = 400
    }

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
                        Text(Strings.OnboardingPremium.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(Strings.OnboardingPremium.subtitle)
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
                            title: Strings.OnboardingPremium.freeTier,
                            features: [
                                TierFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.fiveHabits, color: .green),
                                TierFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.dailyTracking, color: .green),
                                TierFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.basicNotifications, color: .green),
                                TierFeature(icon: "checkmark.circle.fill", text: Strings.OnboardingPremium.tipsInsights, color: .green)
                            ],
                            isPro: false,
                            geometry: geometry
                        )

                        // Pro tier
                        TierCard(
                            title: Strings.OnboardingPremium.proTier,
                            features: [
                                TierFeature(icon: "infinity.circle.fill", text: Strings.OnboardingPremium.unlimitedHabits, color: .orange),
                                TierFeature(icon: "chart.line.uptrend.xyaxis.circle.fill", text: Strings.OnboardingPremium.advancedAnalytics, color: .orange),
                                TierFeature(icon: "bell.badge.circle.fill", text: Strings.OnboardingPremium.customReminders, color: .orange),
                                TierFeature(icon: "square.and.arrow.up.circle.fill", text: Strings.OnboardingPremium.dataExport, color: .orange)
                            ],
                            isPro: true,
                            geometry: geometry
                        )
                    }
                    .padding(.horizontal, adaptivePadding(for: geometry.size.width))

                    // Footer text
                    Text(Strings.OnboardingPremium.footer)
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
        case 0..<LayoutConstants.smallHeightBreakpoint:
            return LayoutConstants.smallSpacing  // Small screens - compact spacing
        case LayoutConstants.smallHeightBreakpoint..<LayoutConstants.mediumHeightBreakpoint:
            return LayoutConstants.mediumSpacing  // Medium screens
        default:
            return LayoutConstants.largeSpacing  // Large screens - original spacing
        }
    }

    private func adaptivePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case 0..<LayoutConstants.smallWidthBreakpoint:
            return LayoutConstants.smallPadding  // Small screens
        case LayoutConstants.smallWidthBreakpoint..<LayoutConstants.mediumWidthBreakpoint:
            return LayoutConstants.mediumPadding  // Medium screens
        default:
            return LayoutConstants.largePadding  // Large screens - original padding
        }
    }
}

private struct TierFeature: Identifiable {
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
