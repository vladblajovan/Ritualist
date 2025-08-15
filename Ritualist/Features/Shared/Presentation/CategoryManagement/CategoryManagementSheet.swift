import SwiftUI
import RitualistCore
import FactoryKit

/// A reusable wrapper around CategoryManagementView that integrates with CategoryManagementPresentationService
/// This component can be used by any view that wants to present Category Management
public struct CategoryManagementSheet: View {
    @Injected(\.categoryManagementPresentationService) private var presentationService
    
    /// Initialize the reusable Category Management sheet
    public init() {}
    
    public var body: some View {
        CategoryManagementView(vm: presentationService.categoryManagementViewModel)
            .onDisappear {
                presentationService.handleCategoryManagementDismissal()
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

/// ViewModifier that integrates presentation service with sheet presentation
private struct CategoryManagementSheetModifier: ViewModifier {
    @Injected(\.categoryManagementPresentationService) private var presentationService
    @Binding var isPresented: Bool
    
    let onDataRefreshNeeded: () async -> Void
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented) {
                CategoryManagementSheet()
            }
            .onAppear {
                // Set up data refresh callback
                presentationService.onDataRefreshNeeded = onDataRefreshNeeded
            }
    }
}

/// Usage example for integrating with CategoryManagementPresentationService:
/// ```swift
/// .categoryManagementSheet(
///     isPresented: $presentationService.showingCategoryManagement,
///     onDataRefreshNeeded: { await vm.load() }
/// )
/// ```