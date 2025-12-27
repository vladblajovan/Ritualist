import Testing
import Foundation
import SwiftData
@testable import RitualistCore

/// Tests for TimezoneService (Phase 2)
///
/// **Service Purpose:** Manages three-timezone model (Current/Home/Display)
/// **Why Critical:** Complex timezone logic affects all habit calculations and travel detection
/// **Test Strategy:** Use REAL dependencies with TestModelContainer (NO MOCKS)
///
/// **CI Timezone Note:**
/// Tests comparing against `TimeZone.current` are timezone-agnostic by design:
/// - Fallback tests verify the service returns device timezone when no profile exists
/// - Detection tests use Pacific/Kiritimati (UTC+14) - virtually no CI system uses this timezone
/// - Tests safely skip if somehow running in that timezone (extremely rare edge case)
///
/// **Test Coverage:**
/// - Getters (8 tests): Current, Home, Display timezone resolution modes
/// - Setters (7 tests): Update operations with history logging
/// - History Management (2 tests): Trimming to 100 entries
/// - Detection (7 tests): Timezone change and travel detection
/// - Update Operations (4 tests): Current timezone updates and change tracking
#if swift(>=6.1)
@Suite(
    "TimezoneService Tests",
    .tags(.timezone, .travel, .businessLogic, .critical, .database, .integration)
)
#else
@Suite("TimezoneService Tests")
#endif
struct TimezoneServiceTests {

    // MARK: - Test Helpers

    /// Create service with REAL dependencies (NO MOCKS)
    /// Following the pattern from HabitCompletionCheckServiceTests
    func createService(container: ModelContainer) -> DefaultTimezoneService {
        // Create REAL data source with TestModelContainer
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)

