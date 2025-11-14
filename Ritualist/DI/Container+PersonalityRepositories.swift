import Foundation
import FactoryKit
import RitualistCore

// MARK: - Personality Analysis Repositories Container Extensions

extension Container {
    
    // MARK: - Personality Repositories
    
    var personalityAnalysisRepository: Factory<PersonalityAnalysisRepositoryProtocol> {
        self {
            PersonalityAnalysisRepositoryImpl(
                dataSource: self.personalityAnalysisDataSource(),
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                completionCalculator: self.scheduleAwareCompletionCalculator(),
                getBatchLogs: self.getBatchLogs(),
                getHabitAnalysisInput: self.getHabitAnalysisInputUseCase(),
                thresholdValidator: self.dataThresholdValidator(),
                preferencesDataSource: self.personalityPreferencesDataSource()
            )
        }
        .singleton
    }
}