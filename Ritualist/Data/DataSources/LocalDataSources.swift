import Foundation
import RitualistCore
import SwiftData

public enum CategoryDataSourceError: Error {
    case categoryAlreadyExists
    case categoryNotFound
}

public final class HabitLocalDataSource: HabitLocalDataSourceProtocol {
    private let context: ModelContext?
    public init(context: ModelContext?) { 
        self.context = context 
    }
    @MainActor
    public func fetchAll() async throws -> [SDHabit] {
        guard let context else { return [] }
        
        let descriptor = FetchDescriptor<SDHabit>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return try context.fetch(descriptor)
    }
    @MainActor
    public func upsert(_ habit: SDHabit) async throws {
        guard let context else { return }
        context.insert(habit)
        try context.save()
    }
    @MainActor
    public func delete(id: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<SDHabit>(predicate: #Predicate { $0.id == id })
        if let found = try context.fetch(descriptor).first {
            context.delete(found)
            try context.save()
        }
    }
}

public final class LogLocalDataSource: LogLocalDataSourceProtocol {
    private let context: ModelContext?
    public init(context: ModelContext?) { self.context = context }
    @MainActor
    public func logs(for habitID: UUID) async throws -> [SDHabitLog] {
        guard let context else { return [] }
        // Use both relationship and habitID field for maximum compatibility
        let descriptor = FetchDescriptor<SDHabitLog>(predicate: #Predicate { 
            $0.habit?.id == habitID || $0.habitID == habitID 
        })
        return try context.fetch(descriptor)
    }
    @MainActor
    public func upsert(_ log: SDHabitLog) async throws {
        guard let context else { return }
        context.insert(log)
        try context.save()
    }
    @MainActor
    public func delete(id: UUID) async throws {
        guard let context else { return }
        let descriptor = FetchDescriptor<SDHabitLog>(predicate: #Predicate { $0.id == id })
        if let found = try context.fetch(descriptor).first {
            context.delete(found)
            try context.save()
        }
    }
}

public final class ProfileLocalDataSource: ProfileLocalDataSourceProtocol {
    private let context: ModelContext?
    public init(context: ModelContext?) { self.context = context }
    @MainActor
    public func load() async throws -> SDUserProfile? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<SDUserProfile>()
        return try context.fetch(descriptor).first
    }
    @MainActor
    public func save(_ profile: SDUserProfile) async throws {
        guard let context else { return }
        
        // Check if profile already exists
        let profileId = profile.id
        let descriptor = FetchDescriptor<SDUserProfile>(predicate: #Predicate { userProfile in
            userProfile.id == profileId
        })
        if let existing = try context.fetch(descriptor).first {
            // Update existing profile
            existing.name = profile.name
            existing.avatarImageData = profile.avatarImageData
            existing.appearance = profile.appearance
        } else {
            // Insert new profile
            context.insert(profile)
        }
        
        try context.save()
    }
}

public final class TipStaticDataSource: TipLocalDataSourceProtocol {
    public init() {}
    
