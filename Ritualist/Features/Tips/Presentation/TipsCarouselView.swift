import SwiftUI
import RitualistCore

// MARK: - Height Preference Key
private struct CardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

public struct TipsCarouselView: View {
    let tips: [Tip]
    let isLoading: Bool
    let onTipTap: (Tip) -> Void
    let onShowMoreTap: () -> Void
    @State private var maxCardHeight: CGFloat = 0
    
    public init(tips: [Tip], isLoading: Bool, onTipTap: @escaping (Tip) -> Void, onShowMoreTap: @escaping () -> Void) {
        self.tips = tips
        self.isLoading = isLoading
        self.onTipTap = onTipTap
        self.onShowMoreTap = onShowMoreTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Section title
            HStack {
                Text(Strings.Tips.carouselTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, Spacing.large)
            
            if isLoading {
                // Loading state
                HStack {
                    ForEach(0..<3, id: \.self) { _ in
                        TipCardPlaceholder()
                    }
                    Spacer()
                }
                .padding(.horizontal, Spacing.large)
            } else if tips.isEmpty {
                // Empty state (shouldn't happen with predefined tips, but good to handle)
                Text("No tips available")
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, Spacing.large)
            } else {
                // Tips carousel
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: Spacing.medium) {
                        // Feature tips
                        ForEach(tips, id: \.id) { tip in
                            TipCard(
                                tip: tip,
                                targetHeight: maxCardHeight,
                                onTap: { onTipTap(tip) }
                            )
                        }
                        
                        // "Show more" card
                        ShowMoreTipCard(
                            targetHeight: maxCardHeight,
                            onTap: onShowMoreTap
                        )
                    }
                    .padding(.horizontal, Spacing.large)
                }
                .onPreferenceChange(CardHeightPreferenceKey.self) { height in
                    maxCardHeight = height
                }
                .mask(
                    // Fade out edges when content overflows
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: .clear, location: 0),
                            .init(color: .black, location: 0.05),
                            .init(color: .black, location: 0.95),
                            .init(color: .clear, location: 1)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        .padding(.vertical, Spacing.medium)
        .background(AppColors.background)
    }
}

// MARK: - Tip Card Component
private struct TipCard: View {
    let tip: Tip
    let targetHeight: CGFloat
    let onTap: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var cardWidth: CGFloat {
        switch horizontalSizeClass {
        case .compact:
            return 160  // Smaller width for iPhone
        case .regular:
            return 200  // Original width for iPad
        default:
            return 160
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Icon and title
                HStack(alignment: .top, spacing: Spacing.small) {
                    if let icon = tip.icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(AppColors.brand)
                            .frame(width: 20)
                    }
                    
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer(minLength: 0)
                }
                
                // Description
                Text(tip.description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.medium)
            .frame(width: cardWidth)
            .frame(height: targetHeight > 0 ? targetHeight : nil)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: CardHeightPreferenceKey.self, value: geometry.size.height)
                }
            )
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.separator.opacity(0.5), lineWidth: ComponentSize.separatorHairline)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tip: \(tip.title). \(tip.description)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Show More Card Component
private struct ShowMoreTipCard: View {
    let targetHeight: CGFloat
    let onTap: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var cardWidth: CGFloat {
        switch horizontalSizeClass {
        case .compact:
            return 160  // Smaller width for iPhone
        case .regular:
            return 200  // Original width for iPad
        default:
            return 160
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.small) {
                Spacer(minLength: 0)
                
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title)
                    .foregroundColor(AppColors.brand)
                
                Text(Strings.Tips.showMore)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer(minLength: 0)
            }
            .padding(Spacing.medium)
            .frame(width: cardWidth)
            .frame(height: targetHeight > 0 ? targetHeight : nil)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: CardHeightPreferenceKey.self, value: geometry.size.height)
                }
            )
            .background(
                AppColors.brand.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.brand.opacity(0.3), lineWidth: ComponentSize.separatorThin)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Strings.Tips.showMore)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Loading Placeholder
private struct TipCardPlaceholder: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var cardWidth: CGFloat {
        switch horizontalSizeClass {
        case .compact:
            return 160  // Smaller width for iPhone
        case .regular:
            return 200  // Original width for iPad
        default:
            return 160
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.systemGray6)
            .frame(width: cardWidth, height: ComponentSize.tipCardHeight)
            .redacted(reason: .placeholder)
    }
}
