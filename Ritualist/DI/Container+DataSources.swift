import Foundation
import FactoryKit
import RitualistCore

// MARK: - Data Sources Container Extensions

extension Container {
    
    // MARK: - Persistence Container
    var persistenceContainer: Factory<RitualistCore.PersistenceContainer?> {
        self { 
            do {
                return try RitualistCore.PersistenceContainer()
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
            return RitualistCore.HabitLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for LogLocalDataSource")
            }
            return RitualistCore.LogLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var profileDataSource: Factory<ProfileLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for ProfileLocalDataSource")
            }
            return RitualistCore.ProfileLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var tipDataSource: Factory<TipLocalDataSourceProtocol> {
        self { RitualistCore.TipStaticDataSource() }
            .singleton
    }
    
    var onboardingDataSource: Factory<OnboardingLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for OnboardingLocalDataSource")
            }
            return RitualistCore.OnboardingLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var categoryDataSource: Factory<CategoryLocalDataSourceProtocol> {
        self { 
            guard let container = self.persistenceContainer()?.container else {
                fatalError("Failed to get ModelContainer for CategoryLocalDataSource")
            }
            return RitualistCore.CategoryLocalDataSource(modelContainer: container)
        }
        .singleton
    }
}