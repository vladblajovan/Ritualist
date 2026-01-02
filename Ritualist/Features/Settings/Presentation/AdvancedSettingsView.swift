import SwiftUI
import RitualistCore
import FactoryKit

/// Advanced Settings page for timezone and technical settings
struct AdvancedSettingsView: View {
    @Bindable var vm: SettingsViewModel
    @Binding var displayTimezoneMode: String
    @Binding var appearance: Int

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
            // Appearance Section
            Section {
                HStack {
                    Label {
                        Picker(Strings.Settings.appearanceSetting, selection: $appearance) {
                            Text(Strings.Settings.followSystem).tag(0)
                            Text(Strings.Settings.light).tag(1)
                            Text(Strings.Settings.dark).tag(2)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .onChange(of: appearance) { _, newValue in
                            Task {
                                vm.profile.appearance = newValue
                                _ = await vm.save()
                                await vm.updateAppearance(newValue)
                            }
                        }
                    } icon: {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }

            } header: {
                Text("Appearance")
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
        .navigationTitle("Advanced")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingHomeTimezonePicker) {
            HomeTimezonePickerView(
                selectedTimezone: homeTimezone,
                onSelect: updateHomeTimezone
            )
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
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
        Task {
            do {
                try await timezoneService.updateDisplayTimezoneMode(newMode)
                displayMode = newMode
                vm.profile.displayTimezoneMode = newMode
                _ = await vm.save()
            } catch {
                errorMessage = "Failed to update display mode: \(error.localizedDescription)"
                showError = true
            }
        }
    }

    private func updateHomeTimezone(_ newTimezone: TimeZone) {
        Task {
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
                errorMessage = "Failed to update timezone: \(error.localizedDescription)"
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
                    Text("You're Traveling")
                        .font(.headline)
                } icon: {
                    Image(systemName: "airplane")
                        .foregroundColor(.blue)
                }

                Text("Your device timezone differs from your home timezone. The app is using your selected display mode for habit tracking.")
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
                Picker("Display Mode", selection: $displayMode) {
                    Text("Current Location").tag(DisplayTimezoneMode.current)
                    Text("Home Location").tag(DisplayTimezoneMode.home)
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
                            Text("Home Timezone")
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
            Text("Habit Tracking")
        } footer: {
            Text("Controls which timezone is used for habit schedules, streaks, and statistics.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var modeExplanation: String {
        switch displayMode {
        case .current:
            return "Habits track in your current device timezone (\(currentTimezone.compactDisplayName)). Perfect for daily use."
        case .home:
            return "Habits track in your home timezone (\(homeTimezone.compactDisplayName)). Use this while traveling to maintain your home schedule."
        case .custom:
            return "Use a custom timezone for habit tracking."
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
                Text("Current Timezone")
                Spacer()
                Text(currentTimezone.localizedDisplayName)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            // Home Timezone (always shown)
            HStack {
                Text("Home Timezone")
                Spacer()
                Text(homeTimezone.localizedDisplayName)
                    .foregroundColor(.secondary)
                    .font(.caption)
            }

            // Active Display Timezone
            HStack {
                Text("Using for Habits")
                Spacer()
                Text(effectiveTimezone.localizedDisplayName)
                    .foregroundColor(.blue)
                    .font(.caption.weight(.medium))
            }
        } header: {
            Text("Timezone Info")
        } footer: {
            Text("Current is auto-detected. Home is where your daily routine happens. The active timezone determines habit schedules.")
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
            .searchable(text: $searchText, prompt: "Search timezones")
            .navigationTitle("Select Home Timezone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
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
