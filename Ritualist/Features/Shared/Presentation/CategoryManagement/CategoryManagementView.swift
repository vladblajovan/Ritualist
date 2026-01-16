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
                        ProgressView(Strings.CategoryManagement.loadingCategories)
                    } else if let error = vm.error {
                        ErrorView(
                            title: Strings.CategoryManagement.failedToLoad,
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
            .navigationTitle(Strings.CategoryManagement.manageCategories)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(Strings.Button.done) {
                        dismiss()
                    }
                }

                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !vm.customCategories.isEmpty {
                        EditButton()
                    }

                    Button(Strings.Common.add) {
                        HapticFeedbackService.shared.trigger(.light)
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
                Strings.CategoryManagement.deleteCategories,
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Common.delete, role: .destructive) {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await deleteSelectedCategories()
                    }
                }
                Button(Strings.Common.cancel, role: .cancel) { }
            } message: {
                Text(deleteConfirmationMessage)
            }
            .confirmationDialog(
                Strings.CategoryManagement.deactivateCategories,
                isPresented: $showingDeactivateConfirmation,
                titleVisibility: .visible
            ) {
                Button(Strings.Button.deactivate, role: .destructive) {
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        await deactivateSelectedCategories()
                    }
                }
                Button(Strings.Common.cancel, role: .cancel) { }
            } message: {
                Text(deactivateConfirmationMessage)
            }
            .task {
                await vm.load()
            }
            .onReceive(NotificationCenter.default.publisher(for: .iCloudDidSyncRemoteChanges)) { _ in
                // Auto-refresh when iCloud syncs new data from another device
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
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
                                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                                    Task { @MainActor in
                                        await vm.toggleActiveStatus(id: category.id)
                                    }
                                }
                            } label: {
                                Label(
                                    category.isActive ? Strings.Button.deactivate : Strings.Button.activate,
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
                                Label(Strings.Common.delete, systemImage: "trash")
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
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            await vm.deleteCategories(at: offsets)
        }
    }

    private func moveCategories(from source: IndexSet, to destination: Int) {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
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
            return Strings.CategoryManagement.deleteConfirmSingle(customCategories.first!.displayName)
        } else {
            return Strings.CategoryManagement.deleteConfirmMultiple(customCategories.count)
        }
    }

    private var deactivateConfirmationMessage: String {
        let categoriesToCount = categoriesToDeactivate.isEmpty ? selectedCategoryIds : categoriesToDeactivate
        let customCategories = vm.categories.filter { categoriesToCount.contains($0.id) && !$0.isPredefined && $0.isActive }

        if customCategories.count == 1 {
            return Strings.CategoryManagement.deactivateConfirmSingle(customCategories.first!.displayName)
        } else {
            return Strings.CategoryManagement.deactivateConfirmMultiple(customCategories.count)
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
                Text(Strings.CategoryManagement.selectedCount(selectedCategoryIds.count))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: Spacing.large) {
                    if hasInactiveSelected {
                        toolbarButton(icon: "play.circle", label: Strings.Button.activate, color: .green) {
                            Task { await onActivate() }
                        }
                    }

                    if hasActiveSelected {
                        toolbarButton(icon: "pause.circle", label: Strings.Button.deactivate, color: .primary, action: onDeactivate)
                    }

                    toolbarButton(icon: "trash", label: Strings.Common.delete, color: .red, action: onDelete)
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
