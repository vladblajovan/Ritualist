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
    @State private var showingAddCustomCategory = false
    @State private var showingCategoryManagement = false
    @ObservationIgnored @Injected(\.categoryManagementViewModel) var categoryManagementVM
    
    public var body: some View {
        Section {
            // Show category selection for new habits or editable habits (not from suggestions)
            if !vm.isEditMode || (vm.originalHabit?.suggestionId == nil) {
                CategorySelectionView(
                    selectedCategory: $vm.selectedCategory,
                    categories: vm.categories,
                    isLoading: vm.isLoadingCategories,
                    showAddCustomOption: true,
                    onCategorySelect: { category in
                        vm.selectCategory(category)
                    },
                    onAddCustomCategory: {
                        showingAddCustomCategory = true
                    },
                    onManageCategories: {
                        showingCategoryManagement = true
                    }
                )
                .padding(.vertical, Spacing.small)
            } else if let originalHabit = vm.originalHabit, originalHabit.suggestionId != nil, let selectedCategory = vm.selectedCategory {
                // Show read-only category for habits from suggestions
                HStack(spacing: Spacing.medium) {
                    Text(selectedCategory.emoji)
                        .font(.title)

                    VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                        HStack {
                            Text(selectedCategory.displayName)
                                .font(.body)
                                .fontWeight(.medium)

                            Spacer()

                            Text(String(localized: "fromSuggestion"))
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, Spacing.small)
                                .padding(.vertical, 2)
                                .background(AppColors.systemGray6, in: Capsule())
                        }

                        Text("Category cannot be changed for suggested habits")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, Spacing.small)
            }
            
            // Error state
            if let error = vm.categoriesError {
                Text(String(format: String(localized: "failedLoadCategories"), error.localizedDescription))
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Category validation feedback
            if !vm.isCategoryValid && vm.selectedCategory == nil && !vm.categories.isEmpty && !vm.isLoadingCategories {
                Text(Strings.Validation.categoryRequired)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.leading, 4)
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showingAddCustomCategory) {
            AddCustomCategorySheet { name, emoji in
                await vm.createCustomCategory(name: name, emoji: emoji)
            }
        }
        .onChange(of: showingAddCustomCategory) { _, isShowing in
            if !isShowing {
                // Refresh categories when sheet is dismissed
                Task {
                    await vm.loadCategories()
                }
            }
        }
        .sheet(isPresented: $showingCategoryManagement) {
            categoryManagementSheet
        }
    }
    
    @ViewBuilder
    private var categoryManagementSheet: some View {
        NavigationStack {
            CategoryManagementView(vm: categoryManagementVM)
        }
    }
}
