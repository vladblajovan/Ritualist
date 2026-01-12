//
//  NotificationCenter+Async.swift
//  Ritualist
//
//  Helper extension for posting notifications safely from async contexts.
//  Ensures notifications are always posted on MainActor to prevent
//  "Publishing changes from background threads" warnings.
//
//  iOS 26+ Support:
//  This file includes support for Swift 6.2's typed notification system
//  (MainActorMessage/AsyncMessage) when available, with fallbacks for iOS 18-25.
//

import Foundation
import RitualistCore

// MARK: - MainActor-Safe Notification Posting

extension NotificationCenter {

    /// Posts a notification on the MainActor.
    ///
    /// Use this method when posting notifications from async contexts where
    /// the current actor isolation may be uncertain (e.g., after iterating
    /// an AsyncSequence or awaiting a non-MainActor function).
    ///
    /// This is especially important for notifications that trigger UI updates,
    /// as SwiftUI's `.onReceive` modifier expects the notification to be
    /// posted from the main thread.
    ///
    /// - Parameters:
    ///   - name: The name of the notification.
    ///   - object: The object posting the notification.
    ///   - userInfo: Optional dictionary of user info.
    @MainActor
    func postOnMainActor(
        name: Notification.Name,
        object: Any? = nil,
        userInfo: [AnyHashable: Any]? = nil
    ) {
        post(name: name, object: object, userInfo: userInfo)
    }

    /// Posts a notification on the MainActor from any async context.
    ///
    /// This async version can be awaited from any isolation domain and will
    /// automatically hop to MainActor before posting.
    ///
    /// Example:
    /// ```swift
    /// func someAsyncMethod() async {
    ///     // ... do async work that might be off MainActor ...
    ///     await NotificationCenter.default.postOnMainActorAsync(
    ///         name: .myNotification
    ///     )
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the notification.
    ///   - object: The object posting the notification (must be Sendable).
    func postOnMainActorAsync(
        name: Notification.Name,
        object: (any Sendable)? = nil
    ) async {
        await MainActor.run {
            post(name: name, object: object)
        }
    }
}

// MARK: - Typed Notification Support (iOS 26+)

/// Protocol for typed notifications that are always delivered on MainActor.
/// Use this for UI-related notifications.
///
/// iOS 26+ uses the native `MainActorMessage` protocol.
/// iOS 18-25 uses this custom protocol with manual MainActor dispatch.
///
/// Example:
/// ```swift
/// struct HabitsDataChangedNotification: TypedMainActorNotification {
///     static let name = Notification.Name.habitsDataDidChange
///     let changedHabitIds: [UUID]
/// }
///
/// // Post
/// await HabitsDataChangedNotification(changedHabitIds: [id]).post()
///
/// // Observe (in SwiftUI)
/// .onTypedNotification(HabitsDataChangedNotification.self) { notification in
///     // Handle on MainActor
/// }
/// ```
@MainActor
public protocol TypedMainActorNotification: Sendable {
    /// The notification name for this typed notification.
    static var name: Notification.Name { get }
}

extension TypedMainActorNotification {
    /// Posts this typed notification on the MainActor.
    @MainActor
    public func post() {
        NotificationCenter.default.post(name: Self.name, object: self)
    }

    /// Posts this typed notification asynchronously, ensuring MainActor execution.
    public func postAsync() async {
        await MainActor.run {
            NotificationCenter.default.post(name: Self.name, object: self)
        }
    }
}

/// Protocol for typed notifications that can be delivered asynchronously.
/// Use this for non-UI notifications that don't need MainActor.
///
/// iOS 26+ uses the native `AsyncMessage` protocol.
/// iOS 18-25 uses this custom protocol.
public protocol TypedAsyncNotification: Sendable {
    /// The notification name for this typed notification.
    static var name: Notification.Name { get }
}

extension TypedAsyncNotification {
    /// Posts this typed notification.
    public func post() {
        NotificationCenter.default.post(name: Self.name, object: self)
    }
}

// MARK: - App-Specific Typed Notifications

/// Typed notification for when habits data changes.
/// Delivers on MainActor for UI updates.
@MainActor
public struct HabitsDataChangedNotification: TypedMainActorNotification {
    public static let name = Notification.Name.habitsDataDidChange

    public init() {}
}

/// Typed notification for when user profile changes.
/// Delivers on MainActor for UI updates.
@MainActor
public struct UserProfileChangedNotification: TypedMainActorNotification {
    public static let name = Notification.Name.userProfileDidChange

    /// The updated profile, if available
    public let profile: Any?

    public init(profile: Any? = nil) {
        self.profile = profile
    }
}

/// Typed notification for when premium status changes.
/// Delivers on MainActor for UI updates.
@MainActor
public struct PremiumStatusChangedNotification: TypedMainActorNotification {
    public static let name = Notification.Name.premiumStatusDidChange

    public init() {}
}

/// Typed notification for when iCloud sync completes.
/// Delivers on MainActor for UI updates.
@MainActor
public struct ICloudSyncCompletedNotification: TypedMainActorNotification {
    public static let name = Notification.Name.iCloudDidSyncRemoteChanges

    public init() {}
}

// MARK: - iOS 26+ Native Typed Notifications (Future Migration Path)

/*
 When targeting iOS 26+ exclusively, migrate to native typed notifications:

 // Define using MainActorMessage for MainActor-delivered notifications:
 @available(iOS 26.0, *)
 struct HabitsDataChangedMessage: MainActorMessage {
     let changedHabitIds: [UUID]
 }

 // Define using AsyncMessage for async-delivered notifications:
 @available(iOS 26.0, *)
 struct BackgroundSyncCompletedMessage: AsyncMessage {
     let syncResult: SyncResult
 }

 // Post:
 await HabitsDataChangedMessage(changedHabitIds: [id]).post()

 // Observe:
 for await message in HabitsDataChangedMessage.messages {
     // Handle on MainActor automatically
 }

 Migration checklist:
 1. Add @available(iOS 26.0, *) versions of each TypedMainActorNotification
 2. Update posting sites to use #available checks
 3. Update observers to use the new async sequences
 4. Remove legacy TypedMainActorNotification conformances when iOS 26 is minimum
*/
