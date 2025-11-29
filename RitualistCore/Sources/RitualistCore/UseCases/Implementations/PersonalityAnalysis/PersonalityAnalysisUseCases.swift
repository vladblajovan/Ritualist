import Foundation

// MARK: - Personality Analysis Use Case Implementations

public final class DefaultAnalyzePersonalityUseCase: AnalyzePersonalityUseCase {
    
    private let personalityService: PersonalityAnalysisService
    private let thresholdValidator: DataThresholdValidator
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(
        personalityService: PersonalityAnalysisService,
        thresholdValidator: DataThresholdValidator,
        repository: PersonalityAnalysisRepositoryProtocol
    ) {
        self.personalityService = personalityService
        self.thresholdValidator = thresholdValidator
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile {
        // First validate that analysis can be performed
        let canAnalyze = try await canPerformAnalysis(for: userId)
        guard canAnalyze else {
            throw PersonalityAnalysisError.insufficientData
        }
        
        // Business workflow: Get input data for analysis
        let input = try await repository.getHabitAnalysisInput(for: userId)
        
        // Get enhanced completion statistics with schedule-aware calculations
        let endDate = Date()
        let startDate = CalendarUtils.addDaysLocal(-30, to: endDate, timezone: .current)
        let completionStats = try await repository.getHabitCompletionStats(for: userId, from: startDate, to: endDate)
        
        // Calculate personality scores using Service as utility
        let traitScores = personalityService.calculatePersonalityScores(from: input)
        
        // Determine dominant trait using Service as utility
        let dominantTrait = personalityService.determineDominantTrait(from: traitScores)
        
        // Create metadata (business logic)
        let enhancedDataPoints = input.totalDataPoints + (completionStats.totalHabits > 0 ? 10 : 0)
        let metadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: enhancedDataPoints,
            timeRangeAnalyzed: input.analysisTimeRange,
            version: "1.6"
        )
        
        // Calculate confidence using Service as utility
        let confidence = personalityService.calculateConfidence(from: metadata)
        
        // Create the profile (business logic)
        let profile = PersonalityProfile(
            id: UUID(),
            userId: userId,
            traitScores: traitScores,
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: metadata
        )
        
        // Save the profile to the database
        try await repository.savePersonalityProfile(profile)
        
        return profile
    }
    
    public func canPerformAnalysis(for userId: UUID) async throws -> Bool {
        let eligibility = try await thresholdValidator.validateEligibility(for: userId)
        return eligibility.isEligible
    }
}

public final class DefaultUpdatePersonalityAnalysisUseCase: UpdatePersonalityAnalysisUseCase {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    private let analyzePersonalityUseCase: AnalyzePersonalityUseCase
    
    // Update analysis if it's older than 7 days
    private let analysisValidityPeriod: TimeInterval = 7 * 24 * 60 * 60
    
    public init(
        repository: PersonalityAnalysisRepositoryProtocol,
        analyzePersonalityUseCase: AnalyzePersonalityUseCase
    ) {
        self.repository = repository
        self.analyzePersonalityUseCase = analyzePersonalityUseCase
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile {
        // Delegate to the analysis UseCase (follows Clean Architecture)
        let newProfile = try await analyzePersonalityUseCase.execute(for: userId)
        
        // Profile is already saved by the AnalyzePersonalityUseCase
        return newProfile
    }
    
    public func regenerateAnalysis(for userId: UUID) async throws -> PersonalityProfile {
        // Get existing profile to delete it
        if let existingProfile = try await repository.getPersonalityProfile(for: userId) {
            try await repository.deletePersonalityProfile(id: existingProfile.id)
        }
        
        // Generate and save new analysis
        return try await execute(for: userId)
    }
    
    public func shouldUpdateAnalysis(for userId: UUID) async throws -> Bool {
        guard let existingProfile = try await repository.getPersonalityProfile(for: userId) else {
            // No existing profile, should create one
            return true
        }
        
        let timeSinceAnalysis = Date().timeIntervalSince(existingProfile.analysisMetadata.analysisDate)
        
        // Update if analysis is older than validity period
        return timeSinceAnalysis > analysisValidityPeriod
    }
}

public final class DefaultGetPersonalityProfileUseCase: GetPersonalityProfileUseCase {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile? {
        return try await repository.getPersonalityProfile(for: userId)
    }
    
