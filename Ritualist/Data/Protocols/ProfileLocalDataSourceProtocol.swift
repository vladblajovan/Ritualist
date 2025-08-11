//
//  ProfileLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

public protocol ProfileLocalDataSourceProtocol {
    @MainActor func load() async throws -> SDUserProfile?
    @MainActor func save(_ profile: SDUserProfile) async throws
}
