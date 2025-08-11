//
//  TipRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import RitualistCore

public final class TipRepositoryImpl: TipRepository {
    private let local: TipLocalDataSourceProtocol
    public init(local: TipLocalDataSourceProtocol) { self.local = local }
    public func getAllTips() async throws -> [Tip] {
        try await local.getAllTips()
    }
    public func getFeaturedTips() async throws -> [Tip] {
        try await local.getFeaturedTips()
    }
    public func getTip(by id: UUID) async throws -> Tip? {
        try await local.getTip(by: id)
    }
    public func getTips(by category: TipCategory) async throws -> [Tip] {
        try await local.getTips(by: category)
    }
}
