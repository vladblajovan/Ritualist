//
//  Double+Currency.swift
//  RitualistCore
//
//  Created on 2025-11-20
//  Currency formatting extension for Double
//

import Foundation

public extension Double {
    /// Format a double value as a currency string
    /// - Parameter currencyCode: The ISO currency code (defaults to "USD")
    /// - Returns: Formatted currency string
    func asCurrency(currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: self)) ?? "$\(String(format: "%.2f", self))"
    }
}
