//
//  ProgressChartDataPoint.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 13.08.2025.
//


import Foundation

public struct ProgressChartDataPoint {
    public let date: Date
    public let completionRate: Double
    
    public init(date: Date, completionRate: Double) {
        self.date = date
        self.completionRate = completionRate
    }
}