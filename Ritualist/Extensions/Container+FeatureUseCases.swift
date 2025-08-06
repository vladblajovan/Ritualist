import Foundation
import FactoryKit

// MARK: - Feature Gating Use Cases Container Extensions

extension Container {
    
    // MARK: - Feature Gating Operations
    
    @MainActor
    var checkHabitCreationLimit: Factory<CheckHabitCreationLimit> {
        self { @MainActor in CheckHabitCreationLimit(featureGatingService: self.featureGatingService()) }
    }
}