//
//  ProfileLocalDataSourceProtocol.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import RitualistCore

public protocol ProfileLocalDataSourceProtocol {
    func load() async throws -> UserProfile?
    func save(_ profile: UserProfile) async throws
}
