//
//  AppearanceSettingsView.swift
//  Ritualist
//
//  Dedicated settings page for app appearance/theme configuration.
//

import SwiftUI
import FactoryKit

/// Appearance settings page for theme selection (System/Light/Dark)
struct AppearanceSettingsView: View {
    @Injected(\.settingsViewModel) var vm

    // Local form state for appearance
    @State private var appearance = 0

    var body: some View {
        Form {
            Section {
                Picker(Strings.Settings.appearanceSetting, selection: $appearance) {
                    Text(Strings.Settings.followSystem).tag(0)
                    Text(Strings.Settings.light).tag(1)
                    Text(Strings.Settings.dark).tag(2)
                }
                .pickerStyle(.inline)
                .labelsHidden()
                .onChange(of: appearance) { _, newValue in
                    // Note: Task { } does NOT inherit MainActor isolation, must explicitly specify
                    Task { @MainActor in
                        vm.profile.appearance = newValue
                        _ = await vm.save()
                        await vm.updateAppearance(newValue)
                    }
                }
            }
        }
        .navigationTitle(Strings.Settings.sectionAppearance)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            appearance = vm.profile.appearance
        }
        .onChange(of: vm.profile) { _, _ in
            appearance = vm.profile.appearance
        }
    }
}

#Preview {
    NavigationStack {
        AppearanceSettingsView()
    }
}
