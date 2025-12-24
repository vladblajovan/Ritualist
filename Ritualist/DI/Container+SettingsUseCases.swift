import Foundation
import FactoryKit
import RitualistCore

// MARK: - Settings Use Cases Container Extensions

extension Container {
    
    // MARK: - Profile Operations

    /// Cache-aware SaveProfile that invalidates the shared profile cache on save
    var saveProfile: Factory<SaveProfileUseCase> {
        self {
            let innerSaveProfile = SaveProfile(repo: self.profileRepository())
            return CacheAwareSaveProfile(
                innerSaveProfile: innerSaveProfile,
                cache: self.profileCache()
            )
        }
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
        self {
            DefaultDeleteiCloudDataUseCase(
                modelContext: self.persistenceContainer().context,
                iCloudKeyValueService: self.iCloudKeyValueService()
            )
        }
    }

    var deduplicateData: Factory<DeduplicateDataUseCase> {
        self {
            DefaultDeduplicateDataUseCase(
                deduplicationService: self.dataDeduplicationService(),
                logger: self.debugLogger()
            )
        }
    }

    var exportUserData: Factory<ExportUserDataUseCase> {
        self {
            // NOTE: PersonalityAnalysis intentionally excluded for privacy
            DefaultExportUserDataUseCase(
                loadProfile: self.loadProfile(),
                getLastSyncDate: self.getLastSyncDate(),
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                logDataSource: self.logDataSource(),
                logger: self.debugLogger()
            )
        }
    }

    var importUserData: Factory<ImportUserDataUseCase> {
        self {
            // NOTE: PersonalityAnalysis intentionally excluded for privacy
            DefaultImportUserDataUseCase(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                habitRepository: self.habitRepository(),
                categoryRepository: self.categoryRepository(),
                logDataSource: self.logDataSource(),
                updateLastSyncDate: self.updateLastSyncDate(),
                validationService: self.importValidationService(),
                modelContext: self.persistenceContainer().context,
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