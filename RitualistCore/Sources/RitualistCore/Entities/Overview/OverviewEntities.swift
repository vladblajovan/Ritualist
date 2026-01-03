//
//  OverviewEntities.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

public struct OverviewPersonalityInsight: Identifiable, Hashable {
    public let id = UUID()
    public let title: String
    public let message: String
    public let type: OverviewPersonalityInsightType
    
    public init(title: String, message: String, type: OverviewPersonalityInsightType) {
        self.title = title
        self.message = message
        self.type = type
    }
}

public enum OverviewPersonalityInsightType: CaseIterable {
    case pattern
    case recommendation  
    case motivation
    
    public var icon: String {
        switch self {
        case .pattern:
            return "brain.head.profile"
        case .recommendation:
            return "lightbulb"
        case .motivation:
            return "heart"
        }
    }
    
    @available(iOS 13.0, watchOS 6.0, macOS 10.15, *)
    public var color: Color {
        switch self {
        case .pattern:
            return .purple
        case .recommendation:
            return .orange
        case .motivation:
            return .pink
        }
    }
}

#endif
