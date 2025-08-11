//
//  PersonalityTailoredNotificationTestScenarios.swift
//  Ritualist
//
//  Created by Claude on 11.08.2025.
//

import Foundation
import RitualistCore
import UserNotifications

// Import all necessary domain entities
// These imports ensure we have access to all the personality analysis types
// Note: Since these are domain entities in the same app module, they should be accessible

#if DEBUG
/// Test scenarios for personality-tailored notifications
public struct PersonalityTailoredNotificationTestScenarios {
    
    // MARK: - Test Data Factory
    
    /// Creates sample personality profiles for testing
    public static func createTestProfiles() -> [PersonalityProfile] {
        let baseDate = Date()
        let analysisMetadata = AnalysisMetadata(
            analysisDate: baseDate,
            dataPointsAnalyzed: 120,
            timeRangeAnalyzed: 30,
            version: "1.0"
        )
        
        return [
            // High Conscientiousness Profile
            PersonalityProfile(
                id: UUID(),
                userId: UUID(),
                traitScores: [
                    PersonalityTrait.conscientiousness: 0.85,
                    PersonalityTrait.openness: 0.45,
                    PersonalityTrait.extraversion: 0.35,
                    PersonalityTrait.agreeableness: 0.60,
                    PersonalityTrait.neuroticism: 0.25
                ],
                dominantTrait: PersonalityTrait.conscientiousness,
                confidence: ConfidenceLevel.high,
                analysisMetadata: analysisMetadata
            ),
            
            // High Openness Profile
            PersonalityProfile(
                id: UUID(),
                userId: UUID(),
                traitScores: [
                    PersonalityTrait.openness: 0.90,
                    PersonalityTrait.conscientiousness: 0.55,
                    PersonalityTrait.extraversion: 0.70,
                    PersonalityTrait.agreeableness: 0.40,
                    PersonalityTrait.neuroticism: 0.30
                ],
                dominantTrait: PersonalityTrait.openness,
                confidence: ConfidenceLevel.veryHigh,
                analysisMetadata: analysisMetadata
            ),
            
            // High Extraversion Profile
            PersonalityProfile(
                id: UUID(),
                userId: UUID(),
                traitScores: [
                    PersonalityTrait.extraversion: 0.88,
                    PersonalityTrait.agreeableness: 0.75,
                    PersonalityTrait.conscientiousness: 0.50,
                    PersonalityTrait.openness: 0.60,
                    PersonalityTrait.neuroticism: 0.20
                ],
                dominantTrait: PersonalityTrait.extraversion,
                confidence: ConfidenceLevel.high,
                analysisMetadata: analysisMetadata
            ),
            
            // High Agreeableness Profile
            PersonalityProfile(
                id: UUID(),
                userId: UUID(),
                traitScores: [
                    PersonalityTrait.agreeableness: 0.82,
                    PersonalityTrait.conscientiousness: 0.65,
                    PersonalityTrait.openness: 0.55,
                    PersonalityTrait.extraversion: 0.45,
                    PersonalityTrait.neuroticism: 0.35
                ],
                dominantTrait: PersonalityTrait.agreeableness,
                confidence: ConfidenceLevel.high,
                analysisMetadata: analysisMetadata
            ),
            
            // High Neuroticism Profile
            PersonalityProfile(
                id: UUID(),
                userId: UUID(),
                traitScores: [
                    PersonalityTrait.neuroticism: 0.75,
                    PersonalityTrait.conscientiousness: 0.70,
                    PersonalityTrait.agreeableness: 0.60,
                    PersonalityTrait.openness: 0.40,
                    PersonalityTrait.extraversion: 0.25
                ],
                dominantTrait: PersonalityTrait.neuroticism,
                confidence: ConfidenceLevel.medium,
                analysisMetadata: analysisMetadata
            ),
            
            // Outdated Analysis Profile (45 days old)
            PersonalityProfile(
                id: UUID(),
                userId: UUID(),
                traitScores: [
                    PersonalityTrait.conscientiousness: 0.80,
                    PersonalityTrait.openness: 0.60,
                    PersonalityTrait.extraversion: 0.50,
                    PersonalityTrait.agreeableness: 0.55,
                    PersonalityTrait.neuroticism: 0.30
                ],
                dominantTrait: PersonalityTrait.conscientiousness,
                confidence: ConfidenceLevel.high,
                analysisMetadata: AnalysisMetadata(
                    analysisDate: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
                    dataPointsAnalyzed: 95,
                    timeRangeAnalyzed: 30,
                    version: "1.0"
                )
            )
        ]
    }
    
    // MARK: - Test Scenarios
    
    /// Test scenario 1: Conscientiousness - Morning Meditation
    public static func testConscientiousMorningMeditation() -> TestScenario {
        let profile = createTestProfiles()[0] // High conscientiousness
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 7, minute: 0)
        
