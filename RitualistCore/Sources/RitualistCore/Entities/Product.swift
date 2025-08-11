//
//  Product.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 01.08.2025.
//

import Foundation

public struct Product: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let description: String
    public let price: String
    public let localizedPrice: String
    public let subscriptionPlan: SubscriptionPlan
    public let duration: ProductDuration
    public let features: [String]
    public let isPopular: Bool
    public let discount: String?
    
    public init(id: String, name: String, description: String, price: String, 
                localizedPrice: String, subscriptionPlan: SubscriptionPlan, 
                duration: ProductDuration, features: [String], 
                isPopular: Bool = false, discount: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.localizedPrice = localizedPrice
        self.subscriptionPlan = subscriptionPlan
        self.duration = duration
        self.features = features
        self.isPopular = isPopular
        self.discount = discount
    }
}
