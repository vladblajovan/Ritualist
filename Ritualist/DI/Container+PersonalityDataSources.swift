import Foundation
import FactoryKit
import RitualistCore

// MARK: - Personality Analysis Data Sources Container Extensions

extension Container {
    
    // MARK: - Personality Data Sources
    
    var personalityAnalysisDataSource: Factory<PersonalityAnalysisDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for PersonalityAnalysisDataSource")
            }
            return PersonalityAnalysisDataSource(modelContainer: container)
        }
        .singleton
    }
}
