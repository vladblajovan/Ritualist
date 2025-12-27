//
//  TipRepository.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol TipRepository: Sendable {
    func getAllTips() async throws -> [Tip]
    func getFeaturedTips() async throws -> [Tip]
    func getTip(by id: UUID) async throws -> Tip?
    func getTips(by category: TipCategory) async throws -> [Tip]
}