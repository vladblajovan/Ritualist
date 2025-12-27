import SwiftUI
import FactoryKit
import RitualistCore

public struct CategoryManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var vm: CategoryManagementViewModel
    @Injected(\.debugLogger) private var logger
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
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Auto-refresh when iCloud syncs new data from another device
                Task {
                    logger.log(
                        "☁️ iCloud sync detected - refreshing Categories",
                        level: .info,
                        category: .system
                    )
                    await vm.load()
                }
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
        CategoryBatchToolbar(
            selectedCategoryIds: selectedCategoryIds,
            categories: vm.categories,
            onActivate: { await activateSelectedCategories() },
            onDeactivate: {
                categoriesToDeactivate = selectedCategoryIds
                showingDeactivateConfirmation = true
            },
            onDelete: {
                categoriesToDelete = selectedCategoryIds
                showingDeleteConfirmation = true
            }
        )
    }

    private var deleteConfirmationMessage: String {
        let categoriesToCount = categoriesToDelete.isEmpty ? selectedCategoryIds : categoriesToDelete
        let customCategories = vm.categories.filter { categoriesToCount.contains($0.id) && !$0.isPredefined }

        if customCategories.count == 1 {
            return "Are you sure you want to delete \"\(customCategories.first!.displayName)\"? This action cannot be undone."
        } else {
            return "Are you sure you want to delete \(customCategories.count) categories? This action cannot be undone."
        }
    }

    private var deactivateConfirmationMessage: String {
        let categoriesToCount = categoriesToDeactivate.isEmpty ? selectedCategoryIds : categoriesToDeactivate
        let customCategories = vm.categories.filter { categoriesToCount.contains($0.id) && !$0.isPredefined && $0.isActive }

        if customCategories.count == 1 {
            return "Are you sure you want to deactivate \"\(customCategories.first!.displayName)\"? It will be hidden from habit creation but existing habits will remain."
        } else {
            return "Are you sure you want to deactivate \(customCategories.count) categories? They will be hidden from habit creation but existing habits will remain."
        }
    }

    private func activateSelectedCategories() async {
        for categoryId in selectedCategoryIds {
            if let category = vm.categories.first(where: { $0.id == categoryId }) {
                await vm.updateCategory(category.withActiveStatus(true))
            }
        }
        selectedCategoryIds.removeAll()
    }

    private func deactivateSelectedCategories() async {
        for categoryId in categoriesToDeactivate {
            if let category = vm.categories.first(where: { $0.id == categoryId }) {
                await vm.updateCategory(category.withActiveStatus(false))
            }
        }
        selectedCategoryIds.removeAll()
    }

    private func deleteSelectedCategories() async {
        let customCategories = vm.categories.filter { categoriesToDelete.contains($0.id) && !$0.isPredefined }
        for category in customCategories {
            await vm.deleteCategory(category.id)
        }
        selectedCategoryIds.removeAll()
    }
}

// MARK: - Category Batch Toolbar

private struct CategoryBatchToolbar: View {
    let selectedCategoryIds: Set<String>
    let categories: [HabitCategory]
    let onActivate: () async -> Void
    let onDeactivate: () -> Void
    let onDelete: () -> Void

    private var hasActiveSelected: Bool {
        categories.filter { selectedCategoryIds.contains($0.id) }.contains { $0.isActive }
    }

    private var hasInactiveSelected: Bool {
        categories.filter { selectedCategoryIds.contains($0.id) }.contains { !$0.isActive }
    }

    private var selectedArePredefined: Bool {
        categories.filter { selectedCategoryIds.contains($0.id) }.contains { $0.isPredefined }
    }

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            HStack {
                Text("\(selectedCategoryIds.count) selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: Spacing.large) {
                    if hasInactiveSelected {
                        toolbarButton(icon: "play.circle", label: "Activate", color: .green) {
                            Task { await onActivate() }
                        }
                    }

                    if hasActiveSelected {
                        toolbarButton(icon: "pause.circle", label: "Deactivate", color: .primary, action: onDeactivate)
                    }

                    toolbarButton(icon: "trash", label: "Delete", color: .red, action: onDelete)
                        .disabled(selectedArePredefined)
                }
            }
            .padding(.horizontal, Spacing.large)
            .padding(.vertical, Spacing.medium)
            .background(.regularMaterial)
        }
    }

    private func toolbarButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon).font(.title2)
                Text(label).font(.caption2)
            }
        }
        .foregroundColor(color)
    }
}

#Preview {
    let vm = Container.shared.categoryManagementViewModel()
    CategoryManagementView(vm: vm)
}
