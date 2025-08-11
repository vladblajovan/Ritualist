import Foundation
import FactoryKit

// MARK: - Feature Gating Use Cases Container Extensions

extension Container {
    
    // MARK: - Feature Gating Operations
    
    var checkHabitCreationLimit: Factory<CheckHabitCreationLimit> {
        self { CheckHabitCreationLimit(featureGatingService: self.featureGatingService()) }
    }
}