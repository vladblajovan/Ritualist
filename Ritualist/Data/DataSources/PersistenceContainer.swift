import Foundation
import SwiftData

/// Core persistence container for Ritualist app
/// Manages SwiftData ModelContainer with simple, direct model approach
public final class PersistenceContainer {
    public let container: ModelContainer
    public let context: ModelContext
    
    /// Initialize persistence container with direct SwiftData models
    /// 
    /// Architecture:
    /// - Uses direct model classes (SDHabit, SDHabitLog, etc.)
    /// - Simple ModelContainer setup without versioning complexity
    /// - Single ModelContext instance shared across the app for data consistency
    public init() throws {
        
        // Use simple direct models without versioning
        container = try ModelContainer(
            for: SDHabit.self, SDHabitLog.self, SDUserProfile.self, 
                SDCategory.self, SDOnboardingState.self, SDPersonalityProfile.self
        )
        
        // Create single ModelContext instance to prevent threading issues
        // This context is shared across all repositories for data consistency
        context = ModelContext(container)
    }
}
