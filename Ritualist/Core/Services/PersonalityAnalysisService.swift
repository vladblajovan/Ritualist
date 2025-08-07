//
//  PersonalityAnalysisService.swift
//  Ritualist
//
//  Created by Claude on 06.08.2025.
//

import Foundation

/// Service responsible for analyzing user behavior and calculating personality traits
public protocol PersonalityAnalysisService {
    /// Perform comprehensive personality analysis for a user
    func analyzePersonality(for userId: UUID) async throws -> PersonalityProfile
    
    /// Calculate personality scores from habit analysis input
    func calculatePersonalityScores(from input: HabitAnalysisInput) -> [PersonalityTrait: Double]
    
    /// Determine dominant trait from scores
    func determineDominantTrait(from scores: [PersonalityTrait: Double]) -> PersonalityTrait
    
    /// Calculate confidence level for analysis
    func calculateConfidence(from metadata: AnalysisMetadata) -> ConfidenceLevel
}

// swiftlint:disable function_body_length type_body_length
public final class DefaultPersonalityAnalysisService: PersonalityAnalysisService {
    
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func analyzePersonality(for userId: UUID) async throws -> PersonalityProfile {
        // Get input data for analysis
        let input = try await repository.getHabitAnalysisInput(for: userId)
        
        // Get enhanced completion statistics with schedule-aware calculations
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        let completionStats = try await repository.getHabitCompletionStats(for: userId, from: startDate, to: endDate)
        
        // Calculate personality scores with enhanced data
        let (traitScores, accumulators, weights) = calculatePersonalityScoresWithDetails(
            from: input, 
            completionStats: completionStats
        )
        
        // Determine dominant trait with intelligent tie-breaking
        let dominantTrait = determineDominantTraitWithTieBreaking(
            from: traitScores,
            traitAccumulators: accumulators,
            totalWeights: weights,
            input: input
        )
        
        // Create metadata with enhanced data points
        let enhancedDataPoints = input.totalDataPoints + (completionStats.totalHabits > 0 ? 10 : 0)
        let metadata = AnalysisMetadata(
            analysisDate: Date(),
            dataPointsAnalyzed: enhancedDataPoints,
            timeRangeAnalyzed: input.analysisTimeRange,
            version: "1.1"
        )
        
        // Calculate confidence with enhanced completion data
        let confidence = calculateConfidenceWithCompletionStats(from: metadata, completionStats: completionStats)
        
        // Create profile
        let profile = PersonalityProfile(
            id: UUID(),
            userId: userId,
            traitScores: traitScores,
            dominantTrait: dominantTrait,
            confidence: confidence,
            analysisMetadata: metadata
        )
        
        return profile
    }
    
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
        
        // Analyze habit selections from suggestions
        for suggestion in input.selectedSuggestions {
            guard let weights = suggestion.personalityWeights else { 
                continue 
            }
            
            for (traitKey, weight) in weights {
                if let trait = PersonalityTrait(rawValue: traitKey) {
                    traitAccumulators[trait, default: 0.0] += weight
                    totalWeights[trait, default: 0.0] += abs(weight)
                }
            }
        }
        
        // CRITICAL FIX: Analyze predefined category habits
        
        // Group active habits by predefined category
        var habitsByPredefinedCategory: [String: [Habit]] = [:]
        for habit in input.activeHabits {
            guard let categoryId = habit.categoryId else { continue }
            guard let category = input.habitCategories.first(where: { $0.id == categoryId && $0.isPredefined }) else { continue }
            habitsByPredefinedCategory[categoryId, default: []].append(habit)
        }
        