    public func getHistory(for userId: UUID) async throws -> [PersonalityProfile] {
        return try await repository.getPersonalityHistory(for: userId)
    }
    
    public func hasProfiles(for userId: UUID) async throws -> Bool {
        let profile = try await repository.getPersonalityProfile(for: userId)
        return profile != nil
    }
}

public final class DefaultGetPersonalityInsightsUseCase: GetPersonalityInsightsUseCase {
    
    public init() {}
    
    public func execute(for userId: UUID) async throws -> PersonalityProfile? {
        // This is a simple wrapper - the actual implementation would use the repository
        // For now, return nil as this needs to be connected to the repository layer
        return nil
    }
    
    public func getHabitRecommendations(for profile: PersonalityProfile) -> [PersonalityInsight] {
        var insights: [PersonalityInsight] = []
        
        let topTraits = profile.traitsByScore.prefix(3)
        
        for (trait, score) in topTraits where score > 0.6 {
            switch trait {
            case .openness:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Explore Creative Habits",
                    description: "Your high openness suggests you'd enjoy creative pursuits like art, music, or learning new skills.",
                    actionable: "Try adding habits like 'Practice drawing', 'Learn a new language', or 'Read diverse genres'",
                    confidence: profile.confidence
                ))
                
            case .conscientiousness:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Structure Your Routine",
                    description: "Your conscientiousness means you thrive with organized, goal-oriented habits.",
                    actionable: "Set specific targets, use detailed tracking, and create morning/evening routines",
                    confidence: profile.confidence
                ))
                
