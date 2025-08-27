//
//  IsPersonalityAnalysisEnabledUseCase.swift
//  Ritualist
//
//  Created by Claude on 27.08.2025.
//

import Foundation
import RitualistCore

public final class DefaultIsPersonalityAnalysisEnabledUseCase: IsPersonalityAnalysisEnabledUseCase {
    private let repository: PersonalityAnalysisRepositoryProtocol
    
    public init(repository: PersonalityAnalysisRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(for userId: UUID) async throws -> Bool {
        return try await repository.isPersonalityAnalysisEnabled(for: userId)
    }
}