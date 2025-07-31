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
        NavigationStack {
            VStack(spacing: 0) {
                // Handle bar for dragging
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(AppColors.systemGray4)
                    .frame(width: ComponentSize.drawerHandle, height: ComponentSize.drawerHandleHeight)
                    .padding(.top, Spacing.small)
                    .padding(.bottom, Spacing.medium)
                
                // Tips list
                if tips.isEmpty {
                    // Empty state
                    VStack(spacing: Spacing.medium) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: Typography.mediumIcon))
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
                                    NavigationLink(destination: TipDetailContentView(tip: tip)) {
                                        TipListRowContent(tip: tip)
                                    }
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
                                        NavigationLink(destination: TipDetailContentView(tip: tip)) {
                                            TipListRowContent(tip: tip)
                                        }
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(Strings.Button.done) {
                        onDismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
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

// MARK: - Tip List Row Component (Legacy - kept for compatibility)
private struct TipListRow: View {
    let tip: Tip
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            TipListRowContent(tip: tip)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tip: \(tip.title). \(tip.description)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Tip List Row Content (for NavigationLink)
private struct TipListRowContent: View {
    let tip: Tip
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            // Icon
            if let icon = tip.icon {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(AppColors.brand)
                    .frame(width: ComponentSize.iconMedium, height: ComponentSize.iconMedium)
            } else {
                // Placeholder circle if no icon
                Circle()
                    .fill(AppColors.brand.opacity(0.2))
                    .frame(width: ComponentSize.iconMedium, height: ComponentSize.iconMedium)
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
        }
        .padding(.vertical, Spacing.xxsmall)
        .accessibilityLabel("Tip: \(tip.title). \(tip.description)")
    }
}

// MARK: - Tip Detail Content View for NavigationStack
private struct TipDetailContentView: View {
    let tip: Tip
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.large) {
                // Header section with icon and title
                headerSection
                
                // Content section
                contentSection
                
                // Category and metadata
                metadataSection
                
                Spacer()
            }
            .padding(Spacing.large)
        }
        .navigationTitle(tip.title)
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Icon and category
            HStack {
                if let icon = tip.icon {
                    Image(systemName: icon)
                        .font(.largeTitle)
                        .foregroundColor(AppColors.brand)
                }
                
                Spacer()
                
                // Category badge
                Text(categoryDisplayName(tip.category))
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xxsmall)
                    .background(AppColors.brand.opacity(0.1), in: Capsule())
                    .foregroundColor(AppColors.brand)
            }
            
            // Description (short version)
            if !tip.description.isEmpty {
                Text(tip.description)
                    .font(.headline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Divider
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: ComponentSize.separatorThin)
                .padding(.vertical, Spacing.small)
            
            // Full content
            Text(tip.content)
                .font(.body)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack {
                Text("Category")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textSecondary)
                
                Spacer()
                
                Text(categoryDisplayName(tip.category))
                    .font(.caption)
                    .foregroundColor(AppColors.textPrimary)
            }
            
            if tip.isFeaturedInCarousel {
                HStack {
                    Text("Featured")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(AppColors.textSecondary)
                    
                    Spacer()
                    
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(AppColors.accentYellow)
                }
            }
        }
        .padding(Spacing.medium)
        .background(AppColors.surface, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.separator.opacity(0.5), lineWidth: ComponentSize.separatorHairline)
        )
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