import Foundation
import FactoryKit
import RitualistCore

// MARK: - Repositories Container Extensions

extension Container {
    
    // MARK: - Repository Implementations
    
    var habitRepository: Factory<HabitRepository> {
        self { HabitRepositoryImpl(local: self.habitDataSource(), context: self.persistenceContainer()?.mainContext) }
            .singleton
    }
    
    var logRepository: Factory<LogRepository> {
        self { LogRepositoryImpl(local: self.logDataSource(), context: self.persistenceContainer()?.mainContext) }
            .singleton
    }
    
    var profileRepository: Factory<ProfileRepository> {
        self { ProfileRepositoryImpl(local: self.profileDataSource()) }
            .singleton
    }
    
    var tipRepository: Factory<TipRepository> {
        self { TipRepositoryImpl(local: self.tipDataSource()) }
            .singleton
    }
    
    var onboardingRepository: Factory<OnboardingRepository> {
        self { OnboardingRepositoryImpl(local: self.onboardingDataSource()) }
            .singleton
    }
    
    var categoryRepository: Factory<CategoryRepository> {
        self { CategoryRepositoryImpl(local: self.categoryDataSource()) }
            .singleton
    }
}