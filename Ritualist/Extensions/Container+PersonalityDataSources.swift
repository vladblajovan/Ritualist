import Foundation
import FactoryKit

// MARK: - Personality Analysis Data Sources Container Extensions

extension Container {
    
    // MARK: - Personality Data Sources
    
    var personalityAnalysisDataSource: Factory<PersonalityAnalysisDataSource> {
        self { 
            guard let context = self.swiftDataStack()?.context else {
                fatalError("SwiftData context not available")
            }
            return SwiftDataPersonalityAnalysisDataSource(modelContext: context)
        }
        .singleton
    }
}