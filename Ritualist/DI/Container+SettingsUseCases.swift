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

    var getCurrentSubscriptionPlan: Factory<GetCurrentSubscriptionPlan> {
        self { GetCurrentSubscriptionPlan(subscriptionService: self.subscriptionService()) }
    }

    var getSubscriptionExpiryDate: Factory<GetSubscriptionExpiryDate> {
        self { GetSubscriptionExpiryDate(subscriptionService: self.subscriptionService()) }
    }

    // MARK: - iCloud Sync Operations

    var syncWithiCloud: Factory<SyncWithiCloudUseCase> {
        self { DefaultSyncWithiCloudUseCase(checkiCloudStatus: self.checkiCloudStatus()) }
    }

    var checkiCloudStatus: Factory<CheckiCloudStatusUseCase> {
        self {
            // ✅ CloudKit ENABLED - Using real implementation with error handler
            DefaultCheckiCloudStatusUseCase(
                syncErrorHandler: CloudSyncErrorHandler(errorHandler: self.errorHandler()),
                logger: self.debugLogger()
            )
        }
    }

    var getLastSyncDate: Factory<GetLastSyncDateUseCase> {
        self { DefaultGetLastSyncDateUseCase() }
    }

    var updateLastSyncDate: Factory<UpdateLastSyncDateUseCase> {
        self { DefaultUpdateLastSyncDateUseCase() }
    }

    var deleteiCloudData: Factory<DeleteiCloudDataUseCase> {
        self { DefaultDeleteiCloudDataUseCase(modelContext: self.persistenceContainer().context) }
    }

    var exportUserData: Factory<ExportUserDataUseCase> {
        self {
            DefaultExportUserDataUseCase(
                loadProfile: self.loadProfile(),
                getLastSyncDate: self.getLastSyncDate(),
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                personalityRepository: self.personalityAnalysisRepository(),
                logDataSource: self.logDataSource(),
                logger: self.debugLogger()
            )
        }
    }

    var importUserData: Factory<ImportUserDataUseCase> {
        self {
            DefaultImportUserDataUseCase(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                personalityRepository: self.personalityAnalysisRepository(),
                logDataSource: self.logDataSource(),
                updateLastSyncDate: self.updateLastSyncDate(),
                logger: self.debugLogger()
            )
        }
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
                completeOnboardingUseCase: self.completeOnboarding(),
                logger: self.debugLogger()
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