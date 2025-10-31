import Foundation
import FactoryKit
import RitualistCore

// MARK: - Personality Analysis Data Sources Container Extensions

extension Container {
    
    // MARK: - Personality Data Sources
    
    var personalityAnalysisDataSource: Factory<PersonalityAnalysisDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
            return PersonalityAnalysisDataSource(modelContainer: container)
        }
        .singleton
    }
}
