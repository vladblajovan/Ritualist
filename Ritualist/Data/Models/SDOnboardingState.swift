//
//  SDOnboardingState.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation
import SwiftData

@Model public final class SDOnboardingState: @unchecked Sendable {
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
}
