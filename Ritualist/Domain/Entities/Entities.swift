import Foundation

public enum HabitKind: Codable, Equatable, Hashable { case binary, numeric }
public enum HabitSchedule: Codable, Equatable, Hashable {
    case daily
    case daysOfWeek(Set<Int>) // 1=Mon…7=Sun
    case timesPerWeek(Int) // 1…7
}

public struct ReminderTime: Codable, Hashable {
    public var hour: Int; public var minute: Int
    public init(hour: Int, minute: Int) { self.hour = hour; self.minute = minute }
}

public struct Habit: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var emoji: String?
    public var kind: HabitKind
    public var unitLabel: String?
    public var dailyTarget: Double?
    public var schedule: HabitSchedule
    public var reminders: [ReminderTime]
    public var startDate: Date
    public var endDate: Date?
    public var isActive: Bool
    public init(id: UUID = UUID(), name: String, colorHex: String = "#2DA9E3", emoji: String? = nil,
                kind: HabitKind = .binary, unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, reminders: [ReminderTime] = [],
                startDate: Date = Date(), endDate: Date? = nil, isActive: Bool = true) {
        self.id = id; self.name = name; self.colorHex = colorHex; self.emoji = emoji
        self.kind = kind; self.unitLabel = unitLabel; self.dailyTarget = dailyTarget
        self.schedule = schedule; self.reminders = reminders
        self.startDate = startDate; self.endDate = endDate; self.isActive = isActive
    }
}

public struct HabitLog: Identifiable, Codable, Hashable {
    public var id: UUID
    public var habitID: UUID
    public var date: Date
    public var value: Double?
    public init(id: UUID = UUID(), habitID: UUID, date: Date, value: Double? = nil) {
        self.id = id; self.habitID = habitID; self.date = date; self.value = value
    }
}

public struct UserProfile: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var avatarImageData: Data?
    public var firstDayOfWeek: Int // 1..7
    public var appearance: Int // 0 followSystem, 1 light, 2 dark
    public init(id: UUID = UUID(), name: String = "", avatarImageData: Data? = nil,
                firstDayOfWeek: Int = 2, appearance: Int = 0) {
        self.id = id; self.name = name; self.avatarImageData = avatarImageData
        self.firstDayOfWeek = firstDayOfWeek; self.appearance = appearance
    }
}

public enum TipCategory: String, Codable, CaseIterable {
    case gettingStarted = "getting_started"
    case tracking = "tracking" 
    case motivation = "motivation"
    case advanced = "advanced"
}

public struct Tip: Identifiable, Codable, Hashable {
    public var id: UUID
    public var title: String
    public var description: String // Short description for carousel
    public var content: String // Full content for detail view
    public var category: TipCategory
    public var order: Int // For carousel ordering
    public var isFeaturedInCarousel: Bool
    public var icon: String? // SF Symbol name
    
    public init(id: UUID = UUID(), title: String, description: String, content: String,
                category: TipCategory, order: Int = 0, isFeaturedInCarousel: Bool = false,
                icon: String? = nil) {
        self.id = id; self.title = title; self.description = description; self.content = content
        self.category = category; self.order = order
        self.isFeaturedInCarousel = isFeaturedInCarousel; self.icon = icon
    }
}

public struct OnboardingState: Codable, Hashable {
    public var isCompleted: Bool
    public var completedDate: Date?
    public var userName: String?
    public var hasGrantedNotifications: Bool
    
    public init(isCompleted: Bool = false, completedDate: Date? = nil, 
                userName: String? = nil, hasGrantedNotifications: Bool = false) {
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.userName = userName
        self.hasGrantedNotifications = hasGrantedNotifications
    }
}

public enum HabitSuggestionCategory: String, CaseIterable {
    case health
    case wellness
    case productivity
    case learning
    case social
}

public struct HabitSuggestion: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let emoji: String
    public let colorHex: String
    public let category: HabitSuggestionCategory
    public let kind: HabitKind
    public let unitLabel: String?
    public let dailyTarget: Double?
    public let schedule: HabitSchedule
    public let description: String
    
    public init(id: String, name: String, emoji: String, colorHex: String,
                category: HabitSuggestionCategory, kind: HabitKind,
                unitLabel: String? = nil, dailyTarget: Double? = nil,
                schedule: HabitSchedule = .daily, description: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorHex = colorHex
        self.category = category
        self.kind = kind
        self.unitLabel = unitLabel
        self.dailyTarget = dailyTarget
        self.schedule = schedule
        self.description = description
    }
    
    /// Convert suggestion to a habit entity
    public func toHabit() -> Habit {
        Habit(
            name: name,
            colorHex: colorHex,
            emoji: emoji,
            kind: kind,
            unitLabel: unitLabel,
            dailyTarget: dailyTarget,
            schedule: schedule,
            reminders: [],
            startDate: Date(),
            endDate: nil,
            isActive: true
        )
    }
}

