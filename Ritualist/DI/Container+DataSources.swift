import Foundation
import FactoryKit
import RitualistCore

// MARK: - Data Sources Container Extensions

extension Container {

    // MARK: - Persistence Container
    var persistenceContainer: Factory<RitualistCore.PersistenceContainer> {
        self {
            do {
                // Bridge ALL_FEATURES_ENABLED flag to Swift Package for premium feature gating
                // (habit limits, analytics, etc. - NOT for sync, which is now free)
                #if ALL_FEATURES_ENABLED
                UserDefaults.standard.set(true, forKey: UserDefaultsKeys.allFeaturesEnabledCache)
                #else
                UserDefaults.standard.set(false, forKey: UserDefaultsKeys.allFeaturesEnabledCache)
                #endif

                // Execute pending restore BEFORE creating ModelContainer
                // This avoids SQLite integrity violations from replacing open database files
                let backupManager = RitualistCore.BackupManager()
                try backupManager.executePendingRestoreIfNeeded()

                // iCloud sync is always enabled - it's free for all users
                return try RitualistCore.PersistenceContainer()
            } catch {
                let logger = Container.shared.debugLogger()
                logger.log("Failed to initialize persistence container: \(error)", level: .critical, category: .dataIntegrity)
                logger.log("App group: group.com.vladblajovan.Ritualist", level: .critical, category: .dataIntegrity)
                logger.log("Persistence failure will cause onboarding loop and data loss", level: .critical, category: .dataIntegrity)
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
