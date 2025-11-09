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
        self { CheckPremiumStatus(subscriptionService: self.subscriptionService()) }
    }

    var updateUserSubscription: Factory<UpdateUserSubscription> {
        self { UpdateUserSubscription() }
    }

    // MARK: - iCloud Sync Operations

    var syncWithiCloud: Factory<SyncWithiCloudUseCase> {
        self { DefaultSyncWithiCloudUseCase(userBusinessService: self.userBusinessService()) }
    }

    var checkiCloudStatus: Factory<CheckiCloudStatusUseCase> {
        self {
            // ⚠️ TEMPORARY: Using disabled implementation while CloudKit entitlements are off
            // This prevents crashes when trying to access CKContainer without entitlements
            //
            // TO RE-ENABLE: Uncomment the DefaultCheckiCloudStatusUseCase below when
            // CloudKit entitlements are restored (see ICLOUD-INVESTIGATION-SUMMARY.md)

            DisabledCheckiCloudStatusUseCase()

            // DefaultCheckiCloudStatusUseCase(
            //     syncErrorHandler: CloudSyncErrorHandler(errorHandler: self.errorHandler())
            // )
        }
    }

    var getLastSyncDate: Factory<GetLastSyncDateUseCase> {
        self { DefaultGetLastSyncDateUseCase() }
    }

    var updateLastSyncDate: Factory<UpdateLastSyncDateUseCase> {
        self { DefaultUpdateLastSyncDateUseCase() }
    }
    
    // MARK: - Development Operations

    var clearPurchases: Factory<ClearPurchases> {
        self { ClearPurchases(paywallService: self.paywallService()) }
    }

    #if DEBUG
    var populateTestData: Factory<PopulateTestData> {
        self {
            PopulateTestData(
                debugService: self.debugService(),
                habitSuggestionsService: self.habitSuggestionsService(),
                createHabitFromSuggestionUseCase: self.createHabitFromSuggestionUseCase(),
                createCustomCategoryUseCase: self.createCustomCategory(),
                logHabitUseCase: self.logHabit(),
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                habitCompletionService: self.habitCompletionService(),
                testDataUtilities: self.testDataPopulationService(),
                completeOnboardingUseCase: self.completeOnboarding()
            )
        }
    }

    var getDatabaseStats: Factory<GetDatabaseStats> {
        self { GetDatabaseStats(debugService: self.debugService()) }
    }
    
    var clearDatabase: Factory<ClearDatabase> {
        self { ClearDatabase(debugService: self.debugService()) }
    }
    #endif
}