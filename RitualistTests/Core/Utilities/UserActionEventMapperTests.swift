//
//  UserActionEventMapperTests.swift
//  RitualistTests
//
//  Created by Claude on 28.11.2025.
//
//  Unit tests for UserActionEventMapper ensuring all events map correctly.
//

import Testing
import Foundation
@testable import RitualistCore

@Suite("UserActionEventMapper Tests", .tags(.isolated, .fast))
@MainActor
struct UserActionEventMapperTests {

    let mapper = UserActionEventMapper()

    // MARK: - Onboarding Permission Events

    @Test("Notification permission failed event maps correctly")
    func notificationPermissionFailedMapsCorrectly() {
        let event = UserActionEvent.onboardingNotificationPermissionFailed
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)

        #expect(name == "onboarding_notification_permission_failed")
        #expect(properties.isEmpty)
    }

    @Test("Location permission failed event maps correctly")
    func locationPermissionFailedMapsCorrectly() {
        let event = UserActionEvent.onboardingLocationPermissionFailed
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)

        #expect(name == "onboarding_location_permission_failed")
        #expect(properties.isEmpty)
    }

    @Test("Notification permission granted event maps correctly")
    func notificationPermissionGrantedMapsCorrectly() {
        let event = UserActionEvent.onboardingNotificationPermissionGranted
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_notification_permission_granted")
    }

    @Test("Notification permission denied event maps correctly")
    func notificationPermissionDeniedMapsCorrectly() {
        let event = UserActionEvent.onboardingNotificationPermissionDenied
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_notification_permission_denied")
    }

    @Test("Location permission granted event includes status")
    func locationPermissionGrantedIncludesStatus() {
        let event = UserActionEvent.onboardingLocationPermissionGranted(status: "authorizedWhenInUse")
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)

        #expect(name == "onboarding_location_permission_granted")
        #expect(properties["status"] as? String == "authorizedWhenInUse")
    }

    @Test("Location permission denied event maps correctly")
    func locationPermissionDeniedMapsCorrectly() {
        let event = UserActionEvent.onboardingLocationPermissionDenied
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_location_permission_denied")
    }

    // MARK: - Onboarding Flow Events

    @Test("Onboarding started event maps correctly")
    func onboardingStartedMapsCorrectly() {
        let event = UserActionEvent.onboardingStarted
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_started")
    }

    @Test("Onboarding completed event maps correctly")
    func onboardingCompletedMapsCorrectly() {
        let event = UserActionEvent.onboardingCompleted
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_completed")
    }

    @Test("Onboarding skipped event maps correctly")
    func onboardingSkippedMapsCorrectly() {
        let event = UserActionEvent.onboardingSkipped
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_skipped")
    }

    @Test("Onboarding page viewed includes page info")
    func onboardingPageViewedIncludesPageInfo() {
        let event = UserActionEvent.onboardingPageViewed(page: 2, pageName: "customization")
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)

        #expect(name == "onboarding_page_viewed")
        #expect(properties["page"] as? Int == 2)
        #expect(properties["page_name"] as? String == "customization")
    }

    @Test("Onboarding page next includes navigation info")
    func onboardingPageNextIncludesNavigationInfo() {
        let event = UserActionEvent.onboardingPageNext(fromPage: 1, toPage: 2)
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)

        #expect(name == "onboarding_page_next")
        #expect(properties["from_page"] as? Int == 1)
        #expect(properties["to_page"] as? Int == 2)
    }

    @Test("Onboarding page back includes navigation info")
    func onboardingPageBackIncludesNavigationInfo() {
        let event = UserActionEvent.onboardingPageBack(fromPage: 3, toPage: 2)
        let name = mapper.eventName(for: event)
        let properties = mapper.eventProperties(for: event)

        #expect(name == "onboarding_page_back")
        #expect(properties["from_page"] as? Int == 3)
        #expect(properties["to_page"] as? Int == 2)
    }

    @Test("Onboarding user name entered includes hasName flag")
    func onboardingUserNameEnteredIncludesFlag() {
        let eventWithName = UserActionEvent.onboardingUserNameEntered(hasName: true)
        let nameWithName = mapper.eventName(for: eventWithName)
        let propertiesWithName = mapper.eventProperties(for: eventWithName)

        #expect(nameWithName == "onboarding_user_name_entered")
        #expect(propertiesWithName["has_name"] as? Bool == true)

        let eventWithoutName = UserActionEvent.onboardingUserNameEntered(hasName: false)
        let propertiesWithoutName = mapper.eventProperties(for: eventWithoutName)

        #expect(propertiesWithoutName["has_name"] as? Bool == false)
    }

    @Test("Notification permission requested event maps correctly")
    func notificationPermissionRequestedMapsCorrectly() {
        let event = UserActionEvent.onboardingNotificationPermissionRequested
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_notification_permission_requested")
    }

    @Test("Location permission requested event maps correctly")
    func locationPermissionRequestedMapsCorrectly() {
        let event = UserActionEvent.onboardingLocationPermissionRequested
        let name = mapper.eventName(for: event)

        #expect(name == "onboarding_location_permission_requested")
    }
}
