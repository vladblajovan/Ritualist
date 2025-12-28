import Foundation
import RitualistCore
import FactoryKit

// MARK: - ViewModels Container Extensions

extension Container {
    
    // MARK: - Main ViewModels
    
    @MainActor
    var rootTabViewModel: Factory<RootTabViewModel> {
        self { @MainActor in
            RootTabViewModel(
                loadProfile: self.loadProfile(),
                iCloudKeyValueService: self.iCloudKeyValueService(),
                userDefaults: self.userDefaultsService(),
                appearanceManager: self.appearanceManager(),
                navigationService: self.navigationService(),
                personalityDeepLinkCoordinator: self.personalityDeepLinkCoordinator(),
                logger: self.debugLogger()
            )
        }
        .singleton
    }
    
    @MainActor
    var habitsViewModel: Factory<HabitsViewModel> {
        self { @MainActor in
            HabitsViewModel()
        }
        .singleton
    }
    
    @MainActor
    var overviewViewModel: Factory<OverviewViewModel> {
        self { @MainActor in
            OverviewViewModel()
        }
        .singleton
    }
    
    @MainActor
    var habitsAssistantViewModel: Factory<HabitsAssistantViewModel> {
        self { @MainActor in
            HabitsAssistantViewModel(
                getPredefinedCategoriesUseCase: self.getPredefinedCategoriesUseCase(),
                getHabitsFromSuggestionsUseCase: self.getHabitsFromSuggestionsUseCase(),
                getSuggestionsUseCase: self.getSuggestionsUseCase(),
                trackUserAction: self.trackUserAction()
            )
        }
        .singleton
    }
    
    // MARK: - Parameterized ViewModels (for editing)
    
    @MainActor
    func habitDetailViewModel(for habit: Habit?) -> HabitDetailViewModel {
        HabitDetailViewModel(habit: habit)
    }
    
    @MainActor
    var categoryManagementViewModel: Factory<CategoryManagementViewModel> {
        self { @MainActor in
            CategoryManagementViewModel(
                getAllCategoriesUseCase: self.getAllCategories(),
                createCustomCategoryUseCase: self.createCustomCategory(),
                updateCategoryUseCase: self.updateCategory(),
                deleteCategoryUseCase: self.deleteCategory(),
                getHabitsByCategoryUseCase: self.getHabitsByCategory(),
                orphanHabitsFromCategoryUseCase: self.orphanHabitsFromCategory()
            )
        }
    }

    @MainActor
    var tipsViewModel: Factory<TipsViewModel> {
        self { @MainActor in
            TipsViewModel(
                getAllTips: self.getAllTips(),
                getFeaturedTips: self.getFeaturedTips(),
                getTipById: self.getTipById(),
                getTipsByCategory: self.getTipsByCategory()
            )
        }
    }
    
    @MainActor
    var paywallViewModel: Factory<PaywallViewModel> {
        self { @MainActor in
            PaywallViewModel(
                loadPaywallProducts: self.loadPaywallProducts(),
                purchaseProduct: self.purchaseProduct(),
                restorePurchases: self.restorePurchases(),
                checkProductPurchased: self.checkProductPurchased(),
                errorHandler: self.errorHandler()
            )
        }
    }
    
    @MainActor
    var settingsViewModel: Factory<SettingsViewModel> {
        self { @MainActor in
            SettingsViewModel(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                permissionCoordinator: self.permissionCoordinator(),
                checkNotificationStatus: self.checkNotificationStatus(),
                getLocationAuthStatus: self.getLocationAuthStatus(),
                clearPurchases: self.clearPurchases(),
                checkPremiumStatus: self.checkPremiumStatus(),
                getCurrentSubscriptionPlan: self.getCurrentSubscriptionPlan(),
                getSubscriptionExpiryDate: self.getSubscriptionExpiryDate(),
                syncWithiCloud: self.syncWithiCloud(),
                checkiCloudStatus: self.checkiCloudStatus(),
                getLastSyncDate: self.getLastSyncDate(),
                deleteData: self.deleteData(),
                exportUserData: self.exportUserData(),
                importUserData: self.importUserData(),
                populateTestData: {
                    #if DEBUG
                    return self.populateTestData() as (any Any)?
                    #else
                    return nil
                    #endif
                }()
            )
        }
        .singleton
    }
    
    @MainActor
    var onboardingViewModel: Factory<OnboardingViewModel> {
        self { @MainActor in
            OnboardingViewModel(
                getOnboardingState: self.getOnboardingState(),
                saveOnboardingState: self.saveOnboardingState(),
                completeOnboarding: self.completeOnboarding(),
                permissionCoordinator: self.permissionCoordinator()
            )
        }
        .singleton
    }
    
    // MARK: - Stats ViewModels
    
    @MainActor
    var statsViewModel: Factory<StatsViewModel> {
        self { @MainActor in
            StatsViewModel(logger: self.debugLogger())
        }
        .singleton
    }
    
    // MARK: - Personality ViewModels
    
    @MainActor
    var personalityInsightsViewModel: Factory<PersonalityInsightsViewModel> {
        self { @MainActor in
            PersonalityInsightsViewModel(
                analyzePersonalityUseCase: self.analyzePersonalityUseCase(),
                getPersonalityProfileUseCase: self.getPersonalityProfileUseCase(),
                validateAnalysisDataUseCase: self.validateAnalysisDataUseCase(),
                getAnalysisPreferencesUseCase: self.getAnalysisPreferencesUseCase(),
                saveAnalysisPreferencesUseCase: self.saveAnalysisPreferencesUseCase(),
                deletePersonalityDataUseCase: self.deletePersonalityDataUseCase(),
                startAnalysisSchedulingUseCase: self.startAnalysisSchedulingUseCase(),
                updateAnalysisSchedulingUseCase: self.updateAnalysisSchedulingUseCase(),
                getNextScheduledAnalysisUseCase: self.getNextScheduledAnalysisUseCase(),
                triggerAnalysisCheckUseCase: self.triggerAnalysisCheckUseCase(),
                forceManualAnalysisUseCase: self.forceManualAnalysisUseCase(),
                loadProfile: self.loadProfile(),
                logger: self.debugLogger()
            )
        }
        .singleton
    }
    
    // MARK: - Presentation Services
    
    @MainActor
    var habitsAssistantPresentationService: Factory<HabitsAssistantPresentationService> {
        self { @MainActor in
            HabitsAssistantPresentationService()
        }
        .singleton
    }
    
    @MainActor
    var categoryManagementPresentationService: Factory<CategoryManagementPresentationService> {
        self { @MainActor in
            CategoryManagementPresentationService()
        }
        .singleton
    }
}
