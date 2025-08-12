import Foundation
import SwiftData

/// Core persistence container for Ritualist app
/// Manages SwiftData ModelContainer with background context support
public final class PersistenceContainer {
    public let container: ModelContainer
    public let mainContext: ModelContext      // For main thread operations
    
    /// Initialize persistence container with direct SwiftData models
    /// 
    /// Architecture:
    /// - Uses direct model classes (SDHabit, SDHabitLog, etc.)
    /// - Simple ModelContainer setup without versioning complexity
    /// - Supports both main thread and background context creation for threading safety
    public init() throws {
        
        // Use simple direct models without versioning
        container = try ModelContainer(
            for: SDHabit.self, SDHabitLog.self, SDUserProfile.self, 
                SDCategory.self, SDOnboardingState.self, SDPersonalityProfile.self
        )
        
        // Create main context for main thread operations
        mainContext = ModelContext(container)
    }
    
    /// Create a new background context for background operations
    /// Each background context is isolated and thread-safe
    public func createBackgroundContext() -> ModelContext {
        return ModelContext(container)
    }
}
