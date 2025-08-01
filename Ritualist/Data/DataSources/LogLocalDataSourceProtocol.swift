//
//  LogLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

public protocol LogLocalDataSourceProtocol {
    @MainActor func logs(for habitID: UUID) async throws -> [SDHabitLog]
    @MainActor func upsert(_ log: SDHabitLog) async throws
    @MainActor func delete(id: UUID) async throws
}
