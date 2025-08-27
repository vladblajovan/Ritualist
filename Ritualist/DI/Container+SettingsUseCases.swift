import Foundation
import FactoryKit
import RitualistCore

// MARK: - Settings Use Cases Container Extensions

extension Container {
    
    // MARK: - Profile Operations
    
    var saveProfile: Factory<SaveProfile> {
        self { SaveProfile(repo: self.profileRepository()) }
    }
    
    // MARK: - Notification Operations
    
    var requestNotificationPermission: Factory<RequestNotificationPermission> {
        self { RequestNotificationPermission(notificationService: self.notificationService()) }
    }
    
    var checkNotificationStatus: Factory<CheckNotificationStatus> {
        self { CheckNotificationStatus(notificationService: self.notificationService()) }
    }
    
    // MARK: - App Content Operations
    
    var getCurrentSlogan: Factory<GetCurrentSlogan> {
        self { GetCurrentSlogan(slogansService: self.slogansService()) }
    }
    
    // MARK: - Premium Status Operations
    
    var checkPremiumStatus: Factory<CheckPremiumStatus> {
        self { CheckPremiumStatus(userService: self.userService()) }
    }
    
    var updateUserSubscription: Factory<UpdateUserSubscription> {
        self { UpdateUserSubscription(userService: self.userService()) }
    }
    
    // MARK: - Development Operations
    
    var clearPurchases: Factory<ClearPurchases> {
        self { ClearPurchases(paywallService: self.paywallService()) }
    }
    
    var populateTestData: Factory<PopulateTestData> {
        self { PopulateTestData(testDataPopulationService: self.testDataPopulationService()) }
    }
    
    #if DEBUG
    var getDatabaseStats: Factory<GetDatabaseStats> {
        self { GetDatabaseStats(debugService: self.debugService()) }
    }
    
    var clearDatabase: Factory<ClearDatabase> {
        self { ClearDatabase(debugService: self.debugService()) }
    }
    #endif
}