//
//  CategoryCarouselWithManagement.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 06.11.2025.
//

import SwiftUI
import RitualistCore

/// Reusable category carousel with integrated cogwheel management button
public struct CategoryCarouselWithManagement: View {
    let categories: [HabitCategory]
    let selectedCategory: HabitCategory?
    let onCategoryTap: (HabitCategory?) -> Void
    let onManageTap: () -> Void
    let scrollToStartOnSelection: Bool
    let allowDeselection: Bool

    public init(
        categories: [HabitCategory],
        selectedCategory: HabitCategory?,
        onCategoryTap: @escaping (HabitCategory?) -> Void,
        onManageTap: @escaping () -> Void,
        scrollToStartOnSelection: Bool = false,
        allowDeselection: Bool = false
    ) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        self.onCategoryTap = onCategoryTap
        self.onManageTap = onManageTap
        self.scrollToStartOnSelection = scrollToStartOnSelection
        self.allowDeselection = allowDeselection
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.small) {
                    cogwheelButton
                    categoryChips(scrollProxy: proxy)
                }
                .padding(.horizontal, Spacing.screenMargin)
            }
            .mask(gradientMask)
        }
    }

    private var cogwheelButton: some View {
        Button {
            onManageTap()
        } label: {
            cogwheelButtonContent
        }
        .accessibilityLabel("Manage Categories")
        .id("cogwheel")
    }

    private var cogwheelButtonContent: some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: "gearshape")
                .font(.system(size: 15, weight: .medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(Color(.tertiarySystemBackground))
        )
        .foregroundColor(.primary)
    }

    @ViewBuilder
    private func categoryChips(scrollProxy: ScrollViewProxy) -> some View {
        ForEach(categories, id: \.id) { category in
            Chip(
                text: category.displayName,
                emoji: category.emoji,
                isSelected: selectedCategory?.id == category.id
            )
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
            // Deselect - don't scroll
            onCategoryTap(nil)
        } else {
            // Select - optionally scroll to start
            if scrollToStartOnSelection && !isCurrentlySelected {
                withAnimation {
                    scrollProxy.scrollTo("cogwheel", anchor: .leading)
                }
            }
            onCategoryTap(category)
        }
    }
}
