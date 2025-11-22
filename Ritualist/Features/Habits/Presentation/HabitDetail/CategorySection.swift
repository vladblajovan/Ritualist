//
//  CategorySection.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import SwiftUI
import FactoryKit
import RitualistCore

public struct CategorySection: View {
    @Bindable var vm: HabitDetailViewModel
    @Binding var showingCategoryManagement: Bool

    public var body: some View {
        Section("Category") {
            // Show category selection for new habits or editable habits (not from suggestions)
            if !vm.isEditMode || (vm.originalHabit?.suggestionId == nil) {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    if vm.isLoadingCategories {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Loading categories...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, Spacing.medium)
                    } else {
                        // Reusable category carousel with cogwheel
                        CategoryCarouselWithManagement(
                            categories: vm.categories,
                            selectedCategory: vm.selectedCategory,
                            onCategoryTap: { category in
                                if let category = category {
                                    vm.selectCategory(category)
                                }
                            },
                            onManageTap: {
                                showingCategoryManagement = true
                            }
                        )
                    }
                }
                .padding(.vertical, Spacing.small)
            } else if let originalHabit = vm.originalHabit, originalHabit.suggestionId != nil {
                // Show read-only category for habits from suggestions
                if vm.isLoadingCategories {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading category...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, Spacing.medium)
                } else {
                    // Try to get category from selectedCategory first, then look it up from categories
                    let category = vm.selectedCategory ?? vm.categories.first { $0.id == originalHabit.categoryId }

                    if let category = category {
                        HStack(spacing: Spacing.medium) {
                            Text(category.emoji)
                                .font(.title)

                            Text(category.displayName)
                                .font(.body)
                                .fontWeight(.medium)

                            Spacer()
                        }
                        .padding(.vertical, Spacing.small)
                    }
                }
            }

            // Error state
            if let error = vm.categoriesError {
                Text(String(format: String(localized: "failedLoadCategories"), error.localizedDescription))
                    .font(.caption)
                    .foregroundColor(.red)
            }

            // Category validation feedback (only for non-suggested habits)
            if !vm.isCategoryValid && vm.selectedCategory == nil && !vm.categories.isEmpty && !vm.isLoadingCategories && !(vm.originalHabit?.suggestionId != nil) {
                Text(Strings.Validation.categoryRequired)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
    }
}
