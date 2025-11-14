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
    
    // MARK: - Personality Analysis Preferences Use Cases
    
    var getAnalysisPreferencesUseCase: Factory<GetAnalysisPreferencesUseCase> {
        self { DefaultGetAnalysisPreferencesUseCase(repository: self.personalityAnalysisRepository()) }
    }
    
    var saveAnalysisPreferencesUseCase: Factory<SaveAnalysisPreferencesUseCase> {
        self { DefaultSaveAnalysisPreferencesUseCase(repository: self.personalityAnalysisRepository()) }
    }
    
    var deletePersonalityDataUseCase: Factory<DeletePersonalityDataUseCase> {
        self { DefaultDeletePersonalityDataUseCase(repository: self.personalityAnalysisRepository()) }
    }
    
    // MARK: - Personality Analysis Scheduler Use Cases
    
    var startAnalysisSchedulingUseCase: Factory<StartAnalysisSchedulingUseCase> {
        self { DefaultStartAnalysisSchedulingUseCase(scheduler: self.personalityAnalysisScheduler()) }
    }
    
    var updateAnalysisSchedulingUseCase: Factory<UpdateAnalysisSchedulingUseCase> {
        self { DefaultUpdateAnalysisSchedulingUseCase(scheduler: self.personalityAnalysisScheduler()) }
    }
    
    var getNextScheduledAnalysisUseCase: Factory<GetNextScheduledAnalysisUseCase> {
        self { DefaultGetNextScheduledAnalysisUseCase(scheduler: self.personalityAnalysisScheduler()) }
    }
    
    var triggerAnalysisCheckUseCase: Factory<TriggerAnalysisCheckUseCase> {
        self { DefaultTriggerAnalysisCheckUseCase(scheduler: self.personalityAnalysisScheduler()) }
    }
    
    var forceManualAnalysisUseCase: Factory<ForceManualAnalysisUseCase> {
        self { DefaultForceManualAnalysisUseCase(scheduler: self.personalityAnalysisScheduler()) }
    }

    // MARK: - Personality Analysis Data Use Cases

    var getHabitAnalysisInputUseCase: Factory<GetHabitAnalysisInputUseCase> {
        self {
            DefaultGetHabitAnalysisInputUseCase(
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                getBatchLogs: self.getBatchLogs(),
                completionCalculator: self.scheduleAwareCompletionCalculator(),
                getSelectedSuggestions: self.getSelectedHabitSuggestionsUseCase(),
                calculateTrackingDays: self.calculateConsecutiveTrackingDaysService()
            )
        }
    }

    var getSelectedHabitSuggestionsUseCase: Factory<GetSelectedHabitSuggestionsUseCase> {
        self {
            DefaultGetSelectedHabitSuggestionsUseCase(suggestionsService: self.habitSuggestionsService())
        }
    }

    var estimateDaysToEligibilityUseCase: Factory<EstimateDaysToEligibilityUseCase> {
        self { DefaultEstimateDaysToEligibilityUseCase() }
    }
}