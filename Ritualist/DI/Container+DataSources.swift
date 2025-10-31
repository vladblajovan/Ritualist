import Foundation
import FactoryKit
import RitualistCore

// MARK: - Data Sources Container Extensions

extension Container {
    
    // MARK: - Persistence Container
    var persistenceContainer: Factory<RitualistCore.PersistenceContainer> {
        self { 
            do {
                return try RitualistCore.PersistenceContainer()
            } catch {
                print("[PERSISTENCE-ERROR] Failed to initialize persistence container: \(error)")
                print("[PERSISTENCE-ERROR] App group: group.com.vladblajovan.Ritualist")
                print("[PERSISTENCE-ERROR] This will cause onboarding to show every time and data to not persist")
                fatalError("Persistence container is required for app functionality: \(error)")
            }
        }
        .singleton
    }
    
    // MARK: - Local Data Sources
    
    var habitDataSource: Factory<HabitLocalDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
            return RitualistCore.HabitLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
            return RitualistCore.LogLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var profileDataSource: Factory<ProfileLocalDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
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
            let container = self.persistenceContainer().container
            return RitualistCore.OnboardingLocalDataSource(modelContainer: container)
        }
        .singleton
    }
    
    var categoryDataSource: Factory<CategoryLocalDataSourceProtocol> {
        self { 
            let container = self.persistenceContainer().container
            return RitualistCore.CategoryLocalDataSource(modelContainer: container)
        }
        .singleton
    }
}