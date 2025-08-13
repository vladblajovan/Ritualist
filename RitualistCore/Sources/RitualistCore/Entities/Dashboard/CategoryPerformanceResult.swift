//
//  CategoryPerformanceResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct CategoryPerformanceResult {
    public let categoryId: String
    public let categoryName: String
    public let completionRate: Double
    public let habitCount: Int
    public let color: String
    public let emoji: String?
    
    public init(
        categoryId: String,
        categoryName: String,
        completionRate: Double,
        habitCount: Int,
        color: String,
        emoji: String? = nil
    ) {
        self.categoryId = categoryId
        self.categoryName = categoryName
        self.completionRate = completionRate
        self.habitCount = habitCount
        self.color = color
        self.emoji = emoji
    }
}