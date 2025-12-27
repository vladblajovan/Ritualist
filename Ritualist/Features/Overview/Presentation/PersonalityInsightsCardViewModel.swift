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

    /// Whether to show the personality insights card
    public var shouldShowPersonalityInsights = true

    /// Whether user has sufficient data for new personality analysis
    public var isPersonalityDataSufficient = false

    /// Current threshold requirements status
    public var personalityThresholdRequirements: [ThresholdRequirement] = []

    /// The dominant personality trait name (e.g., "Conscientiousness")
    public var dominantPersonalityTrait: String?

    // MARK: - Dependencies

    @ObservationIgnored @Injected(\.getPersonalityProfileUseCase) private var getPersonalityProfileUseCase
    @ObservationIgnored @Injected(\.getPersonalityInsightsUseCase) private var getPersonalityInsightsUseCase
    @ObservationIgnored @Injected(\.updatePersonalityAnalysisUseCase) private var updatePersonalityAnalysisUseCase
    @ObservationIgnored @Injected(\.validateAnalysisDataUseCase) private var validateAnalysisDataUseCase
    @ObservationIgnored @Injected(\.isPersonalityAnalysisEnabledUseCase) private var isPersonalityAnalysisEnabledUseCase
    @ObservationIgnored @Injected(\.checkPremiumStatus) private var checkPremiumStatus
    @ObservationIgnored @Injected(\.personalityDeepLinkCoordinator) private var personalityDeepLinkCoordinator
    @ObservationIgnored @Injected(\.getCurrentUserProfile) private var getCurrentUserProfile
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
            // Check if user is premium - personality insights is a premium feature
            let isPremium = await checkPremiumStatus.execute()
            guard isPremium else {
                // Non-premium users should not see the personality insights card
                shouldShowPersonalityInsights = false
                personalityInsights = []
                dominantPersonalityTrait = nil
                isPersonalityDataSufficient = false
                personalityThresholdRequirements = []
                return
            }

            // Always get eligibility and requirements info using the UseCase
            let userId = await getUserId()
            let eligibility = try await validateAnalysisDataUseCase.execute(for: userId)
            let requirements = try await validateAnalysisDataUseCase.getProgressDetails(for: userId)

            // Update state with eligibility info
            isPersonalityDataSufficient = eligibility.isEligible
            personalityThresholdRequirements = requirements

            // Show the card for premium users - it will handle different states internally
            shouldShowPersonalityInsights = true

            // Get existing personality profile
            var personalityProfile = try await getPersonalityProfileUseCase.execute(for: userId)

            // If user is eligible but no profile exists, attempt to create one
            if eligibility.isEligible && personalityProfile == nil {
                do {
                    let newProfile = try await updatePersonalityAnalysisUseCase.execute(for: userId)
                    personalityProfile = newProfile
                } catch {
                    // Log the error - analysis creation failures shouldn't crash the app
                    logger.log("Failed to create personality analysis: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
                    // If analysis fails, we still show the card but with error state
                    personalityInsights = []
                    dominantPersonalityTrait = nil
                    return
                }
            }

            // If we have a profile, get insights from it
            if let profile = personalityProfile {
                let insights = getPersonalityInsightsUseCase.getAllInsights(for: profile)

                // Convert to OverviewPersonalityInsight format for the new card
                var cardInsights: [OverviewPersonalityInsight] = []

                // Add pattern insights
                for insight in insights.patternInsights.prefix(2) {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: insight.title,
                        message: insight.description,
                        type: .pattern
                    ))
                }

                // Add habit recommendations
                for insight in insights.habitRecommendations.prefix(2) {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: insight.title,
                        message: insight.actionable,
                        type: .recommendation
                    ))
                }

                // Add one motivational insight
                if let motivationalInsight = insights.motivationalInsights.first {
                    cardInsights.append(OverviewPersonalityInsight(
                        title: motivationalInsight.title,
                        message: motivationalInsight.actionable,
                        type: .motivation
                    ))
                }

                personalityInsights = cardInsights
                dominantPersonalityTrait = profile.dominantTrait.displayName
            } else {
                // No profile available (either data insufficient or analysis failed)
                personalityInsights = []
                dominantPersonalityTrait = nil
            }
        } catch {
            // Log the error for debugging - personality analysis failures shouldn't crash the app
            logger.log("Failed to load personality insights: \(error.localizedDescription)", level: .error, category: .dataIntegrity)
            // Even on error, show the card but with empty state
            personalityInsights = []
            dominantPersonalityTrait = nil
            isPersonalityDataSufficient = false
            personalityThresholdRequirements = []
        }
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
