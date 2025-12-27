//
//  CategoryDefinitionsServiceTests.swift
//  RitualistTests
//
//  Created by Phase 2 Consolidation on 13.11.2025.
//

import Testing
@testable import RitualistCore

@Suite("CategoryDefinitionsService Tests")
@MainActor
struct CategoryDefinitionsServiceTests {

    // MARK: - Test Setup

    let service = CategoryDefinitionsService()

    // MARK: - Basic Functionality Tests

    @Test("Returns exactly 6 predefined categories")
    func returnsAllCategories() {
        let categories = service.getPredefinedCategories()
        #expect(categories.count == 6, "Should return all 6 predefined categories")
    }

    @Test("All categories are marked as predefined")
    func allCategoriesArePredefined() {
        let categories = service.getPredefinedCategories()
        for category in categories {
            #expect(category.isPredefined == true, "\(category.id) should be marked as predefined")
        }
    }

    @Test("All categories are marked as active")
    func allCategoriesAreActive() {
        let categories = service.getPredefinedCategories()
        for category in categories {
            #expect(category.isActive == true, "\(category.id) should be marked as active")
        }
    }

    @Test("All categories have personality weights")
    func allCategoriesHavePersonalityWeights() {
        let categories = service.getPredefinedCategories()
        for category in categories {
            #expect(category.personalityWeights != nil, "\(category.id) should have personality weights")
            #expect(!category.personalityWeights!.isEmpty, "\(category.id) should have non-empty personality weights")
        }
    }

    // MARK: - Order Tests

    @Test("Categories have sequential order from 0 to 5")
    func categoriesHaveCorrectOrder() {
        let categories = service.getPredefinedCategories()
        let orders = Set(categories.map { $0.order })
        #expect(orders == Set([0, 1, 2, 3, 4, 5]), "Orders should be 0 through 5")
    }

    @Test("No duplicate orders")
    func noDuplicateOrders() {
        let categories = service.getPredefinedCategories()
        let orders = categories.map { $0.order }
        let uniqueOrders = Set(orders)
        #expect(orders.count == uniqueOrders.count, "All orders should be unique")
    }

    // MARK: - ID Tests

    @Test("No duplicate IDs")
    func noDuplicateIds() {
        let categories = service.getPredefinedCategories()
        let ids = categories.map { $0.id }
        let uniqueIds = Set(ids)
        #expect(ids.count == uniqueIds.count, "All IDs should be unique")
    }

    @Test("Contains expected category IDs")
    func containsExpectedCategoryIds() {
        let categories = service.getPredefinedCategories()
        let ids = Set(categories.map { $0.id })
        let expectedIds: Set<String> = ["health", "wellness", "productivity", "social", "learning", "creativity"]
        #expect(ids == expectedIds, "Should contain all expected category IDs")
    }

    // MARK: - Health Category Tests

    @Test("Health category has correct properties")
    func healthCategoryProperties() {
        let categories = service.getPredefinedCategories()
        guard let health = categories.first(where: { $0.id == "health" }) else {
            Issue.record("Health category not found")
            return
        }

        #expect(health.name == "health")
        #expect(health.displayName == "Health")
        #expect(health.emoji == "💪")
        #expect(health.order == 0)
        #expect(health.isActive == true)
        #expect(health.isPredefined == true)
    }

    @Test("Health category has correct personality weights")
    func healthCategoryWeights() {
        let categories = service.getPredefinedCategories()
        guard let health = categories.first(where: { $0.id == "health" }),
              let weights = health.personalityWeights else {
            Issue.record("Health category or weights not found")
            return
        }

        #expect(weights["conscientiousness"] == 0.6)
        #expect(weights["neuroticism"] == -0.3)
        #expect(weights["agreeableness"] == 0.2)
    }

    // MARK: - Wellness Category Tests

    @Test("Wellness category has correct properties")
    func wellnessCategoryProperties() {
        let categories = service.getPredefinedCategories()
        guard let wellness = categories.first(where: { $0.id == "wellness" }) else {
            Issue.record("Wellness category not found")
            return
        }

        #expect(wellness.name == "wellness")
        #expect(wellness.displayName == "Wellness")
        #expect(wellness.emoji == "🧘")
        #expect(wellness.order == 1)
    }

    @Test("Wellness category has correct personality weights")
    func wellnessCategoryWeights() {
        let categories = service.getPredefinedCategories()
        guard let wellness = categories.first(where: { $0.id == "wellness" }),
              let weights = wellness.personalityWeights else {
            Issue.record("Wellness category or weights not found")
            return
        }

        #expect(weights["conscientiousness"] == 0.4)
        #expect(weights["neuroticism"] == -0.5)
        #expect(weights["openness"] == 0.3)
        #expect(weights["agreeableness"] == 0.2)
    }

    // MARK: - Productivity Category Tests

    @Test("Productivity category has correct properties")
    func productivityCategoryProperties() {
        let categories = service.getPredefinedCategories()
        guard let productivity = categories.first(where: { $0.id == "productivity" }) else {
            Issue.record("Productivity category not found")
            return
        }

        #expect(productivity.name == "productivity")
        #expect(productivity.displayName == "Productivity")
        #expect(productivity.emoji == "⚡")
        #expect(productivity.order == 2)
    }

