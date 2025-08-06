import Foundation
import FactoryKit

// MARK: - Personality Analysis Services Container Extensions

extension Container {
    
    // MARK: - Core Personality Services
    
    var personalityAnalysisService: Factory<PersonalityAnalysisService> {
        self { DefaultPersonalityAnalysisService(repository: self.personalityAnalysisRepository()) }
            .singleton
    }
    
    var dataThresholdValidator: Factory<DataThresholdValidator> {
        self { DefaultDataThresholdValidator(repository: self.personalityAnalysisRepository()) }
            .singleton
    }
}