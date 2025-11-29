//
//  DebugMenuView.swift
//  Ritualist
//
//  Created by Claude on 18.08.2025.
//

import SwiftUI
import RitualistCore
import FactoryKit
import NaturalLanguage
import os.log
import UserNotifications

#if DEBUG
struct DebugMenuView: View { // swiftlint:disable:this type_body_length
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingScenarios = false
    @State private var showingMigrationHistory = false
    @State private var showingBackupList = false
    @State private var showingMigrationSimulationAlert = false
    @State private var showingMotivationCardDemo = false
    @State private var showingResetOnboardingConfirmation = false
    @State private var showingRestartRequiredAlert = false
    @State private var restartInstructionMessage = ""
    @State private var migrationLogger = MigrationLogger.shared
    @State private var backupManager = BackupManager()
    @State private var backupCount: Int = 0
    @State private var migrationHistoryCount: Int = 0
    
    var body: some View {
        Form {
            Section {
                Text("Debug tools for development and testing. These options are only available in debug builds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Test Data") {
                GenericRowView.settingsRow(
                    title: "Test Data Scenarios",
                    subtitle: "Populate database with test user journeys",
                    icon: "cylinder.split.1x2",
                    iconColor: .blue
                ) {
                    showingScenarios = true
                }

                // Show progress inline when populating
                if vm.isPopulatingTestData {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "hourglass")
                                .foregroundColor(.blue)

                            Text(vm.testDataProgressMessage.isEmpty ? "Populating test data..." : vm.testDataProgressMessage)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Spacer()
                        }

                        ProgressView(value: vm.testDataProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    }
                    .padding(.vertical, 4)
                }
            }

            Section("UI Components") {
                GenericRowView.settingsRow(
                    title: "Motivation Cards Demo",
                    subtitle: "View all message variants and trigger types",
                    icon: "sparkles",
                    iconColor: .orange
                ) {
                    showingMotivationCardDemo = true
                }
            }

            Section("Database Management") {
                // Database Statistics
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Database Statistics")
                            .font(.headline)
                        
                        Spacer()
                        
                        if vm.databaseStats == nil {
                            Button("Load Stats") {
                                Task {
                                    await vm.loadDatabaseStats()
                                }
                            }
                            .buttonStyle(.borderless)
                            .foregroundColor(.blue)
                        }
                    }
                    
                    if let stats = vm.databaseStats {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Habits:")
                                Spacer()
                                Text("\(stats.habitsCount)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Habit Logs:")
                                Spacer()
                                Text("\(stats.logsCount)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Categories:")
                                Spacer()
                                Text("\(stats.categoriesCount)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Profiles:")
                                Spacer()
                                Text("\(stats.profilesCount)")
                                    .fontWeight(.medium)
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
                
                // Clear Database Button
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: vm.isClearingDatabase ? "hourglass" : "trash")
                            .foregroundColor(.red)
                        
                        if vm.isClearingDatabase {
                            Text("Clearing Database...")
                        } else {
                            Text("Clear All Database Data")
                        }
                        
                        Spacer()
                    }
                }
                .disabled(vm.isClearingDatabase)
            }

            Section("Notifications") {
                Button {
                    Task {
                        await clearAppBadge()
                    }
                } label: {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.red)

                        Text("Clear App Badge")

                        Spacer()
                    }
                }

                Text("Removes any stuck badge count from the app icon.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Onboarding Management") {
                Button(role: .destructive) {
                    showingResetOnboardingConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundColor(.purple)

                        Text("Reset Onboarding")

                        Spacer()
                    }
                }

                Text("Clears onboarding completion status. You'll need to manually restart the app to see the onboarding flow again.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Migration Management") {
                // Current Schema Version
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Schema Version")
                            .font(.headline)
                        Spacer()
                        Text("V\(RitualistMigrationPlan.currentSchemaVersion.description)")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }

                    // Show last known version from UserDefaults
                    if let lastVersion = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastSchemaVersion) {
                        Text("Last Known: \(lastVersion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("No migration history (first launch)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("SwiftData versioned schema system enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                // Simulate migration button (for testing)
                Button(role: .destructive) {
                    simulateMigration()
                } label: {
                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.purple)

                        Text("Simulate Migration from V\(getPreviousVersionNumber())")

                        Spacer()
                    }
                }

                Text("Sets schema version to \(getPreviousVersionNumber()).0.0 to trigger migration on next app launch")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Clean duplicate migrations button
                Button(role: .destructive) {
                    cleanDuplicateMigrations()
                } label: {
                    HStack {
                        Image(systemName: "trash.circle")
                            .foregroundColor(.orange)

                        Text("Clean Duplicate Migrations")

                        Spacer()
                    }
                }
                .disabled(migrationHistoryCount <= 1)

                Text("Removes duplicate migration entries, keeping only the latest for each version transition")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Migration History
                GenericRowView.settingsRow(
                    title: "Migration History",
                    subtitle: migrationHistoryCount > 0
                        ? "\(migrationHistoryCount) migration(s) recorded"
                        : "No migrations recorded yet",
                    icon: "clock.arrow.circlepath",
                    iconColor: .purple
                ) {
                    showingMigrationHistory = true
                }

                // Backup Management
                GenericRowView.settingsRow(
                    title: "Database Backups",
                    subtitle: backupCount > 0
                        ? "\(backupCount) manual backup(s) available"
                        : "No manual backups created yet",
                    icon: "externaldrive",
                    iconColor: .blue
                ) {
                    showingBackupList = true
                }
            }

            Section("Timezone Diagnostics") {
                VStack(alignment: .leading, spacing: 12) {
                    // Current Device Timezone
                    HStack {
                        Text("Device Timezone")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Identifier:")
                            Spacer()
                            Text(TimeZone.current.identifier)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        HStack {
                            Text("Abbreviation:")
                            Spacer()
                            Text(TimeZone.current.abbreviation() ?? "N/A")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("UTC Offset:")
                            Spacer()
                            Text(formatUTCOffset(TimeZone.current.secondsFromGMT()))
                                .fontWeight(.medium)
                        }
                    }
                    .font(.subheadline)

                    Divider()

                    // Current Date/Time in Different Contexts
                    HStack {
                        Text("Current Date/Time")
                            .font(.headline)
                        Spacer()
                    }

                    let now = Date()
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Local Time:")
                            Spacer()
                            Text(formatDateTime(now, timezone: .current))
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("UTC Time:")
                            Spacer()
                            Text(formatDateTime(now, timezone: TimeZone(abbreviation: "UTC")!))
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("UTC Timestamp:")
                            Spacer()
                            Text(String(format: "%.0f", now.timeIntervalSince1970))
                                .fontWeight(.medium)
                                .font(.caption)
                        }
                    }
                    .font(.subheadline)

                    Divider()

                    // Day Boundaries
                    HStack {
                        Text("Day Boundaries")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Today (Local):")
                            Spacer()
                            Text(formatDate(CalendarUtils.startOfDayLocal(for: now)))
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Today (UTC):")
                            Spacer()
                            Text(formatDate(CalendarUtils.startOfDayUTC(for: now)))
                                .fontWeight(.medium)
                        }

                        // Show if different
                        if !CalendarUtils.areSameDayUTC(now, CalendarUtils.startOfDayLocal(for: now)) {
                            Text("⚠️ Local and UTC days are different!")
                                .font(.caption)
                                .foregroundColor(.orange)
                                .padding(.top, 2)
                        }
                    }
                    .font(.subheadline)

                    Divider()

                    // Weekday Information
                    HStack {
                        Text("Weekday")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Calendar (Local):")
                            Spacer()
                            Text("\(CalendarUtils.weekdayComponentLocal(from: now)) (\(weekdayName(CalendarUtils.weekdayComponentLocal(from: now))))")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                        }

                        HStack {
                            Text("Calendar (UTC):")
                            Spacer()
                            Text("\(CalendarUtils.weekdayComponentUTC(from: now)) (\(weekdayName(CalendarUtils.weekdayComponentUTC(from: now))))")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Habit (Local):")
                            Spacer()
                            let habitWeekday = CalendarUtils.calendarWeekdayToHabitWeekday(CalendarUtils.weekdayComponentLocal(from: now))
                            Text("\(habitWeekday) (\(habitWeekdayName(habitWeekday)))")
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        Text("Note: Calendar uses 1=Sunday, Habit uses 1=Monday")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                    .font(.subheadline)

                    Divider()

                    // User Profile Settings
                    HStack {
                        Text("Display Settings")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Display Mode:")
                            Spacer()
                            Text(vm.profile.displayTimezoneMode.toLegacyString())
                                .fontWeight(.medium)
                                .foregroundColor(.purple)
                        }

                        HStack {
                            Text("Home Timezone:")
                            Spacer()
                            Text(vm.profile.homeTimezoneIdentifier)
                                .fontWeight(.medium)
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)

                Text("Use this information to diagnose timezone-related issues with habit schedules and logging.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Performance Monitoring") {
                // FPS Overlay Toggle
                Toggle(isOn: $vm.showFPSOverlay) {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.67percent")
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show FPS Overlay")
                                .fontWeight(.medium)

                            Text("Display frames-per-second in top-right corner")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                // Performance Stats Section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Performance Statistics")
                            .font(.headline)

                        Spacer()

                        Button {
                            vm.updatePerformanceStats()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                    }

                    if let memoryMB = vm.memoryUsageMB {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Memory Usage:")
                                Spacer()
                                Text("\(memoryMB, specifier: "%.1f") MB")
                                    .fontWeight(.medium)
                                    .foregroundColor(memoryColor(for: memoryMB))
                            }

                            // Memory usage bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 8)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(memoryColor(for: memoryMB))
                                        .frame(width: min(geometry.size.width * (memoryMB / 500.0), geometry.size.width), height: 8)
                                }
                            }
                            .frame(height: 8)

                            Text("Typical range: 150-300 MB. Warning at 500+ MB")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                        .padding(.top, 4)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("Subscription Testing") {
                #if !ALL_FEATURES_ENABLED
                // Show current subscription status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Current Subscription")
                            .font(.headline)
                        Spacer()
                        Text(vm.subscriptionPlan.displayName)
                            .fontWeight(.medium)
                            .foregroundColor(subscriptionColor(for: vm.subscriptionPlan))
                    }

                    if vm.subscriptionPlan != .free {
                        Text("Mock subscription stored in UserDefaults")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)

                // Clear Mock Purchases button
                Button(role: .destructive) {
                    Task {
                        await clearMockPurchases()
                    }
                } label: {
                    HStack {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(.orange)

                        Text("Clear Mock Purchases")

                        Spacer()
                    }
                }
                .disabled(vm.subscriptionPlan == .free)

                Text("Clears mock subscription from UserDefaults to test free tier")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #else
                Text("Subscription testing is not available in AllFeatures mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #endif
            }

            Section("Offer Codes Testing") {
                #if !ALL_FEATURES_ENABLED
                NavigationLink {
                    DebugOfferCodesView(
                        paywallService: vm.paywallService,
                        subscriptionService: vm.subscriptionService
                    )
                } label: {
                    HStack {
                        Image(systemName: "giftcard")
                            .foregroundColor(.purple)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Manage Offer Codes")
                                .fontWeight(.medium)

                            Text("Create and test promotional codes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Text("Create custom offer codes with discounts, free trials, and eligibility rules for testing")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #else
                Text("Offer code testing is not available in AllFeatures mode")
                    .font(.caption)
                    .foregroundColor(.secondary)
                #endif
            }

            Section("iCloud Sync Diagnostics") {
                // CloudKit Container Info
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("CloudKit Configuration")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Container:")
                            Spacer()
                            Text(iCloudConstants.containerIdentifier)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.blue)
                        }

                        HStack {
                            Text("Environment:")
                            Spacer()
                            #if DEBUG
                            Text("Development")
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                            #else
                            Text("Production")
                                .fontWeight(.medium)
                                .foregroundColor(.green)
                            #endif
                        }

                        HStack {
                            Text("iCloud Status:")
                            Spacer()
                            Text(vm.iCloudStatus.displayMessage)
                                .fontWeight(.medium)
                                .foregroundColor(vm.iCloudStatus == .available ? .green : .red)
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)

                // Push Notification Status
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Push Notifications")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Registered:")
                            Spacer()
                            Text(ICloudSyncDiagnostics.shared.isRegisteredForRemoteNotifications ? "Yes" : "No")
                                .fontWeight(.medium)
                                .foregroundColor(ICloudSyncDiagnostics.shared.isRegisteredForRemoteNotifications ? .green : .red)
                        }

                        HStack {
                            Text("Push Received:")
                            Spacer()
                            Text("\(ICloudSyncDiagnostics.shared.pushNotificationCount)")
                                .fontWeight(.medium)
                                .foregroundColor(ICloudSyncDiagnostics.shared.pushNotificationCount > 0 ? .green : .secondary)
                        }

                        if let lastPush = ICloudSyncDiagnostics.shared.lastPushNotificationDate {
                            HStack {
                                Text("Last Push:")
                                Spacer()
                                Text(lastPush, format: .relative(presentation: .named))
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)

                // Sync Events
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Store Changes")
                            .font(.headline)
                        Spacer()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Remote Changes:")
                            Spacer()
                            Text("\(ICloudSyncDiagnostics.shared.remoteChangeCount)")
                                .fontWeight(.medium)
                                .foregroundColor(ICloudSyncDiagnostics.shared.remoteChangeCount > 0 ? .green : .secondary)
                        }

                        if let lastChange = ICloudSyncDiagnostics.shared.lastRemoteChangeDate {
                            HStack {
                                Text("Last Sync:")
                                Spacer()
                                Text(lastChange, format: .relative(presentation: .named))
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                        }

                        HStack {
                            Text("Dedup Runs:")
                            Spacer()
                            Text("\(ICloudSyncDiagnostics.shared.deduplicationRunCount)")
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("Total Duplicates Removed:")
                            Spacer()
                            Text("\(ICloudSyncDiagnostics.shared.totalDuplicatesRemoved)")
                                .fontWeight(.medium)
                                .foregroundColor(ICloudSyncDiagnostics.shared.totalDuplicatesRemoved > 0 ? .orange : .secondary)
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.vertical, 4)

                // Force Sync Check Button
                Button {
                    Task {
                        await vm.forceCloudStatusCheck()
                    }
                } label: {
                    HStack {
                        Image(systemName: vm.isCheckingCloudStatus ? "hourglass" : "arrow.triangle.2.circlepath.icloud")
                            .foregroundColor(.blue)

                        Text(vm.isCheckingCloudStatus ? "Checking..." : "Force iCloud Status Check")

                        Spacer()
                    }
                }
                .disabled(vm.isCheckingCloudStatus)

                // Reset Diagnostics Button
                Button(role: .destructive) {
                    ICloudSyncDiagnostics.shared.reset()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                            .foregroundColor(.orange)

                        Text("Reset Sync Diagnostics")

                        Spacer()
                    }
                }

                Text("Sync flow: Push Received → Store Changes. If 'Registered' is No, check Push Notifications capability. If pushes come but no store changes, check CloudKit Dashboard schema deployment.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Build Information") {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("App Version:")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Build Number:")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }

                    HStack {
                        Text("Build Configuration:")
                        Spacer()
                        Text("Debug")
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }

                    HStack {
                        Text("All Features Enabled:")
                        Spacer()
                        #if ALL_FEATURES_ENABLED
                        Text("Yes")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        #else
                        Text("No")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        #endif
                    }

                    HStack {
                        Text("Subscription Enabled:")
                        Spacer()
                        #if SUBSCRIPTION_ENABLED
                        Text("Yes")
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        #else
                        Text("No")
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                        #endif
                    }
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Debug Menu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            // Load database stats when the view appears
            await vm.loadDatabaseStats()
            // Load migration stats
            loadMigrationStats()
        }
        .sheet(isPresented: $showingScenarios) {
            NavigationStack {
                TestDataScenariosView(vm: vm)
            }
        }
        .sheet(isPresented: $showingMigrationHistory) {
            NavigationStack {
                MigrationHistoryView(logger: migrationLogger)
            }
        }
        .sheet(isPresented: $showingBackupList) {
            NavigationStack {
                BackupListView(backupManager: backupManager, onRefresh: loadMigrationStats)
            }
        }
        .sheet(isPresented: $showingMotivationCardDemo) {
            MotivationCardDemoView()
        }
        .alert("Clear Database?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                Task {
                    await vm.clearDatabase()
                }
            }
        } message: {
            Text("This will permanently delete all habits, logs, categories, and user data from the local database. This action cannot be undone.\n\nThis is useful for testing with a clean slate.")
        }
        .alert("Migration Simulation Ready", isPresented: $showingMigrationSimulationAlert) {
            Button("OK") { }
        } message: {
            let previousVersion = getPreviousVersionNumber()
            let currentVersionString = RitualistMigrationPlan.currentSchemaVersion.description
            let localizedText = String(localized: "alert.message.migration_restart_test", defaultValue: "Restart to test V%1$lld → V%2$@", comment: "Alert message for migration simulation")
            Text(String(format: localizedText, previousVersion, currentVersionString))
        }
        .alert("Reset Onboarding?", isPresented: $showingResetOnboardingConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task {
                    await vm.resetOnboarding()
                    restartInstructionMessage = "Onboarding has been reset. Please close and reopen the app to see the onboarding flow."
                    showingRestartRequiredAlert = true
                }
            }
        } message: {
            Text("This will clear the onboarding completion status. You'll need to manually restart the app to see the onboarding flow again.")
        }
        .alert("Restart Required", isPresented: $showingRestartRequiredAlert) {
            Button("OK") { }
        } message: {
            Text(restartInstructionMessage)
        }
        .refreshable {
            await vm.loadDatabaseStats()
        }
    }

    // MARK: - Helper Functions

    /// Formats a UTC offset in seconds to a readable string (e.g., "+02:00")
    private func formatUTCOffset(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = abs(seconds % 3600) / 60
        return String(format: "%+03d:%02d", hours, minutes)
    }

    /// Formats a date with both date and time
    private func formatDateTime(_ date: Date, timezone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        formatter.timeZone = timezone
        return formatter.string(from: date)
    }

    /// Formats a date (date only)
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Returns the weekday name from Calendar weekday (1=Sunday...7=Saturday)
    private func weekdayName(_ calendarWeekday: Int) -> String {
        let names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        let index = (calendarWeekday - 1) % 7
        return names[index]
    }

    /// Returns the weekday name from Habit weekday (1=Monday...7=Sunday)
    private func habitWeekdayName(_ habitWeekday: Int) -> String {
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        let index = (habitWeekday - 1) % 7
        return names[index]
    }

    /// Returns appropriate color for memory usage level
    /// Typical iOS app memory usage:
    /// - Small apps: 50-150MB
    /// - Medium apps: 150-300MB
    /// - Large apps: 300-500MB
    /// - Warning territory: 500MB+
    private func memoryColor(for memoryMB: Double) -> Color {
        if memoryMB < 200 {
            return .green       // Excellent - well within normal range
        } else if memoryMB < 400 {
            return .orange      // Acceptable - normal for feature-rich apps
        } else {
            return .red         // High - approaching memory warning territory
        }
    }

    // MARK: - Notifications

    /// Clears the app badge count
    @MainActor
    private func clearAppBadge() async {
        try? await UNUserNotificationCenter.current().setBadgeCount(0)
        Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
            .info("Cleared app badge")
    }

    // MARK: - Migration Management

    /// Loads migration statistics (backup count, migration history count)
    private func loadMigrationStats() {
        backupCount = (try? backupManager.listBackups().count) ?? 0
        migrationHistoryCount = migrationLogger.getMigrationHistory().count
    }

    // MARK: - Migration Testing

    /// Gets the previous schema version number (current - 1)
    private func getPreviousVersionNumber() -> Int {
        let currentVersion = RitualistMigrationPlan.currentSchemaVersion.description
        // Extract major version number from "8.0.0" format
        if let majorVersion = Int(currentVersion.split(separator: ".").first ?? "0") {
            return max(majorVersion - 1, 1) // Ensure we don't go below V1
        }
        return 1
    }

    /// Simulates a migration scenario by setting schema version to (current - 1)
    /// On next app restart, the system will detect migration and show modal
    private func simulateMigration() {
        let previousVersion = getPreviousVersionNumber()
        let versionString = "\(previousVersion).0.0"

        UserDefaults.standard.set(versionString, forKey: UserDefaultsKeys.lastSchemaVersion)

        Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
            .info("Set schema version to \(versionString) - restart app to see migration modal")

        // Show alert to restart app
        showingMigrationSimulationAlert = true
    }

    /// Removes duplicate migration entries from history
    /// Keeps only the latest migration for each version transition
    private func cleanDuplicateMigrations() {
        let history = migrationLogger.getMigrationHistory()
        var uniqueMigrations: [String: MigrationEvent] = [:]

        // Keep only the latest migration for each version transition
        for event in history {
            let key = "\(event.fromVersion) → \(event.toVersion)"
            // If we haven't seen this transition, or this event is newer, keep it
            if let existing = uniqueMigrations[key] {
                if event.startTime > existing.startTime {
                    uniqueMigrations[key] = event
                }
            } else {
                uniqueMigrations[key] = event
            }
        }

        // Clear history and save only unique migrations
        migrationLogger.clearHistory()

        // Re-save unique migrations using the standard save method
        // This ensures proper encoding and persistence
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(Array(uniqueMigrations.values)),
           let key = "com.ritualist.migration.history" as String? {
            UserDefaults.standard.set(data, forKey: key)
        }

        // Reload stats to update UI
        loadMigrationStats()

        Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
            .info("Cleaned migration history: \(history.count) → \(uniqueMigrations.count) entries")
    }

    // MARK: - Subscription Testing

    /// Clears mock purchases from UserDefaults to reset to free tier
    private func clearMockPurchases() async {
        do {
            // Clear purchases via the service (clears both memory and UserDefaults)
            try await vm.subscriptionService.clearPurchases()

            // Refresh the subscription status in the ViewModel
            await vm.refreshSubscriptionStatus()

            Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
                .info("Cleared mock purchases")
        } catch {
            Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
                .error("Failed to clear mock purchases: \(error.localizedDescription)")
        }
    }

    /// Returns appropriate color for subscription tier
    private func subscriptionColor(for plan: SubscriptionPlan) -> Color {
        switch plan {
        case .free:
            return .secondary
        case .weekly, .monthly, .annual:
            return .green
        case .lifetime:
            return .orange
        }
    }

}

