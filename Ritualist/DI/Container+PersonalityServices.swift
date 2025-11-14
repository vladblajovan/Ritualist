import Foundation
import FactoryKit
import RitualistCore

// MARK: - Personality Analysis Services Container Extensions

extension Container {
    
    // MARK: - Core Personality Services
    
    var personalityAnalysisService: Factory<PersonalityAnalysisService> {
        self { 
            DefaultPersonalityAnalysisService(
                repository: self.personalityAnalysisRepository(),
                errorHandler: self.errorHandler()
            )
        }
        .singleton
    }
    
    var dataThresholdValidator: Factory<DataThresholdValidator> {
        self { DefaultDataThresholdValidator(getHabitAnalysisInput: self.getHabitAnalysisInputUseCase()) }
            .singleton
    }
    
    var personalityAnalysisScheduler: Factory<PersonalityAnalysisSchedulerProtocol> {
        self {
            PersonalityAnalysisScheduler(
                personalityRepository: self.personalityAnalysisRepository(),
                analyzePersonalityUseCase: self.analyzePersonalityUseCase(),
                validateAnalysisDataUseCase: self.validateAnalysisDataUseCase(),
                notificationService: self.notificationService(),
                errorHandler: self.errorHandler()
            )
        }
        .singleton
    }

    var calculateConsecutiveTrackingDaysService: Factory<CalculateConsecutiveTrackingDaysService> {
        self { DefaultCalculateConsecutiveTrackingDaysService() }
            .singleton
    }
}