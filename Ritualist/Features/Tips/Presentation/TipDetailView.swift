import SwiftUI
import RitualistCore

public struct TipDetailView: View {
    let tip: Tip
    let onDismiss: () -> Void
    
    public init(tip: Tip, onDismiss: @escaping () -> Void) {
        self.tip = tip
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        NavigationView {
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
            .navigationTitle(Strings.Tips.tipDetailTitle)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button(Strings.Button.done) {
                    onDismiss()
                }
            )
        }
        .presentationDetents([.large])
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
            
            // Title
            Text(tip.title)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppColors.textPrimary)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Description (short version)
            if !tip.description.isEmpty {
                Text(tip.description)
                    .font(.headline)
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            
            // Divider
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 1)
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
                Text(String(localized: "categoryLabel"))
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
                    Text(String(localized: "featuredLabel"))
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
                .stroke(AppColors.separator.opacity(0.5), lineWidth: 0.5)
        )
    }
    
    private func categoryDisplayName(_ category: TipCategory) -> String {
        switch category {
        case .gettingStarted:
            return String(localized: "gettingStarted")
        case .tracking:
            return String(localized: "trackingTips")
        case .motivation:
            return String(localized: "motivationTips")
        case .advanced:
            return String(localized: "advancedTips")
        }
    }
}

// MARK: - Preview Support
#if DEBUG
struct TipDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TipDetailView(
            tip: Tip(
                title: "Start Small",
                description: "Begin with tiny habits that are easy to maintain",
                content: "Starting small is one of the most effective strategies for building lasting habits. " +
                         "When you set the bar low, you remove the friction and excuses that often derail habit formation. " +
                         "Want to read more? Start with just one page a day. Want to exercise? Start with 2 minutes. " +
                         "The key is consistency over intensity. Once the habit becomes automatic, you can gradually increase the difficulty.",
                category: .gettingStarted,
                order: 1,
                isFeaturedInCarousel: true,
                icon: "leaf"
            ),
            onDismiss: {}
        )
    }
}
#endif
