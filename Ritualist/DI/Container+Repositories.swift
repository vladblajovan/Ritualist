import Foundation
import FactoryKit
import RitualistCore

// MARK: - Repositories Container Extensions

extension Container {
    
    // MARK: - Repository Implementations
    
    var habitRepository: Factory<HabitRepository> {
        self { RitualistCore.HabitRepositoryImpl(local: self.habitDataSource()) }
            .singleton
    }
    
    var logRepository: Factory<LogRepository> {
        self { RitualistCore.LogRepositoryImpl(local: self.logDataSource()) }
            .singleton
    }
    
    var profileRepository: Factory<ProfileRepository> {
        self { RitualistCore.ProfileRepositoryImpl(local: self.profileDataSource()) }
            .singleton
    }
    
    var tipRepository: Factory<TipRepository> {
        self { RitualistCore.TipRepositoryImpl(local: self.tipDataSource()) }
            .singleton
    }
    
    var onboardingRepository: Factory<OnboardingRepository> {
        self { RitualistCore.OnboardingRepositoryImpl(local: self.onboardingDataSource()) }
            .singleton
    }
    
    var categoryRepository: Factory<CategoryRepository> {
        self { RitualistCore.CategoryRepositoryImpl(local: self.categoryDataSource()) }
            .singleton
    }
}