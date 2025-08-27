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
                getOnboardingState: self.getOnboardingState(),
                loadProfile: self.loadProfile(),
                appearanceManager: self.appearanceManager(),
                navigationService: self.navigationService(),
                personalityDeepLinkCoordinator: self.personalityDeepLinkCoordinator()
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
                suggestionsService: self.habitSuggestionsService(),
                userActionTracker: self.userActionTracker()
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
                paywallBusinessService: self.paywallBusinessService(),
                updateProfileSubscription: self.updateProfileSubscription(),
                errorHandler: self.errorHandlingActor()
            )
        }
    }
    
    @MainActor
    var settingsViewModel: Factory<SettingsViewModel> {
        self { @MainActor in
            SettingsViewModel(
                loadProfile: self.loadProfile(),
                saveProfile: self.saveProfile(),
                requestNotificationPermission: self.requestNotificationPermission(),
                checkNotificationStatus: self.checkNotificationStatus(),
                clearPurchases: self.clearPurchases(),
                checkPremiumStatus: self.checkPremiumStatus(),
                updateUserSubscription: self.updateUserSubscription(),
                populateTestData: {
                    #if DEBUG
                    return self.populateTestData()
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
                requestNotificationPermission: self.requestNotificationPermission(),
                checkNotificationStatus: self.checkNotificationStatus()
            )
        }
    }
    
    // MARK: - Dashboard ViewModels
    
    @MainActor
    var dashboardViewModel: Factory<DashboardViewModel> {
        self { @MainActor in
            DashboardViewModel()
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
                personalityRepository: self.personalityAnalysisRepository(),
                scheduler: self.personalityAnalysisScheduler(),
                loadProfile: self.loadProfile()
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
