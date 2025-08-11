//
//  ProductDuration.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum ProductDuration: String, Codable, CaseIterable {
    case monthly
    case annual
    
    public var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
}
