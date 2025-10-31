import SwiftUI
import RitualistCore
import FactoryKit

/// A reusable wrapper around CategoryManagementView for sheet presentation
/// This component can be used by any view that wants to present Category Management
public struct CategoryManagementSheet: View {
    @Injected(\.categoryManagementViewModel) private var viewModel

    let onDismiss: () async -> Void

    /// Initialize the reusable Category Management sheet
    /// - Parameter onDismiss: Callback executed when sheet is dismissed (for data refresh)
    public init(onDismiss: @escaping () async -> Void = {}) {
        self.onDismiss = onDismiss
    }

    public var body: some View {
        CategoryManagementView(vm: viewModel)
            .onDisappear {
                Task {
                    await onDismiss()
                }
            }
    }
}

/// Extension providing convenient sheet presentation modifiers
public extension View {
    /// Present the Category Management as a sheet with integrated presentation logic
    /// - Parameters:
    ///   - isPresented: Binding to control sheet presentation
    ///   - onDataRefreshNeeded: Callback triggered when data should be refreshed
    func categoryManagementSheet(
        isPresented: Binding<Bool>,
        onDataRefreshNeeded: @escaping () async -> Void = {}
    ) -> some View {
        self.modifier(
            CategoryManagementSheetModifier(
                isPresented: isPresented,
                onDataRefreshNeeded: onDataRefreshNeeded
            )
        )
    }
}

/// ViewModifier for presenting the Category Management sheet
private struct CategoryManagementSheetModifier: ViewModifier {
    @Binding var isPresented: Bool

    let onDataRefreshNeeded: () async -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                CategoryManagementSheet(onDismiss: onDataRefreshNeeded)
            }
    }
}

/// Usage example:
/// ```swift
/// .categoryManagementSheet(
///     isPresented: $showingCategoryManagement,
///     onDataRefreshNeeded: { await vm.load() }
/// )
/// ```