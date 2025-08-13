//
//  ValidationResult.swift
//  RitualistCore
//
//  Created by Vlad Blajovan on 14.08.2025.
//


import Foundation

/// Result of a domain validation operation
public enum ValidationResult {
    case valid
    case invalid(reason: String)
    
    /// Whether the validation passed
    public var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
    
    /// The validation error message, if any
    public var errorMessage: String? {
        switch self {
        case .valid: return nil
        case .invalid(let reason): return reason
        }
    }
}