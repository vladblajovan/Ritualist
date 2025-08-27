//
//  LogRepository.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public protocol LogRepository {
    func logs(for habitID: UUID) async throws -> [HabitLog]
    func logs(for habitIDs: [UUID]) async throws -> [HabitLog]
    func upsert(_ log: HabitLog) async throws
    func deleteLog(id: UUID) async throws
}