// MARK: - Authentication Entities

public enum SubscriptionPlan: String, Codable, CaseIterable {
    case free = "free"
    case monthly = "monthly"
    case annual = "annual"
    
    public var displayName: String {
        switch self {
        case .free: return "Free"
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
    
    public var price: String {
        switch self {
        case .free: return "$0"
        case .monthly: return "$9.99"
        case .annual: return "$39.99"
        }
    }
}

public struct User: Identifiable, Codable, Hashable {
    public var id: UUID
    public var email: String
    public var name: String
    public var subscriptionPlan: SubscriptionPlan
    public var subscriptionExpiryDate: Date?
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), email: String, name: String, 
                subscriptionPlan: SubscriptionPlan = .free, 
                subscriptionExpiryDate: Date? = nil,
                createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.email = email
        self.name = name
        self.subscriptionPlan = subscriptionPlan
        self.subscriptionExpiryDate = subscriptionExpiryDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public var hasActiveSubscription: Bool {
        switch subscriptionPlan {
        case .free: return false
        case .monthly, .annual:
            guard let expiryDate = subscriptionExpiryDate else { return false }
            return expiryDate > Date()
        }
    }
    
    public var isPremiumUser: Bool {
        hasActiveSubscription
    }
}

public enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
    
    public var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
    
    public var currentUser: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}

public struct AuthCredentials {
    public let email: String
    public let password: String
    
    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case networkError
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network connection error"
        case .unknown(let message):
            return message
        }
    }
}

// MARK: - Paywall Entities

public struct Product: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let price: String
    public let localizedPrice: String
    public let subscriptionPlan: SubscriptionPlan
    public let duration: ProductDuration
    public let features: [String]
    public let isPopular: Bool
    public let discount: String?
    
    public init(id: String, name: String, description: String, price: String, 
                localizedPrice: String, subscriptionPlan: SubscriptionPlan, 
                duration: ProductDuration, features: [String], 
                isPopular: Bool = false, discount: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.localizedPrice = localizedPrice
        self.subscriptionPlan = subscriptionPlan
        self.duration = duration
        self.features = features
        self.isPopular = isPopular
        self.discount = discount
    }
}

public enum ProductDuration: String, Codable, CaseIterable {
    case monthly = "monthly"
    case annual = "annual"
    
    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
}

public enum PurchaseState: Equatable {
    case idle
    case purchasing(String) // product ID
    case success(Product)
    case failed(String)
    case cancelled
    
    public var isPurchasing: Bool {
        if case .purchasing = self { return true }
        return false
    }
    
    public var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}

public struct PaywallBenefit: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String // SF Symbol name
    public let isHighlighted: Bool
    
    public init(id: String, title: String, description: String, 
                icon: String, isHighlighted: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isHighlighted = isHighlighted
    }
    
    public static var defaultBenefits: [PaywallBenefit] {
        [
            PaywallBenefit(
                id: "unlimited_habits",
                title: "Unlimited Habits",
                description: "Track as many habits as you want",
                icon: "infinity.circle.fill",
                isHighlighted: true
            ),
            PaywallBenefit(
                id: "advanced_analytics",
                title: "Advanced Analytics",
                description: "Detailed insights and streak tracking",
                icon: "chart.line.uptrend.xyaxis.circle.fill"
            ),
            PaywallBenefit(
                id: "custom_reminders",
                title: "Custom Reminders",
                description: "Set personalized notification times",
                icon: "bell.badge.circle.fill"
            ),
            PaywallBenefit(
                id: "data_export",
                title: "Data Export",
                description: "Export your habit data to CSV",
                icon: "square.and.arrow.up.circle.fill"
            ),
            PaywallBenefit(
                id: "priority_support",
                title: "Priority Support",
                description: "Get help faster with premium support",
                icon: "person.badge.plus.fill"
            ),
            PaywallBenefit(
                id: "themes",
                title: "Premium Themes",
                description: "Beautiful color schemes and customization",
                icon: "paintpalette.fill"
            )
        ]
    }
}

public enum PaywallError: Error, LocalizedError {
    case productsNotAvailable
    case purchaseFailed(String)
    case userCancelled
    case networkError
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .productsNotAvailable:
            return "Products are not available"
        case .purchaseFailed(let message):
            return "Purchase failed: \(message)"
        case .userCancelled:
            return "Purchase was cancelled"
        case .networkError:
            return "Network connection error"
        case .unknown(let message):
            return message
        }
    }
}
