//
//  TipLocalDataSourceProtocol.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 16.08.2025.
//

import Foundation

/// Protocol for local tip data source operations
public protocol TipLocalDataSourceProtocol: Sendable {
    /// Get all available tips
    func getAllTips() async throws -> [Tip]
    
    /// Get featured tips for display
    func getFeaturedTips() async throws -> [Tip]
    
    /// Get a specific tip by ID
    func getTip(by id: UUID) async throws -> Tip?
    
    /// Get tips filtered by category
    func getTips(by category: TipCategory) async throws -> [Tip]
}