        let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
            for: habitID,
            habitName: "Morning Meditation",
            reminderTime: reminderTime,
            personalityProfile: profile,
            habitCategory: "Wellness",
            currentStreak: 11,
            isWeekend: false
        )
        
        return TestScenario(
            name: "Conscientious Morning Meditation",
            expectedTitle: "🎯 Disciplined Start: Morning Meditation",
            expectedBodyPattern: "disciplined nature.*consistency.*07:00.*Day 12.*systematic approach.*paying off",
            actualContent: content,
            personality: PersonalityTrait.conscientiousness,
            timeOfDay: .morning,
            streak: 11
        )
    }
    
    /// Test scenario 2: Openness - Weekend Creative Writing
    public static func testOpennessWeekendWriting() -> TestScenario {
        let profile = createTestProfiles()[1] // High openness
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 10, minute: 30)
        
        let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
            for: habitID,
            habitName: "Creative Writing",
            reminderTime: reminderTime,
            personalityProfile: profile,
            habitCategory: "Learning",
            currentStreak: 4,
            isWeekend: true
        )
        
        return TestScenario(
            name: "Open Weekend Creative Writing",
            expectedTitle: "🎨 Creative Weekend: Creative Writing",
            expectedBodyPattern: "(Try a new approach|Experiment with|Add a creative twist|Explore new).*10:30.*Day 5.*curiosity",
            actualContent: content,
            personality: PersonalityTrait.openness,
            timeOfDay: .noon,
            streak: 4
        )
    }
    
    /// Test scenario 3: Extraversion - Evening Exercise with Social Element
    public static func testExtraversionEveningExercise() -> TestScenario {
        let profile = createTestProfiles()[2] // High extraversion
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 19, minute: 0)
        
        let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
            for: habitID,
            habitName: "Evening Run",
            reminderTime: reminderTime,
            personalityProfile: profile,
            habitCategory: "Fitness",
            currentStreak: 7,
            isWeekend: false
        )
        
        return TestScenario(
            name: "Extraverted Evening Exercise",
            expectedTitle: "🎉 Evening Power: Evening Run",
            expectedBodyPattern: "(Share your.*energy|enthusiasm can inspire others|Channel your social energy).*19:00.*Day 8",
            actualContent: content,
            personality: PersonalityTrait.extraversion,
            timeOfDay: .evening,
            streak: 7
        )
    }
    
    /// Test scenario 4: Agreeableness - Self-Care Health Habit
    public static func testAgreeablenessSelfCare() -> TestScenario {
        let profile = createTestProfiles()[3] // High agreeableness
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 14, minute: 15)
        
        let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
            for: habitID,
            habitName: "Healthy Lunch",
            reminderTime: reminderTime,
            personalityProfile: profile,
            habitCategory: "Health",
            currentStreak: 2,
            isWeekend: false
        )
        
        return TestScenario(
            name: "Agreeable Self-Care Health",
            expectedTitle: "💖 Compassionate Time: Healthy Lunch",
            expectedBodyPattern: "Taking care of yourself helps you care for others.*14:15.*Day 3",
            actualContent: content,
            personality: PersonalityTrait.agreeableness,
            timeOfDay: .noon,
            streak: 2
        )
    }
    
    /// Test scenario 5: Neuroticism - Gentle Evening Reading
    public static func testNeuroticismGentleEvening() -> TestScenario {
        let profile = createTestProfiles()[4] // High neuroticism
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 21, minute: 30)
        
        let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
            for: habitID,
            habitName: "Evening Reading",
            reminderTime: reminderTime,
            personalityProfile: profile,
            habitCategory: "Learning",
            currentStreak: 0,
            isWeekend: false
        )
        
        return TestScenario(
            name: "Neurotic Gentle Evening",
            expectedTitle: "🕯️ Calming Evening: Evening Reading",
            expectedBodyPattern: "(Take it one step|Be gentle|Progress.*not perfection|You're doing great).*21:30.*wellbeing",
            actualContent: content,
            personality: PersonalityTrait.neuroticism,
            timeOfDay: .evening,
            streak: 0
        )
    }
    
    /// Test scenario 6: Outdated Analysis Fallback
    public static func testOutdatedAnalysisFallback() -> TestScenario {
        let outdatedProfile = createTestProfiles()[5] // 45 days old
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 8, minute: 0)
        
        // This should trigger fallback behavior
        let hasRecentAnalysis = PersonalityTailoredNotificationContentGenerator.hasRecentAnalysis(outdatedProfile)
        
        return TestScenario(
            name: "Outdated Analysis Fallback",
            expectedTitle: "Should fallback to rich reminders",
            expectedBodyPattern: "Analysis older than 30 days should not be used",
            actualContent: UNMutableNotificationContent(), // Placeholder
            personality: PersonalityTrait.conscientiousness,
            timeOfDay: .morning,
            streak: 3,
            shouldFallback: !hasRecentAnalysis
        )
    }
    
    /// Test scenario 7: High Conscientiousness + High Openness Combo
    public static func testConscientiousOpennessCombo() -> TestScenario {
        // Create mixed profile
        let mixedProfile = PersonalityProfile(
            id: UUID(),
            userId: UUID(),
            traitScores: [
                .conscientiousness: 0.85, // Dominant
                .openness: 0.75,          // High secondary
                .extraversion: 0.40,
                .agreeableness: 0.55,
                .neuroticism: 0.30
            ],
            dominantTrait: .conscientiousness,
            confidence: .high,
            analysisMetadata: AnalysisMetadata(
                analysisDate: Date(),
                dataPointsAnalyzed: 150,
                timeRangeAnalyzed: 30,
                version: "1.0"
            )
        )
        
        let habitID = UUID()
        let reminderTime = ReminderTime(hour: 9, minute: 0)
        
        let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
            for: habitID,
            habitName: "Learning Spanish",
            reminderTime: reminderTime,
            personalityProfile: mixedProfile,
            habitCategory: "Learning",
            currentStreak: 5,
            isWeekend: false
        )
        
        return TestScenario(
            name: "Conscientious + Open Combination",
            expectedTitle: "⚡ Focused Time: Learning Spanish",
            expectedBodyPattern: "disciplined.*09:00.*Day 6.*(organized.*exploring|Stay organized.*new approaches)",
            actualContent: content,
            personality: PersonalityTrait.conscientiousness,
            timeOfDay: .morning,
            streak: 5
        )
    }
    
    // MARK: - Test Execution
    
    /// Runs all test scenarios and returns results
    public static func runAllTestScenarios() -> [TestResult] {
        let scenarios = [
            testConscientiousMorningMeditation(),
            testOpennessWeekendWriting(),
            testExtraversionEveningExercise(),
            testAgreeablenessSelfCare(),
            testNeuroticismGentleEvening(),
            testOutdatedAnalysisFallback(),
            testConscientiousOpennessCombo()
        ]
        
        return scenarios.map { scenario in
            let titleMatches = scenario.actualContent.title.contains(scenario.expectedTitle.prefix(10)) // Check prefix
            let bodyMatches = scenario.expectedBodyPattern.isEmpty || 
                             matchesPattern(scenario.actualContent.body, pattern: scenario.expectedBodyPattern)
            
            let passed = scenario.shouldFallback ? scenario.shouldFallback : (titleMatches && bodyMatches)
            
            return TestResult(
                scenarioName: scenario.name,
                passed: passed,
                actualTitle: scenario.actualContent.title,
                actualBody: scenario.actualContent.body,
                expectedPattern: scenario.expectedBodyPattern,
                notes: scenario.shouldFallback ? "Fallback behavior verified" : nil
            )
        }
    }
    
    private static func matchesPattern(_ text: String, pattern: String) -> Bool {
        // Simple pattern matching for key phrases
        let keyWords = pattern.lowercased().components(separatedBy: ".*")
        return keyWords.allSatisfy { keyword in
            text.lowercased().contains(keyword.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

// MARK: - Test Data Structures

public struct TestScenario {
    let name: String
    let expectedTitle: String
    let expectedBodyPattern: String
    let actualContent: UNMutableNotificationContent
    let personality: PersonalityTrait
    let timeOfDay: TimeOfDay
    let streak: Int
    let shouldFallback: Bool
    
    init(name: String, expectedTitle: String, expectedBodyPattern: String, 
         actualContent: UNMutableNotificationContent, personality: PersonalityTrait, 
         timeOfDay: TimeOfDay, streak: Int, shouldFallback: Bool = false) {
        self.name = name
        self.expectedTitle = expectedTitle
        self.expectedBodyPattern = expectedBodyPattern
        self.actualContent = actualContent
        self.personality = personality
        self.timeOfDay = timeOfDay
        self.streak = streak
        self.shouldFallback = shouldFallback
    }
}

public struct TestResult {
    let scenarioName: String
    let passed: Bool
    let actualTitle: String
    let actualBody: String
    let expectedPattern: String
    let notes: String?
}


// MARK: - Test Runner Extension

extension PersonalityTailoredNotificationTestScenarios {
    
    /// Quick test runner that prints results to console
    public static func runQuickTest() {
        print("🧪 Running Personality-Tailored Notification Tests...")
        print("================================================")
        
        let results = runAllTestScenarios()
        let passedCount = results.filter { $0.passed }.count
        
        for result in results {
            let status = result.passed ? "✅ PASS" : "❌ FAIL"
            print("\(status): \(result.scenarioName)")
            
            if !result.passed {
                print("   Expected pattern: \(result.expectedPattern)")
                print("   Actual title: \(result.actualTitle)")
                print("   Actual body: \(result.actualBody)")
            }
            
            if let notes = result.notes {
                print("   Note: \(notes)")
            }
            print("")
        }
        
        print("================================================")
        print("Test Summary: \(passedCount)/\(results.count) scenarios passed")
        
        if passedCount == results.count {
            print("🎉 All tests passed!")
        } else {
            print("⚠️ Some tests failed - check implementation")
        }
    }
}

#endif