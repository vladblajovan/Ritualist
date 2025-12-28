//
//  CategoryDefinitionsService.swift
//  RitualistCore
//
//  Created by Phase 2 Consolidation on 13.11.2025.
//

import Foundation

/// Protocol for category definitions service
/// Provides predefined habit categories with personality trait weights
public protocol CategoryDefinitionsServiceProtocol: Sendable {
    /// Returns all predefined habit categories
    func getPredefinedCategories() -> [HabitCategory]
}

/// Service that provides predefined habit category definitions
/// Extracted from CategoryLocalDataSource for proper layer separation
public final class CategoryDefinitionsService: CategoryDefinitionsServiceProtocol, Sendable {

    public init() {}

    /// Returns all predefined habit categories with personality weights
    /// These categories are core to the app and cannot be deleted by users
    public func getPredefinedCategories() -> [HabitCategory] {
        return [
            HabitCategory(
                id: "health",
                name: "health",
                displayName: "Health",
                emoji: "💪",
                order: 0,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.6,
                    "neuroticism": -0.3,
                    "agreeableness": 0.2
                ]
            ),
            HabitCategory(
                id: "wellness",
                name: "wellness",
                displayName: "Wellness",
                emoji: "🧘",
                order: 1,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.4,
                    "neuroticism": -0.5,
                    "openness": 0.3,
                    "agreeableness": 0.2
                ]
            ),
            HabitCategory(
                id: "productivity",
                name: "productivity",
                displayName: "Productivity",
                emoji: "⚡",
                order: 2,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.8,
                    "neuroticism": -0.2,
                    "openness": 0.1
                ]
            ),
            HabitCategory(
                id: "social",
                name: "social",
                displayName: "Social",
                emoji: "👥",
                order: 3,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "extraversion": 0.7,
                    "agreeableness": 0.6,
                    "conscientiousness": 0.3
                ]
            ),
            HabitCategory(
                id: "learning",
                name: "learning",
                displayName: "Learning",
                emoji: "📚",
                order: 4,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "openness": 0.8,
                    "conscientiousness": 0.5,
                    "extraversion": 0.2
                ]
            ),
            HabitCategory(
                id: "creativity",
                name: "creativity",
                displayName: "Creativity",
                emoji: "🎨",
                order: 5,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "openness": 0.9,
                    "extraversion": 0.3,
                    "conscientiousness": 0.1
                ]
            )
        ]
    }
}
