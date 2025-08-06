import Foundation
import FactoryKit

// MARK: - Personality Analysis Use Cases Container Extensions

extension Container {
    
    // MARK: - Personality Analysis Use Cases
    
    var analyzePersonalityUseCase: Factory<AnalyzePersonalityUseCase> {
        self { 
            DefaultAnalyzePersonalityUseCase(
                personalityService: self.personalityAnalysisService(),
                thresholdValidator: self.dataThresholdValidator()
            ) 
        }
    }
    
    var getPersonalityProfileUseCase: Factory<GetPersonalityProfileUseCase> {
        self { DefaultGetPersonalityProfileUseCase(repository: self.personalityAnalysisRepository()) }
    }
    
    var validateAnalysisDataUseCase: Factory<ValidateAnalysisDataUseCase> {
        self { 
            DefaultValidateAnalysisDataUseCase(
                repository: self.personalityAnalysisRepository(),
                thresholdValidator: self.dataThresholdValidator()
            ) 
        }
    }
    
    var updatePersonalityAnalysisUseCase: Factory<UpdatePersonalityAnalysisUseCase> {
        self { 
            DefaultUpdatePersonalityAnalysisUseCase(
                repository: self.personalityAnalysisRepository(),
                analysisService: self.personalityAnalysisService()
            ) 
        }
    }
    
    var getPersonalityInsightsUseCase: Factory<GetPersonalityInsightsUseCase> {
        self { DefaultGetPersonalityInsightsUseCase() }
    }
}