            case .extraversion:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Add Social Elements",
                    description: "Your extraversion suggests social and energetic activities align with your nature.",
                    actionable: "Try habits like 'Meet friends weekly', 'Join group fitness', or 'Call family daily'",
                    confidence: profile.confidence
                ))
                
            case .agreeableness:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Focus on Connection",
                    description: "Your agreeableness indicates you value helping others and maintaining relationships.",
                    actionable: "Consider habits like 'Random acts of kindness', 'Check in with loved ones', or 'Volunteer weekly'",
                    confidence: profile.confidence
                ))
                
            case .neuroticism:
                insights.append(PersonalityInsight(
                    id: UUID().uuidString,
                    category: .habitRecommendation,
                    trait: trait,
                    title: "Prioritize Stress Management",
                    description: "Higher emotional sensitivity suggests stress-reduction habits would be particularly beneficial.",
                    actionable: "Try meditation, deep breathing exercises, journaling, or regular nature walks",
                    confidence: profile.confidence
                ))
            }
        }
        
        return insights
    }
    
    public func getPatternInsights(for profile: PersonalityProfile) -> [PersonalityInsight] {
        var insights: [PersonalityInsight] = []
        
        // Analyze dominant trait patterns
        let dominantScore = profile.traitScores[profile.dominantTrait] ?? 0.0
        
        if dominantScore > 0.8 {
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .patternAnalysis,
                trait: profile.dominantTrait,
                title: "Strong \(profile.dominantTrait.displayName) Pattern",
                description: "Your habits strongly reflect \(profile.dominantTrait.displayName.lowercased()) tendencies.",
                actionable: "Continue leveraging this strength while exploring habits that develop other traits",
                confidence: profile.confidence
            ))
        }
        
        // Look for balanced traits
        let balancedTraits = profile.traitScores.filter { abs($0.value - 0.5) < 0.15 }
        if balancedTraits.count >= 3 {
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .patternAnalysis,
                trait: nil,
                title: "Balanced Personality Profile",
                description: "Your habits show a well-rounded approach across multiple personality dimensions.",
                actionable: "This flexibility allows you to adapt your habits to different life situations and goals",
                confidence: profile.confidence
            ))
        }
        
        return insights
    }
    
    public func getMotivationalInsights(for profile: PersonalityProfile) -> [PersonalityInsight] {
        var insights: [PersonalityInsight] = []
        
        // Motivational strategies based on dominant trait
        switch profile.dominantTrait {
        case .openness:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .openness,
                title: "Variety Keeps You Engaged",
                description: "Your openness means routine can become boring. Keep habits fresh with variation.",
                actionable: "Rotate activities, try new approaches, or set creative challenges within existing habits",
                confidence: profile.confidence
            ))
            
        case .conscientiousness:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .conscientiousness,
                title: "Progress Tracking Motivates You",
                description: "Your conscientiousness is fueled by seeing concrete progress and achievement.",
                actionable: "Use detailed metrics, celebrate milestones, and track long-term improvements",
                confidence: profile.confidence
            ))
            
        case .extraversion:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .extraversion,
                title: "Social Accountability Works",
                description: "Your extraversion suggests you're motivated by social connection and external energy.",
                actionable: "Share your goals, find habit buddies, or join community challenges",
                confidence: profile.confidence
            ))
            
        case .agreeableness:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .agreeableness,
                title: "Purpose-Driven Habits Stick",
                description: "Your agreeableness means habits connected to helping others will be most sustainable.",
                actionable: "Frame personal habits in terms of how they help you better serve family, friends, or community",
                confidence: profile.confidence
            ))
            
        case .neuroticism:
            insights.append(PersonalityInsight(
                id: UUID().uuidString,
                category: .motivation,
                trait: .neuroticism,
                title: "Gentle Consistency Over Intensity",
                description: "Your sensitivity suggests steady, manageable habits work better than aggressive goals.",
                actionable: "Start small, be kind to yourself on off days, and focus on stress-reducing habits first",
                confidence: profile.confidence
            ))
        }
        
        return insights
    }
    
    public func getAllInsights(for profile: PersonalityProfile) -> PersonalityInsightCollection {
        let recommendations = getHabitRecommendations(for: profile)
        let patterns = getPatternInsights(for: profile)
        let motivational = getMotivationalInsights(for: profile)
        
        return PersonalityInsightCollection(
            habitRecommendations: recommendations,
            patternInsights: patterns,
            motivationalInsights: motivational,
            generatedDate: Date(),
            profileId: profile.id.uuidString
        )
    }
}

public final class DefaultIsPersonalityAnalysisEnabledUseCase: IsPersonalityAnalysisEnabledUseCase {
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> Bool {
        return try await repository.isPersonalityAnalysisEnabled(for: userId)
    }
}

public final class DefaultValidateAnalysisDataUseCase: ValidateAnalysisDataUseCase {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    private let thresholdValidator: DataThresholdValidator
    
    public init(
        repository: PersonalityAnalysisRepositoryProtocol,
        thresholdValidator: DataThresholdValidator
    ) {
        self.repository = repository
        self.thresholdValidator = thresholdValidator
    }
    
    public func execute(for userId: UUID) async throws -> AnalysisEligibility {
        return try await repository.validateAnalysisEligibility(for: userId)
    }
    
    public func getProgressDetails(for userId: UUID) async throws -> [ThresholdRequirement] {
        return try await repository.getThresholdProgress(for: userId)
    }
    
    public func getEstimatedDaysToEligibility(for userId: UUID) async throws -> Int? {
        let requirements = try await getProgressDetails(for: userId)
        
        // Calculate based on missing tracking days and creation needs
        var maxDaysNeeded = 0
        
        for requirement in requirements where !requirement.isMet {
            switch requirement.category {
            case .tracking:
                // Assume user needs to track consistently for remaining days
                let daysNeeded = requirement.requiredValue - requirement.currentValue
                maxDaysNeeded = max(maxDaysNeeded, daysNeeded)
                
            case .habits, .customization:
                // Assume user can create habits/categories immediately but needs tracking time
                maxDaysNeeded = max(maxDaysNeeded, 1)
                
            case .diversity:
                // Diversity improvements might take a few days to establish
                maxDaysNeeded = max(maxDaysNeeded, 3)
            }
        }
        
        return maxDaysNeeded > 0 ? maxDaysNeeded : nil
    }
}

