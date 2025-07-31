import SwiftUI

public struct TipsCarouselView: View {
    let tips: [Tip]
    let isLoading: Bool
    let onTipTap: (Tip) -> Void
    let onShowMoreTap: () -> Void
    
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
                    HStack(spacing: Spacing.medium) {
                        // Feature tips
                        ForEach(tips, id: \.id) { tip in
                            TipCard(
                                tip: tip,
                                onTap: { onTipTap(tip) }
                            )
                        }
                        
                        // "Show more" card
                        ShowMoreTipCard(onTap: onShowMoreTap)
                    }
                    .padding(.horizontal, Spacing.large)
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
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.small) {
                // Icon and title
                HStack(spacing: Spacing.small) {
                    if let icon = tip.icon {
                        Image(systemName: icon)
                            .font(.title2)
                            .foregroundColor(AppColors.brand)
                    }
                    
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                
                // Description
                Text(tip.description)
                    .font(.caption)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                Spacer()
            }
            .padding(Spacing.medium)
            .frame(width: 200, height: 100)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.separator.opacity(0.5), lineWidth: 0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tip: \(tip.title). \(tip.description)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Show More Card Component
private struct ShowMoreTipCard: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Spacing.small) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title)
                    .foregroundColor(AppColors.brand)
                
                Text(Strings.Tips.showMore)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .padding(Spacing.medium)
            .frame(width: 200, height: 100)
            .background(
                AppColors.brand.opacity(0.1),
                in: RoundedRectangle(cornerRadius: 12)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.brand.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(Strings.Tips.showMore)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Loading Placeholder
private struct TipCardPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(AppColors.systemGray6)
            .frame(width: 200, height: 100)
            .redacted(reason: .placeholder)
    }
}