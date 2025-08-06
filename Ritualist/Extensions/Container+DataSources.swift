import Foundation
import FactoryKit

// MARK: - Data Sources Container Extensions

extension Container {
    
    // MARK: - SwiftData Context
    var swiftDataStack: Factory<SwiftDataStack?> {
        self { try? SwiftDataStack() }
            .singleton
    }
    
    // MARK: - Local Data Sources
    
    var habitDataSource: Factory<HabitLocalDataSource> {
        self { HabitLocalDataSource(context: self.swiftDataStack()?.context) }
            .singleton
    }
    
    var logDataSource: Factory<LogLocalDataSource> {
        self { LogLocalDataSource(context: self.swiftDataStack()?.context) }
            .singleton
    }
    
    var profileDataSource: Factory<ProfileLocalDataSource> {
        self { ProfileLocalDataSource(context: self.swiftDataStack()?.context) }
            .singleton
    }
    
    var tipDataSource: Factory<TipLocalDataSource> {
        self { TipLocalDataSource() }
            .singleton
    }
    
    var onboardingDataSource: Factory<OnboardingLocalDataSource> {
        self { OnboardingLocalDataSource(context: self.swiftDataStack()?.context) }
            .singleton
    }
    
    var categoryDataSource: Factory<SwiftDataCategoryLocalDataSource> {
        self { SwiftDataCategoryLocalDataSource(context: self.swiftDataStack()?.context) }
            .singleton
    }
}