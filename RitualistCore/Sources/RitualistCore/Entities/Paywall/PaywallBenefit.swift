//
//  PaywallBenefit.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct PaywallBenefit: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let description: String
    public let icon: String
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
                isHighlighted: false
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
                id: "data_import_export",
                title: "Import & Export",
                description: "Import or export your habit data",
                icon: "arrow.up.arrow.down.circle.fill"
            )
        ]
    }
}
