//
//  OnboardingStateModel.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class OnboardingStateModel: @unchecked Sendable {
    @Attribute(.unique) public var id: UUID // TODO: Remove .unique when enabling CloudKit
    public var isCompleted: Bool = false // CloudKit requires default values
    public var completedDate: Date?
    public var userName: String?
    public var hasGrantedNotifications: Bool = false // CloudKit requires default values
    
    public init(id: UUID = UUID(), isCompleted: Bool = false, completedDate: Date? = nil,
                userName: String? = nil, hasGrantedNotifications: Bool = false) {
        self.id = id
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.userName = userName
        self.hasGrantedNotifications = hasGrantedNotifications
    }
    
    /// Convert SwiftData model to domain entity
    public func toEntity() -> OnboardingState {
        return OnboardingState(
            isCompleted: isCompleted, 
            completedDate: completedDate,
            userName: userName, 
            hasGrantedNotifications: hasGrantedNotifications
        )
    }
    
    /// Create SwiftData model from domain entity
    public static func fromEntity(_ state: OnboardingState) -> OnboardingStateModel {
        return OnboardingStateModel(
            isCompleted: state.isCompleted, 
            completedDate: state.completedDate,
            userName: state.userName, 
            hasGrantedNotifications: state.hasGrantedNotifications
        )
    }
}
