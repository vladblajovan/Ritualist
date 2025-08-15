import Foundation
import Observation
import FactoryKit
import RitualistCore

@MainActor @Observable
public final class CategoryManagementPresentationService {
    
    // MARK: - Factory Injected Dependencies
    @ObservationIgnored @Injected(\.userActionTracker) var userActionTracker
    @ObservationIgnored @Injected(\.categoryManagementViewModel) var categoryManagementViewModelInjected
    
    // MARK: - Navigation State
    public var showingCategoryManagement = false
    
    // MARK: - ViewModel Access
    public var categoryManagementViewModel: CategoryManagementViewModel {
        categoryManagementViewModelInjected
    }
    
    // MARK: - Callbacks
    /// Callback executed when data needs to be refreshed (e.g., after category changes)
    public var onDataRefreshNeeded: (() async -> Void)?
    
    // MARK: - Public Interface
    
    /// Handle category management button tap
    public func handleCategoryManagementTap() {
        userActionTracker.track(.categoryManagementOpened)
        showingCategoryManagement = true
    }
    
    /// Handle when category management sheet is dismissed - refresh data
    public func handleCategoryManagementDismissal() {
        Task {
            await onDataRefreshNeeded?()
        }
    }
    
    // MARK: - Initialization
    public init() {}
}