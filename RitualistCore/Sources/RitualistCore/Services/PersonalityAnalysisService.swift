//
//  PersonalityAnalysisService.swift
//  RitualistCore
//
//  Created by Claude on 06.08.2025.
//

import Foundation
import NaturalLanguage

/// Service responsible for personality calculation utilities
/// Business operations moved to AnalyzePersonalityUseCase
public protocol PersonalityAnalysisService: Sendable {
    /// Calculate personality scores from habit analysis input
    func calculatePersonalityScores(from input: HabitAnalysisInput) -> [PersonalityTrait: Double]

    /// Calculate personality scores with detailed breakdown (accumulators and weights)
    func calculatePersonalityScoresWithDetails(
        from input: HabitAnalysisInput,
        completionStats: HabitCompletionStats?
    ) -> (
        scores: [PersonalityTrait: Double],
        accumulators: [PersonalityTrait: Double],
        totalWeights: [PersonalityTrait: Double]
    )

    /// Determine dominant trait from scores
    func determineDominantTrait(from scores: [PersonalityTrait: Double]) -> PersonalityTrait

    /// Calculate confidence level for analysis
    func calculateConfidence(from metadata: AnalysisMetadata) -> ConfidenceLevel
}

// swiftlint:disable function_body_length type_body_length
public final class DefaultPersonalityAnalysisService: PersonalityAnalysisService {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    private let errorHandler: ErrorHandler?
    
    public init(repository: PersonalityAnalysisRepositoryProtocol, errorHandler: ErrorHandler? = nil) {
        self.repository = repository
        self.errorHandler = errorHandler
    }
    
    // PHASE 2: Business method removed - use AnalyzePersonalityUseCase instead
    // This service now contains only utility calculation methods
    
    public func calculatePersonalityScores(from input: HabitAnalysisInput) -> [PersonalityTrait: Double] {
        let (scores, _, _) = calculatePersonalityScoresWithDetails(from: input, completionStats: nil)
        return scores
    }
    