        // Process each predefined category
        for (categoryId, categoryHabits) in habitsByPredefinedCategory {
            guard let category = input.habitCategories.first(where: { $0.id == categoryId }) else { continue }
            guard let weights = category.personalityWeights else { continue }
            
            
            // Distribute category weight across habits in that category
            let habitWeight = 1.0 / Double(categoryHabits.count)
            
            // Apply weights for each habit in this category with specific modifiers and completion weighting
            for habit in categoryHabits {
                
                // Get individual habit completion rate
                let completionRate = getCompletionRateForHabit(habit: habit, input: input)
                
                // Calculate habit-specific modifiers
                let habitModifiers = calculateHabitSpecificModifiers(habit: habit, input: input)
                
                // Calculate completion-based weighting (0.3 to 1.0 range)
                // High completion rates get full weight, low completion rates get reduced weight
                let completionWeighting = 0.3 + (completionRate * 0.7)
                
                for (traitKey, categoryWeight) in weights {
                    if let trait = PersonalityTrait(rawValue: traitKey) {
                        // Apply habit-specific modifier and completion weighting to base category weight
                        let habitModifier = habitModifiers[trait] ?? 1.0
                        let modifiedWeight = categoryWeight * habitModifier * completionWeighting
                        let contribution = modifiedWeight * habitWeight
                        
                        traitAccumulators[trait, default: 0.0] += contribution
                        totalWeights[trait, default: 0.0] += abs(contribution)
                        
                    }
                }
            }
        }
        
        
        // Analyze custom habit categories
        for category in input.customCategories {
            let categoryHabits = input.customHabits.filter { $0.categoryId == category.id }
            
            // Use explicit weights if available, otherwise infer from behavior
            var weights = category.personalityWeights
            if weights == nil {
                weights = inferPersonalityWeights(for: category, habits: categoryHabits, allLogs: input.completionRates)
            }
            
            let categoryWeight = Double(categoryHabits.count) / Double(max(input.customHabits.count, 1))
            
            if let weights = weights {
                // Calculate average completion rate for habits in this custom category
                let categoryCompletionRates = categoryHabits.compactMap { habit in
                    getCompletionRateForHabit(habit: habit, input: input)
                }
                let avgCategoryCompletion = categoryCompletionRates.isEmpty ? 0.5 : 
                    categoryCompletionRates.reduce(0.0, +) / Double(categoryCompletionRates.count)
                let categoryCompletionWeighting = 0.3 + (avgCategoryCompletion * 0.7)
                
                
                for (traitKey, weight) in weights {
                    if let trait = PersonalityTrait(rawValue: traitKey) {
                        let contribution = weight * categoryWeight * categoryCompletionWeighting
                        traitAccumulators[trait, default: 0.0] += contribution
                        totalWeights[trait, default: 0.0] += abs(contribution)
                        
                    }
                }
            }
        }
        
        // Analyze completion rates with enhanced schedule-aware statistics
        if let stats = completionStats, stats.totalHabits > 0 {
            // Use enhanced schedule-aware completion rate
            let scheduleAwareCompletionRate = stats.completionRate
            let conscientiousnessBonus = (scheduleAwareCompletionRate - 0.5) * 0.4 // Enhanced weight
            
            // Additional bonus for cross-habit consistency (habits with >50% completion)
            let consistencyRatio = Double(stats.completedHabits) / Double(stats.totalHabits)
            let consistencyBonus = (consistencyRatio - 0.5) * 0.2
            
            traitAccumulators[.conscientiousness, default: 0.0] += conscientiousnessBonus + consistencyBonus
            totalWeights[.conscientiousness, default: 0.0] += 0.6 // Increased weight for enhanced data
            
            // Neuroticism analysis: High completion suggests emotional stability
            if scheduleAwareCompletionRate > 0.7 {
                let stabilityBonus = -0.2 // Negative neuroticism (more stable)
                traitAccumulators[.neuroticism, default: 0.0] += stabilityBonus
                totalWeights[.neuroticism, default: 0.0] += 0.2
            } else if scheduleAwareCompletionRate < 0.3 {
                let instabilityPenalty = 0.3 // Higher neuroticism
                traitAccumulators[.neuroticism, default: 0.0] += instabilityPenalty
                totalWeights[.neuroticism, default: 0.0] += 0.3
            }
            
        } else {
            // Fallback to original completion rate analysis
            let avgCompletionRate = input.completionRates.reduce(0.0, +) / Double(max(input.completionRates.count, 1))
            let conscientiousnessBonus = (avgCompletionRate - 0.5) * 0.3
            traitAccumulators[.conscientiousness, default: 0.0] += conscientiousnessBonus
            totalWeights[.conscientiousness, default: 0.0] += 0.3
        }
        
        // Analyze habit diversity and schedule flexibility (openness to experience)
        let diversityScore = Double(input.habitCategories.count) / 10.0 // Normalize to 0-1+ range
        let opennessBonus = min(diversityScore, 1.0) * 0.2
        
