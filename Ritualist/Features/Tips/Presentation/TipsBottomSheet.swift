import SwiftUI

public struct TipsBottomSheet: View {
    let tips: [Tip]
    let onTipTap: (Tip) -> Void
    let onDismiss: () -> Void
    
    public init(tips: [Tip], onTipTap: @escaping (Tip) -> Void, onDismiss: @escaping () -> Void) {
        self.tips = tips
        self.onTipTap = onTipTap
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Handle bar for dragging
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(AppColors.systemGray4)
                    .frame(width: 36, height: 5)
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.medium)
                
                // Tips list
                if tips.isEmpty {
                    // Empty state
                    VStack(spacing: Spacing.medium) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColors.systemGray3)
                        
                        Text("No tips available")
                            .font(.headline)
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        // Featured tips section
                        let featuredTips = tips.filter { $0.isFeaturedInCarousel }.sorted { $0.order < $1.order }
                        if !featuredTips.isEmpty {
                            Section(header: Text("Featured Tips").font(.subheadline).fontWeight(.medium)) {
                                ForEach(featuredTips, id: \.id) { tip in
                                    TipListRow(tip: tip, onTap: { onTipTap(tip) })
                                }
                            }
                        }
                        
                        // Tips by category
                        let categories = TipCategory.allCases
                        ForEach(categories, id: \.self) { category in
                            let categoryTips = tips.filter { $0.category == category && !$0.isFeaturedInCarousel }
                                                    .sorted { $0.title < $1.title }
                            
                            if !categoryTips.isEmpty {
                                Section(header: Text(categoryDisplayName(category)).font(.subheadline).fontWeight(.medium)) {
                                    ForEach(categoryTips, id: \.id) { tip in
                                        TipListRow(tip: tip, onTap: { onTipTap(tip) })
                                    }
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle(Strings.Tips.allTipsTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(Strings.Button.done) {
                    onDismiss()
                }
            )
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden) // We have our own handle bar
    }
    
    private func categoryDisplayName(_ category: TipCategory) -> String {
        switch category {
        case .gettingStarted:
            return "Getting Started"
        case .tracking:
            return "Tracking"
        case .motivation:
            return "Motivation"
        case .advanced:
            return "Advanced"
        }
    }
}

// MARK: - Tip List Row Component
private struct TipListRow: View {
    let tip: Tip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: Spacing.medium) {
                // Icon
                if let icon = tip.icon {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(AppColors.brand)
                        .frame(width: 28, height: 28)
                } else {
                    // Placeholder circle if no icon
                    Circle()
                        .fill(AppColors.brand.opacity(0.2))
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(tip.title.prefix(1)))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.brand)
                        )
                }
                
                // Content
                VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                    Text(tip.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(tip.description)
                        .font(.caption)
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppColors.systemGray3)
            }
            .padding(.vertical, Spacing.xxsmall)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tip: \(tip.title). \(tip.description)")
        .accessibilityAddTraits(.isButton)
    }
}