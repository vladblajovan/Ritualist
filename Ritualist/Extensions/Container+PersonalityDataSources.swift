import Foundation
import FactoryKit

// MARK: - Personality Analysis Data Sources Container Extensions

extension Container {
    
    // MARK: - Personality Data Sources
    
    var personalityAnalysisDataSource: Factory<PersonalityAnalysisDataSource> {
        self { 
            SwiftDataPersonalityAnalysisDataSource(modelContext: self.persistenceContainer()?.createBackgroundContext())
        }
        .singleton
    }
}