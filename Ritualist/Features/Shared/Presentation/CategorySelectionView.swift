import SwiftUI

public struct CategorySelectionView: View {
    @Binding var selectedCategory: Category?
    let categories: [Category]
    let isLoading: Bool
    let onCategorySelect: (Category) -> Void
    let onAddCustomCategory: () -> Void
    let showAddCustomOption: Bool
    
    public init(
        selectedCategory: Binding<Category?>,
        categories: [Category],
        isLoading: Bool = false,
        showAddCustomOption: Bool = true,
        onCategorySelect: @escaping (Category) -> Void,
        onAddCustomCategory: @escaping () -> Void
    ) {
        self._selectedCategory = selectedCategory
        self.categories = categories
        self.isLoading = isLoading
        self.showAddCustomOption = showAddCustomOption
        self.onCategorySelect = onCategorySelect
        self.onAddCustomCategory = onAddCustomCategory
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            // Section header
            HStack {
                Text("Category")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
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
        Category(id: "health", name: "health", displayName: "Health", emoji: "💪", order: 0),
        Category(id: "wellness", name: "wellness", displayName: "Wellness", emoji: "🧘", order: 1),
        Category(id: "productivity", name: "productivity", displayName: "Productivity", emoji: "⚡", order: 2),
        Category(id: "learning", name: "learning", displayName: "Learning", emoji: "📚", order: 3)
    ]
    
    return VStack(spacing: Spacing.large) {
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