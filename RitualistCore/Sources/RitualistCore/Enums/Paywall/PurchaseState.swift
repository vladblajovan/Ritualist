//
//  PurchaseState 2.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public enum PurchaseState: Equatable, Sendable {
    case idle
    case purchasing(String) // product ID
    case success(Product)
    case failed(String)
    case cancelled
    
    public var isPurchasing: Bool {
        if case .purchasing = self { return true }
        return false
    }
    
    public var errorMessage: String? {
        if case .failed(let message) = self { return message }
        return nil
    }
}
