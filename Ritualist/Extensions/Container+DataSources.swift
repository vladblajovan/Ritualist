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
        self { HabitLocalDataSource(context: self.persistenceContainer()?.context) }
            .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { LogLocalDataSource(context: self.persistenceContainer()?.context) }
            .singleton
    }
    
    var profileDataSource: Factory<ProfileLocalDataSourceProtocol> {
        self { ProfileLocalDataSource(context: self.persistenceContainer()?.context) }
            .singleton
    }
    
    var tipDataSource: Factory<TipLocalDataSourceProtocol> {
        self { TipStaticDataSource() }
            .singleton
    }
    
    var onboardingDataSource: Factory<OnboardingLocalDataSourceProtocol> {
        self { OnboardingLocalDataSource(context: self.persistenceContainer()?.context) }
            .singleton
    }
    
    var categoryDataSource: Factory<CategoryLocalDataSourceProtocol> {
        self { PersistenceCategoryDataSource(context: self.persistenceContainer()?.context) }
            .singleton
    }
}