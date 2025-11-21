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
#if compiler(>=6.0)
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

        // Verify it returned a valid timezone
        #expect(homeTz != nil)

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

        // Verify it returned a valid timezone
        #expect(displayTz != nil)

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

        let currentTz = service.getCurrentTimezone()

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

    @Test("getDisplayTimezone resolves based on mode - current")
    func getDisplayTimezoneResolvesModeCurrentCorrectly() async throws {
        let container = try TestModelContainer.create()
        let currentTz = TimezoneTestHelpers.newYork
        let homeTz = TimezoneTestHelpers.tokyo

        let profile = UserProfileBuilder.standard(
            currentTimezone: currentTz,
            homeTimezone: homeTz,
            displayMode: .current
        )
        try await saveProfile(profile, to: container)

        let service = createService(container: container)
        let displayTz = try await service.getDisplayTimezone()

        // Should resolve to current timezone
        #expect(displayTz.identifier == currentTz.identifier)
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

        // Verify history was trimmed to 100 entries
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        #expect(updatedProfile?.timezoneChangeHistory.count == 100)
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

        #expect(updatedProfile?.timezoneChangeHistory.count == 100)

        // The most recent entry should be the Tokyo update
        let mostRecent = updatedProfile?.timezoneChangeHistory.last
        #expect(mostRecent?.toTimezone == TimezoneTestHelpers.tokyo.identifier)
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
        if TimeZone.current.identifier == storedTimezone.identifier {
            return // Skip if somehow running in this extremely rare timezone
        }

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
        if TimeZone.current.identifier == storedTimezone.identifier {
            return
        }

        // Now we can assert without conditionals
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
        if TimeZone.current.identifier == storedTimezone.identifier {
            return
        }

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
        if TimeZone.current.identifier == storedTimezone.identifier {
            return
        }

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
        if TimeZone.current.identifier == storedTimezone.identifier {
            return
        }

        // Verify updatedAt was updated
        let profileDataSource = ProfileLocalDataSource(modelContainer: container)
        let profileRepository = ProfileRepositoryImpl(local: profileDataSource)
        let updatedProfile = try await profileRepository.loadProfile()

        if let updatedAt = updatedProfile?.updatedAt {
            #expect(updatedAt >= beforeUpdate)
        }
    }

    // MARK: - Error Path Tests

    /// Mock repository that throws errors for testing error handling
    actor FailingProfileRepository: ProfileRepository {
        var shouldFailLoad: Bool = false
        var shouldFailSave: Bool = false
        var profileToReturn: UserProfile?

        func loadProfile() async throws -> UserProfile? {
            if shouldFailLoad {
                throw NSError(domain: "FailingRepository", code: 1, userInfo: [NSLocalizedDescriptionKey: "Load failed"])
            }
            return profileToReturn
        }

        func saveProfile(_ profile: UserProfile) async throws {
            if shouldFailSave {
                throw NSError(domain: "FailingRepository", code: 2, userInfo: [NSLocalizedDescriptionKey: "Save failed"])
            }
            profileToReturn = profile
        }
    }

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
        if TimeZone.current.identifier == TimezoneTestHelpers.kiritimati.identifier {
            return
        }

        // Should throw when save fails
        do {
            try await service.updateCurrentTimezone()
            Issue.record("Expected error to be thrown")
        } catch {
            // Verify save error was propagated
            #expect(error.localizedDescription.contains("Save failed"))
        }
    }
}

// MARK: - Actor Helper Extensions

extension TimezoneServiceTests.FailingProfileRepository {
    func setShouldFailLoad(_ value: Bool) {
        self.shouldFailLoad = value
    }

    func setShouldFailSave(_ value: Bool) {
        self.shouldFailSave = value
    }

    func setProfileToReturn(_ profile: UserProfile?) {
        self.profileToReturn = profile
    }
}
