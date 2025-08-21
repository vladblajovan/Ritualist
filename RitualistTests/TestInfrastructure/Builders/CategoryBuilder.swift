//
//  CategoryBuilder.swift
//  RitualistTests
//
//  Created by Claude on 21.08.2025.
//

import Foundation
@testable import RitualistCore

/// A fluent builder for creating HabitCategory test instances with sensible defaults.
///
/// Usage:
/// ```swift
/// let category = CategoryBuilder()
///     .withName("Health & Fitness")
///     .withDisplayName("Health & Fitness")
///     .withEmoji("🏃‍♂️")
///     .withOrder(1)
///     .build()
/// ```
public class CategoryBuilder {
    private var id = UUID().uuidString
    private var name = "Test Category"
    private var displayName = "Test Category"
    private var emoji = "📝"
    private var order = 0
    private var isActive = true
    private var isPredefined = false
    private var personalityWeights: [String: Double]? = nil
    
    public init() {}
    
    // MARK: - Fluent API
    
    /// Sets a custom ID for the category. If not called, a random UUID string is generated.
    @discardableResult
    public func withId(_ id: String) -> CategoryBuilder {
        self.id = id
        return self
    }
    
    /// Sets the category name (used for internal identification).
    @discardableResult
    public func withName(_ name: String) -> CategoryBuilder {
        self.name = name
        return self
    }
    
    /// Sets the display name (shown to users).
    @discardableResult
    public func withDisplayName(_ displayName: String) -> CategoryBuilder {
        self.displayName = displayName
        return self
    }
    
    /// Sets the category emoji.
    @discardableResult
    public func withEmoji(_ emoji: String) -> CategoryBuilder {
        self.emoji = emoji
        return self
    }
    
    /// Sets the display order for the category.
    @discardableResult
    public func withOrder(_ order: Int) -> CategoryBuilder {
        self.order = order
        return self
    }
    
    /// Sets whether the category is active.
    @discardableResult
    public func withIsActive(_ isActive: Bool) -> CategoryBuilder {
        self.isActive = isActive
        return self
    }
    
    /// Sets whether the category is predefined (built-in) or custom.
    @discardableResult
    public func withIsPredefined(_ isPredefined: Bool) -> CategoryBuilder {
        self.isPredefined = isPredefined
        return self
    }
    
    /// Sets the personality trait weights for this category.
    @discardableResult
    public func withPersonalityWeights(_ weights: [String: Double]?) -> CategoryBuilder {
        self.personalityWeights = weights
        return self
    }
    
    // MARK: - Convenience Methods
    
    /// Marks the category as predefined (built-in).
    @discardableResult
    public func asPredefined() -> CategoryBuilder {
        return self.withIsPredefined(true)
    }
    
    /// Marks the category as custom (user-created).
    @discardableResult
    public func asCustom() -> CategoryBuilder {
        return self.withIsPredefined(false)
    }
    
    /// Marks the category as inactive (hidden from UI).
    @discardableResult
    public func asInactive() -> CategoryBuilder {
        return self.withIsActive(false)
    }
    
    /// Sets both name and display name to the same value for convenience.
    @discardableResult
    public func withNameAndDisplay(_ name: String) -> CategoryBuilder {
        return self
            .withName(name)
            .withDisplayName(name)
    }
    
    /// Adds personality weights focused on Conscientiousness (organization, discipline).
    @discardableResult
    public func withConscientiousnessWeights() -> CategoryBuilder {
        let weights = [
            "conscientiousness": 0.8,
            "openness": 0.2,
            "extraversion": 0.0,
            "agreeableness": 0.0,
            "neuroticism": -0.3
        ]
        return self.withPersonalityWeights(weights)
    }
    
    /// Adds personality weights focused on Extraversion (social activities).
    @discardableResult
    public func withExtraversionWeights() -> CategoryBuilder {
        let weights = [
            "extraversion": 0.9,
            "agreeableness": 0.4,
            "openness": 0.3,
            "conscientiousness": 0.1,
            "neuroticism": -0.2
        ]
        return self.withPersonalityWeights(weights)
    }
    
    /// Adds personality weights focused on Openness (creativity, learning).
    @discardableResult
    public func withOpennessWeights() -> CategoryBuilder {
        let weights = [
            "openness": 0.9,
            "conscientiousness": 0.3,
            "extraversion": 0.2,
            "agreeableness": 0.1,
            "neuroticism": 0.0
        ]
        return self.withPersonalityWeights(weights)
    }
    
    // MARK: - Build
    
    /// Creates the HabitCategory instance with all configured properties.
    public func build() -> HabitCategory {
        return HabitCategory(
            id: id,
            name: name,
            displayName: displayName,
            emoji: emoji,
            order: order,
            isActive: isActive,
            isPredefined: isPredefined,
            personalityWeights: personalityWeights
        )
    }
}

