import SwiftUI
import FactoryKit
import RitualistCore

public struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CategoryManagementViewModel
    @State private var showingAddCategory = false
    @State private var selectedCategoryIds: Set<String> = []
    @State private var showingDeleteConfirmation = false
    @State private var showingDeactivateConfirmation = false
    @State private var categoriesToDelete: Set<String> = []
    @State private var categoriesToDeactivate: Set<String> = []
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
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !vm.customCategories.isEmpty {
                        EditButton()
                    }
                    
                    Button("Add") {
                        showingAddCategory = true
                    }
                    .disabled(vm.isLoading)
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
            .confirmationDialog(
                "Delete Categories",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteSelectedCategories()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .confirmationDialog(
                "Deactivate Categories",
                isPresented: $showingDeactivateConfirmation,
                titleVisibility: .visible
            ) {
                Button("Deactivate", role: .destructive) {
                    Task {
                        await deactivateSelectedCategories()
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text(deactivateConfirmationMessage)
            }
            .task {
                await vm.load()
            }
        }
    }
    
    private var categoryList: some View {
        List(selection: $selectedCategoryIds) {
            ForEach(vm.categories, id: \.id) { category in
                GenericRowView.categoryRow(category: category)
                    .deleteDisabled(category.isPredefined)
                    .selectionDisabled(category.isPredefined)
                    .tag(category.id)
                    .swipeActions(edge: .leading) {
                        if editMode?.wrappedValue != .active {
                            Button {
                                if category.isActive {
                                    // Show deactivate confirmation for individual category
                                    categoriesToDeactivate = [category.id]
                                    showingDeactivateConfirmation = true
                                } else {
                                    // Activate directly without confirmation
                                    Task {
                                        await vm.toggleActiveStatus(id: category.id)
                                    }
                                }
                            } label: {
                                Label(
                                    category.isActive ? "Deactivate" : "Activate",
                                    systemImage: category.isActive ? "pause.circle" : "play.circle"
                                )
                            }
                            .tint(category.isActive ? .orange : .green)
                        }
                    }
                    .swipeActions(edge: .trailing) {
                        if editMode?.wrappedValue != .active && !category.isPredefined {
                            Button(role: .destructive) {
                                // Show delete confirmation for individual category
                                categoriesToDelete = [category.id]
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
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
                    }
                    
                    // Deactivate button (only show if active categories are selected)
                    if hasActiveSelectedCategories {
                        Button {
                            categoriesToDeactivate = selectedCategoryIds
                            showingDeactivateConfirmation = true
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "pause.circle")
                                    .font(.title2)
                                Text("Deactivate")
                                    .font(.caption2)
                            }
                        }
                    }
                    
                    // Delete button
                    Button {
                        categoriesToDelete = selectedCategoryIds
                        showingDeleteConfirmation = true
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
    
    private var deleteConfirmationMessage: String {
        // Use the live selection for counting, but filter to get actual categories to delete
        let categoriesToCount = categoriesToDelete.isEmpty ? selectedCategoryIds : categoriesToDelete
        let selectedCategories = vm.categories.filter { categoriesToCount.contains($0.id) }
        let customCategories = selectedCategories.filter { !$0.isPredefined }
        
        if customCategories.count == 1 {
            return "Are you sure you want to delete \"\(customCategories.first!.displayName)\"? This action cannot be undone."
        } else {
            return "Are you sure you want to delete \(customCategories.count) categories? This action cannot be undone."
        }
    }
    
    private var deactivateConfirmationMessage: String {
        // Use the live selection for counting, but filter to get actual categories to deactivate
        let categoriesToCount = categoriesToDeactivate.isEmpty ? selectedCategoryIds : categoriesToDeactivate
        let selectedCategories = vm.categories.filter { categoriesToCount.contains($0.id) }
        let customCategories = selectedCategories.filter { !$0.isPredefined && $0.isActive }
        
        if customCategories.count == 1 {
            return "Are you sure you want to deactivate \"\(customCategories.first!.displayName)\"? It will be hidden from habit creation but existing habits will remain."
        } else {
            return "Are you sure you want to deactivate \(customCategories.count) categories? They will be hidden from habit creation but existing habits will remain."
        }
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
            if let category = vm.categories.first(where: { $0.id == categoryId }) {
                let updatedCategory = HabitCategory(
                    id: category.id,
                    name: category.name,
                    displayName: category.displayName,
                    emoji: category.emoji,
                    order: category.order,
                    isActive: true,
                    isPredefined: category.isPredefined,
                    personalityWeights: category.personalityWeights
                )
                await vm.updateCategory(updatedCategory)
            }
        }
        selectedCategoryIds.removeAll()
    }
    
    private func deactivateSelectedCategories() async {
        for categoryId in categoriesToDeactivate {
            if let category = vm.categories.first(where: { $0.id == categoryId }) {
                print("DEBUG: Deactivating category: \(category.displayName)")
                let updatedCategory = HabitCategory(
                    id: category.id,
                    name: category.name,
                    displayName: category.displayName,
                    emoji: category.emoji,
                    order: category.order,
                    isActive: false,
                    isPredefined: category.isPredefined,
                    personalityWeights: category.personalityWeights
                )
                await vm.updateCategory(updatedCategory)
            }
        }
        selectedCategoryIds.removeAll()
    }
    
    private func deleteSelectedCategories() async {
        let selectedCategories = vm.categories.filter { categoriesToDelete.contains($0.id) }
        let customCategories = selectedCategories.filter { !$0.isPredefined }
        
        for category in customCategories {
            print("DEBUG: Deleting category: \(category.displayName)")
            await vm.deleteCategory(category.id)
        }
        selectedCategoryIds.removeAll()
    }
}



#Preview {
    let vm = Container.shared.categoryManagementViewModel()
    CategoryManagementView(vm: vm)
}