// MARK: - Personality Analysis Preferences Use Cases

public final class DefaultGetAnalysisPreferencesUseCase: GetAnalysisPreferencesUseCase {
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> PersonalityAnalysisPreferences? {
        return try await repository.getAnalysisPreferences(for: userId)
    }
}

public final class DefaultSaveAnalysisPreferencesUseCase: SaveAnalysisPreferencesUseCase {
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ preferences: PersonalityAnalysisPreferences) async throws {
        try await repository.saveAnalysisPreferences(preferences)
    }
}

public final class DefaultDeletePersonalityDataUseCase: DeletePersonalityDataUseCase {
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws {
        try await repository.deleteAllPersonalityProfiles(for: userId)
    }
}

// MARK: - Personality Analysis Scheduler Use Cases

public final class DefaultStartAnalysisSchedulingUseCase: StartAnalysisSchedulingUseCase {
    private let scheduler: PersonalityAnalysisSchedulerProtocol
    
    public init(scheduler: PersonalityAnalysisSchedulerProtocol) {
        self.scheduler = scheduler
    }
    
    public func execute(for userId: UUID) async {
        await scheduler.startScheduling(for: userId)
    }
}

public final class DefaultUpdateAnalysisSchedulingUseCase: UpdateAnalysisSchedulingUseCase {
    private let scheduler: PersonalityAnalysisSchedulerProtocol
    
    public init(scheduler: PersonalityAnalysisSchedulerProtocol) {
        self.scheduler = scheduler
    }
    
    public func execute(for userId: UUID, preferences: PersonalityAnalysisPreferences) async {
        await scheduler.updateScheduling(for: userId, preferences: preferences)
    }
}

public final class DefaultGetNextScheduledAnalysisUseCase: GetNextScheduledAnalysisUseCase {
    private let scheduler: PersonalityAnalysisSchedulerProtocol
    
    public init(scheduler: PersonalityAnalysisSchedulerProtocol) {
        self.scheduler = scheduler
    }
    
    public func execute(for userId: UUID) async -> Date? {
        return await scheduler.getNextScheduledAnalysis(for: userId)
    }
}

public final class DefaultTriggerAnalysisCheckUseCase: TriggerAnalysisCheckUseCase {
    private let scheduler: PersonalityAnalysisSchedulerProtocol
    
    public init(scheduler: PersonalityAnalysisSchedulerProtocol) {
        self.scheduler = scheduler
    }
    
    public func execute(for userId: UUID) async {
        await scheduler.triggerAnalysisCheck(for: userId)
    }
}

public final class DefaultForceManualAnalysisUseCase: ForceManualAnalysisUseCase {
    private let scheduler: PersonalityAnalysisSchedulerProtocol

    public init(scheduler: PersonalityAnalysisSchedulerProtocol) {
        self.scheduler = scheduler
    }

    public func execute(for userId: UUID) async {
        await scheduler.forceManualAnalysis(for: userId)
    }
}

// MARK: - Personality Analysis Data Use Cases

public final class DefaultGetHabitAnalysisInputUseCase: GetHabitAnalysisInputUseCase {

    private let habitRepository: HabitRepository
    private let categoryRepository: CategoryRepository
    private let getBatchLogs: GetBatchLogsUseCase
    private let completionCalculator: ScheduleAwareCompletionCalculator
    private let getSelectedSuggestions: GetSelectedHabitSuggestionsUseCase
    private let calculateTrackingDays: CalculateConsecutiveTrackingDaysService

    public init(
        habitRepository: HabitRepository,
        categoryRepository: CategoryRepository,
        getBatchLogs: GetBatchLogsUseCase,
        completionCalculator: ScheduleAwareCompletionCalculator,
        getSelectedSuggestions: GetSelectedHabitSuggestionsUseCase,
        calculateTrackingDays: CalculateConsecutiveTrackingDaysService
    ) {
        self.habitRepository = habitRepository
        self.categoryRepository = categoryRepository
        self.getBatchLogs = getBatchLogs
        self.completionCalculator = completionCalculator
        self.getSelectedSuggestions = getSelectedSuggestions
        self.calculateTrackingDays = calculateTrackingDays
    }

