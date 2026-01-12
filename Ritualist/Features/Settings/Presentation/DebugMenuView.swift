//
//  DebugMenuView.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 18.08.2025.
//

import SwiftUI
import RitualistCore

#if DEBUG
struct DebugMenuView: View {
    @Bindable var vm: SettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false
    @State private var showingScenarios = false
    @State private var showingMigrationHistory = false
    @State private var showingBackupList = false
    @State private var showingMigrationSimulationAlert = false
    @State private var showingMotivationCardDemo = false
    @State private var showingResetOnboardingConfirmation = false
    @State private var showingSimulateNewDeviceConfirmation = false
    @State private var showingRestartRequiredAlert = false
    @State private var restartInstructionMessage = ""
    @State private var migrationLogger = MigrationLogger.shared
    @State private var backupManager = BackupManager()
    @State private var backupCount: Int = 0
    @State private var migrationHistoryCount: Int = 0

    var body: some View {
        baseContent
            .modifier(DebugMenuSheetsModifier(
                showingScenarios: $showingScenarios,
                showingMigrationHistory: $showingMigrationHistory,
                showingBackupList: $showingBackupList,
                showingMotivationCardDemo: $showingMotivationCardDemo,
                vm: vm,
                migrationLogger: migrationLogger,
                backupManager: backupManager,
                loadMigrationStats: loadMigrationStats
            ))
            .modifier(DebugMenuAlertsModifier(
                showingDeleteAlert: $showingDeleteAlert,
                showingMigrationSimulationAlert: $showingMigrationSimulationAlert,
                showingResetOnboardingConfirmation: $showingResetOnboardingConfirmation,
                showingSimulateNewDeviceConfirmation: $showingSimulateNewDeviceConfirmation,
                showingRestartRequiredAlert: $showingRestartRequiredAlert,
                restartInstructionMessage: $restartInstructionMessage,
                vm: vm,
                getPreviousVersionNumber: getPreviousVersionNumber
            ))
    }

    private var baseContent: some View {
        formContent
            .navigationTitle("Debug Menu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .task { await loadInitialData() }
            .refreshable { await vm.loadDatabaseStats() }
    }

    // MARK: - Body Helpers

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") { dismiss() }
        }
    }

    private func loadInitialData() async {
        await vm.loadDatabaseStats()
        loadMigrationStats()
    }

    private var formContent: some View {
        Form {
            Section {
                Text("Debug tools for development and testing. These options are only available in debug builds.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            DebugMenuTestDataSection(vm: vm, showingScenarios: $showingScenarios)

            DebugMenuUIComponentsSection(showingMotivationCardDemo: $showingMotivationCardDemo)

            DebugMenuDatabaseSection(vm: vm, showingDeleteAlert: $showingDeleteAlert)

            DebugMenuNotificationsSection()

            DebugMenuOnboardingSection(
                vm: vm,
                showingResetOnboardingConfirmation: $showingResetOnboardingConfirmation,
                showingSimulateNewDeviceConfirmation: $showingSimulateNewDeviceConfirmation
            )

            DebugMenuMigrationSection(
                showingMigrationSimulationAlert: $showingMigrationSimulationAlert,
                showingMigrationHistory: $showingMigrationHistory,
                showingBackupList: $showingBackupList,
                migrationHistoryCount: $migrationHistoryCount,
                backupCount: $backupCount,
                migrationLogger: migrationLogger,
                onRefresh: loadMigrationStats
            )

            DebugMenuPerformanceSection(vm: vm)

            DebugMenuSubscriptionSection(vm: vm)

            DebugMenuiCloudSection(vm: vm)

            DebugMenuBuildInfoSection()
        }
    }

    // MARK: - Helper Functions

    private func loadMigrationStats() {
        backupCount = (try? backupManager.listBackups().count) ?? 0
        migrationHistoryCount = migrationLogger.getMigrationHistory().count
    }

    private func getPreviousVersionNumber() -> Int {
        let currentVersion = RitualistMigrationPlan.currentSchemaVersion.description
        if let majorVersion = Int(currentVersion.split(separator: ".").first ?? "0") {
            return max(majorVersion - 1, 1)
        }
        return 1
    }
}

// MARK: - Sheets Modifier

private struct DebugMenuSheetsModifier: ViewModifier {
    @Binding var showingScenarios: Bool
    @Binding var showingMigrationHistory: Bool
    @Binding var showingBackupList: Bool
    @Binding var showingMotivationCardDemo: Bool
    let vm: SettingsViewModel
    let migrationLogger: MigrationLogger
    let backupManager: BackupManager
    let loadMigrationStats: () -> Void

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $showingScenarios) {
                NavigationStack { TestDataScenariosView(vm: vm) }
            }
            .sheet(isPresented: $showingMigrationHistory) {
                NavigationStack { MigrationHistoryView(logger: migrationLogger) }
            }
            .sheet(isPresented: $showingBackupList) {
                NavigationStack { BackupListView(backupManager: backupManager, onRefresh: loadMigrationStats) }
            }
            .sheet(isPresented: $showingMotivationCardDemo) {
                MotivationCardDemoView()
            }
    }
}