    private lazy var predefinedTips: [Tip] = {
        [
            // Featured carousel tips
            Tip(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
                title: Strings.Tips.startSmallTitle,
                description: Strings.Tips.startSmallDescription,
                content: "Start with tiny habits that are so easy you can't fail. Want to read more? " +
                         "Start with just one page a day. Want to exercise? Start with 2 minutes. " +
                         "The key is consistency over intensity. Once the habit becomes automatic, " +
                         "you can gradually increase the difficulty.",
                category: .gettingStarted,
                order: 1,
                isFeaturedInCarousel: true,
                icon: "leaf"
            ),
            Tip(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!,
                title: Strings.Tips.consistencyTitle,
                description: Strings.Tips.consistencyDescription,
                content: "Consistency beats perfection every time. It's better to do a habit for 2 minutes " +
                         "every day than for 2 hours once a week. Your brain builds neural pathways through " +
                         "repetition, not intensity. Focus on showing up every day, even if it's just " +
                         "the minimum viable version of your habit.",
                category: .motivation,
                order: 2,
                isFeaturedInCarousel: true,
                icon: "calendar"
            ),
            Tip(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                title: Strings.Tips.trackImmediatelyTitle,
                description: Strings.Tips.trackImmediatelyDescription,
                content: "The best time to track your habit is immediately after you complete it. " +
                         "This creates a positive feedback loop and helps cement the habit in your mind. " +
                         "Don't wait until the end of the day when you might forget - track it right away " +
                         "and celebrate that small win!",
                category: .tracking,
                order: 3,
                isFeaturedInCarousel: true,
                icon: "checkmark.circle"
            ),
            
            // Additional non-carousel tips
            Tip(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!,
                title: "Stack Your Habits",
                description: "Link new habits to existing ones for better success",
                content: "Habit stacking is a powerful technique where you attach a new habit to an " +
                         "existing one. For example: 'After I pour my morning coffee, I will write down " +
                         "three things I'm grateful for.' This leverages the neural pathways of " +
                         "established habits to build new ones more effectively.",
                category: .gettingStarted,
                order: 4,
                isFeaturedInCarousel: false,
                icon: "link"
            ),
            Tip(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!,
                title: "Use Visual Cues",
                description: "Make your habits obvious with environmental design",
                content: "Your environment shapes your behavior more than you realize. Want to read more? " +
                         "Put a book on your pillow. Want to drink more water? Fill a water bottle and " +
                         "place it on your desk. Make good habits obvious and bad habits invisible by " +
                         "designing your environment strategically.",
                category: .advanced,
                order: 5,
                isFeaturedInCarousel: false,
                icon: "eye"
            ),
            Tip(
                id: UUID(uuidString: "66666666-6666-6666-6666-666666666666")!,
                title: "Track Streaks Wisely",
                description: "Focus on the process, not just the streak count",
                content: "While streaks can be motivating, don't let them become a source of stress. " +
                         "If you miss a day, don't break the chain - get back on track immediately. " +
                         "What matters most is the overall pattern over time, not perfect adherence. " +
                         "Aim for 80% consistency rather than 100% perfection.",
                category: .tracking,
                order: 6,
                isFeaturedInCarousel: false,
                icon: "chart.line.uptrend.xyaxis"
            ),
            Tip(
                id: UUID(uuidString: "77777777-7777-7777-7777-777777777777")!,
                title: "Identity-Based Habits",
                description: "Focus on who you want to become, not what you want to achieve",
                content: "Instead of saying 'I want to run a marathon,' say 'I am a runner.' Every time " +
                         "you complete your habit, you cast a vote for this new identity. The goal isn't " +
                         "to read a book, it's to become a reader. This shift in mindset makes habits " +
                         "feel less like work and more like expressions of who you are.",
                category: .motivation,
                order: 7,
                isFeaturedInCarousel: false,
                icon: "person.fill"
            ),
            Tip(
                id: UUID(uuidString: "88888888-8888-8888-8888-888888888888")!,
                title: "Two-Minute Rule",
                description: "Make new habits take less than two minutes to complete",
                content: "When starting a new habit, it should take less than two minutes to do. " +
                         "'Read before bed' becomes 'read one page.' 'Do thirty minutes of yoga' becomes " +
                         "'take out my yoga mat.' The point is to master the habit of showing up. " +
                         "Once you've established the routine, you can improve it.",
                category: .gettingStarted,
                order: 8,
                isFeaturedInCarousel: false,
                icon: "timer"
            )
        ]
    }()
    
    public func getAllTips() async throws -> [Tip] {
        predefinedTips
    }
    
    public func getFeaturedTips() async throws -> [Tip] {
        predefinedTips.filter { $0.isFeaturedInCarousel }
    }
    
    public func getTip(by id: UUID) async throws -> Tip? {
        predefinedTips.first { $0.id == id }
    }
    
    public func getTips(by category: TipCategory) async throws -> [Tip] {
        predefinedTips.filter { $0.category == category }
    }
}

public final class OnboardingLocalDataSource: OnboardingLocalDataSourceProtocol {
    private let context: ModelContext?
    public init(context: ModelContext?) { 
        self.context = context 
    }
    
    @MainActor
    public func load() async throws -> SDOnboardingState? {
        guard let context else { return nil }
        let descriptor = FetchDescriptor<SDOnboardingState>()
        return try context.fetch(descriptor).first
    }
    
    @MainActor
    public func save(_ state: SDOnboardingState) async throws {
        guard let context else { return }
        
        // Check if onboarding state already exists (there should only be one)
        let descriptor = FetchDescriptor<SDOnboardingState>()
        if let existing = try context.fetch(descriptor).first {
            // Update existing state
            existing.isCompleted = state.isCompleted
            existing.completedDate = state.completedDate
            existing.userName = state.userName
            existing.hasGrantedNotifications = state.hasGrantedNotifications
        } else {
            // Insert new state
            context.insert(state)
        }
        
        try context.save()
    }
}

public final class PersistenceCategoryDataSource: CategoryLocalDataSourceProtocol {
    private let context: ModelContext?
    
    public init(context: ModelContext?) { 
        self.context = context 
    }
    
