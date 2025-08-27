import Foundation
import FactoryKit
import RitualistCore

// MARK: - Personality Analysis Use Cases Container Extensions

extension Container {
    
    // MARK: - Personality Analysis Use Cases
    
    var analyzePersonalityUseCase: Factory<AnalyzePersonalityUseCase> {
        self { 
            DefaultAnalyzePersonalityUseCase(
                personalityService: self.personalityAnalysisService(),
                thresholdValidator: self.dataThresholdValidator(),
                repository: self.personalityAnalysisRepository()
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
                analyzePersonalityUseCase: self.analyzePersonalityUseCase()
            ) 
        }
    }
    
    var getPersonalityInsightsUseCase: Factory<GetPersonalityInsightsUseCase> {
        self { DefaultGetPersonalityInsightsUseCase() }
    }
    
    var isPersonalityAnalysisEnabledUseCase: Factory<IsPersonalityAnalysisEnabledUseCase> {
        self { DefaultIsPersonalityAnalysisEnabledUseCase(repository: self.personalityAnalysisRepository()) }
    }
}