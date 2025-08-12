import Foundation
import FactoryKit
import RitualistCore

// MARK: - Settings Use Cases Container Extensions

extension Container {
    
    // MARK: - Profile Operations
    
    var saveProfile: Factory<SaveProfile> {
        self { SaveProfile(repo: self.profileRepository()) }
    }
    
    // MARK: - Notification Operations
    
    var requestNotificationPermission: Factory<RequestNotificationPermission> {
        self { RequestNotificationPermission(notificationService: self.notificationService()) }
    }
    
    var checkNotificationStatus: Factory<CheckNotificationStatus> {
        self { CheckNotificationStatus(notificationService: self.notificationService()) }
    }
}