import SwiftUI
import RitualistCore
import FactoryKit

/// Timezone settings page for timezone and travel configuration
struct AdvancedSettingsView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var displayTimezoneMode: String

    @Injected(\.timezoneService) private var timezoneService

    @State private var currentTimezone: TimeZone = .current
    @State private var homeTimezone: TimeZone = .current
    @State private var displayMode: DisplayTimezoneMode = .current
    @State private var showingHomeTimezonePicker = false
    @State private var travelStatus: TravelStatus?
    @State private var errorMessage: String?
    @State private var showError = false

    var body: some View {
        Form {
            // Intro Section
            Section {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    Text(Strings.Timezone.intro)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Travel Status Section (if traveling)
            if let travel = travelStatus, travel.isTravel {
                TravelStatusSectionView(travelStatus: travel)
            }

            // Display Mode Section
            DisplayModeSectionView(
                displayMode: $displayMode,
                currentTimezone: currentTimezone,
                homeTimezone: homeTimezone,
                onModeChange: updateDisplayMode,
                onShowPicker: { showingHomeTimezonePicker = true }
            )

            // Timezone Information Section
            TimezoneInformationSectionView(
                currentTimezone: currentTimezone,
                homeTimezone: homeTimezone,
                displayMode: displayMode
            )
        }
        .navigationTitle(Strings.Timezone.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingHomeTimezonePicker) {
            HomeTimezonePickerView(
                selectedTimezone: homeTimezone,
                onSelect: updateHomeTimezone
            )
        }
        .alert(Strings.Common.error, isPresented: $showError) {
            Button(Strings.Common.ok, role: .cancel) { }
        } message: {
            if let errorMessage {
                Text(errorMessage)
            }
        }
        .task {
            await loadTimezoneData()
        }
    }

    // MARK: - Data Loading

    private func loadTimezoneData() async {
        do {
            currentTimezone = await timezoneService.getCurrentTimezone()
            homeTimezone = try await timezoneService.getHomeTimezone()
            displayMode = try await timezoneService.getDisplayTimezoneMode()
            travelStatus = try await timezoneService.detectTravelStatus()
        } catch {
            // Fallback to current timezone on error
            currentTimezone = .current
            homeTimezone = .current
            displayMode = .current
        }
    }

    private func updateDisplayMode(_ newMode: DisplayTimezoneMode) {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            do {
                try await timezoneService.updateDisplayTimezoneMode(newMode)
                displayMode = newMode
                vm.profile.displayTimezoneMode = newMode
                _ = await vm.save()
            } catch {
                errorMessage = "\(Strings.Timezone.failedToUpdateMode): \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func updateHomeTimezone(_ newTimezone: TimeZone) {
        // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
        Task { @MainActor in
            do {
                try await timezoneService.updateHomeTimezone(newTimezone)
                homeTimezone = newTimezone
                showingHomeTimezonePicker = false

                // Auto-switch to home mode when user selects a home timezone
                // This ensures the selected timezone takes effect immediately
                if displayMode != .home {
                    try await timezoneService.updateDisplayTimezoneMode(.home)
                    displayMode = .home
                    vm.profile.displayTimezoneMode = .home
                    _ = await vm.save()
                }

                // Refresh travel status
                travelStatus = try await timezoneService.detectTravelStatus()
            } catch {
                errorMessage = "\(Strings.Timezone.failedToUpdateTimezone): \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - Travel Status Section

private struct TravelStatusSectionView: View {
    let travelStatus: TravelStatus

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.small) {
                Label {
                    Text(Strings.Timezone.youAreTraveling)
                        .font(.headline)
                } icon: {
                    Image(systemName: "airplane")
                        .foregroundColor(.blue)
                }

                Text(Strings.Timezone.travelingDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, Spacing.small)
        }
    }
}

// MARK: - Display Mode Section

private struct DisplayModeSectionView: View {
    @Binding var displayMode: DisplayTimezoneMode
    let currentTimezone: TimeZone
    let homeTimezone: TimeZone
    let onModeChange: (DisplayTimezoneMode) -> Void
    let onShowPicker: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: Spacing.medium) {
                // Display Mode Picker
                Picker(Strings.Timezone.displayMode, selection: $displayMode) {
                    Text(Strings.Timezone.currentLocation).tag(DisplayTimezoneMode.current)
                    Text(Strings.Timezone.homeLocation).tag(DisplayTimezoneMode.home)
                }
                .pickerStyle(.segmented)
                .onChange(of: displayMode) { _, newValue in
                    onModeChange(newValue)
                }

                // Mode Explanation
                Text(modeExplanation)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Home Timezone Selector (only for Home mode)
                if displayMode == .home {
                    Button {
                        onShowPicker()
                    } label: {
                        HStack {
                            Text(Strings.Timezone.homeTimezone)
                                .foregroundColor(.primary)
                            Spacer()
                            Text(homeTimezone.compactDisplayName)
                                .foregroundColor(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            .padding(.vertical, Spacing.small)
        } header: {
            Text(Strings.Timezone.habitTracking)
        } footer: {
            Text(Strings.Timezone.habitTrackingFooter)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var modeExplanation: String {
        switch displayMode {
        case .current:
            return Strings.Timezone.currentModeExplanation(currentTimezone.compactDisplayName)
        case .home:
            return Strings.Timezone.homeModeExplanation(homeTimezone.compactDisplayName)
        case .custom:
            return Strings.Timezone.customModeExplanation
        }
    }
}

// MARK: - Timezone Information Section

private struct TimezoneInformationSectionView: View {
    let currentTimezone: TimeZone
    let homeTimezone: TimeZone
    let displayMode: DisplayTimezoneMode

    var body: some View {
        Section {
            // Current Timezone (always shown)
            HStack {
                Text(Strings.Timezone.currentTimezone)
                Spacer()
                Text(currentTimezone.localizedDisplayName)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            // Home Timezone (always shown)
            HStack {
                Text(Strings.Timezone.homeTimezone)
                Spacer()
                Text(homeTimezone.localizedDisplayName)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            // Active Display Timezone
            HStack {
                Text(Strings.Timezone.usingForHabits)
                Spacer()
                Text(effectiveTimezone.localizedDisplayName)
                    .foregroundColor(.blue)
                    .font(.caption.weight(.medium))
            }
        } header: {
            Text(Strings.Timezone.timezoneInfo)
        } footer: {
            Text(Strings.Timezone.timezoneInfoFooter)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var effectiveTimezone: TimeZone {
        switch displayMode {
        case .current:
            return currentTimezone
        case .home:
            return homeTimezone
        case .custom(let identifier):
            return TimeZone(identifier: identifier) ?? currentTimezone
        }
    }
}

// MARK: - Home Timezone Picker

private struct HomeTimezonePickerView: View {
    @Environment(\.dismiss) private var dismiss
    let selectedTimezone: TimeZone
    let onSelect: (TimeZone) -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredTimezones, id: \.identifier) { timezone in
                    Button {
                        onSelect(timezone)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(timezone.cityName)
                                    .foregroundColor(.primary)

                                Text(timezone.gmtOffsetString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if timezone.identifier == selectedTimezone.identifier {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: Strings.Timezone.searchTimezones)
            .navigationTitle(Strings.Timezone.selectHomeTimezone)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .presentationDragIndicator(.visible)
    }

    private var filteredTimezones: [TimeZone] {
        let all = TimeZone.knownTimeZoneIdentifiers
            .compactMap { TimeZone(identifier: $0) }
            .sorted { $0.cityName < $1.cityName }

        if searchText.isEmpty {
            return all
        }

        return all.filter { timezone in
            timezone.searchableText.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// Preview requires full dependency injection setup
// Use SettingsRoot in app to view this page