    // swiftlint:disable function_body_length cyclomatic_complexity empty_count
    public func calculatePersonalityScoresWithDetails(
        from input: HabitAnalysisInput, 
        completionStats: HabitCompletionStats? = nil
    ) -> (
        scores: [PersonalityTrait: Double],
        accumulators: [PersonalityTrait: Double],
        totalWeights: [PersonalityTrait: Double]
    ) {
        var traitAccumulators: [PersonalityTrait: Double] = [
            .openness: 0.0,
            .conscientiousness: 0.0,
            .extraversion: 0.0,
            .agreeableness: 0.0,
            .neuroticism: 0.0
        ]
        
        var totalWeights: [PersonalityTrait: Double] = [
            .openness: 0.0,
            .conscientiousness: 0.0,
            .extraversion: 0.0,
            .agreeableness: 0.0,
            .neuroticism: 0.0
        ]
        
        // REMOVED: Suggestion analysis - suggestions are processed via their categories
        // Having both was causing double-counting and unpredictable results
        // Category weights are the authoritative source for personality traits
        
        // CRITICAL FIX: Analyze predefined category habits
        // Category weights are the PRIMARY signal - semantic analysis only ADDS to traits, never overrides

        // Group active habits by predefined category
        var habitsByPredefinedCategory: [String: [Habit]] = [:]
        for habit in input.activeHabits {
            guard let categoryId = habit.categoryId else { continue }
            guard let category = input.habitCategories.first(where: { $0.id == categoryId && $0.isPredefined }) else { continue }
            habitsByPredefinedCategory[categoryId, default: []].append(habit)
        }

        // Process each predefined category - USE CATEGORY WEIGHTS DIRECTLY
        for (categoryId, categoryHabits) in habitsByPredefinedCategory {
            guard let category = input.habitCategories.first(where: { $0.id == categoryId }) else { continue }
            guard let weights = category.personalityWeights else { continue }

            // SIMPLIFIED: Use category weights directly - no semantic blending for predefined categories
            // Predefined categories have carefully calibrated weights that should not be diluted

            // Distribute category weight across habits in that category
            let habitWeight = 1.0 / Double(categoryHabits.count)

            // Apply weights for each habit in this category
            for habit in categoryHabits {

                // Get individual habit completion rate
                let completionRate = getCompletionRateForHabit(habit: habit, input: input)

                // Completion weighting: direct scaling from 0.1 to 1.0
                // Low completion (e.g., 20%) should significantly reduce category contribution
                // This allows low completion to properly signal reduced conscientiousness
                let completionWeighting = max(0.1, min(1.0, completionRate))

                for (traitKey, categoryWeight) in weights {
                    if let trait = PersonalityTrait(rawValue: traitKey) {
                        // ROBUST: Negative weights (like neuroticism: -0.3) stay negative
                        // They reduce that trait's score, which is correct behavior
                        // Low completion simply reduces the MAGNITUDE of the contribution
                        let contribution = categoryWeight * completionWeighting * habitWeight

                        traitAccumulators[trait, default: 0.0] += contribution
                        totalWeights[trait, default: 0.0] += abs(contribution)
                    }
                }
            }
        }
        
        
        // Analyze custom habit categories - use keyword inference for weights
        // Custom categories contribute with lower weight than predefined categories
        let customCategoryWeight = 0.5 // Custom categories have 50% influence of predefined
        for category in input.customCategories {
            let categoryHabits = input.customHabits.filter { $0.categoryId == category.id }
            guard !categoryHabits.isEmpty else { continue }

            // Use explicit weights if available, otherwise infer from name/habits
            var weights = category.personalityWeights
            if weights == nil {
                weights = inferPersonalityWeights(for: category, habits: categoryHabits, allLogs: input.completionRates)
            }

            guard let weights = weights else { continue }

            let habitWeight = 1.0 / Double(categoryHabits.count)

            for habit in categoryHabits {
                let completionRate = getCompletionRateForHabit(habit: habit, input: input)
                let completionWeighting = max(0.1, min(1.0, completionRate))

                for (traitKey, weight) in weights {
                    if let trait = PersonalityTrait(rawValue: traitKey) {
                        let contribution = weight * completionWeighting * habitWeight * customCategoryWeight
                        traitAccumulators[trait, default: 0.0] += contribution
                        totalWeights[trait, default: 0.0] += abs(contribution)
                    }
                }
            }
        }
        
        // Analyze completion rates with enhanced schedule-aware statistics
        // This is a SECONDARY signal that modifies conscientiousness and neuroticism
        if let stats = completionStats, stats.totalHabits > 0 {
            let completionRate = stats.completionRate

            // Conscientiousness: High completion = disciplined, low completion = less disciplined
            // Scale is centered at 0.5 (neutral)
            let conscientiousnessBonus = (completionRate - 0.5) * 0.5
            traitAccumulators[.conscientiousness, default: 0.0] += conscientiousnessBonus
            totalWeights[.conscientiousness, default: 0.0] += 0.5

            // Neuroticism: ONLY low completion (<30%) indicates struggle/instability
            // High completion does NOT add negative neuroticism - that comes from category weights
            // This ensures category weights remain the primary signal
            if completionRate < 0.3 {
                // Low completion indicates struggle - add STRONG positive neuroticism
                // Scales with struggle severity and habit count (more failing habits = more stress)
                let struggleSeverity = (0.3 - completionRate) / 0.3 // 0.0 to 1.0
                let habitMultiplier = min(Double(stats.totalHabits) / 5.0, 2.0) // More habits = stronger signal
                let instabilityContribution = (0.5 + (struggleSeverity * 0.5)) * habitMultiplier // 0.5 to 2.0
                traitAccumulators[.neuroticism, default: 0.0] += instabilityContribution
                totalWeights[.neuroticism, default: 0.0] += 0.7 * habitMultiplier
            }
            // For completion >= 30%, neuroticism is determined by category weights alone
            // Categories like Health, Wellness have negative neuroticism weights
            // which will naturally reduce neuroticism for users completing those habits

        } else {
            // Fallback to original completion rate analysis
            let avgCompletionRate = input.completionRates.reduce(0.0, +) / Double(max(input.completionRates.count, 1))
            let conscientiousnessBonus = (avgCompletionRate - 0.5) * 0.3
            traitAccumulators[.conscientiousness, default: 0.0] += conscientiousnessBonus
            totalWeights[.conscientiousness, default: 0.0] += 0.3

            // Add neuroticism signal only for very low completion
            if avgCompletionRate < 0.3 {
                let struggleSeverity = (0.3 - avgCompletionRate) / 0.3
                let instabilityContribution = 0.4 + (struggleSeverity * 0.4)
                traitAccumulators[.neuroticism, default: 0.0] += instabilityContribution
                totalWeights[.neuroticism, default: 0.0] += 0.5
            }
        }
        
        // Analyze habit diversity (openness to experience) - TERTIARY signal
        // Openness is primarily determined by category weights (Learning, Creativity categories)
        // Diversity only adds a small bonus
        let diversityScore = Double(input.habitCategories.count) / 10.0
        let diversityBonus = min(diversityScore, 0.5) * 0.15 // Small bonus, max 0.075
        traitAccumulators[.openness, default: 0.0] += diversityBonus
        totalWeights[.openness, default: 0.0] += 0.15
        
        // Analyze scheduling patterns (extraversion for social/evening habits)
        let socialHabits = input.customHabits.filter { habit in
            habit.name.localizedCaseInsensitiveContains("social") ||
            habit.name.localizedCaseInsensitiveContains("meet") ||
            habit.name.localizedCaseInsensitiveContains("friend")
        }
        
        if !input.customHabits.isEmpty {
            let socialRatio = Double(socialHabits.count) / Double(input.customHabits.count)
            let extraversionBonus = socialRatio * 0.25
            traitAccumulators[.extraversion, default: 0.0] += extraversionBonus
            totalWeights[.extraversion, default: 0.0] += 0.25
        }
        
        
        // Normalization with evidence strength consideration
        // Traits with more evidence should have more impact than traits with little evidence
        var normalizedScores: [PersonalityTrait: Double] = [:]
        let maxTotalWeight = totalWeights.values.max() ?? 1.0

        for trait in PersonalityTrait.allCases {
            let accumulator = traitAccumulators[trait, default: 0.0]
            let totalWeight = totalWeights[trait, default: 0.0]

            if totalWeight > 0.001 {
                // Calculate base ratio: accumulator / totalWeight gives -1 to 1 range
                let ratio = accumulator / totalWeight
                let clampedRatio = max(-1.0, min(1.0, ratio))

                // Convert to 0-1 range (base score)
                let baseScore = (clampedRatio + 1.0) / 2.0

                // Evidence strength: linear scaling based on relative evidence
                // This ensures traits with more evidence get higher final scores
                // and breaks ties between close traits like extraversion vs agreeableness
                let relativeEvidence = totalWeight / maxTotalWeight
                let evidenceStrength = relativeEvidence

                // Apply evidence dampening: weak evidence → score closer to 0.5
                let adjustedScore = 0.5 + (baseScore - 0.5) * evidenceStrength
                normalizedScores[trait] = adjustedScore
            } else {
                // No data for this trait - default to neutral
                normalizedScores[trait] = 0.5
            }
        }
        
        return (scores: normalizedScores, accumulators: traitAccumulators, totalWeights: totalWeights)
    }
    // swiftlint:enable function_body_length
    
