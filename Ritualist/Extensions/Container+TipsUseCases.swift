import Foundation
import FactoryKit
import RitualistCore

// MARK: - Tips Use Cases Container Extensions

extension Container {
    
    // MARK: - Tips Operations
    
    var getAllTips: Factory<GetAllTips> {
        self { GetAllTips(repo: self.tipRepository()) }
    }
    
    var getFeaturedTips: Factory<GetFeaturedTips> {
        self { GetFeaturedTips(repo: self.tipRepository()) }
    }
    
    var getTipById: Factory<GetTipById> {
        self { GetTipById(repo: self.tipRepository()) }
    }
    
    var getTipsByCategory: Factory<GetTipsByCategory> {
        self { GetTipsByCategory(repo: self.tipRepository()) }
    }
}