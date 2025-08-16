import Foundation
import SwiftData

/// Core persistence container for Ritualist app
/// Manages SwiftData ModelContainer with simple, direct model approach
public final class PersistenceContainer {
    public let container: ModelContainer
    public let context: ModelContext
    
    /// Initialize persistence container with direct SwiftData models
    ///
    public init() throws {
        
        // Use simple direct models without versioning
        container = try ModelContainer(
            for: HabitModel.self, HabitLogModel.self, UserProfileModel.self, 
                HabitCategoryModel.self, OnboardingStateModel.self, PersonalityAnalysisModel.self
        )
        
        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
    }
}
