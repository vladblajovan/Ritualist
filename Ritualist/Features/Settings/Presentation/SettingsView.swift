import SwiftUI
import UIKit

public struct SettingsRoot: View {
    private let factory: SettingsFactory?
    
    public init(factory: SettingsFactory? = nil) { 
        self.factory = factory
    }
    
    public var body: some View {
        SettingsContentView(factory: factory)
            .navigationTitle("Settings")
    }
}

private struct SettingsContentView: View {
    @Environment(\.appContainer) private var di
    @State private var vm: SettingsViewModel?
    @State private var isInitializing = true
    
    private let factory: SettingsFactory?
    
    init(factory: SettingsFactory?) {
        self.factory = factory
    }
    
    var body: some View {
        Group {
            if isInitializing {
                ProgressView("Initializing...")
            } else if let vm = vm {
                SettingsFormView(vm: vm)
            } else {
                ErrorView(
                    title: "Failed to Initialize",
                    message: "Unable to set up the settings screen"
                ) {
                    await initializeAndLoad()
                }
            }
        }
        .task {
            await initializeAndLoad()
        }
    }
    
    @MainActor
    private func initializeAndLoad() async {
        let actualFactory = factory ?? SettingsFactory(container: di)
        vm = actualFactory.makeViewModel()
        await vm?.load()
        isInitializing = false
    }
}

private struct SettingsFormView: View {
    @Environment(\.appContainer) private var appContainer
    @Bindable var vm: SettingsViewModel
    @FocusState private var isNameFieldFocused: Bool
    @State private var showingImagePicker = false
    @State private var selectedImageData: Data?
    @State private var showingPaywall = false
    @State private var paywallViewModel: PaywallViewModel?
    
