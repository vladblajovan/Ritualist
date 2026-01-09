import SwiftUI
import RitualistCore

public struct CategoryFilterCarousel: View {
    @Binding var selectedCategory: HabitCategory?
    let categories: [HabitCategory]
    let isLoading: Bool
    let onCategorySelect: (HabitCategory?) -> Void
    let onManageCategories: (() -> Void)?
    let onAddHabit: (() -> Void)?
    let onAssistant: (() -> Void)?
    let showHeader: Bool

    public init(
        selectedCategory: Binding<HabitCategory?>,
        categories: [HabitCategory],
        isLoading: Bool = false,
        onCategorySelect: @escaping (HabitCategory?) -> Void,
        onManageCategories: (() -> Void)? = nil,
        onAddHabit: (() -> Void)? = nil,
        onAssistant: (() -> Void)? = nil,
        showHeader: Bool = true
    ) {
        self._selectedCategory = selectedCategory
        self.categories = categories
        self.isLoading = isLoading
        self.onCategorySelect = onCategorySelect
        self.onManageCategories = onManageCategories
        self.onAddHabit = onAddHabit
        self.onAssistant = onAssistant
        self.showHeader = showHeader
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            // Header with title, manage button and add habit button
            if showHeader {
                HStack {
                    Text(Strings.CategoryManagement.categories)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let onManageCategories = onManageCategories {
                        Button {
                            onManageCategories()
                        } label: {
                            HStack(spacing: Spacing.xsmall) {
                                Image(systemName: "gear")
                                    .font(.caption)
                                Text(Strings.CategoryManagement.manage)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    HStack(spacing: Spacing.small) {
                        if let onAssistant = onAssistant {
                            Button {
                                onAssistant()
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 28, height: 28)

                                    Text("🤖")
                                        .font(.system(size: 16))
                                        .accessibilityHidden(true) // Decorative emoji
                                }
                            }
                            .frame(minWidth: 44, minHeight: 44) // Meet 44pt touch target
                            .accessibilityLabel(Strings.Components.habitsAssistant)
                            .accessibilityHint(Strings.Components.assistantHint)
                            .accessibilityIdentifier("category_filter_assistant_button")
                        }

                        if let onAddHabit = onAddHabit {
                            Button {
                                onAddHabit()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundColor(AppColors.brand)
                            }
                            .frame(minWidth: 44, minHeight: 44) // Meet 44pt touch target
                            .accessibilityLabel(Strings.Components.addHabit)
                            .accessibilityHint(Strings.Components.createHabitHint)
                            .accessibilityIdentifier("category_filter_add_habit_button")
                        }
                    }
                }
                .padding(.horizontal, Spacing.large)
            }

            // Category filter carousel
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(Strings.CategoryManagement.loadingCategories)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, Spacing.large)
                .padding(.vertical, Spacing.medium)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // Category chips
                        ForEach(categories, id: \.id) { category in
                            Button {
                                // Toggle: if already selected, deselect; otherwise select
                                if selectedCategory?.id == category.id {
                                    onCategorySelect(nil)
                                } else {
                                    onCategorySelect(category)
                                }
                            } label: {
                                Chip(
                                    text: category.displayName,
                                    emoji: category.emoji,
                                    isSelected: selectedCategory?.id == category.id,
                                    accessibilityIdentifier: "category_chip_\(category.id)"
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .onLongPressGesture {
                                onManageCategories?()
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.large)
                }
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
        CategoryFilterCarousel(
            selectedCategory: .constant(nil),
            categories: sampleCategories,
            isLoading: false,
            onCategorySelect: { _ in },
            onManageCategories: { }
        )
        
        CategoryFilterCarousel(
            selectedCategory: .constant(sampleCategories[1]),
            categories: sampleCategories,
            isLoading: false,
            onCategorySelect: { _ in }
        )
        
        CategoryFilterCarousel(
            selectedCategory: .constant(nil),
            categories: [],
            isLoading: true,
            onCategorySelect: { _ in }
        )
    }
    .padding()
}