    nonisolated public func determineDominantTrait(from scores: [PersonalityTrait: Double]) -> PersonalityTrait {
        return scores.max(by: { $0.value < $1.value })?.key ?? .conscientiousness
    }
    
    /// Determine dominant trait with sophisticated multi-criteria tie-breaking
    nonisolated public func determineDominantTraitWithTieBreaking(
        from scores: [PersonalityTrait: Double],
        traitAccumulators: [PersonalityTrait: Double],
        totalWeights: [PersonalityTrait: Double],
        input: HabitAnalysisInput
    ) -> PersonalityTrait {
        // Find the highest score
        let maxScore = scores.values.max() ?? 0.0
        let topTraits = scores.filter { $0.value == maxScore }
        
        if topTraits.count == 1 {
            return topTraits.first!.key
        }
        
        // Multi-criteria tie-breaking system
        
        var traitScores: [(trait: PersonalityTrait, score: Double)] = []
        
        for (trait, _) in topTraits {
            var tieBreakScore = 0.0
            
            // Criteria 1: Raw accumulator precision (weight: 40%)
            let rawScore = traitAccumulators[trait, default: 0.0]
            tieBreakScore += rawScore * 0.4
            
            // Criteria 2: Evidence diversity (weight: 30%)
            // Count different sources of evidence for this trait
            var evidenceSources = 0
            
            // Check predefined categories
            for category in input.habitCategories where category.isPredefined {
                if let weights = category.personalityWeights,
                   let weight = weights[trait.rawValue],
                   abs(weight) > 0.001 {
                    evidenceSources += 1
                }
            }
            
            // Check custom categories
            for category in input.customCategories {
                let categoryHabits = input.customHabits.filter { $0.categoryId == category.id }
                if !categoryHabits.isEmpty {
                    evidenceSources += 1
                }
            }
            
            // Check behavioral bonuses
            if trait == .conscientiousness && !input.completionRates.isEmpty {
                evidenceSources += 1
            }
            if trait == .openness && input.habitCategories.count > 1 {
                evidenceSources += 1
            }
            if trait == .extraversion && !input.customHabits.isEmpty {
                evidenceSources += 1
            }
            
            let diversityScore = Double(evidenceSources) / 10.0 // Normalize
            tieBreakScore += diversityScore * 0.3
            
            // Criteria 3: Trait stability preference (weight: 20%)
            // Prefer traits that are generally more stable/foundational
            let stabilityScore = traitStabilityWeight(trait)
            tieBreakScore += stabilityScore * 0.2
            
            // Criteria 4: Data recency bonus (weight: 10%)
            // Prefer traits with more recent evidence
            let recencyBonus = trait == .conscientiousness ? 0.1 : 0.0 // Completion data is most recent
            tieBreakScore += recencyBonus * 0.1
            
            traitScores.append((trait: trait, score: tieBreakScore))
            
        }
        
        // Sort by final tie-break score
        traitScores.sort { $0.score > $1.score }
        
        let winner = traitScores.first!.trait
        return winner
    }
    
    /// Returns stability weight for personality traits (higher = more foundational)
    private func traitStabilityWeight(_ trait: PersonalityTrait) -> Double {
        switch trait {
        case .conscientiousness: return 0.9  // Most stable - relates to habits directly
        case .openness: return 0.8           // Stable - intellectual openness
        case .neuroticism: return 0.7        // Moderately stable - emotional patterns
        case .agreeableness: return 0.6      // Less stable - social context dependent  
        case .extraversion: return 0.5       // Least stable - varies by situation
        }
    }
    
    nonisolated public func calculateConfidence(from metadata: AnalysisMetadata) -> ConfidenceLevel {
        let dataPoints = Double(metadata.dataPointsAnalyzed)
        
        // Confidence based on amount of data analyzed
        // Updated thresholds to reflect enhanced individual habit completion rate analysis
        switch dataPoints {
        case 0..<30:
            return .low
        case 30..<75:
            return .medium
        case 75..<150:
            return .high
        default:
            return .veryHigh
        }
    }
    
