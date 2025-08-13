//
//  FeatureType.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

public enum FeatureType: String, CaseIterable {
    case unlimitedHabits = "unlimited_habits"
    case advancedAnalytics = "advanced_analytics"
    case customReminders = "custom_reminders"
    case dataExport = "data_export"
    case premiumThemes = "premium_themes"
    case prioritySupport = "priority_support"
    
    public var displayName: String {
        switch self {
        case .unlimitedHabits: return "Unlimited Habits"
        case .advancedAnalytics: return "Advanced Analytics"
        case .customReminders: return "Custom Reminders"
        case .dataExport: return "Data Export"
        case .premiumThemes: return "Premium Themes"
        case .prioritySupport: return "Priority Support"
        }
    }
}