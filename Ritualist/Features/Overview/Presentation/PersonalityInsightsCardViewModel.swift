//
//  PersonalityInsightsCardViewModel.swift
//  Ritualist
//
//  Extracted from OverviewViewModel for Single Responsibility Principle.
//  Handles personality insights display, premium status, and data eligibility.
//

import SwiftUI
import Foundation
import FactoryKit
import RitualistCore

// MARK: - PersonalityInsightsCardViewModel

@MainActor
@Observable
public final class PersonalityInsightsCardViewModel {

    // MARK: - Observable Properties

    /// Personality insights to display on the card
    public var personalityInsights: [OverviewPersonalityInsight] = []

    /// Whether to show the personality insights card (only for premium users)
    public var shouldShowPersonalityInsights = false

    /// Whether to show the personality upsell card (free users with sufficient data)
    public var showPersonalityUpsell = false

    /// Whether user has sufficient data for new personality analysis
    public var isPersonalityDataSufficient = false

    /// Current threshold requirements status
    public var personalityThresholdRequirements: [ThresholdRequirement] = []

    /// The dominant personality trait name (e.g., "Conscientiousness")
    public var dominantPersonalityTrait: String?

    /// Paywall item for presenting the paywall sheet
    public var paywallItem: PaywallItem?

    // MARK: - Dependencies

    @ObservationIgnored @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @ObservationIgnored @Injected(\.getPersonalityInsightsUseCase) private var getPersonalityInsightsUseCase
    @ObservationIgnored @Injected(\.updatePersonalityAnalysisUseCase) private var updatePersonalityAnalysisUseCase
    @ObservationIgnored @Injected(\.validateAnalysisDataUseCase) private var validateAnalysisDataUseCase
    @ObservationIgnored @Injected(\.isPersonalityAnalysisEnabledUseCase) private var isPersonalityAnalysisEnabledUseCase
    @ObservationIgnored @Injected(\.checkPremiumStatus) private var checkPremiumStatus
    @ObservationIgnored @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    @ObservationIgnored @Injected(\.getCurrentUserProfile) private var getCurrentUserProfile
    @ObservationIgnored @Injected(\.paywallViewModel) private var paywallViewModel
    @ObservationIgnored @Injected(\.debugLogger) private var logger

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Navigate to the full personality analysis screen
    public func openPersonalityAnalysis() {
        personalityDeepLinkCoordinator.showPersonalityAnalysisDirectly()
    }

    /// Refresh personality insights from the data layer
    public func refreshPersonalityInsights() async {
        await loadPersonalityInsights()
    }

    /// Load personality insights
    /// Called after data loads or when user returns to the overview
    public func loadPersonalityInsights() async {
        do {
            let isPremium = await checkPremiumStatus.execute()
            let userId = await getUserId()

            if !isPremium {
                // For free users, check if they have enough data to show upsell
                try await updateEligibilityState(for: userId)

                if isPersonalityDataSufficient {
                    // Show upsell card for free users with sufficient data
                    showPersonalityUpsell = true
                    shouldShowPersonalityInsights = false
                    logger.log("Showing personality upsell for free user with sufficient data", level: .info, category: .ui)
                } else {
                    // Not enough data - hide everything
                    resetInsightsForNonPremium()
                }
                return
            }

            // Premium user - show full insights
            showPersonalityUpsell = false
            try await updateEligibilityState(for: userId)
            shouldShowPersonalityInsights = true

            let personalityProfile = try await fetchOrCreateProfile(for: userId)
            updateInsightsFromProfile(personalityProfile)
        } catch {
            logger.log("Failed to load personality insights: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            resetInsightsOnError()
        }
    }

    /// Show the paywall for personality insights upsell
    public func showPaywall() async {
        await paywallViewModel.load()
        paywallViewModel.trackPaywallShown(source: "overview", trigger: "personality_upsell")
        paywallItem = PaywallItem(viewModel: paywallViewModel)
    }

    private func resetInsightsForNonPremium() {
        shouldShowPersonalityInsights = false
        showPersonalityUpsell = false
        personalityInsights = []
        dominantPersonalityTrait = nil
        isPersonalityDataSufficient = false
        personalityThresholdRequirements = []
    }

    private func resetInsightsOnError() {
        personalityInsights = []
        dominantPersonalityTrait = nil
        isPersonalityDataSufficient = false
        personalityThresholdRequirements = []
        showPersonalityUpsell = false
    }

    private func updateEligibilityState(for userId: UUID) async throws {
        let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
        let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)
        isPersonalityDataSufficient = eligibility.isEligible
        personalityThresholdRequirements = requirements
    }

    private func fetchOrCreateProfile(for userId: UUID) async throws -> PersonalityProfile? {
        var profile = try await getPersonalityProfileUseCase.execute(for: userId)

        if isPersonalityDataSufficient && profile == nil {
            do {
                profile = try await updatePersonalityAnalysisUseCase.execute(for: userId)
            } catch {
                logger.log("Failed to create personality analysis: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
                personalityInsights = []
                dominantPersonalityTrait = nil
            }
        }
        return profile
    }

    private func updateInsightsFromProfile(_ profile: PersonalityProfile?) {
        guard let profile = profile else {
            personalityInsights = []
            dominantPersonalityTrait = nil
            return
        }

        let insights = getPersonalityInsightsUseCase.getAllInsights(for: profile)
        personalityInsights = buildCardInsights(from: insights)
        dominantPersonalityTrait = profile.dominantTrait.displayName
    }

    private func buildCardInsights(from insights: PersonalityInsightCollection) -> [OverviewPersonalityInsight] {
        var cardInsights: [OverviewPersonalityInsight] = []

        for insight in insights.patternInsights.prefix(2) {
            cardInsights.append(OverviewPersonalityInsight(title: insight.title, message: insight.description, type: .pattern))
        }

        for insight in insights.habitRecommendations.prefix(2) {
            cardInsights.append(OverviewPersonalityInsight(title: insight.title, message: insight.actionable, type: .recommendation))
        }

        if let motivationalInsight = insights.motivationalInsights.first {
            cardInsights.append(OverviewPersonalityInsight(title: motivationalInsight.title, message: motivationalInsight.actionable, type: .motivation))
        }

        return cardInsights
    }

    /// Check if personality analysis is eligible for this user
    public func checkPersonalityAnalysisEligibility() async -> Bool {
        do {
            let userId = await getUserId()
            // Check if personality analysis service is enabled for this user
            let isEnabled = try await isPersonalityAnalysisEnabledUseCase.execute(for: userId)

            guard isEnabled else {
                return false
            }

            // Use the proper eligibility validation UseCase
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            return eligibility.isEligible
        } catch {
            return false
        }
    }

    // MARK: - Private Methods

    private func getUserId() async -> UUID {
        await getCurrentUserProfile.execute().id
    }
}