    private lazy var predefinedCategories: [Category] = {
        [
            Category(
                id: "health",
                name: "health",
                displayName: "Health",
                emoji: "💪",
                order: 0,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.6,  // Disciplined health routines
                    "neuroticism": -0.3,       // Lower anxiety, stress management
                    "agreeableness": 0.2       // Self-care affects relationships
                ]
            ),
            Category(
                id: "wellness",
                name: "wellness",
                displayName: "Wellness",
                emoji: "🧘",
                order: 1,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.4,  // Regular wellness practices
                    "neuroticism": -0.5,       // Stress reduction, emotional stability
                    "openness": 0.3,           // Open to new wellness practices
                    "agreeableness": 0.2       // Mindfulness affects empathy
                ]
            ),
            Category(
                id: "productivity",
                name: "productivity",
                displayName: "Productivity",
                emoji: "⚡",
                order: 2,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.8,  // High organization and discipline
                    "neuroticism": -0.2,       // Confidence in systems
                    "openness": 0.1            // Trying new productivity methods
                ]
            ),
            Category(
                id: "learning",
                name: "learning",
                displayName: "Learning",
                emoji: "📚",
                order: 3,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "openness": 0.7,           // High curiosity and learning
                    "conscientiousness": 0.4,  // Disciplined study habits
                    "extraversion": -0.1       // Some preference for quiet study
                ]
            ),
            Category(
                id: "social",
                name: "social",
                displayName: "Social",
                emoji: "👥",
                order: 4,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "extraversion": 0.8,       // High social engagement
                    "agreeableness": 0.5,      // Cooperative and friendly
                    "openness": 0.2,           // Open to new social experiences
                    "neuroticism": -0.2        // Comfortable in social settings
                ]
            )
        ]
    }()
    
    private func getStoredCategories() async throws -> [Category] {
        guard let context else { return [] }
        let descriptor = FetchDescriptor<SDCategory>()
        let sdCategories = try context.fetch(descriptor)
        return sdCategories.map { CategoryMapper.fromSD($0) }
    }
    
    public func getAllCategories() async throws -> [Category] {
        let storedCategories = try await getStoredCategories()
        let allCategories = predefinedCategories + storedCategories
        return allCategories.sorted { $0.order < $1.order }
    }
    
    public func getCategory(by id: String) async throws -> Category? {
        let allCategories = try await getAllCategories()
        return allCategories.first { $0.id == id }
    }
    
    public func getActiveCategories() async throws -> [Category] {
        let allCategories = try await getAllCategories()
        return allCategories.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    public func getPredefinedCategories() async throws -> [Category] {
        predefinedCategories.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    public func getCustomCategories() async throws -> [Category] {
        let allCategories = try await getAllCategories()
        return allCategories.filter { !$0.isPredefined && $0.isActive }.sorted { $0.order < $1.order }
    }
    
    public func createCustomCategory(_ category: Category) async throws {
        guard let context else { return }
        
        // Check if category already exists
        let allCategories = try await getAllCategories()
        guard !allCategories.contains(where: { $0.id == category.id }) else {
            throw CategoryDataSourceError.categoryAlreadyExists
        }
        
        let sdCategory = CategoryMapper.toSD(category)
        context.insert(sdCategory)
        try context.save()
    }
    
    public func updateCategory(_ category: Category) async throws {
        guard let context else { return }
        
        // Find the existing category in SwiftData
        let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == category.id })
        guard let existingCategory = try context.fetch(descriptor).first else {
            throw CategoryDataSourceError.categoryNotFound
        }
        
        // Update the properties
        existingCategory.name = category.name
        existingCategory.displayName = category.displayName
        existingCategory.emoji = category.emoji
        existingCategory.order = category.order
        existingCategory.isActive = category.isActive
        existingCategory.isPredefined = category.isPredefined
        
        try context.save()
    }
    
    public func deleteCategory(id: String) async throws {
        guard let context else { return }
        
        // Find the category to delete
        let descriptor = FetchDescriptor<SDCategory>(predicate: #Predicate { $0.id == id })
        guard let categoryToDelete = try context.fetch(descriptor).first else {
            throw CategoryDataSourceError.categoryNotFound
        }
        
        context.delete(categoryToDelete)
        try context.save()
    }
    
    public func categoryExists(id: String) async throws -> Bool {
        let allCategories = try await getAllCategories()
        return allCategories.contains { $0.id == id }
    }
    
    public func categoryExists(name: String) async throws -> Bool {
        let allCategories = try await getAllCategories()
        return allCategories.contains { $0.name.lowercased() == name.lowercased() }
    }
}

public final class CategoryStaticDataSource: CategoryLocalDataSourceProtocol {
    public init() {}
    