    public func execute(for userId: UUID) async throws -> HabitAnalysisInput {
        // Get all active habits
        let allHabits = try await habitRepository.fetchAllHabits()
        let activeHabits = allHabits.filter { $0.isActive }

        // Get all habit logs for the last 30 days using batch optimization
        let endDate = Date()
        let startDate = CalendarUtils.addDaysLocal(-30, to: endDate, timezone: .current)

        // OPTIMIZATION: Use batch loading to avoid N+1 queries
        let habitIds = activeHabits.map(\.id)
        let logsByHabitId = try await getBatchLogs.execute(for: habitIds, since: startDate, until: endDate)
        let allLogs = logsByHabitId.values.flatMap { $0 }

        // Calculate completion rates per habit using schedule-aware logic
        let completionRates = activeHabits.map { habit in
            completionCalculator.calculateCompletionRate(
                for: habit,
                logs: allLogs,
                startDate: startDate,
                endDate: endDate
            )
        }

        // Get custom habits (non-suggested habits)
        let customHabits = activeHabits.filter { $0.suggestionId == nil }

        // Get all categories
        let allCategories = try await categoryRepository.getAllCategories()
        let customCategories = try await categoryRepository.getCustomCategories()

        // Get habit categories (categories that have active habits)
        let habitCategoryIds = Set(activeHabits.map { $0.categoryId })
        let habitCategories = allCategories.filter { habitCategoryIds.contains($0.id) }

        // Get selected suggestions (habits that came from suggestions)
        let selectedSuggestions = try await getSelectedSuggestions.execute(from: activeHabits)

        // Calculate tracking consistency
        let trackingDays = calculateTrackingDays.execute(logs: allLogs)

        // Calculate total data points for analysis confidence
        let individualHabitAnalysis = activeHabits.count
        let totalDataPoints = allLogs.count + customHabits.count + customCategories.count + individualHabitAnalysis

        return HabitAnalysisInput(
            activeHabits: activeHabits,
            completionRates: completionRates,
            customHabits: customHabits,
            customCategories: customCategories,
            habitCategories: habitCategories,
            selectedSuggestions: selectedSuggestions,
            trackingDays: trackingDays,
            analysisTimeRange: 30,
            totalDataPoints: totalDataPoints
        )
    }
}

public final class DefaultGetSelectedHabitSuggestionsUseCase: GetSelectedHabitSuggestionsUseCase {

    private let suggestionsService: HabitSuggestionsService

    public init(suggestionsService: HabitSuggestionsService) {
        self.suggestionsService = suggestionsService
    }

    public func execute(from habits: [Habit]) async throws -> [HabitSuggestion] {
        var selectedSuggestions: [HabitSuggestion] = []

        // Find habits that were created from suggestions (have a suggestionId)
        let habitsSuggestionsIds = habits.compactMap { $0.suggestionId }

        // Look up the original suggestions by ID
        for suggestionId in habitsSuggestionsIds {
            if let suggestion = suggestionsService.getSuggestion(by: suggestionId) {
                selectedSuggestions.append(suggestion)
            }
        }

        return selectedSuggestions
    }
}

public final class DefaultEstimateDaysToEligibilityUseCase: EstimateDaysToEligibilityUseCase {

    public init() {}

    public func execute(from unmetRequirements: [ThresholdRequirement]) -> Int? {
        var maxDaysNeeded = 0

        for requirement in unmetRequirements {
            switch requirement.category {
            case .tracking:
                let daysNeeded = requirement.requiredValue - requirement.currentValue
                maxDaysNeeded = max(maxDaysNeeded, max(0, daysNeeded))
            case .habits, .customization:
                maxDaysNeeded = max(maxDaysNeeded, 1)
            case .diversity:
                maxDaysNeeded = max(maxDaysNeeded, 3)
            }
        }

        return maxDaysNeeded > 0 ? maxDaysNeeded : nil
    }
}