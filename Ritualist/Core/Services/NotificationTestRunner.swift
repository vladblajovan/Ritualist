//
//  NotificationTestRunner.swift  
//  Ritualist
//
//  Created by Claude on 11.08.2025.
//

import Foundation
import RitualistCore

#if DEBUG
/// Simple test runner for notification systems
public struct NotificationTestRunner {
    
    /// Run all notification-related tests
    public static func runAllTests() {
        print("🔔 RITUALIST NOTIFICATION SYSTEM TESTS")
        print("====================================")
        print("")
        
        // Test 1: Personality-Tailored Notifications
        PersonalityTailoredNotificationTestScenarios.runQuickTest()
        
        print("")
        print("====================================")
        print("🏁 All notification tests completed!")
    }
    
    /// Test specific personality trait scenarios
    public static func testSpecificTrait(_ trait: PersonalityTrait) {
        print("🧠 Testing \(trait.displayName) Notifications")
        print("=" + String(repeating: "=", count: trait.displayName.count + 25))
        
        let testScenarios = PersonalityTailoredNotificationTestScenarios.runAllTestScenarios()
        let traitTests = testScenarios.filter { result in
            result.scenarioName.lowercased().contains(trait.rawValue.lowercased())
        }
        
        if traitTests.isEmpty {
            print("No specific tests found for \(trait.displayName)")
        } else {
            for result in traitTests {
                let status = result.passed ? "✅" : "❌"
                print("\(status) \(result.scenarioName)")
                print("   Title: \(result.actualTitle)")
                print("   Body: \(result.actualBody)")
                print("")
            }
        }
    }
    
    /// Demo notification content generation
    public static func demoNotificationGeneration() {
        print("📱 NOTIFICATION CONTENT DEMO")
        print("===========================")
        
        let profiles = PersonalityTailoredNotificationTestScenarios.createTestProfiles()
        let habitNames = ["Morning Meditation", "Evening Run", "Creative Writing", "Healthy Cooking", "Reading"]
        let times = [
            ReminderTime(hour: 7, minute: 0),
            ReminderTime(hour: 12, minute: 30),
            ReminderTime(hour: 19, minute: 15)
        ]
        
        for (index, profile) in profiles.prefix(3).enumerated() {
            let habit = habitNames[index]
            let time = times[index]
            
            print("\n🧠 \(profile.dominantTrait.displayName) Personality:")
            print("Habit: \(habit) at \(String(format: "%02d:%02d", time.hour, time.minute))")
            
            let content = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
                for: UUID(),
                habitName: habit,
                reminderTime: time,
                personalityProfile: profile,
                habitCategory: "Wellness",
                currentStreak: Int.random(in: 0...20),
                isWeekend: false
            )
            
            print("📱 \(content.title)")
            print("💬 \(content.body)")
        }
        
        print("\n===========================")
    }
    
    /// Test recent analysis detection
    public static func testRecentAnalysisDetection() {
        print("📅 RECENT ANALYSIS DETECTION TEST")
        print("================================")
        
        let profiles = PersonalityTailoredNotificationTestScenarios.createTestProfiles()
        
        for (index, profile) in profiles.enumerated() {
            let isRecent = PersonalityTailoredNotificationContentGenerator.hasRecentAnalysis(profile)
            let daysSince = Calendar.current.dateComponents([.day], from: profile.analysisMetadata.analysisDate, to: Date()).day ?? 0
            
            let status = isRecent ? "✅ Recent" : "❌ Outdated"
            print("\(status) Profile \(index + 1): \(daysSince) days old")
        }
        
        print("================================")
    }
    
    /// Benchmark notification generation performance
    public static func benchmarkNotificationGeneration() {
        print("⚡ NOTIFICATION GENERATION BENCHMARK")
        print("==================================")
        
        let profiles = PersonalityTailoredNotificationTestScenarios.createTestProfiles()
        let iterations = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<iterations {
            let profile = profiles[i % profiles.count]
            let _ = PersonalityTailoredNotificationContentGenerator.generateTailoredContent(
                for: UUID(),
                habitName: "Test Habit \(i)",
                reminderTime: ReminderTime(hour: Int.random(in: 6...22), minute: Int.random(in: 0...59)),
                personalityProfile: profile,
                habitCategory: "Test",
                currentStreak: Int.random(in: 0...50),
                isWeekend: Bool.random()
            )
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let avgTime = (totalTime / Double(iterations)) * 1000 // Convert to milliseconds
        
        print("Generated \(iterations) notifications in \(String(format: "%.2f", totalTime)) seconds")
        print("Average time per notification: \(String(format: "%.2f", avgTime)) ms")
        print("==================================")
    }
}

// MARK: - Usage Examples Extension

extension NotificationTestRunner {
    
    /// Show usage examples for developers
    public static func showUsageExamples() {
        print("📖 NOTIFICATION SYSTEM USAGE EXAMPLES")
        print("=====================================")
        print("""
        
        // 1. Run all tests
        NotificationTestRunner.runAllTests()
        
        // 2. Test specific personality trait
        NotificationTestRunner.testSpecificTrait(.conscientiousness)
        
        // 3. Demo notification generation
        NotificationTestRunner.demoNotificationGeneration()
        
        // 4. Test recent analysis detection
        NotificationTestRunner.testRecentAnalysisDetection()
        
        // 5. Benchmark performance
        NotificationTestRunner.benchmarkNotificationGeneration()
        
        // 6. Use in production code
        let notificationService: NotificationService = LocalNotificationService()
        
        if let personalityProfile = userPersonalityProfile {
            try await notificationService.schedulePersonalityTailoredReminders(
                for: habitID,
                habitName: "Morning Meditation", 
                habitCategory: "Wellness",
                currentStreak: 7,
                personalityProfile: personalityProfile,
                times: [ReminderTime(hour: 7, minute: 0)]
            )
        } else {
            // Fallback to rich reminders
            try await notificationService.scheduleRichReminders(
                for: habitID,
                habitName: "Morning Meditation",
                habitCategory: "Wellness", 
                currentStreak: 7,
                times: [ReminderTime(hour: 7, minute: 0)]
            )
        }
        
        """)
        print("=====================================")
    }
}

#endif