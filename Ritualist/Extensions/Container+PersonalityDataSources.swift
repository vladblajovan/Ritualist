import Foundation
import FactoryKit

// MARK: - Personality Analysis Data Sources Container Extensions

extension Container {
    
    // MARK: - Personality Data Sources
    
    var personalityAnalysisDataSource: Factory<PersonalityAnalysisDataSource> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for PersonalityAnalysisDataSource")
            }
            return PersonalityAnalysisDataSourceActor(modelContainer: container)
        }
        .singleton
    }
}