        // Enhanced openness analysis: schedule flexibility preferences
        if let stats = completionStats, stats.totalHabits > 0 {
            // Analyze schedule pattern preferences from active habits
            var flexibleScheduleCount = 0
            var rigidScheduleCount = 0
            
            for habit in input.activeHabits {
                switch habit.schedule {
                case .daily:
                    rigidScheduleCount += 1
                case .daysOfWeek(let days):
                    if days.count <= 3 {
                        flexibleScheduleCount += 1 // Selective days = flexibility
                    } else {
                        rigidScheduleCount += 1
                    }
                case .timesPerWeek(_):
                    flexibleScheduleCount += 1 // Times per week = high flexibility
                }
            }
            
            let totalScheduledHabits = flexibleScheduleCount + rigidScheduleCount
            if totalScheduledHabits > 0 {
                let flexibilityRatio = Double(flexibleScheduleCount) / Double(totalScheduledHabits)
                let flexibilityBonus = (flexibilityRatio - 0.5) * 0.25 // Bonus for preferring flexibility
                traitAccumulators[.openness, default: 0.0] += opennessBonus + flexibilityBonus
                totalWeights[.openness, default: 0.0] += 0.45
            } else {
                traitAccumulators[.openness, default: 0.0] += opennessBonus
                totalWeights[.openness, default: 0.0] += 0.2
            }
        } else {
            traitAccumulators[.openness, default: 0.0] += opennessBonus
            totalWeights[.openness, default: 0.0] += 0.2
        }
        
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
        
        
        // Normalize scores with evidence strength consideration
        var normalizedScores: [PersonalityTrait: Double] = [:]
        let maxTotalWeight = totalWeights.values.max() ?? 1.0
        
        for trait in PersonalityTrait.allCases {
            let accumulator = traitAccumulators[trait, default: 0.0]
            let totalWeight = totalWeights[trait, default: 0.0]
            
            if totalWeight > 0 {
                // Calculate base ratio (-1 to 1 range)
                let rawRatio = accumulator / totalWeight
                
                // Evidence strength factor (0.1 to 1.0) - weak evidence gets dampened
                let evidenceStrength = min(totalWeight / maxTotalWeight, 1.0)
                let minStrength = 0.1
                let adjustedStrength = max(evidenceStrength, minStrength)
                
                // Apply evidence dampening to extreme ratios
                var adjustedRatio = rawRatio
                if abs(rawRatio) > 0.8 && adjustedStrength < 0.3 {
                    // Dampen extreme ratios when evidence is weak
                    let dampeningFactor = 0.3 + (adjustedStrength * 0.5) // 0.3 to 0.8 range
                    adjustedRatio = rawRatio * dampeningFactor
                }
                
                // Convert from -1 to 1 range to 0 to 1 range
                let normalizedScore = (adjustedRatio + 1.0) / 2.0
                normalizedScores[trait] = max(0.0, min(1.0, normalizedScore))
                
            } else {
                // Default to neutral (0.5) if no data
                normalizedScores[trait] = 0.5
            }
        }
        
        let winner = determineDominantTrait(from: normalizedScores)
        
