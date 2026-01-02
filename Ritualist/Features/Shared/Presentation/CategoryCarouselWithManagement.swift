//
//  CategoryCarouselWithManagement.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.11.2025.
//

import SwiftUI
import RitualistCore

/// Reusable category carousel with optional cogwheel management button
/// When no category is selected (nil), all items are shown
/// When `scrollToStartOnSelection` is true, selected category is moved to first position
public struct CategoryCarouselWithManagement: View {
    let categories: [HabitCategory]
    @Binding var selectedCategory: HabitCategory?
    let onCategoryTap: ((HabitCategory?) -> Void)?
    let onManageTap: (() -> Void)?
    let scrollToStartOnSelection: Bool
    let allowDeselection: Bool
    let unselectedBackgroundColor: Color

    /// Whether to show the cogwheel button
    private var showCogwheel: Bool { onManageTap != nil }

    /// Categories with selected category moved to first position (when scrollToStartOnSelection is true)
    private var displayCategories: [HabitCategory] {
        guard scrollToStartOnSelection, let selected = selectedCategory else {
            return categories
        }
        var reordered = categories
        if let selectedIndex = reordered.firstIndex(where: { $0.id == selected.id }) {
            let selectedCategory = reordered.remove(at: selectedIndex)
            reordered.insert(selectedCategory, at: 0)
        }
        return reordered
    }

    public init(
        categories: [HabitCategory],
        selectedCategory: Binding<HabitCategory?>,
        onCategoryTap: ((HabitCategory?) -> Void)? = nil,
        onManageTap: (() -> Void)? = nil,
        scrollToStartOnSelection: Bool = false,
        allowDeselection: Bool = true,
        unselectedBackgroundColor: Color = AppColors.chipUnselectedBackground
    ) {
        self.categories = categories
        self._selectedCategory = selectedCategory
        self.onCategoryTap = onCategoryTap
        self.onManageTap = onManageTap
        self.scrollToStartOnSelection = scrollToStartOnSelection
        self.allowDeselection = allowDeselection
        self.unselectedBackgroundColor = unselectedBackgroundColor
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    if showCogwheel {
                        cogwheelButton
                    }
                    categoryChips(scrollProxy: proxy)
                }
                .padding(.leading, showCogwheel ? 0 : Spacing.medium)
                .padding(.trailing, Spacing.medium)
            }
            .mask(gradientMask)
        }
    }

    @ViewBuilder
    private var cogwheelButton: some View {
        if let onManageTap = onManageTap {
            Button {
                onManageTap()
            } label: {
                cogwheelButtonContent
            }
            .accessibilityLabel("Manage Categories")
            .id("cogwheel")
        }
    }

    private var cogwheelButtonContent: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "gearshape")
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(unselectedBackgroundColor)
        )
        .foregroundColor(.primary)
    }

    @ViewBuilder
    private func categoryChips(scrollProxy: ScrollViewProxy) -> some View {
        ForEach(displayCategories, id: \.id) { category in
            Chip(
                text: category.displayName,
                emoji: category.emoji,
                unselectedBackgroundColor: unselectedBackgroundColor,
                isSelected: selectedCategory?.id == category.id
            )
            .id(category.id)
            .onTapGesture {
                handleCategoryTap(category, scrollProxy: scrollProxy)
            }
        }
    }

    private var gradientMask: some View {
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
    }

    private func handleCategoryTap(_ category: HabitCategory, scrollProxy: ScrollViewProxy) {
        let isCurrentlySelected = selectedCategory?.id == category.id

        if allowDeselection && isCurrentlySelected {
            selectedCategory = nil
            onCategoryTap?(nil)
        } else {
            selectedCategory = category
            onCategoryTap?(category)
            // Scroll to cogwheel when scrollToStartOnSelection is enabled (used in habit detail)
            if scrollToStartOnSelection && showCogwheel {
                Task { @MainActor in
                    scrollProxy.scrollTo("cogwheel", anchor: .leading)
                }
            }
        }
    }
}
