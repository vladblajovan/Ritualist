//
//  SmartInsight.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct SmartInsight {
    public let title: String
    public let message: String
    public let type: InsightType
    
    public enum InsightType {
        case pattern
        case suggestion
        case celebration
        case warning
    }
    
    public init(title: String, message: String, type: InsightType) {
        self.title = title
        self.message = message
        self.type = type
    }
}