    // Local form state
    @State private var name = ""
    @State private var firstDayOfWeek = 2
    @State private var appearance = 0
    
    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Loading settings...")
            } else if let error = vm.error {
                ErrorView(
                    title: "Failed to Load Settings",
                    message: error.localizedDescription
                ) {
                    await vm.retry()
                }
            } else {
                Form {
                    Section(Strings.Settings.profile) {
                        // Avatar and Name row
                        HStack(spacing: Spacing.medium) {
                            AvatarView(
                                name: displayName,
                                imageData: vm.profile.avatarImageData,
                                size: 60,
                                showEditBadge: true
                            ) {
                                showingImagePicker = true
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                TextField(Strings.Form.name, text: $name)
                                    .focused($isNameFieldFocused)
                                    .onSubmit {
                                        isNameFieldFocused = false
                                        Task {
                                            await updateUserName()
                                        }
                                    }
                                
                                if vm.isUpdatingUser {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                        Text("Updating...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }

                        HStack {
                            Picker(Strings.Settings.firstDayOfWeek, selection: $firstDayOfWeek) {
                                ForEach(1...7, id: \.self) { day in
                                    Text(dayOfWeekName(day)).tag(day)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        HStack {
                            Picker(Strings.Settings.appearanceSetting, selection: $appearance) {
                                Text(Strings.Settings.followSystem).tag(0)
                                Text(Strings.Settings.light).tag(1)
                                Text(Strings.Settings.dark).tag(2)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                    
                    // Account Section
                    if vm.isAuthenticated {
                        Section("Account") {
                            // Email display
                            if let user = vm.currentUser {
                                HStack {
                                    Label("Email", systemImage: "envelope")
                                    Spacer()
                                    Text(user.email)
                                        .foregroundColor(.secondary)
                                }
                                
                                // Subscription info
                                HStack {
                                    Label("Subscription", systemImage: "crown")
                                    Spacer()
                                    Text(user.subscriptionPlan.displayName)
                                        .foregroundColor(user.isPremiumUser ? .orange : .secondary)
                                        .fontWeight(user.isPremiumUser ? .medium : .regular)
                                }
                                
                                if let expiryDate = user.subscriptionExpiryDate, user.isPremiumUser {
                                    HStack {
                                        Label("Expires", systemImage: "calendar")
                                        Spacer()
                                        Text(expiryDate.formatted(date: .abbreviated, time: .omitted))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                // Cancel subscription for premium users or Subscribe for free users
                                if user.isPremiumUser {
                                    Button {
                                        Task {
                                            await vm.cancelSubscription()
                                        }
                                    } label: {
                                        HStack {
                                            if vm.isCancellingSubscription {
                                                ProgressView()
                                                    .scaleEffect(0.8)
                                                Text("Cancelling...")
                                            } else {
                                                Label("Cancel Subscription", systemImage: "xmark.circle")
                                            }
                                            Spacer()
                                        }
                                        .foregroundColor(.orange)
                                    }
                                    .disabled(vm.isCancellingSubscription)
                                } else {
                                    // Subscribe button for free users
                                    Button {
                                        showPaywall()
                                    } label: {
                                        HStack {
                                            Label("Subscribe to Pro", systemImage: "crown.fill")
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            // Logout button
                            Button {
                                Task {
                                    await vm.signOut()
                                }
                            } label: {
                                HStack {
                                    if vm.isLoggingOut {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("Signing Out...")
                                    } else {
                                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    }
                                    Spacer()
                                }
                                .foregroundColor(.red)
                            }
                            .disabled(vm.isLoggingOut)
                        }
                    }
                    
                    Section(Strings.Settings.notifications) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: Spacing.medium) {
                                Image(systemName: vm.hasNotificationPermission ? "bell.fill" : "bell.slash.fill")
                                    .foregroundColor(vm.hasNotificationPermission ? .green : .orange)
                                    .font(.title2)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(Strings.Settings.notificationPermission)
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    Text(vm.hasNotificationPermission ? 
                                         Strings.Settings.notificationsEnabled :
                                         Strings.Settings.notificationsDisabled)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                
                                Spacer()
                            }
                            
                            // Button aligned with text content, not icon
                            HStack {
                                // Spacer to match icon width + spacing
                                Spacer()
                                    .frame(width: 24 + Spacing.medium)
                                
                                if !vm.hasNotificationPermission {
                                    Button(Strings.Settings.enable) {
                                        Task {
                                            await vm.requestNotificationPermission()
                                        }
                                    }
                                    .disabled(vm.isRequestingNotifications)
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.regular)
                                    .overlay {
                                        if vm.isRequestingNotifications {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                                .foregroundColor(.white)
                                        }
                                    }
                                } else {
                                    Button(Strings.Settings.openSettings) {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.regular)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                }
                .refreshable {
                    await vm.load()
                    updateLocalState()
                }
                .onAppear {
                    updateLocalState()
                    Task {
                        await vm.refreshNotificationStatus()
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await saveChanges()
                            }
                        } label: {
                            if vm.isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text(Strings.Button.save)
                                    .fontWeight(hasChanges ? .semibold : .regular)
                            }
                        }
                        .disabled(!hasChanges || vm.isSaving)
                    }
                }
                .safeAreaInset(edge: .top) {
                    if vm.saveSuccess {
                        AutoSaveConfirmationView(message: Strings.Settings.settingsSaved) {
                            vm.clearSaveSuccess()
                        }
                        .padding(.top, 8)
                    }
                }
                .sheet(isPresented: $showingImagePicker) {
                    AvatarImagePicker(
                        name: displayName,
                        currentImageData: vm.profile.avatarImageData,
                        selectedImageData: $selectedImageData
                    ) { newImageData in
                        vm.profile.avatarImageData = newImageData
                        Task {
                            _ = await vm.save()
                        }
                        selectedImageData = nil
                    } onDismiss: {
                        selectedImageData = nil
                        showingImagePicker = false
                    }
                }
                .sheet(item: Binding<PaywallItem?>(
                    get: { 
                        guard showingPaywall, let vm = paywallViewModel else { return nil }
                        return PaywallItem(viewModel: vm)
                    },
                    set: { _ in 
                        showingPaywall = false
                        paywallViewModel = nil
                    }
                )) { item in
                    PaywallView(vm: item.viewModel)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showPaywall() {
        // Create the viewModel without loading - let PaywallView handle the loading
        let factory = PaywallFactory(container: appContainer)
        paywallViewModel = factory.makeViewModel()
        showingPaywall = true
    }
    
    // MARK: - Computed Properties
    
    private var displayName: String {
        // Use authenticated user's name if available, otherwise fall back to profile name
        vm.currentUser?.name ?? vm.profile.name
    }
    
    private var hasChanges: Bool {
        let currentName = vm.currentUser?.name ?? vm.profile.name
        return name != currentName ||
               firstDayOfWeek != vm.profile.firstDayOfWeek ||
               appearance != vm.profile.appearance
    }
    
    private func updateLocalState() {
        // Use authenticated user's name if available, otherwise use profile name
        name = vm.currentUser?.name ?? vm.profile.name
        firstDayOfWeek = vm.profile.firstDayOfWeek
        appearance = vm.profile.appearance
    }
    
    private func updateUserName() async {
        // If user is authenticated, update their name in the user account
        if vm.isAuthenticated {
            await vm.updateUserName(name)
        } else {
            // If not authenticated, update the profile name
            vm.profile.name = name
            _ = await vm.save()
        }
    }
    
    private func saveChanges() async {
        // Update profile settings (but not name if user is authenticated)
        if !vm.isAuthenticated {
            vm.profile.name = name
        }
        vm.profile.firstDayOfWeek = firstDayOfWeek
        vm.profile.appearance = appearance
        _ = await vm.save()
        
        // Update user name if authenticated
        if vm.isAuthenticated && name != vm.currentUser?.name {
            await vm.updateUserName(name)
        }
        
        // Update app appearance
        await MainActor.run {
            appContainer.appearanceManager.updateFromProfile(vm.profile)
        }
        
        // Update local state to reflect saved values
        updateLocalState()
    }
    
    private func dayOfWeekName(_ day: Int) -> String {
        switch day {
        case 1: return Strings.DayOfWeek.sunday
        case 2: return Strings.DayOfWeek.monday
        case 3: return Strings.DayOfWeek.tuesday
        case 4: return Strings.DayOfWeek.wednesday
        case 5: return Strings.DayOfWeek.thursday
        case 6: return Strings.DayOfWeek.friday
        case 7: return Strings.DayOfWeek.saturday
        default: return Strings.DayOfWeek.unknown
        }
    }
    
    private func appearanceName(_ appearance: Int) -> String {
        switch appearance {
        case 0: return "Follow System"
        case 1: return "Light"
        case 2: return "Dark"
        default: return "Unknown"
        }
    }
}

private struct AutoSaveConfirmationView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(message)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: message)
        .task {
            // Auto-dismiss after 3 seconds
            try? await Task.sleep(for: .seconds(3))
            onDismiss()
        }
    }
}

#Preview {
    let container = DefaultAppContainer.createMinimal()
    return SettingsRoot(factory: SettingsFactory(container: container))
        .environment(\.appContainer, container)
}