// MARK: - Alerts Modifier

private struct DebugMenuAlertsModifier: ViewModifier {
    @Binding var showingDeleteAlert: Bool
    @Binding var showingMigrationSimulationAlert: Bool
    @Binding var showingResetOnboardingConfirmation: Bool
    @Binding var showingSimulateNewDeviceConfirmation: Bool
    @Binding var showingRestartRequiredAlert: Bool
    @Binding var restartInstructionMessage: String
    let vm: SettingsViewModel
    let getPreviousVersionNumber: () -> Int

    func body(content: Content) -> some View {
        content
            .modifier(ClearDatabaseAlertModifier(
                isPresented: $showingDeleteAlert,
                vm: vm
            ))
            .modifier(MigrationSimulationAlertModifier(
                isPresented: $showingMigrationSimulationAlert,
                getPreviousVersionNumber: getPreviousVersionNumber
            ))
            .modifier(ResetOnboardingAlertModifier(
                isPresented: $showingResetOnboardingConfirmation,
                showingRestartRequiredAlert: $showingRestartRequiredAlert,
                restartInstructionMessage: $restartInstructionMessage,
                vm: vm
            ))
            .modifier(SimulateNewDeviceAlertModifier(
                isPresented: $showingSimulateNewDeviceConfirmation,
                showingRestartRequiredAlert: $showingRestartRequiredAlert,
                restartInstructionMessage: $restartInstructionMessage,
                vm: vm
            ))
            .alert("Restart Required", isPresented: $showingRestartRequiredAlert) {
                Button("OK") { }
            } message: {
                Text(restartInstructionMessage)
            }
    }
}

// MARK: - Individual Alert Modifiers

private struct ClearDatabaseAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let vm: SettingsViewModel

    func body(content: Content) -> some View {
        content.alert("Clear Database?", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All Data", role: .destructive) {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in await vm.clearDatabaseData() }
            }
        } message: {
            Text("This will permanently delete all habits, logs, categories, and user data from the local database. This action cannot be undone.\n\nThis is useful for testing with a clean slate.")
        }
    }
}

private struct MigrationSimulationAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    let getPreviousVersionNumber: () -> Int

    func body(content: Content) -> some View {
        content.alert("Migration Simulation Ready", isPresented: $isPresented) {
            Button("OK") { }
        } message: {
            let previousVersion = getPreviousVersionNumber()
            let currentVersionString = RitualistMigrationPlan.currentSchemaVersion.description
            let localizedText = String(localized: "alert.message.migration_restart_test", defaultValue: "Restart to test V%1$lld → V%2$@", comment: "Alert message for migration simulation")
            Text(String(format: localizedText, previousVersion, currentVersionString))
        }
    }
}

private struct ResetOnboardingAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var showingRestartRequiredAlert: Bool
    @Binding var restartInstructionMessage: String
    let vm: SettingsViewModel

    func body(content: Content) -> some View {
        content.alert("Reset Onboarding?", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.resetOnboarding()
                    restartInstructionMessage = "Onboarding and tips have been reset. Please close and reopen the app to see the onboarding flow and tips again."
                    showingRestartRequiredAlert = true
                }
            }
        } message: {
            Text("This will clear the onboarding completion status and reset all tips. Restart the app to see the onboarding flow and tips again.")
        }
    }
}

private struct SimulateNewDeviceAlertModifier: ViewModifier {
    @Binding var isPresented: Bool
    @Binding var showingRestartRequiredAlert: Bool
    @Binding var restartInstructionMessage: String
    let vm: SettingsViewModel

    func body(content: Content) -> some View {
        content.alert("Simulate New Device?", isPresented: $isPresented) {
            Button("Cancel", role: .cancel) { }
            Button("Simulate", role: .destructive) {
                // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                Task { @MainActor in
                    await vm.simulateNewDevice()
                    restartInstructionMessage = "New device simulation ready. Please close and reopen the app to test the returning user flow."
                    showingRestartRequiredAlert = true
                }
            }
        } message: {
            Text("This will simulate a returning user on a new device by keeping the iCloud onboarding flag but clearing local device flags. You'll need to restart the app to see the effect.")
        }
    }
}
#endif