        // Create REAL repository
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)

        // Create REAL use cases
        let loadProfile = LoadProfile(repo: profileRepository)
        let saveProfile = SaveProfile(repo: profileRepository)

        // Create service with REAL dependencies
        return DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )
    }

    /// Save a user profile to the test container
    func saveProfile(_ profile: UserProfile, to container: ModelContainer) async throws {
        let context = ModelContext(container)
        let profileModel = profile.toModel()
        context.insert(profileModel)
        try context.save()
    }

    // MARK: - First Launch Tests (Profile Doesn't Exist)

    @Test("getHomeTimezone creates default profile on first launch")
    func getHomeTimezoneCreatesDefaultProfileOnFirstLaunch() async throws {
        let container = try TestModelContainer.create()
        // DO NOT save a profile - simulate first app launch

        let service = createService(container: container)

        // Should create default profile and return home timezone
        let homeTz = try await service.getHomeTimezone()

        // Verify it returned the current timezone (default for new profiles)
        #expect(homeTz.identifier == TimeZone.current.identifier)

        // Verify default profile was created in database
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let loadedProfile = try await profileRepository.loadProfile()

        #expect(loadedProfile != nil, "Default profile should be created on first launch")
    }

    @Test("getDisplayTimezone creates default profile on first launch")
    func getDisplayTimezoneCreatesDefaultProfileOnFirstLaunch() async throws {
        let container = try TestModelContainer.create()
        // DO NOT save a profile - simulate first app launch

        let service = createService(container: container)

        // Should create default profile and return display timezone
        let displayTz = try await service.getDisplayTimezone()

        // Verify it returned the current timezone (default for new profiles)
        #expect(displayTz.identifier == TimeZone.current.identifier)

        // Verify default profile was created
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let loadedProfile = try await profileRepository.loadProfile()

        #expect(loadedProfile != nil, "Default profile should be created on first launch")
    }

    @Test("updateHomeTimezone creates default profile if missing")
    func updateHomeTimezoneCreatesDefaultProfileIfMissing() async throws {
        let container = try TestModelContainer.create()
        // DO NOT save a profile - simulate corrupted state

        let service = createService(container: container)

        // Should create default profile and update it
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify profile was created and updated
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let loadedProfile = try await profileRepository.loadProfile()

        #expect(loadedProfile != nil, "Profile should be created if missing")
        #expect(loadedProfile?.homeTimezoneIdentifier == TimezoneTestHelpers.tokyo.identifier)
    }

    // MARK: - Getters Tests

    @Test("getCurrentTimezone returns device timezone")
    func getCurrentTimezoneReturnsDeviceTimezone() async throws {
        let container = try TestModelContainer.create()
        let service = createService(container: container)

        let currentTz = await service.getCurrentTimezone()

        #expect(currentTz == TimeZone.current)
    }

    @Test("getHomeTimezone returns stored home timezone")
    func getHomeTimezoneReturnsStoredHomeTimezone() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            homeTimezone: TimezoneTestHelpers.tokyo
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let homeTz = try await service.getHomeTimezone()

        #expect(homeTz.identifier == TimezoneTestHelpers.tokyo.identifier)
    }

    @Test("getHomeTimezone falls back to current on invalid identifier")
    func getHomeTimezoneFallsBackToCurrentOnInvalidIdentifier() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()
        profile.homeTimezoneIdentifier = "Invalid/Timezone"  // Invalid identifier
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let homeTz = try await service.getHomeTimezone()

        // Should fall back to TimeZone.current
        #expect(homeTz == TimeZone.current)
    }

    @Test("getDisplayTimezoneMode returns stored display mode")
    func getDisplayTimezoneModeReturnsStoredDisplayMode() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            displayMode: .home
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let mode = try await service.getDisplayTimezoneMode()

        #expect(mode == .home)
    }

    @Test("getDisplayTimezone resolves based on mode - current (uses live device timezone)")
    func getDisplayTimezoneResolvesModeCurrentCorrectly() async throws {
        let container = try TestModelContainer.create()
        let storedCurrentTz = TimezoneTestHelpers.newYork
        let homeTz = TimezoneTestHelpers.tokyo

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedCurrentTz,
            homeTimezone: homeTz,
            displayMode: .current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let displayTz = try await service.getDisplayTimezone()

        // In .current mode, should resolve to LIVE device timezone (TimeZone.current),
        // NOT the stored currentTimezoneIdentifier. The stored value is for change detection,
        // but display should always use the actual device timezone.
        #expect(displayTz.identifier == TimeZone.current.identifier)
    }

    @Test("getDisplayTimezone resolves based on mode - home")
    func getDisplayTimezoneResolvesModeHomeCorrectly() async throws {
        let container = try TestModelContainer.create()
        let currentTz = TimezoneTestHelpers.newYork
        let homeTz = TimezoneTestHelpers.tokyo

        let profile = UserProfileBuilder.standard(
            currentTimezone: currentTz,
            homeTimezone: homeTz,
            displayMode: .home
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let displayTz = try await service.getDisplayTimezone()

        // Should resolve to home timezone
        #expect(displayTz.identifier == homeTz.identifier)
    }

    @Test("getDisplayTimezone resolves based on mode - custom")
    func getDisplayTimezoneResolvesModeCustomCorrectly() async throws {
        let container = try TestModelContainer.create()
        let currentTz = TimezoneTestHelpers.newYork
        let homeTz = TimezoneTestHelpers.tokyo
        let customTz = TimezoneTestHelpers.london

        let profile = UserProfileBuilder.standard(
            currentTimezone: currentTz,
            homeTimezone: homeTz,
            displayMode: .custom(customTz.identifier)
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let displayTz = try await service.getDisplayTimezone()

        // Should resolve to custom timezone
        #expect(displayTz.identifier == customTz.identifier)
    }

    @Test("getDisplayTimezone falls back to current on invalid identifier")
    func getDisplayTimezoneFallsBackToCurrentOnInvalidIdentifier() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()
        profile.displayTimezoneMode = .custom("Invalid/Timezone")
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let displayTz = try await service.getDisplayTimezone()

        // Should fall back to TimeZone.current
        #expect(displayTz == TimeZone.current)
    }

    // MARK: - Setters Tests

    @Test("updateHomeTimezone updates profile")
    func updateHomeTimezoneUpdatesProfile() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            homeTimezone: TimezoneTestHelpers.newYork
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update to Tokyo timezone
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify profile was saved with new timezone
        let updatedProfile = try await service.getHomeTimezone()
        #expect(updatedProfile.identifier == TimezoneTestHelpers.tokyo.identifier)
    }

    @Test("updateHomeTimezone logs timezone change")
    func updateHomeTimezoneLogsTimezoneChange() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            homeTimezone: TimezoneTestHelpers.newYork
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update to Tokyo timezone
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify timezone change was logged
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.timezoneChangeHistory.count == 1)

        let change = updatedProfile?.timezoneChangeHistory.first
        #expect(change?.fromTimezone == TimezoneTestHelpers.newYork.identifier)
        #expect(change?.toTimezone == TimezoneTestHelpers.tokyo.identifier)
        #expect(change?.trigger == .userUpdate)
    }

    @Test("updateHomeTimezone validates timezone can be recreated")
    func updateHomeTimezoneValidatesTimezoneCanBeRecreated() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard()
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Test that valid timezones are accepted
        // The implementation has a defensive check: TimeZone(identifier: newHomeTimezone) != nil
        // This verifies the timezone can be recreated from its identifier
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify timezone was successfully updated
        let updated = try await service.getHomeTimezone()
        #expect(updated.identifier == TimezoneTestHelpers.tokyo.identifier)

        // Note: Swift's TimeZone type validates identifiers at creation time,
        // so we cannot create an invalid TimeZone instance to test the error path.
        // The defensive check in the implementation protects against corrupted
        // identifiers that might come from database or external sources.
    }

    @Test("updateHomeTimezone updates timestamps")
    func updateHomeTimezoneUpdatesTimestamps() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            homeTimezone: TimezoneTestHelpers.newYork
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let beforeUpdate = Date()

        // Update to Tokyo timezone
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify updatedAt was updated
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        if let updatedAt = updatedProfile?.updatedAt {
            #expect(updatedAt >= beforeUpdate)
        }
    }

    @Test("updateDisplayTimezoneMode updates profile")
    func updateDisplayTimezoneModeUpdatesProfile() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            displayMode: .current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update to home mode
        try await service.updateDisplayTimezoneMode(.home)

        // Verify profile was saved with new mode
        let mode = try await service.getDisplayTimezoneMode()
        #expect(mode == .home)
    }

    @Test("updateDisplayTimezoneMode logs change when mode changes")
    func updateDisplayTimezoneModeLogsChangeWhenModeChanges() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            displayMode: .current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update to home mode
        try await service.updateDisplayTimezoneMode(.home)

        // Verify timezone change was logged
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.timezoneChangeHistory.count == 1)

        let change = updatedProfile?.timezoneChangeHistory.first
        #expect(change?.trigger == .displayModeChange)
    }

    @Test("updateDisplayTimezoneMode does not log when mode unchanged")
    func updateDisplayTimezoneModeDoesNotLogWhenModeUnchanged() async throws {
        let container = try TestModelContainer.create()
        let profile = UserProfileBuilder.standard(
            displayMode: .current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update to same mode (.current)
        try await service.updateDisplayTimezoneMode(.current)

        // Verify no timezone change was logged
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.timezoneChangeHistory.count == 0)
    }

    // MARK: - History Management Tests

    @Test("Timezone change history is trimmed to 100 entries")
    func timezoneChangeHistoryIsTrimmedTo100Entries() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()

        // Create 105 existing timezone changes
        profile.timezoneChangeHistory = (0..<105).map { index in
            TimezoneChange(
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                fromTimezone: "UTC",
                toTimezone: "America/New_York",
                trigger: .userUpdate
            )
        }
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Add one more change (should trigger trimming)
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify history was trimmed to at most 100 entries
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        // Contract: history should have at most 100 entries after trimming
        #expect((updatedProfile?.timezoneChangeHistory.count ?? 0) <= 100)
    }

    @Test("Timezone change history preserves most recent entries")
    func timezoneChangeHistoryPreservesMostRecentEntries() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()

        // Create 105 timezone changes with identifiable timestamps
        let oldestDate = Date().addingTimeInterval(-105 * 3600)
        profile.timezoneChangeHistory = (0..<105).map { index in
            TimezoneChange(
                timestamp: oldestDate.addingTimeInterval(TimeInterval(index * 3600)),
                fromTimezone: "UTC",
                toTimezone: "America/New_York",
                trigger: .userUpdate
            )
        }
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Add one more change (should trigger trimming)
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify the most recent 100 entries were preserved
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        // Contract: history should have at most 100 entries after trimming
        #expect((updatedProfile?.timezoneChangeHistory.count ?? 0) <= 100)

        // The most recent entry should be the Tokyo update
        let mostRecent = updatedProfile?.timezoneChangeHistory.last
        #expect(mostRecent?.toTimezone == TimezoneTestHelpers.tokyo.identifier)
    }

    @Test("Timezone history boundary: 100 entries stays at 100 after append")
    func timezoneHistoryBoundaryCondition() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()

        // Create exactly 100 existing timezone changes (at the limit)
        profile.timezoneChangeHistory = (0..<100).map { index in
            TimezoneChange(
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                fromTimezone: "UTC",
                toTimezone: "America/New_York",
                trigger: .userUpdate
            )
        }
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Add one more change - should truncate to 99, then append = 100
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        // Contract: count should be exactly 100 (not 101)
        #expect(updatedProfile?.timezoneChangeHistory.count == 100)

        // The most recent entry should be the Tokyo update
        let mostRecentEntry = updatedProfile?.timezoneChangeHistory.last
        #expect(mostRecentEntry?.toTimezone == TimezoneTestHelpers.tokyo.identifier)
    }

    @Test("Timezone history boundary: 101 entries (over limit) truncates to 100 after append")
    func timezoneHistoryOverLimitBoundaryCondition() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()

        // Create 101 existing timezone changes (one over the limit)
        // This simulates a scenario where data might have exceeded limit due to bug or migration
        profile.timezoneChangeHistory = (0..<101).map { index in
            TimezoneChange(
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                fromTimezone: "UTC",
                toTimezone: "America/New_York",
                trigger: .userUpdate
            )
        }
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Add one more change - should truncate to 99, then append = 100
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        // Contract: count should be exactly 100 (not 102)
        #expect(updatedProfile?.timezoneChangeHistory.count == 100)

        // The most recent entry should be the Tokyo update
        let mostRecentEntry = updatedProfile?.timezoneChangeHistory.last
        #expect(mostRecentEntry?.toTimezone == TimezoneTestHelpers.tokyo.identifier)
    }

    @Test("Timezone history boundary: 99 entries stays under limit after append")
    func timezoneHistoryUnderLimitBoundaryCondition() async throws {
        let container = try TestModelContainer.create()
        var profile = UserProfileBuilder.standard()

        // Create 99 existing timezone changes (one under the limit)
        profile.timezoneChangeHistory = (0..<99).map { index in
            TimezoneChange(
                timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
                fromTimezone: "UTC",
                toTimezone: "America/New_York",
                trigger: .userUpdate
            )
        }
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Add one more change - should simply append = 100 (no truncation needed)
        try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)

        // Verify
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        // Contract: count should be exactly 100 (99 + 1)
        #expect(updatedProfile?.timezoneChangeHistory.count == 100)

        // The most recent entry should be the Tokyo update
        let mostRecentEntry = updatedProfile?.timezoneChangeHistory.last
        #expect(mostRecentEntry?.toTimezone == TimezoneTestHelpers.tokyo.identifier)
    }

    // MARK: - Detection Tests

    @Test("detectTimezoneChange returns nil when no change")
    func detectTimezoneChangeReturnsNilWhenNoChange() async throws {
        let container = try TestModelContainer.create()
        // Set stored current timezone to match device timezone
        let profile = UserProfileBuilder.standard(
            currentTimezone: TimeZone.current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let change = try await service.detectTimezoneChange()

        // Should return nil when no change detected
        #expect(change == nil)
    }

    @Test("detectTimezoneChange detects device timezone change")
    func detectTimezoneChangeDetectsDeviceTimezoneChange() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        // Virtually guaranteed to never be a CI system's timezone
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let change = try await service.detectTimezoneChange()

        // Should detect change (device is virtually never in Kiritimati)
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        guard let change = change else {
            Issue.record("Should detect timezone change when stored differs from device")
            return
        }

        #expect(change.previousTimezone == storedTimezone.identifier)
        #expect(change.newTimezone == TimeZone.current.identifier)
    }

    @Test("detectTimezoneChange returns correct previous and new timezones")
    func detectTimezoneChangeReturnsCorrectPreviousAndNewTimezones() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let change = try await service.detectTimezoneChange()

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")
        guard let change = change else {
            Issue.record("Expected timezone change to be detected")
            return
        }

        #expect(change.previousTimezone == storedTimezone.identifier)
        #expect(change.newTimezone == TimeZone.current.identifier)
        #expect(change.detectedAt <= Date())
    }

    @Test("detectTravelStatus returns nil when not traveling")
    func detectTravelStatusReturnsNilWhenNotTraveling() async throws {
        let container = try TestModelContainer.create()
        // Set current and home to same timezone
        let profile = UserProfileBuilder.standard(
            currentTimezone: TimezoneTestHelpers.newYork,
            homeTimezone: TimezoneTestHelpers.newYork
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let travelStatus = try await service.detectTravelStatus()

        // Should return nil when current == home
        #expect(travelStatus == nil)
    }

    @Test("detectTravelStatus detects travel (Current ≠ Home)")
    func detectTravelStatusDetectsTravelWhenCurrentNotEqualHome() async throws {
        let container = try TestModelContainer.create()
        // Set current and home to different timezones
        let profile = UserProfileBuilder.traveling(
            currentTimezone: TimezoneTestHelpers.tokyo,
            homeTimezone: TimezoneTestHelpers.newYork
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let travelStatus = try await service.detectTravelStatus()

        // Should detect travel
        #expect(travelStatus != nil)
        #expect(travelStatus?.currentTimezone.identifier == TimezoneTestHelpers.tokyo.identifier)
        #expect(travelStatus?.homeTimezone.identifier == TimezoneTestHelpers.newYork.identifier)
    }

    @Test("detectTravelStatus sets isTravel flag correctly")
    func detectTravelStatusSetsIsTravelFlagCorrectly() async throws {
        let container = try TestModelContainer.create()
        // Set current and home to different timezones
        let profile = UserProfileBuilder.traveling(
            currentTimezone: TimezoneTestHelpers.tokyo,
            homeTimezone: TimezoneTestHelpers.newYork
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let travelStatus = try await service.detectTravelStatus()

        // Verify isTravel flag is true
        #expect(travelStatus?.isTravel == true)
    }

    // MARK: - Update Operations Tests

    @Test("updateCurrentTimezone updates device timezone")
    func updateCurrentTimezoneUpdatesDeviceTimezone() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update current timezone to device timezone
        try await service.updateCurrentTimezone()

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // Verify profile was updated to device timezone
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.currentTimezoneIdentifier == TimeZone.current.identifier)
    }

    @Test("updateCurrentTimezone logs timezone change")
    func updateCurrentTimezoneLogsTimezoneChange() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update current timezone
        try await service.updateCurrentTimezone()

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // Verify timezone change was logged
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.timezoneChangeHistory.count == 1)

        let change = updatedProfile?.timezoneChangeHistory.first
        #expect(change?.fromTimezone == storedTimezone.identifier)
        #expect(change?.toTimezone == TimeZone.current.identifier)
        #expect(change?.trigger == .deviceChange)
    }

    @Test("updateCurrentTimezone skips update if unchanged")
    func updateCurrentTimezoneSkipsUpdateIfUnchanged() async throws {
        let container = try TestModelContainer.create()
        // Set stored current to match device timezone
        let profile = UserProfileBuilder.standard(
            currentTimezone: TimeZone.current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Update current timezone (should skip since already matches)
        try await service.updateCurrentTimezone()

        // Verify no change was logged
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.timezoneChangeHistory.count == 0)
    }

    @Test("updateCurrentTimezone updates timestamps when change occurs")
    func updateCurrentTimezoneUpdatesTimestampsWhenChangeOccurs() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let beforeUpdate = Date()

        // Update current timezone
        try await service.updateCurrentTimezone()

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // Verify updatedAt was updated
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        if let updatedAt = updatedProfile?.updatedAt {
            #expect(updatedAt >= beforeUpdate)
        }
    }

    // MARK: - Error Path Tests

    @Test("getHomeTimezone propagates repository errors")
    func getHomeTimezonePropagatesRepositoryErrors() async throws {
        let failingRepo = FailingProfileRepository()
        await failingRepo.setShouldFailLoad(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Should throw the repository error
        do {
            _ = try await service.getHomeTimezone()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify error was propagated
            #expect(error.localizedDescription.contains("Load failed"))
        }
    }

    @Test("updateHomeTimezone propagates save errors")
    func updateHomeTimezonePropagatesSaveErrors() async throws {
        let failingRepo = FailingProfileRepository()

        // Set up initial profile
        let initialProfile = UserProfileBuilder.standard()
        await failingRepo.setProfileToReturn(initialProfile)

        await failingRepo.setShouldFailSave(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Should throw when save fails
        do {
            try await service.updateHomeTimezone(TimezoneTestHelpers.tokyo)
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify save error was propagated
            #expect(error.localizedDescription.contains("Save failed"))
        }
    }

    @Test("updateDisplayTimezoneMode propagates save errors")
    func updateDisplayTimezoneModePropagatesSaveErrors() async throws {
        let failingRepo = FailingProfileRepository()

        // Set up initial profile
        let initialProfile = UserProfileBuilder.standard(displayMode: .current)
        await failingRepo.setProfileToReturn(initialProfile)

        await failingRepo.setShouldFailSave(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Should throw when save fails
        do {
            try await service.updateDisplayTimezoneMode(.home)
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify save error was propagated
            #expect(error.localizedDescription.contains("Save failed"))
        }
    }

    @Test("detectTimezoneChange propagates repository errors")
    func detectTimezoneChangePropagatesRepositoryErrors() async throws {
        let failingRepo = FailingProfileRepository()
        await failingRepo.setShouldFailLoad(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Should throw the repository error
        do {
            _ = try await service.detectTimezoneChange()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify error was propagated
            #expect(error.localizedDescription.contains("Load failed"))
        }
    }

    @Test("detectTravelStatus propagates repository errors")
    func detectTravelStatusPropagatesRepositoryErrors() async throws {
        let failingRepo = FailingProfileRepository()
        await failingRepo.setShouldFailLoad(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Should throw the repository error
        do {
            _ = try await service.detectTravelStatus()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify error was propagated
            #expect(error.localizedDescription.contains("Load failed"))
        }
    }

    @Test("updateCurrentTimezone propagates load errors")
    func updateCurrentTimezonePropagatesLoadErrors() async throws {
        let failingRepo = FailingProfileRepository()
        await failingRepo.setShouldFailLoad(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Should throw the repository error
        do {
            try await service.updateCurrentTimezone()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify error was propagated
            #expect(error.localizedDescription.contains("Load failed"))
        }
    }

    @Test("updateCurrentTimezone propagates save errors")
    func updateCurrentTimezonePropagatesSaveErrors() async throws {
        let failingRepo = FailingProfileRepository()

        // Set up profile with different timezone to trigger save
        let initialProfile = UserProfileBuilder.standard(
            currentTimezone: TimezoneTestHelpers.kiritimati  // Extremely rare timezone
        )
        await failingRepo.setProfileToReturn(initialProfile)

        // Fail only on save, not load
        await failingRepo.setShouldFailSave(true)

        let loadProfile = LoadProfile(repo: failingRepo)
        let saveProfile = SaveProfile(repo: failingRepo)

        let service = DefaultTimezoneService(
            loadProfile: loadProfile,
            saveProfile: saveProfile
        )

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != TimezoneTestHelpers.kiritimati.identifier, "Test not applicable in Kiritimati timezone")

        // Should throw when save fails
        do {
            try await service.updateCurrentTimezone()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify save error was propagated
            #expect(error.localizedDescription.contains("Save failed"))
        }
    }

    // MARK: - Detection Logic Tests (Additional Coverage)

    @Test("detectTimezoneChange is read-only (does not modify profile)")
    func detectTimezoneChangeIsReadOnlyDoesNotModifyProfile() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // Detect change - this should NOT update the stored timezone
        // (updateCurrentTimezone() is separate and must be called explicitly)
        let change = try await service.detectTimezoneChange()

        // Verify change was detected
        #expect(change != nil)

        // Verify the stored timezone was NOT modified (detectTimezoneChange is read-only)
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(
            updatedProfile?.currentTimezoneIdentifier == storedTimezone.identifier,
            "detectTimezoneChange should be read-only - use updateCurrentTimezone to persist changes"
        )
    }

    @Test("detectTimezoneChange followed by updateCurrentTimezone persists change")
    func detectTimezoneChangeFollowedByUpdateCurrentTimezonePersistsChange() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // First detect the change
        let change = try await service.detectTimezoneChange()
        #expect(change != nil, "Should detect change")

        // Then explicitly update (this is the expected usage pattern)
        try await service.updateCurrentTimezone()

        // Verify the stored timezone WAS updated after explicit update call
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.currentTimezoneIdentifier == TimeZone.current.identifier)
    }

    @Test("Multiple detectTimezoneChange calls return same change until updateCurrentTimezone called")
    func multipleDetectTimezoneChangeCallsReturnSameChangeUntilUpdateCalled() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // First call should detect change
        let firstChange = try await service.detectTimezoneChange()
        #expect(firstChange != nil)

        // Second call should ALSO detect change (no update was made)
        let secondChange = try await service.detectTimezoneChange()
        #expect(secondChange != nil, "Should still detect change - no update was made")
        #expect(secondChange?.previousTimezone == firstChange?.previousTimezone)
        #expect(secondChange?.newTimezone == firstChange?.newTimezone)

        // Now call updateCurrentTimezone to persist
        try await service.updateCurrentTimezone()

        // Third call should return nil (change has been persisted)
        let thirdChange = try await service.detectTimezoneChange()
        #expect(thirdChange == nil, "Should return nil after updateCurrentTimezone persisted the change")
    }

    @Test("detectTimezoneChange detection info contains accurate timestamp")
    func detectTimezoneChangeDetectionInfoContainsAccurateTimestamp() async throws {
        let container = try TestModelContainer.create()

        // Use an extremely rare timezone (UTC+14, Line Islands)
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        let beforeDetection = Date()

        // Detect change
        let change = try await service.detectTimezoneChange()

        let afterDetection = Date()

        // Verify timestamp is within expected range
        #expect(change != nil)
        #expect(change!.detectedAt >= beforeDetection)
        #expect(change!.detectedAt <= afterDetection)
    }

    // MARK: - Integration Flow Tests

    @Test("Complete timezone change flow: detect → show alert → user confirms → update")
    func completeTimezoneChangeFlowDetectShowAlertUserConfirmsUpdate() async throws {
        let container = try TestModelContainer.create()

        // Setup: User's stored timezone is Kiritimati, device is now something else
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone,
            homeTimezone: storedTimezone  // Home matches stored current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // Step 1: Detect change (app foreground, timer fires, etc.)
        let detectedChange = try await service.detectTimezoneChange()
        #expect(detectedChange != nil, "Should detect timezone has changed")

        // Step 2: App would show alert to user with detectedChange info
        // (User sees: "Your timezone changed from Kiritimati to Bucharest")

        // Step 3: User confirms → app calls updateCurrentTimezone()
        try await service.updateCurrentTimezone()

        // Verify: Profile is updated
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.currentTimezoneIdentifier == TimeZone.current.identifier)
        #expect(updatedProfile?.timezoneChangeHistory.count == 1)
        #expect(updatedProfile?.timezoneChangeHistory.first?.trigger == .deviceChange)
    }

    @Test("Timezone change flow when user dismisses alert: no update persisted")
    func timezoneChangeFlowWhenUserDismissesAlertNoUpdatePersisted() async throws {
        let container = try TestModelContainer.create()

        // Setup: User's stored timezone is Kiritimati
        let storedTimezone = TimezoneTestHelpers.kiritimati

        let profile = UserProfileBuilder.standard(
            currentTimezone: storedTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != storedTimezone.identifier, "Test not applicable in Kiritimati timezone")

        // Step 1: Detect change
        let detectedChange = try await service.detectTimezoneChange()
        #expect(detectedChange != nil)

        // Step 2: User dismisses alert (does NOT confirm)
        // Step 3: App does NOT call updateCurrentTimezone()

        // Verify: Profile is NOT updated
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let unchangedProfile = try await profileRepository.loadProfile()

        #expect(unchangedProfile?.currentTimezoneIdentifier == storedTimezone.identifier)
        #expect(unchangedProfile?.timezoneChangeHistory.isEmpty == true)
    }

    // MARK: - Travel Detection Integration Tests

    @Test("Travel detection: user travels from home timezone to different timezone")
    func travelDetectionUserTravelsFromHomeTimezone() async throws {
        let container = try TestModelContainer.create()

        // Setup: User is at home (New York)
        let homeTimezone = TimezoneTestHelpers.newYork
        let profile = UserProfileBuilder.standard(
            currentTimezone: homeTimezone,
            homeTimezone: homeTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Initially: Not traveling
        let initialTravelStatus = try await service.detectTravelStatus()
        #expect(initialTravelStatus == nil, "Should not detect travel when current == home")

        // Simulate travel: Update current timezone to Tokyo
        try await service.updateHomeTimezone(homeTimezone) // Keep home as NY
        var profileData = ProfileLocalDataSource(modelContainer: container)
        var profileRepo = ProfileRepositoryImpl(local: profileData)
        var travelProfile = try await profileRepo.loadProfile()

        // Manually update current timezone to simulate device detecting new timezone
        travelProfile?.currentTimezoneIdentifier = TimezoneTestHelpers.tokyo.identifier
        try await profileRepo.saveProfile(travelProfile!)

        // Now: Should detect travel
        let travelStatus = try await service.detectTravelStatus()
        #expect(travelStatus != nil, "Should detect travel when current != home")
        #expect(travelStatus?.isTravel == true)
        #expect(travelStatus?.currentTimezone.identifier == TimezoneTestHelpers.tokyo.identifier)
        #expect(travelStatus?.homeTimezone.identifier == homeTimezone.identifier)
    }

    @Test("Travel detection: user returns home")
    func travelDetectionUserReturnsHome() async throws {
        let container = try TestModelContainer.create()

        // Setup: User is traveling (current = Tokyo, home = New York)
        let homeTimezone = TimezoneTestHelpers.newYork
        let currentTimezone = TimezoneTestHelpers.tokyo

        let profile = UserProfileBuilder.traveling(
            currentTimezone: currentTimezone,
            homeTimezone: homeTimezone
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)

        // Initially: Traveling
        let initialTravelStatus = try await service.detectTravelStatus()
        #expect(initialTravelStatus != nil, "Should detect travel")
        #expect(initialTravelStatus?.isTravel == true)

        // User returns home: Update current timezone to match home
        let profileData = ProfileLocalDataSource(modelContainer: container)
        let profileRepo = ProfileRepositoryImpl(local: profileData)
        var returnedProfile = try await profileRepo.loadProfile()
        returnedProfile?.currentTimezoneIdentifier = homeTimezone.identifier
        try await profileRepo.saveProfile(returnedProfile!)

        // Now: Should not detect travel
        let returnedTravelStatus = try await service.detectTravelStatus()
        #expect(returnedTravelStatus == nil, "Should not detect travel when user returns home")
    }

    // MARK: - First Launch Tests

    @Test("First launch: detectTimezoneChange returns nil (no mismatch)")
    func firstLaunchDetectTimezoneChangeReturnsNilNoMismatch() async throws {
        let container = try TestModelContainer.create()
        // DO NOT save a profile - simulate first app launch

        let service = createService(container: container)

        // On first launch, getHomeTimezone/detectTimezoneChange will create a default profile
        // with currentTimezoneIdentifier = TimeZone.current.identifier
        // Therefore, there should be NO mismatch detected

        let change = try await service.detectTimezoneChange()

        #expect(change == nil, "First launch should not detect timezone change - default profile uses device timezone")

        // Verify the default profile was created with current device timezone
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let createdProfile = try await profileRepository.loadProfile()

        #expect(createdProfile != nil, "Default profile should be created on first launch")
        #expect(
            createdProfile?.currentTimezoneIdentifier == TimeZone.current.identifier,
            "Default profile should use device timezone"
        )
    }

    @Test("First launch: no timezone alert should be shown")
    func firstLaunchNoTimezoneAlertShouldBeShown() async throws {
        let container = try TestModelContainer.create()
        // DO NOT save a profile - simulate first app launch

        let service = createService(container: container)

        // Simulate the app's timezone detection flow on first launch
        // 1. App calls detectTimezoneChange()
        // 2. This triggers profile creation with current timezone
        // 3. No change should be detected

        let change = try await service.detectTimezoneChange()

        // The app's logic: if change == nil, don't show alert
        let shouldShowAlert = change != nil

        #expect(shouldShowAlert == false, "First launch should not trigger timezone change alert")
    }

    @Test("First launch with existing iCloud profile: detects timezone change if different")
    func firstLaunchWithExistingICloudProfileDetectsTimezoneChangeIfDifferent() async throws {
        let container = try TestModelContainer.create()

        // Simulate: User has existing iCloud profile from another device in different timezone
        // This could happen when user sets up new device and iCloud syncs profile before first launch
        let existingProfile = UserProfileBuilder.standard(
            currentTimezone: TimezoneTestHelpers.kiritimati  // Extremely rare timezone
        )
        try await saveProfile(existingProfile, to: container)

        let service = createService(container: container)

        // Skip if somehow running in this extremely rare timezone
        try #require(TimeZone.current.identifier != TimezoneTestHelpers.kiritimati.identifier, "Test not applicable in Kiritimati timezone")

        // On this "first launch" with synced profile, timezone SHOULD be detected as changed
        let change = try await service.detectTimezoneChange()

        #expect(change != nil, "Should detect timezone change when iCloud profile has different timezone")
        #expect(change?.previousTimezone == TimezoneTestHelpers.kiritimati.identifier)
        #expect(change?.newTimezone == TimeZone.current.identifier)
    }
}
