//
//  AuthState.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum AuthState: Equatable {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case error(String)
    
    public var isAuthenticated: Bool {
        if case .authenticated = self { return true }
        return false
    }
    
    public var currentUser: User? {
        if case .authenticated(let user) = self { return user }
        return nil
    }
}