// MARK: - Predefined Categories

public extension CategoryBuilder {
    /// Creates a Health & Fitness category.
    static func healthCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("health")
            .withNameAndDisplay("Health & Fitness")
            .withEmoji("🏃‍♂️")
            .withOrder(1)
            .asPredefined()
            .withConscientiousnessWeights()
    }
    
    /// Creates a Productivity category.
    static func productivityCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("productivity")
            .withNameAndDisplay("Productivity")
            .withEmoji("💼")
            .withOrder(2)
            .asPredefined()
            .withConscientiousnessWeights()
    }
    
    /// Creates a Learning category.
    static func learningCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("learning")
            .withNameAndDisplay("Learning")
            .withEmoji("📚")
            .withOrder(3)
            .asPredefined()
            .withOpennessWeights()
    }
    
    /// Creates a Mindfulness category.
    static func mindfulnessCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("mindfulness")
            .withNameAndDisplay("Mindfulness")
            .withEmoji("🧘")
            .withOrder(4)
            .asPredefined()
    }
    
    /// Creates a Social category.
    static func socialCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("social")
            .withNameAndDisplay("Social")
            .withEmoji("👥")
            .withOrder(5)
            .asPredefined()
            .withExtraversionWeights()
    }
    
    /// Creates a Creative category.
    static func creativeCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("creative")
            .withNameAndDisplay("Creative")
            .withEmoji("🎨")
            .withOrder(6)
            .asPredefined()
            .withOpennessWeights()
    }
    
    /// Creates a Finance category.
    static func financeCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("finance")
            .withNameAndDisplay("Finance")
            .withEmoji("💰")
            .withOrder(7)
            .asPredefined()
            .withConscientiousnessWeights()
    }
    
    /// Creates a Home & Lifestyle category.
    static func lifestyleCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("lifestyle")
            .withNameAndDisplay("Home & Lifestyle")
            .withEmoji("🏠")
            .withOrder(8)
            .asPredefined()
    }
    
    /// Creates a custom user-created category.
    static func customCategory(name: String, emoji: String = "⭐") -> CategoryBuilder {
        return CategoryBuilder()
            .withNameAndDisplay(name)
            .withEmoji(emoji)
            .asCustom()
    }
    
    /// Creates an inactive category for testing deletion scenarios.
    static func inactiveCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withNameAndDisplay("Inactive Category")
            .withEmoji("❌")
            .asInactive()
    }
}

// MARK: - Batch Creation Methods

public extension CategoryBuilder {
    /// Creates all predefined categories that come with the app.
    static func createPredefinedCategories() -> [HabitCategory] {
        return [
            healthCategory().build(),
            productivityCategory().build(),
            learningCategory().build(),
            mindfulnessCategory().build(),
            socialCategory().build(),
            creativeCategory().build(),
            financeCategory().build(),
            lifestyleCategory().build()
        ]
    }
    
    /// Creates a mix of predefined and custom categories for testing.
    static func createMixedCategories() -> [HabitCategory] {
        var categories = createPredefinedCategories()
        
        let customCategories = [
            customCategory(name: "Travel", emoji: "✈️").build(),
            customCategory(name: "Cooking", emoji: "👨‍🍳").build(),
            customCategory(name: "Gaming", emoji: "🎮").build()
        ]
        
        categories.append(contentsOf: customCategories)
        return categories
    }
    
    /// Creates categories with personality analysis weights for testing.
    static func createPersonalityCategories() -> [HabitCategory] {
        return [
            healthCategory()
                .withPersonalityWeights([
                    "conscientiousness": 0.7,
                    "neuroticism": -0.4,
                    "openness": 0.2
                ])
                .build(),
            
            creativeCategory()
                .withPersonalityWeights([
                    "openness": 0.9,
                    "extraversion": 0.3,
                    "conscientiousness": 0.1
                ])
                .build(),
            
            socialCategory()
                .withPersonalityWeights([
                    "extraversion": 0.8,
                    "agreeableness": 0.6,
                    "neuroticism": -0.3
                ])
                .build()
        ]
    }
}

// MARK: - Category Validation Helpers

public extension CategoryBuilder {
    /// Validates that a category has all required fields set.
    func validate() -> Bool {
        return !id.isEmpty && !name.isEmpty && !displayName.isEmpty && !emoji.isEmpty
    }
    
    /// Creates a category with intentionally invalid data for error testing.
    static func invalidCategory() -> CategoryBuilder {
        return CategoryBuilder()
            .withId("")  // Invalid: empty ID
            .withName("")  // Invalid: empty name
            .withEmoji("")  // Invalid: empty emoji
    }
}