import SwiftUI
import RitualistCore

public struct CategorySelectionView: View {
    @Binding var selectedCategory: HabitCategory?
    let categories: [HabitCategory]
    let isLoading: Bool
    let onCategorySelect: (HabitCategory) -> Void
    let onAddCustomCategory: () -> Void
    let onManageCategories: (() -> Void)?
    let showAddCustomOption: Bool
    
    public init(
        selectedCategory: Binding<HabitCategory?>,
        categories: [HabitCategory],
        isLoading: Bool = false,
        showAddCustomOption: Bool = true,
        onCategorySelect: @escaping (HabitCategory) -> Void,
        onAddCustomCategory: @escaping () -> Void,
        onManageCategories: (() -> Void)? = nil
    ) {
        self._selectedCategory = selectedCategory
        self.categories = categories
        self.isLoading = isLoading
        self.showAddCustomOption = showAddCustomOption
        self.onCategorySelect = onCategorySelect
        self.onAddCustomCategory = onAddCustomCategory
        self.onManageCategories = onManageCategories
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Section header
            HStack {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                HStack(spacing: Spacing.medium) {
                    if let onManageCategories = onManageCategories {
                        Button {
                            onManageCategories()
                        } label: {
                            HStack(spacing: Spacing.xsmall) {
                                Image(systemName: "gear")
                                    .font(.caption)
                                Text("Manage")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .allowsHitTesting(true)
                    }
                    
                    if showAddCustomOption {
                        Button {
                            onAddCustomCategory()
                        } label: {
                            HStack(spacing: Spacing.xsmall) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                Text("Add Custom")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(AppColors.brand)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .allowsHitTesting(true)
                    }
                }
            }
            
            // Category selector
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading categories...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, Spacing.medium)
            } else {
                HorizontalCarousel(
                    items: categories,
                    selectedItem: selectedCategory,
                    onItemTap: { category in
                        onCategorySelect(category)
                    },
                    showPageIndicator: false,
                    horizontalPadding: 0,
                    content: { category, isSelected in
                        Chip(
                            text: category.displayName,
                            emoji: category.emoji,
                            isSelected: isSelected
                        )
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let sampleCategories = [
        HabitCategory(id: "health", name: "health", displayName: "Health", emoji: "💪", order: 0),
        HabitCategory(id: "wellness", name: "wellness", displayName: "Wellness", emoji: "🧘", order: 1),
        HabitCategory(id: "productivity", name: "productivity", displayName: "Productivity", emoji: "⚡", order: 2),
        HabitCategory(id: "learning", name: "learning", displayName: "Learning", emoji: "📚", order: 3)
    ]
    
    VStack(spacing: Spacing.large) {
        CategorySelectionView(
            selectedCategory: .constant(sampleCategories[0]),
            categories: sampleCategories,
            isLoading: false,
            onCategorySelect: { _ in },
            onAddCustomCategory: { }
        )
        
        CategorySelectionView(
            selectedCategory: .constant(nil),
            categories: [],
            isLoading: true,
            onCategorySelect: { _ in },
            onAddCustomCategory: { }
        )
    }
    .padding()
}
