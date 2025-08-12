//
//  LogLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import RitualistCore

public protocol LogLocalDataSourceProtocol {
    func logs(for habitID: UUID) async throws -> [HabitLog]
    func upsert(_ log: HabitLog) async throws
    func delete(id: UUID) async throws
}