    /// Enhanced confidence calculation that considers completion statistics quality
    nonisolated public func calculateConfidenceWithCompletionStats(from metadata: AnalysisMetadata, completionStats: HabitCompletionStats) -> ConfidenceLevel {
        let baseDataPoints = Double(metadata.dataPointsAnalyzed)
        
        // Adjust confidence based on completion statistics quality
        var adjustedDataPoints = baseDataPoints
        
        // Schedule-aware completion data is higher quality - boost confidence
        if completionStats.totalHabits > 0 {
            // Bonus for having habit diversity
            let diversityBonus = min(Double(completionStats.totalHabits) * 2.0, 20.0)
            adjustedDataPoints += diversityBonus
            
            // Bonus for completion rate quality (very high or very low rates are more informative)
            let completionRate = completionStats.completionRate
            if completionRate > 0.8 || completionRate < 0.2 {
                adjustedDataPoints += 15.0 // Strong signal bonus
            } else if completionRate > 0.6 || completionRate < 0.4 {
                adjustedDataPoints += 8.0 // Moderate signal bonus
            }
            
            // Bonus for habit consistency (some habits are clearly successful vs unsuccessful)
            if completionStats.totalHabits > 0 {
                let consistencyRatio = Double(completionStats.completedHabits) / Double(completionStats.totalHabits)
                if consistencyRatio > 0.7 || consistencyRatio < 0.3 {
                    adjustedDataPoints += 10.0 // Clear patterns bonus
                }
            }
        }
        
        // Enhanced confidence thresholds
        switch adjustedDataPoints {
        case 0..<35:
            return .low
        case 35..<85:
            return .medium
        case 85..<160:
            return .high
        default:
            return .veryHigh
        }
    }
    
