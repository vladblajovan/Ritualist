//
//  LogRepositoryImpl.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

public final class LogRepositoryImpl: LogRepository {
    private let local: LogLocalDataSourceProtocol
    private let context: ModelContext?
    public init(local: LogLocalDataSourceProtocol, context: ModelContext? = nil) { 
        self.local = local
        self.context = context
    }
    public func logs(for habitID: UUID) async throws -> [HabitLog] {
        let sds = try await local.logs(for: habitID)
        return sds.map { HabitLogMapper.fromSD($0) }
    }
    public func upsert(_ log: HabitLog) async throws {
        let sd = HabitLogMapper.toSD(log, context: context)
        try await local.upsert(sd)
    }
    public func deleteLog(id: UUID) async throws {
        try await local.delete(id: id)
    }
}