    @Test("Productivity category has correct personality weights")
    func productivityCategoryWeights() {
        let categories = service.getPredefinedCategories()
        guard let productivity = categories.first(where: { $0.id == "productivity" }),
              let weights = productivity.personalityWeights else {
            Issue.record("Productivity category or weights not found")
            return
        }

        #expect(weights["conscientiousness"] == 0.8)
        #expect(weights["neuroticism"] == -0.2)
        #expect(weights["openness"] == 0.1)
    }

    // MARK: - Social Category Tests

    @Test("Social category has correct properties")
    func socialCategoryProperties() {
        let categories = service.getPredefinedCategories()
        guard let social = categories.first(where: { $0.id == "social" }) else {
            Issue.record("Social category not found")
            return
        }

        #expect(social.name == "social")
        #expect(social.displayName == "Social")
        #expect(social.emoji == "👥")
        #expect(social.order == 3)
    }

    @Test("Social category has correct personality weights")
    func socialCategoryWeights() {
        let categories = service.getPredefinedCategories()
        guard let social = categories.first(where: { $0.id == "social" }),
              let weights = social.personalityWeights else {
            Issue.record("Social category or weights not found")
            return
        }

        #expect(weights["extraversion"] == 0.7)
        #expect(weights["agreeableness"] == 0.6)
        #expect(weights["conscientiousness"] == 0.3)
    }

    // MARK: - Learning Category Tests

    @Test("Learning category has correct properties")
    func learningCategoryProperties() {
        let categories = service.getPredefinedCategories()
        guard let learning = categories.first(where: { $0.id == "learning" }) else {
            Issue.record("Learning category not found")
            return
        }

        #expect(learning.name == "learning")
        #expect(learning.displayName == "Learning")
        #expect(learning.emoji == "📚")
        #expect(learning.order == 4)
    }

    @Test("Learning category has correct personality weights")
    func learningCategoryWeights() {
        let categories = service.getPredefinedCategories()
        guard let learning = categories.first(where: { $0.id == "learning" }),
              let weights = learning.personalityWeights else {
            Issue.record("Learning category or weights not found")
            return
        }

        #expect(weights["openness"] == 0.8)
        #expect(weights["conscientiousness"] == 0.5)
        #expect(weights["extraversion"] == 0.2)
    }

    // MARK: - Creativity Category Tests

    @Test("Creativity category has correct properties")
    func creativityCategoryProperties() {
        let categories = service.getPredefinedCategories()
        guard let creativity = categories.first(where: { $0.id == "creativity" }) else {
            Issue.record("Creativity category not found")
            return
        }

        #expect(creativity.name == "creativity")
        #expect(creativity.displayName == "Creativity")
        #expect(creativity.emoji == "🎨")
        #expect(creativity.order == 5)
    }

    @Test("Creativity category has correct personality weights")
    func creativityCategoryWeights() {
        let categories = service.getPredefinedCategories()
        guard let creativity = categories.first(where: { $0.id == "creativity" }),
              let weights = creativity.personalityWeights else {
            Issue.record("Creativity category or weights not found")
            return
        }

        #expect(weights["openness"] == 0.9)
        #expect(weights["extraversion"] == 0.3)
        #expect(weights["conscientiousness"] == 0.1)
    }

    // MARK: - Consistency Tests

    @Test("Multiple calls return same data")
    func multipleCallsReturnSameData() {
        let categories1 = service.getPredefinedCategories()
        let categories2 = service.getPredefinedCategories()

        #expect(categories1.count == categories2.count)

        for (cat1, cat2) in zip(categories1, categories2) {
            #expect(cat1.id == cat2.id)
            #expect(cat1.name == cat2.name)
            #expect(cat1.displayName == cat2.displayName)
            #expect(cat1.emoji == cat2.emoji)
            #expect(cat1.order == cat2.order)
        }
    }

    // MARK: - Personality Weight Validation Tests

    @Test("All personality weights are valid doubles")
    func personalityWeightsAreValidDoubles() {
        let categories = service.getPredefinedCategories()
        for category in categories {
            guard let weights = category.personalityWeights else {
                Issue.record("\(category.id) has no personality weights")
                continue
            }

            for (trait, weight) in weights {
                #expect(!weight.isNaN, "\(category.id) - \(trait) weight should not be NaN")
                #expect(!weight.isInfinite, "\(category.id) - \(trait) weight should not be infinite")
                #expect(weight >= -1.0 && weight <= 1.0, "\(category.id) - \(trait) weight should be between -1.0 and 1.0")
            }
        }
    }

    @Test("Personality weights use valid Big Five trait names")
    func personalityWeightsUseValidTraitNames() {
        let validTraits: Set<String> = ["openness", "conscientiousness", "extraversion", "agreeableness", "neuroticism"]
        let categories = service.getPredefinedCategories()

        for category in categories {
            guard let weights = category.personalityWeights else {
                Issue.record("\(category.id) has no personality weights")
                continue
            }

            for trait in weights.keys {
                #expect(validTraits.contains(trait), "\(category.id) contains invalid trait: \(trait)")
            }
        }
    }
}
