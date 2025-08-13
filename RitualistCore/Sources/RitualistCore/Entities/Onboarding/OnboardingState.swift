//
//  OnboardingState.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct OnboardingState: Codable, Hashable {
    public var isCompleted: Bool
    public var completedDate: Date?
    public var userName: String?
    public var hasGrantedNotifications: Bool
    
    public init(isCompleted: Bool = false, completedDate: Date? = nil, 
                userName: String? = nil, hasGrantedNotifications: Bool = false) {
        self.isCompleted = isCompleted
        self.completedDate = completedDate
        self.userName = userName
        self.hasGrantedNotifications = hasGrantedNotifications
    }
}