// MARK: - Migration History View


// MARK: - Backup List View

struct BackupListView: View {
    let backupManager: BackupManager
    let onRefresh: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var backups: [URL] = []
    @State private var showingRestoreAlert = false
    @State private var showingRestoreSuccessAlert = false
    @State private var selectedBackup: URL?

    var body: some View {
        List {
            if backups.isEmpty {
                ContentUnavailableView(
                    "No Backups Available",
                    systemImage: "externaldrive.badge.xmark",
                    description: Text("Database backups will appear here")
                )
            } else {
                Section {
                    Text("Backups are automatically created before migrations. You can also create manual backups.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section("Available Backups") {
                    ForEach(backups, id: \.self) { backup in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(backup.lastPathComponent)
                                .font(.headline)

                            if let backupDate = extractBackupDate(from: backup) {
                                HStack(spacing: 4) {
                                    Text(backupDate, style: .date)
                                    Text("at")
                                    Text(backupDate, style: .time)
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }

                            if let fileSize = try? backup.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                                Text("Size: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedBackup = backup
                            showingRestoreAlert = true
                        }
                    }
                    .onDelete(perform: deleteBackups)
                }
            }
        }
        .navigationTitle("Database Backups")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    createBackup()
                } label: {
                    Label("Create Backup", systemImage: "doc.badge.plus")
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .task {
            loadBackups()
        }
        .alert("Restore Backup?", isPresented: $showingRestoreAlert) {
            Button("Cancel", role: .cancel) {
                selectedBackup = nil
            }
            Button("Restore", role: .destructive) {
                restoreBackup()
            }
        } message: {
            Text("This will replace the current database with the selected backup. The current database will be backed up first.\n\nThe app will need to restart after restoration.")
        }
        .alert("Database Restored", isPresented: $showingRestoreSuccessAlert) {
            Button("OK") { }
        } message: {
            Text("The database has been successfully restored. Please close and reopen the app to load the restored data.")
        }
    }

    private func loadBackups() {
        backups = (try? backupManager.listBackups()) ?? []
    }

    private func deleteBackups(at offsets: IndexSet) {
        for index in offsets {
            let backup = backups[index]
            try? FileManager.default.removeItem(at: backup)
        }
        loadBackups()
        onRefresh()
    }

    private func restoreBackup() {
        guard let backup = selectedBackup else { return }

        // Schedule the restore to happen on next app launch (BEFORE ModelContainer creation)
        // This avoids SQLite integrity violations from deleting files while they're open
        backupManager.schedulePendingRestore(from: backup)

        Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
            .info("Scheduled restore from: \(backup.lastPathComponent)")

        selectedBackup = nil

        // Show success alert with restart prompt
        showingRestoreSuccessAlert = true
    }

    /// Extracts the backup date from filename
    /// Format: Ritualist_backup_2025-11-02T18-08-08Z.sqlite
    private func extractBackupDate(from url: URL) -> Date? {
        let filename = url.lastPathComponent

        // Extract timestamp between "Ritualist_backup_" and ".sqlite"
        guard let timestampRange = filename.range(of: "Ritualist_backup_"),
              let extensionRange = filename.range(of: ".sqlite") else {
            return nil
        }

        let startIndex = timestampRange.upperBound
        let endIndex = extensionRange.lowerBound
        let timestamp = String(filename[startIndex..<endIndex])

        // Convert back to ISO8601 format (replace - with : in time part)
        // Format: 2025-11-02T18-08-08Z → 2025-11-02T18:08:08Z
        let components = timestamp.components(separatedBy: "T")
        guard components.count == 2 else { return nil }

        let datePart = components[0]
        let timePart = components[1].replacingOccurrences(of: "-", with: ":")
        let iso8601String = "\(datePart)T\(timePart)"

        // Parse ISO8601 date
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: iso8601String)
    }

    private func createBackup() {
        Task {
            do {
                try backupManager.createBackup()
                loadBackups()
                onRefresh()
            } catch {
                Logger(subsystem: "com.vladblajovan.Ritualist", category: "Debug")
                    .error("Failed to create backup: \(error.localizedDescription)")
            }
        }
    }
}

#endif