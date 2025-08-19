import Foundation
import SwiftData

/// Core persistence container for Ritualist app
/// Manages SwiftData ModelContainer with app group support for widget access
public final class PersistenceContainer {
    public let container: ModelContainer
    public let context: ModelContext
    
    /// App Group identifier for shared container access
    private static let appGroupIdentifier = "group.com.vladblajovan.Ritualist"
    
    /// Initialize persistence container with app group support
    /// Enables data sharing between main app and widget extension
    public init() throws {
        // Get shared container URL for app group
        let sharedContainerURL = PersistenceContainer.getSharedContainerURL()
        
        // Configure ModelContainer with shared URL
        let configuration = ModelConfiguration(
            url: sharedContainerURL.appendingPathComponent("Ritualist.sqlite")
        )
        
        // Use direct models without versioning, configured for app group sharing
        container = try ModelContainer(
            for: HabitModel.self, HabitLogModel.self, UserProfileModel.self, 
                HabitCategoryModel.self, OnboardingStateModel.self, PersonalityAnalysisModel.self,
            configurations: configuration
        )
        
        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
    }
    
    /// Get the shared container URL for app group
    /// Returns the shared directory where both app and widget can access data
    private static func getSharedContainerURL() -> URL {
        guard let sharedContainerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("Failed to get shared container URL for app group: \(appGroupIdentifier)")
        }
        return sharedContainerURL
    }
}
