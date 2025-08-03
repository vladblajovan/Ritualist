import SwiftUI

public struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CategoryManagementViewModel
    @State private var showingAddCategory = false
    @State private var selectedCategoryIds: Set<String> = []
    @Environment(\.editMode) private var editMode
    
    public init(vm: CategoryManagementViewModel) {
        self.vm = vm
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Group {
                    if vm.isLoading {
                        ProgressView("Loading categories...")
                    } else if let error = vm.error {
                        ErrorView(
                            title: "Failed to Load Categories",
                            message: error.localizedDescription
                        ) {
                            await vm.load()
                        }
                    } else {
                        categoryList
                    }
                }
                
                // Bottom toolbar for batch actions when in edit mode
                if !selectedCategoryIds.isEmpty {
                    bottomToolbar
                }
            }
            .navigationTitle("Manage Categories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button("Add") {
                            showingAddCategory = true
                        }
                        .disabled(vm.isLoading)
                        
                        EditButton()
                            .disabled(vm.customCategories.isEmpty)
                    }
                }
            }
            .onChange(of: editMode?.wrappedValue.isEditing) { _, isEditing in
                if isEditing == false {
                    selectedCategoryIds.removeAll()
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                AddCustomCategorySheet { name, emoji in
                    await vm.createCustomCategory(name: name, emoji: emoji)
                }
            }
            .task {
                await vm.load()
            }
        }
    }
    
    private var categoryList: some View {
        List(selection: $selectedCategoryIds) {
            ForEach(vm.categories, id: \.id) { category in
                CategoryRowView(category: category)
                    .deleteDisabled(category.isPredefined)
                    .tag(category.id)
            }
            .onDelete(perform: deleteCategories)
            .onMove(perform: moveCategories)
        }
        .listStyle(.insetGrouped)
    }
    
    private func deleteCategories(offsets: IndexSet) {
        Task {
            await vm.deleteCategories(at: offsets)
        }
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        Task {
            await vm.moveCategories(from: source, to: destination)
        }
    }
    
    private var bottomToolbar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack {
                Text("\(selectedCategoryIds.count) selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                HStack(spacing: Spacing.large) {
                    // Activate button (only show if inactive categories are selected)
                    if hasInactiveSelectedCategories {
                        Button {
                            Task {
                                await activateSelectedCategories()
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "play.circle")
                                    .font(.title2)
                                Text("Activate")
                                    .font(.caption2)
                            }
                        }
                        .foregroundColor(.green)
                        .disabled(selectedCategoriesArePredefined)
                    }
                    
                    // Deactivate button (only show if active categories are selected)
                    if hasActiveSelectedCategories {
                        Button {
                            Task {
                                await deactivateSelectedCategories()
                            }
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "pause.circle")
                                    .font(.title2)
                                Text("Deactivate")
                                    .font(.caption2)
                            }
                        }
                        .disabled(selectedCategoriesArePredefined)
                    }
                    
                    // Delete button
                    Button {
                        Task {
                            await deleteSelectedCategories()
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "trash")
                                .font(.title2)
                            Text("Delete")
                                .font(.caption2)
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(selectedCategoriesArePredefined)
                }
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .background(.regularMaterial)
        }
    }
    
    private var selectedCategoriesArePredefined: Bool {
        let selectedCategories = vm.categories.filter { selectedCategoryIds.contains($0.id) }
        return selectedCategories.contains { $0.isPredefined }
    }
    
    private var hasActiveSelectedCategories: Bool {
        let selectedCategories = vm.categories.filter { selectedCategoryIds.contains($0.id) }
        return selectedCategories.contains { $0.isActive }
    }
    
    private var hasInactiveSelectedCategories: Bool {
        let selectedCategories = vm.categories.filter { selectedCategoryIds.contains($0.id) }
        return selectedCategories.contains { !$0.isActive }
    }
    
    private func activateSelectedCategories() async {
        for categoryId in selectedCategoryIds {
            if let category = vm.categories.first(where: { $0.id == categoryId }), !category.isPredefined {
                let updatedCategory = Category(
                    id: category.id,
                    name: category.name,
                    displayName: category.displayName,
                    emoji: category.emoji,
                    order: category.order,
                    isActive: true,
                    isPredefined: category.isPredefined
                )
                await vm.updateCategory(updatedCategory)
            }
        }
        selectedCategoryIds.removeAll()
    }
    
    private func deactivateSelectedCategories() async {
        for categoryId in selectedCategoryIds {
            if let category = vm.categories.first(where: { $0.id == categoryId }), !category.isPredefined {
                let updatedCategory = Category(
                    id: category.id,
                    name: category.name,
                    displayName: category.displayName,
                    emoji: category.emoji,
                    order: category.order,
                    isActive: false,
                    isPredefined: category.isPredefined
                )
                await vm.updateCategory(updatedCategory)
            }
        }
        selectedCategoryIds.removeAll()
    }
    
    private func deleteSelectedCategories() async {
        let selectedCategories = vm.categories.filter { selectedCategoryIds.contains($0.id) }
        let customCategories = selectedCategories.filter { !$0.isPredefined }
        
        for category in customCategories {
            await vm.deleteCategory(category.id)
        }
        selectedCategoryIds.removeAll()
    }
}

private struct CategoryRowView: View {
    let category: Category
    
    var body: some View {
        HStack(spacing: Spacing.medium) {
            Text(category.emoji)
                .font(.title2)
                .frame(width: 30)
                .opacity(category.isActive ? 1.0 : 0.5)
            
            VStack(alignment: .leading, spacing: Spacing.xxsmall) {
                Text(category.displayName)
                    .font(.headline)
                    .foregroundColor(category.isPredefined ? .secondary : (category.isActive ? .primary : .secondary))
                    .strikethrough(!category.isActive)
                
                HStack(spacing: Spacing.small) {
                    if category.isPredefined {
                        Text("Predefined")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !category.isActive {
                        Text("Inactive")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
        .opacity(category.isActive ? 1.0 : 0.7)
    }
}


#Preview {
    let container = DefaultAppContainer.createMinimal()
    let factory = SettingsFactory(container: container)
    return CategoryManagementView(vm: factory.makeCategoryManagementViewModel())
        .environment(\.appContainer, container)
}