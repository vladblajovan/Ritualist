import Foundation
import FactoryKit

// MARK: - Data Sources Container Extensions

extension Container {
    
    // MARK: - Persistence Container
    var persistenceContainer: Factory<PersistenceContainer?> {
        self { 
            do {
                return try PersistenceContainer()
            } catch {
                return nil
            }
        }
        .singleton
    }
    
    // MARK: - Local Data Sources
    
    var habitDataSource: Factory<HabitLocalDataSourceProtocol> {
        self { HabitLocalDataSource(context: self.persistenceContainer()?.createBackgroundContext()) }
            .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { LogLocalDataSource(context: self.persistenceContainer()?.createBackgroundContext()) }
            .singleton
    }
    
    var profileDataSource: Factory<ProfileLocalDataSourceProtocol> {
        self { ProfileLocalDataSource(context: self.persistenceContainer()?.createBackgroundContext()) }
            .singleton
    }
    
    var tipDataSource: Factory<TipLocalDataSourceProtocol> {
        self { TipStaticDataSource() }
            .singleton
    }
    
    var onboardingDataSource: Factory<OnboardingLocalDataSourceProtocol> {
        self { OnboardingLocalDataSource(context: self.persistenceContainer()?.createBackgroundContext()) }
            .singleton
    }
    
    var categoryDataSource: Factory<CategoryLocalDataSourceProtocol> {
        self { PersistenceCategoryDataSource(context: self.persistenceContainer()?.createBackgroundContext()) }
            .singleton
    }
}