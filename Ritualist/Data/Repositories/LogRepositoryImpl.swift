//
//  LogRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData
import RitualistCore

public final class LogRepositoryImpl: LogRepository {
    private let local: LogLocalDataSourceProtocol
    public init(local: LogLocalDataSourceProtocol) { 
        self.local = local
    }
    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        try await local.logs(for: habitID)
    }
    public func upsert(_ log: HabitLog) async throws {
        try await local.upsert(log)
    }
    public func deleteLog(id: UUID) async throws {
        try await local.delete(id: id)
    }
}