    /// Infers personality weights for custom categories based on behavior patterns
    /// Entry point with device capability check - switches between ML and keyword implementations
    private func inferPersonalityWeights(for category: HabitCategory, habits: [Habit], allLogs: [Double]) -> [String: Double] {
        // Device capability check - use ML on iOS 17+ with NLEmbedding support
        if #available(iOS 17.0, *), let _ = NLEmbedding.wordEmbedding(for: .english) {
            return inferPersonalityWeightsML(for: category, habits: habits, allLogs: allLogs)
        } else {
            return inferPersonalityWeightsKeyword(for: category, habits: habits, allLogs: allLogs)
        }
    }

    /// Infers personality weights from habit names only (for predefined categories)
    /// Uses ML semantic analysis when available, falls back to keywords
    private func inferSemanticWeightsFromHabits(habits: [Habit], completionRates: [Double]) -> [String: Double] {
        // Device capability check - use ML on iOS 17+ with NLEmbedding support
        if #available(iOS 17.0, *), let _ = NLEmbedding.wordEmbedding(for: .english) {
            return inferSemanticWeightsFromHabitsML(habits: habits, completionRates: completionRates)
        } else {
            return inferSemanticWeightsFromHabitsKeyword(habits: habits, completionRates: completionRates)
        }
    }

    /// ML-based semantic weight inference from habit names only
    @available(iOS 17.0, *)
    private func inferSemanticWeightsFromHabitsML(habits: [Habit], completionRates: [Double]) -> [String: Double] {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            // Fallback to keyword if embedding unavailable
            return inferSemanticWeightsFromHabitsKeyword(habits: habits, completionRates: completionRates)
        }

        var weights: [String: Double] = [:]

        // Combine habit names for semantic analysis
        let allText = habits.map { $0.name }.joined(separator: ". ")
        let allTextLower = allText.lowercased()

        // Calculate semantic similarity for each trait
        for trait in PersonalityTrait.allCases {
            let similarity = calculateSemanticSimilarity(
                text: allText,
                trait: trait,
                embedding: embedding
            )

            // Convert similarity (0.0-1.0) to weight (0.05-0.5 range)
            if similarity > 0.3 {
                weights[trait.rawValue] = 0.05 + (similarity - 0.3) * 0.64
            } else {
                weights[trait.rawValue] = 0.05
            }
        }

        // CRITICAL: Check for coping/wellness keywords that REDUCE neuroticism
        // These habits help manage stress, so they should have NEGATIVE neuroticism
        let copingKeywords = ["mindful", "calm", "stability", "self-care", "therapy", "coping",
                               "manage", "relax", "peaceful", "serene", "balanced", "grounded",
                               "meditat", "breath", "zen", "tranquil", "wellness", "yoga"]
        let hasCopingKeywords = copingKeywords.contains { allTextLower.contains($0) }

        let stressKeywords = ["stress", "anxiety", "worry", "overwhelm", "tension", "nervous"]
        let hasStressKeywords = stressKeywords.contains { allTextLower.contains($0) }

        if hasCopingKeywords && !hasStressKeywords {
            // Coping habits WITHOUT stress keywords → reduce neuroticism
            weights["neuroticism"] = -0.3
        } else if hasStressKeywords && !hasCopingKeywords {
            // Stress keywords WITHOUT coping → high neuroticism (keep ML result or boost)
            weights["neuroticism"] = max(weights["neuroticism"] ?? 0.05, 0.4)
        }

        // Enhance with completion rate behavior
        let avgCompletionRate = completionRates.reduce(0.0, +) / Double(max(completionRates.count, 1))

        if avgCompletionRate > 0.7 {
            weights["conscientiousness"] = max(weights["conscientiousness"] ?? 0.05, 0.4)
        }

        if avgCompletionRate < 0.3 {
            weights["neuroticism"] = max(weights["neuroticism"] ?? 0.05, 0.35)
        }

        return weights
    }

    /// Keyword-based semantic weight inference from habit names only
    private func inferSemanticWeightsFromHabitsKeyword(habits: [Habit], completionRates: [Double]) -> [String: Double] {
        var weights: [String: Double] = [
            "openness": 0.05,
            "conscientiousness": 0.05,
            "extraversion": 0.05,
            "agreeableness": 0.05,
            "neuroticism": 0.05
        ]

        let allText = habits.map { $0.name }.joined(separator: " ").lowercased()

        // OPENNESS keywords
        let opennessKeywords = ["new", "learn", "explore", "creative", "experiment", "try",
                                "photography", "art", "music", "innovation", "discover", "curious",
                                "novel", "adventure", "imagination", "travel", "culture", "language"]
        let opennessMatches = opennessKeywords.filter { allText.contains($0) }
        if !opennessMatches.isEmpty {
            weights["openness"] = 0.5
        }

        // CONSCIENTIOUSNESS keywords
        let conscientiousnessKeywords = ["plan", "organize", "routine", "track", "goal", "schedule",
                                          "review", "discipline", "achievement", "complete", "morning",
                                          "evening", "daily", "system", "structure", "checklist",
                                          "preparation", "productivity", "order", "arrangement"]
        let conscientiousnessMatches = conscientiousnessKeywords.filter { allText.contains($0) }
        if !conscientiousnessMatches.isEmpty {
            weights["conscientiousness"] = 0.5
        }

        // EXTRAVERSION keywords
        let extraversionKeywords = ["social", "friend", "meet", "call", "visit", "party", "group",
                                     "team", "networking", "event", "gathering", "club", "collaborate",
                                     "community", "people", "conversation", "interaction", "outgoing"]
        let extraversionMatches = extraversionKeywords.filter { allText.contains($0) }
        if !extraversionMatches.isEmpty {
            weights["extraversion"] = 0.5
        }

        // AGREEABLENESS keywords
        let agreeablenessKeywords = ["love", "care", "help", "family", "relationship", "volunteer",
                                      "support", "kindness", "donate", "compassion", "empathy", "charity",
                                      "giving", "nurturing", "altruism", "cooperation", "harmony"]
        let agreeablenessMatches = agreeablenessKeywords.filter { allText.contains($0) }
        if !agreeablenessMatches.isEmpty {
            weights["agreeableness"] = 0.5
        }

        // NEUROTICISM - Split into stress indicators (positive) and coping indicators (negative)
        // Stress keywords indicate high neuroticism (anxiety, worry)
        let stressKeywords = ["stress", "anxiety", "worry", "overwhelm", "tension", "nervous",
                               "concern", "panic", "fear", "distress", "upset", "frustrated"]
        let stressMatches = stressKeywords.filter { allText.contains($0) }

        // Coping keywords indicate LOW neuroticism (managing stress successfully)
        let copingKeywords = ["mindful", "calm", "stability", "self-care", "therapy", "coping",
                               "manage", "relax", "peaceful", "serene", "balanced", "grounded",
                               "meditat", "breath", "zen", "tranquil"]
        let copingMatches = copingKeywords.filter { allText.contains($0) }

        if !stressMatches.isEmpty && copingMatches.isEmpty {
            // Only stress keywords - high neuroticism
            weights["neuroticism"] = 0.5
        } else if !copingMatches.isEmpty && stressMatches.isEmpty {
            // Only coping keywords - LOW neuroticism (these habits reduce stress)
            weights["neuroticism"] = -0.3
        } else if !stressMatches.isEmpty && !copingMatches.isEmpty {
            // Both - mixed signal, slight positive (acknowledging stress but coping)
            weights["neuroticism"] = 0.1
        }
        // If neither, keep baseline 0.05

        // Enhance with completion rate behavior
        let avgCompletionRate = completionRates.reduce(0.0, +) / Double(max(completionRates.count, 1))

        if avgCompletionRate > 0.7 {
            weights["conscientiousness"] = max(weights["conscientiousness"] ?? 0.05, 0.4)
        }

        if avgCompletionRate < 0.3 {
            weights["neuroticism"] = max(weights["neuroticism"] ?? 0.05, 0.35)
        }

        return weights
    }

    /// Keyword-based personality weight inference (legacy implementation for iOS <17)
    private func inferPersonalityWeightsKeyword(for category: HabitCategory, habits: [Habit], allLogs: [Double]) -> [String: Double] {
        // Start with neutral baseline - using consistent ordering to prevent fluctuations
        var weights: [String: Double] = [
            "openness": 0.05,
            "conscientiousness": 0.05,
            "extraversion": 0.05,
            "agreeableness": 0.05,
            "neuroticism": 0.05
        ]

        // Combine habit names and category name for comprehensive keyword analysis
        let allText = ([category.name, category.displayName] + habits.map { $0.name }).joined(separator: " ").lowercased()

        // Behavior-based inference
        if !habits.isEmpty {
            // OPENNESS: Creativity, exploration, learning, novelty
            let opennessKeywords = ["new", "learn", "explore", "creative", "experiment", "try",
                                    "photography", "art", "music", "innovation", "discover", "curious",
                                    "novel", "adventure", "imagination", "travel", "culture", "language"]
            let opennessMatches = opennessKeywords.filter { allText.contains($0) }
            if !opennessMatches.isEmpty {
                weights["openness"] = 0.5
            } else {
                // Variety of different habits = Openness (fallback)
                let uniqueHabitTypes = Set(habits.map { $0.name.prefix(3) })
                if uniqueHabitTypes.count >= 3 && habits.count >= 3 {
                    weights["openness"] = 0.25
                }
            }

            // CONSCIENTIOUSNESS: Organization, planning, discipline, achievement
            let conscientiousnessKeywords = ["plan", "organize", "routine", "track", "goal", "schedule",
                                              "review", "discipline", "achievement", "complete", "morning",
                                              "evening", "daily", "system", "structure", "checklist",
                                              "preparation", "productivity", "order", "arrangement"]
            let conscientiousnessMatches = conscientiousnessKeywords.filter { allText.contains($0) }
            if !conscientiousnessMatches.isEmpty {
                weights["conscientiousness"] = 0.5
            } else {
                // High consistency = Conscientiousness (fallback)
                let avgCompletionRate = allLogs.reduce(0.0, +) / Double(max(allLogs.count, 1))
                if avgCompletionRate > 0.7 {
                    weights["conscientiousness"] = 0.3
                }
            }

            // EXTRAVERSION: Social interaction, energy, enthusiasm
            let extraversionKeywords = ["social", "friend", "meet", "call", "visit", "party", "group",
                                         "team", "networking", "event", "gathering", "club", "collaborate",
                                         "community", "people", "conversation", "interaction", "outgoing"]
            let extraversionMatches = extraversionKeywords.filter { allText.contains($0) }
            if !extraversionMatches.isEmpty {
                weights["extraversion"] = 0.5
            }

            // AGREEABLENESS: Compassion, cooperation, caring
            let agreeablenessKeywords = ["love", "care", "help", "family", "relationship", "volunteer",
                                          "support", "kindness", "donate", "compassion", "empathy", "charity",
                                          "giving", "nurturing", "altruism", "cooperation", "harmony"]
            let agreeablenessMatches = agreeablenessKeywords.filter { allText.contains($0) }
            if !agreeablenessMatches.isEmpty {
                weights["agreeableness"] = 0.5
            }

            // NEUROTICISM - Split into stress indicators (positive) and coping indicators (negative)
            // Stress keywords indicate high neuroticism (anxiety, worry)
            let stressKeywords = ["stress", "anxiety", "worry", "overwhelm", "tension", "nervous",
                                   "concern", "panic", "fear", "distress", "upset", "frustrated"]
            let stressMatches = stressKeywords.filter { allText.contains($0) }

            // Coping keywords indicate LOW neuroticism (managing stress successfully)
            let copingKeywords = ["mindful", "calm", "stability", "self-care", "therapy", "coping",
                                   "manage", "relax", "peaceful", "serene", "balanced", "grounded",
                                   "meditat", "breath", "zen", "tranquil"]
            let copingMatches = copingKeywords.filter { allText.contains($0) }

            if !stressMatches.isEmpty && copingMatches.isEmpty {
                // Only stress keywords - high neuroticism
                weights["neuroticism"] = 0.5
            } else if !copingMatches.isEmpty && stressMatches.isEmpty {
                // Only coping keywords - LOW neuroticism (these habits reduce stress)
                weights["neuroticism"] = -0.3
            } else if !stressMatches.isEmpty && !copingMatches.isEmpty {
                // Both - mixed signal, slight positive (acknowledging stress but coping)
                weights["neuroticism"] = 0.1
            } else {
                // No emotional keywords - check completion rate fallback
                let avgCompletionRate = allLogs.reduce(0.0, +) / Double(max(allLogs.count, 1))
                if avgCompletionRate < 0.3 {
                    weights["neuroticism"] = 0.3
                }
            }
        }

        return weights
    }

    /// ML-based personality weight inference using NLEmbedding (iOS 17+)
    @available(iOS 17.0, *)
    private func inferPersonalityWeightsML(for category: HabitCategory, habits: [Habit], allLogs: [Double]) -> [String: Double] {
        guard let embedding = NLEmbedding.wordEmbedding(for: .english) else {
            // Fallback to keyword if embedding unavailable
            return inferPersonalityWeightsKeyword(for: category, habits: habits, allLogs: allLogs)
        }

        var weights: [String: Double] = [:]

        // Combine category name + habit names for semantic analysis
        let allText = ([category.name, category.displayName] + habits.map { $0.name })
            .joined(separator: ". ")
        let allTextLower = allText.lowercased()

        // Calculate semantic similarity for each trait
        for trait in PersonalityTrait.allCases {
            let similarity = calculateSemanticSimilarity(
                text: allText,
                trait: trait,
                embedding: embedding
            )

            // Convert similarity (0.0-1.0) to weight (0.05-0.5 range)
            // Threshold: only assign significant weight if similarity > 0.3
            if similarity > 0.3 {
                weights[trait.rawValue] = 0.05 + (similarity - 0.3) * 0.64 // Maps 0.3-1.0 → 0.05-0.5
            } else {
                weights[trait.rawValue] = 0.05 // Baseline
            }
        }

        // CRITICAL: Check for coping/wellness keywords that REDUCE neuroticism
        let copingKeywords = ["mindful", "calm", "stability", "self-care", "therapy", "coping",
                               "manage", "relax", "peaceful", "serene", "balanced", "grounded",
                               "meditat", "breath", "zen", "tranquil", "wellness", "yoga"]
        let hasCopingKeywords = copingKeywords.contains { allTextLower.contains($0) }

        let stressKeywords = ["stress", "anxiety", "worry", "overwhelm", "tension", "nervous"]
        let hasStressKeywords = stressKeywords.contains { allTextLower.contains($0) }

        if hasCopingKeywords && !hasStressKeywords {
            // Coping habits WITHOUT stress keywords → reduce neuroticism
            weights["neuroticism"] = -0.3
        } else if hasStressKeywords && !hasCopingKeywords {
            // Stress keywords WITHOUT coping → high neuroticism
            weights["neuroticism"] = max(weights["neuroticism"] ?? 0.05, 0.4)
        }

        // Enhance with behavior-based analysis (completion rates)
        let avgCompletionRate = allLogs.reduce(0.0, +) / Double(max(allLogs.count, 1))

        // High completion rate boosts conscientiousness
        if avgCompletionRate > 0.7 {
            weights["conscientiousness"] = max(weights["conscientiousness"] ?? 0.05, 0.4)
        }

        // Low completion rate suggests neuroticism
        if avgCompletionRate < 0.3 {
            weights["neuroticism"] = max(weights["neuroticism"] ?? 0.05, 0.35)
        }

        return weights
    }

    /// Calculate semantic similarity between text and personality trait using embeddings
    @available(iOS 17.0, *)
    private func calculateSemanticSimilarity(
        text: String,
        trait: PersonalityTrait,
        embedding: NLEmbedding
    ) -> Double {
        // Get embedding for habit/category text
        guard let textVector = embedding.vector(for: text.lowercased()) else {
            return 0.0
        }

        // Trait descriptors - semantic phrases that define each trait
        let traitDescriptors = getTraitDescriptors(for: trait)

        // Calculate similarity to each trait descriptor, take maximum
        var maxSimilarity = 0.0
        for descriptor in traitDescriptors {
            guard let descriptorVector = embedding.vector(for: descriptor) else { continue }
            let similarity = cosineSimilarity(textVector, descriptorVector)
            maxSimilarity = max(maxSimilarity, similarity)
        }

        return maxSimilarity
    }

    /// Get semantic descriptors for each personality trait
    private func getTraitDescriptors(for trait: PersonalityTrait) -> [String] {
        switch trait {
        case .openness:
            return [
                "creativity imagination innovation",
                "curiosity exploration discovery",
                "learning new experiences adventure",
                "artistic expression photography music",
                "intellectual openness ideas culture"
            ]
        case .conscientiousness:
            return [
                "organization planning structure",
                "discipline routine consistency",
                "goal achievement productivity",
                "responsibility reliability punctuality",
                "order systems preparation"
            ]
        case .extraversion:
            return [
                "social interaction friends people",
                "outgoing energy enthusiasm",
                "networking community collaboration",
                "conversation communication talking",
                "group activities team events"
            ]
        case .agreeableness:
            return [
                "compassion empathy kindness",
                "cooperation harmony helping",
                "caring nurturing supportive",
                "altruism charity volunteering",
                "relationships family love"
            ]
        case .neuroticism:
            // ONLY stress/anxiety indicators - NOT coping mechanisms (those reduce neuroticism)
            return [
                "stress anxiety worry concern",
                "emotional instability mood swings",
                "nervous tension overwhelm panic",
                "fear distress upset frustrated",
                "insecurity vulnerability sensitivity"
            ]
        }
    }

    /// Calculate cosine similarity between two vectors
    private func cosineSimilarity(_ vec1: [Double], _ vec2: [Double]) -> Double {
        guard vec1.count == vec2.count, vec1.count > 0 else { return 0.0 }

        let dotProduct = zip(vec1, vec2).map(*).reduce(0, +)
        let magnitude1 = sqrt(vec1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(vec2.map { $0 * $0 }.reduce(0, +))

        guard magnitude1 > 0, magnitude2 > 0 else { return 0.0 }
        return dotProduct / (magnitude1 * magnitude2)
    }

    /// Calculate habit-specific modifiers based on individual habit characteristics
    nonisolated private func calculateHabitSpecificModifiers(habit: Habit, input: HabitAnalysisInput) -> [PersonalityTrait: Double] {
        var modifiers: [PersonalityTrait: Double] = [:]

        // Get completion rate for this habit to inform modifier decisions
        let completionRate = getCompletionRateForHabit(habit: habit, input: input)

        // 1. Habit name analysis for personality indicators
        let habitName = habit.name.lowercased()

        // Conscientiousness indicators
        if habitName.contains("daily") || habitName.contains("routine") || habitName.contains("schedule") {
            modifiers[.conscientiousness] = 1.2  // +20% boost
        }
        if habitName.contains("organize") || habitName.contains("plan") || habitName.contains("prepare") {
            modifiers[.conscientiousness] = 1.3  // +30% boost
        }

        // Openness indicators - ONLY boost if user is actually completing these habits
        // At low completion, these habits don't demonstrate openness, just intent
        if habitName.contains("learn") || habitName.contains("study") || habitName.contains("explore") {
            if completionRate > 0.5 {
                modifiers[.openness] = 1.2
            } else if completionRate < 0.3 {
                modifiers[.openness] = 0.9 // Reduce openness signal for unfollowed "exploration" habits
            }
        }
        if habitName.contains("creative") || habitName.contains("art") || habitName.contains("music") {
            if completionRate > 0.5 {
                modifiers[.openness] = 1.4  // Strong creativity boost
            } else if completionRate < 0.3 {
                modifiers[.openness] = 0.85
            }
        }
        if habitName.contains("new") || habitName.contains("try") || habitName.contains("experiment") {
            if completionRate > 0.5 {
                modifiers[.openness] = 1.3
            } else if completionRate < 0.3 {
                modifiers[.openness] = 0.85
            }
        }

        // Extraversion indicators
        if habitName.contains("social") || habitName.contains("people") || habitName.contains("friend") {
            modifiers[.extraversion] = 1.3
        }
        if habitName.contains("call") || habitName.contains("meet") || habitName.contains("visit") {
            modifiers[.extraversion] = 1.2
        }
        if habitName.contains("party") || habitName.contains("event") || habitName.contains("gathering") {
            modifiers[.extraversion] = 1.4
        }

        // Agreeableness indicators
        if habitName.contains("help") || habitName.contains("volunteer") || habitName.contains("support") {
            modifiers[.agreeableness] = 1.3
        }
        if habitName.contains("family") || habitName.contains("love") || habitName.contains("care") {
            modifiers[.agreeableness] = 1.2
        }
        if habitName.contains("donate") || habitName.contains("charity") || habitName.contains("give") {
            modifiers[.agreeableness] = 1.4
        }

        // Neuroticism modifiers - completion rate determines if coping or struggling
        let hasNeuroticismKeywords = habitName.contains("stress") || habitName.contains("anxiety") ||
                                      habitName.contains("worry") || habitName.contains("mood") ||
                                      habitName.contains("therapy") || habitName.contains("coping")
        let hasCalmnessKeywords = habitName.contains("meditat") || habitName.contains("calm") ||
                                   habitName.contains("relax") || habitName.contains("mindful") ||
                                   habitName.contains("breath") || habitName.contains("zen")

        if hasNeuroticismKeywords || hasCalmnessKeywords {
            // Completion rate determines interpretation:
            // - High completion (>0.6): Successfully coping → reduce neuroticism
            // - Low completion (<0.4): Struggling with these habits → increase neuroticism
            // - Medium completion: Neutral
            if completionRate > 0.6 {
                // Successfully managing stress/emotions
                modifiers[.neuroticism] = hasCalmnessKeywords ? 0.6 : 0.8
                modifiers[.conscientiousness] = 1.1
            } else if completionRate < 0.4 {
                // Struggling - indicates higher neuroticism
                modifiers[.neuroticism] = hasNeuroticismKeywords ? 1.4 : 1.2
            }
            // Medium completion: no modifier (neutral)
        }
        
        // 2. Habit frequency analysis
        switch habit.schedule {
        case .daily:
            // Daily habits show higher conscientiousness
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.1
        case .daysOfWeek(let days):
            // Specific day patterns show planning (conscientiousness) and some flexibility (openness)
            // But only boost openness if completion rate is decent (actually following through)
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.05
            if days.count <= 3 && completionRate > 0.5 {
                // Selective days with good follow-through suggest thoughtful planning
                modifiers[.openness] = (modifiers[.openness] ?? 1.0) * 1.05
            }
        }
        
        // 3. Habit type analysis
        switch habit.kind {
        case .binary:
            // Binary habits are often more straightforward - slight conscientiousness boost
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.02
        case .numeric:
            // Numeric tracking shows more detailed approach - conscientiousness boost
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.05
        }
        
        // 4. Reminder analysis - more reminders suggest need for external structure
        let reminderCount = habit.reminders.count
        if reminderCount >= 3 {
            // High reminder count suggests need for structure but lower natural conscientiousness
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 0.95
            modifiers[.neuroticism] = (modifiers[.neuroticism] ?? 1.0) * 1.1
        } else if reminderCount == 0 {
            // No reminders suggests self-discipline
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.1
        }
        
        // 5. Daily target analysis - check if habit has high daily targets
        if let dailyTarget = habit.dailyTarget, dailyTarget > 5 {
            // High targets suggest ambition and conscientiousness
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.1
        }
        
        return modifiers
    }
    
    /// Get the completion rate for a specific habit from the analysis input
    nonisolated private func getCompletionRateForHabit(habit: Habit, input: HabitAnalysisInput) -> Double {
        // Find the index of this habit in the activeHabits array
        guard let habitIndex = input.activeHabits.firstIndex(where: { $0.id == habit.id }) else {
            // Habit not found - use average completion rate as fallback
            // This prevents 0.0 completion from incorrectly flipping negative weights
            let avgRate = input.completionRates.isEmpty ? 0.5 :
                input.completionRates.reduce(0.0, +) / Double(input.completionRates.count)
            return avgRate
        }

        // Check if we have a completion rate for this index
        guard habitIndex < input.completionRates.count else {
            // No completion rate data - use average as fallback
            let avgRate = input.completionRates.isEmpty ? 0.5 :
                input.completionRates.reduce(0.0, +) / Double(input.completionRates.count)
            return avgRate
        }

        return input.completionRates[habitIndex]
    }
}