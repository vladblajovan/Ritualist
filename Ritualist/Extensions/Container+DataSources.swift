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
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for HabitLocalDataSource")
            }
            return HabitLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for LogLocalDataSource")
            }
            return LogLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var profileDataSource: Factory<ProfileLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for ProfileLocalDataSource")
            }
            return ProfileLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var tipDataSource: Factory<TipLocalDataSourceProtocol> {
        self { TipStaticDataSource() }
            .singleton
    }
    
    var onboardingDataSource: Factory<OnboardingLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for OnboardingLocalDataSource")
            }
            return OnboardingLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var categoryDataSource: Factory<CategoryLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for CategoryLocalDataSource")
            }
            return CategoryLocalDataSource(modelContainer: container)
        }
        .singleton
    }
}