    private lazy var predefinedCategories: [Category] = {
        [
            Category(
                id: "health",
                name: "health",
                displayName: "Health",
                emoji: "💪",
                order: 0,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.6,  // Disciplined health routines
                    "neuroticism": -0.3,       // Lower anxiety, stress management
                    "agreeableness": 0.2       // Self-care affects relationships
                ]
            ),
            Category(
                id: "wellness",
                name: "wellness",
                displayName: "Wellness",
                emoji: "🧘",
                order: 1,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.4,  // Regular wellness practices
                    "neuroticism": -0.5,       // Stress reduction, emotional stability
                    "openness": 0.3,           // Open to new wellness practices
                    "agreeableness": 0.2       // Mindfulness affects empathy
                ]
            ),
            Category(
                id: "productivity",
                name: "productivity",
                displayName: "Productivity",
                emoji: "⚡",
                order: 2,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "conscientiousness": 0.8,  // High organization and discipline
                    "neuroticism": -0.2,       // Confidence in systems
                    "openness": 0.1            // Trying new productivity methods
                ]
            ),
            Category(
                id: "learning",
                name: "learning",
                displayName: "Learning",
                emoji: "📚",
                order: 3,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "openness": 0.7,           // High curiosity and learning
                    "conscientiousness": 0.4,  // Disciplined study habits
                    "extraversion": -0.1       // Some preference for quiet study
                ]
            ),
            Category(
                id: "social",
                name: "social",
                displayName: "Social",
                emoji: "👥",
                order: 4,
                isActive: true,
                isPredefined: true,
                personalityWeights: [
                    "extraversion": 0.8,       // High social engagement
                    "agreeableness": 0.5,      // Cooperative and friendly
                    "openness": 0.2,           // Open to new social experiences
                    "neuroticism": -0.2        // Comfortable in social settings
                ]
            )
        ]
    }()
    
    private var customCategories: [Category] = []
    
    public func getAllCategories() async throws -> [Category] {
        let allCategories = predefinedCategories + customCategories
        return allCategories.sorted { $0.order < $1.order }
    }
    
    public func getCategory(by id: String) async throws -> Category? {
        let allCategories = predefinedCategories + customCategories
        return allCategories.first { $0.id == id }
    }
    
    public func getActiveCategories() async throws -> [Category] {
        let allCategories = predefinedCategories + customCategories
        return allCategories.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    public func getPredefinedCategories() async throws -> [Category] {
        predefinedCategories.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    public func getCustomCategories() async throws -> [Category] {
        customCategories.filter { $0.isActive }.sorted { $0.order < $1.order }
    }
    
    public func createCustomCategory(_ category: Category) async throws {
        guard !customCategories.contains(where: { $0.id == category.id }) else {
            throw CategoryDataSourceError.categoryAlreadyExists
        }
        customCategories.append(category)
    }
    
    public func updateCategory(_ category: Category) async throws {
        guard let index = customCategories.firstIndex(where: { $0.id == category.id }) else {
            throw CategoryDataSourceError.categoryNotFound
        }
        customCategories[index] = category
    }
    
    public func deleteCategory(id: String) async throws {
        guard let index = customCategories.firstIndex(where: { $0.id == id }) else {
            throw CategoryDataSourceError.categoryNotFound
        }
        customCategories.remove(at: index)
    }
    
    public func categoryExists(id: String) async throws -> Bool {
        let allCategories = predefinedCategories + customCategories
        return allCategories.contains { $0.id == id }
    }
    
    public func categoryExists(name: String) async throws -> Bool {
        let allCategories = predefinedCategories + customCategories
        return allCategories.contains { $0.name.lowercased() == name.lowercased() }
    }
}

public final class CategoryRemoteDataSource: CategoryLocalDataSourceProtocol {
    public init() {}
    
    // TODO: Implement backend integration when available
    // For now, this is a NoOp implementation - replace with real backend calls
    
    public func getAllCategories() async throws -> [Category] {
        // TODO: Fetch from backend API
        // For now, return empty array until backend is available
        return []
    }
    
    public func getCategory(by id: String) async throws -> Category? {
        // TODO: Fetch specific category from backend API
        return nil
    }
    
    public func getActiveCategories() async throws -> [Category] {
        // TODO: Fetch active categories from backend API
        return []
    }
    
    public func getPredefinedCategories() async throws -> [Category] {
        // TODO: Fetch predefined categories from backend API
        return []
    }
    
    public func getCustomCategories() async throws -> [Category] {
        // TODO: Fetch custom categories from backend API
        return []
    }
    
    public func createCustomCategory(_ category: Category) async throws {
        // TODO: Create custom category via backend API
        // For now, this is a NoOp until backend is available
    }
    
    public func updateCategory(_ category: Category) async throws {
        // TODO: Update category via backend API
        // For now, this is a NoOp until backend is available
    }
    
    public func deleteCategory(id: String) async throws {
        // TODO: Delete category via backend API
        // For now, this is a NoOp until backend is available
    }
    
    public func categoryExists(id: String) async throws -> Bool {
        // TODO: Check if category exists via backend API
        // For now, return false until backend is available
        return false
    }
    
    public func categoryExists(name: String) async throws -> Bool {
        // TODO: Check if category name exists via backend API
        // For now, return false until backend is available
        return false
    }
}
