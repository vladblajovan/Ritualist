//
//  AuthError 2.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum AuthError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case networkError
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .userNotFound:
            return "User not found"
        case .networkError:
            return "Network connection error"
        case .unknown(let message):
            return message
        }
    }
}