        return (scores: normalizedScores, accumulators: traitAccumulators, totalWeights: totalWeights)
    }
    // swiftlint:enable function_body_length
    
    public func determineDominantTrait(from scores: [PersonalityTrait: Double]) -> PersonalityTrait {
        return scores.max(by: { $0.value < $1.value })?.key ?? .conscientiousness
    }
    
    /// Determine dominant trait with sophisticated multi-criteria tie-breaking
    public func determineDominantTraitWithTieBreaking(
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
    
    public func calculateConfidence(from metadata: AnalysisMetadata) -> ConfidenceLevel {
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
    public func calculateConfidenceWithCompletionStats(from metadata: AnalysisMetadata, completionStats: HabitCompletionStats) -> ConfidenceLevel {
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
    private func inferPersonalityWeights(for category: Category, habits: [Habit], allLogs: [Double]) -> [String: Double] {
        // Start with neutral baseline - using consistent ordering to prevent fluctuations
        var weights: [String: Double] = [
            "openness": 0.05,
            "conscientiousness": 0.05,  
            "extraversion": 0.05,
            "agreeableness": 0.05,
            "neuroticism": 0.05
        ]
        
        // Behavior-based inference
        if !habits.isEmpty {
            // High consistency = Conscientiousness
            let avgCompletionRate = allLogs.reduce(0.0, +) / Double(max(allLogs.count, 1))
            if avgCompletionRate > 0.7 {
                weights["conscientiousness"] = 0.3
            } else if avgCompletionRate < 0.3 {
                weights["neuroticism"] = 0.2
            }
            
            // Social keywords = Extraversion
            let socialHabits = habits.filter { habit in
                habit.name.localizedCaseInsensitiveContains("social") ||
                habit.name.localizedCaseInsensitiveContains("friend") ||
                habit.name.localizedCaseInsensitiveContains("meet") ||
                habit.name.localizedCaseInsensitiveContains("call") ||
                habit.name.localizedCaseInsensitiveContains("visit")
            }
            if !socialHabits.isEmpty {
                weights["extraversion"] = 0.4
            }
            
            // Variety of different habits = Openness
            let uniqueHabitTypes = Set(habits.map { $0.name.prefix(3) })
            if uniqueHabitTypes.count >= 3 && habits.count >= 3 {
                weights["openness"] = 0.25
            }
            
            // Relationship/care keywords = Agreeableness
            let careHabits = habits.filter { habit in
                habit.name.localizedCaseInsensitiveContains("love") ||
                habit.name.localizedCaseInsensitiveContains("care") ||
                habit.name.localizedCaseInsensitiveContains("help") ||
                habit.name.localizedCaseInsensitiveContains("family") ||
                habit.name.localizedCaseInsensitiveContains("relationship")
            }
            if !careHabits.isEmpty {
                weights["agreeableness"] = 0.5
            }
        }
        
        return weights
    }
    
    /// Calculate habit-specific modifiers based on individual habit characteristics
    private func calculateHabitSpecificModifiers(habit: Habit, input: HabitAnalysisInput) -> [PersonalityTrait: Double] {
        var modifiers: [PersonalityTrait: Double] = [:]
        
        // 1. Habit name analysis for personality indicators
        let habitName = habit.name.lowercased()
        
        // Conscientiousness indicators
        if habitName.contains("daily") || habitName.contains("routine") || habitName.contains("schedule") {
            modifiers[.conscientiousness] = 1.2  // +20% boost
        }
        if habitName.contains("organize") || habitName.contains("plan") || habitName.contains("prepare") {
            modifiers[.conscientiousness] = 1.3  // +30% boost
        }
        
        // Openness indicators  
        if habitName.contains("learn") || habitName.contains("study") || habitName.contains("explore") {
            modifiers[.openness] = 1.2
        }
        if habitName.contains("creative") || habitName.contains("art") || habitName.contains("music") {
            modifiers[.openness] = 1.4  // Strong creativity boost
        }
        if habitName.contains("new") || habitName.contains("try") || habitName.contains("experiment") {
            modifiers[.openness] = 1.3
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
        
        // Neuroticism modifiers (these are often inverse - stress reduction activities)
        if habitName.contains("meditat") || habitName.contains("calm") || habitName.contains("relax") {
            modifiers[.neuroticism] = 0.7  // -30% (less neurotic)
        }
        if habitName.contains("mindful") || habitName.contains("breath") || habitName.contains("zen") {
            modifiers[.neuroticism] = 0.6  // -40% (significant calm effect)
        }
        if habitName.contains("stress") || habitName.contains("anxiety") || habitName.contains("worry") {
            // If explicitly addressing stress/anxiety, this suggests some neuroticism but also coping
            modifiers[.neuroticism] = 0.8  // -20%
            modifiers[.conscientiousness] = 1.1  // +10% for addressing the issue
        }
        
        // 2. Habit frequency analysis
        switch habit.schedule {
        case .daily:
            // Daily habits show higher conscientiousness
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.1
        case .daysOfWeek(let days):
            // Specific day patterns show planning (conscientiousness) and some flexibility (openness)
            modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.05
            if days.count <= 3 {
                // Selective days suggest thoughtful planning
                modifiers[.openness] = (modifiers[.openness] ?? 1.0) * 1.05
            }
        case .timesPerWeek(let times):
            // Flexible frequency suggests adaptability
            modifiers[.openness] = (modifiers[.openness] ?? 1.0) * 1.1
            if times >= 5 {
                // High frequency suggests discipline
                modifiers[.conscientiousness] = (modifiers[.conscientiousness] ?? 1.0) * 1.05
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
    private func getCompletionRateForHabit(habit: Habit, input: HabitAnalysisInput) -> Double {
        // Find the index of this habit in the activeHabits array
        guard let habitIndex = input.activeHabits.firstIndex(where: { $0.id == habit.id }) else {
            return 0.0 // Habit not found in active habits
        }
        
        // Check if we have a completion rate for this index
        guard habitIndex < input.completionRates.count else {
            return 0.0 // No completion rate data for this habit
        }
        
        return input.completionRates[habitIndex]
    }
}
