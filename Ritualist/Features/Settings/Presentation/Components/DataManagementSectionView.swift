import SwiftUI
import RitualistCore
import UniformTypeIdentifiers

struct DataManagementSectionView: View {
    @Bindable var vm: SettingsViewModel
    let onDeleteResult: (SettingsViewModel.DeleteAllDataResult) -> Void
    @State private var showingDeleteConfirmation = false

    /// Dynamic footer text based on iCloud status
    private var footerText: String {
        if vm.iCloudStatus.canSync {
            return Strings.DataManagement.footerWithICloud
        } else {
            return Strings.DataManagement.footerLocalOnly
        }
    }

    /// Dynamic delete confirmation message based on iCloud status
    private var deleteConfirmationMessage: String {
        if vm.iCloudStatus.canSync {
            return Strings.DataManagement.deleteMessageWithICloud
        } else {
            return Strings.DataManagement.deleteMessageLocalOnly
        }
    }

    var body: some View {
        Section {
            // Export My Data Button (Premium Feature)
            Button(action: {
                if vm.isPremiumUser {
                    Task {
                        await vm.exportData()
                        // Only show picker if export succeeded
                        if vm.exportedDataJSON != nil {
                            vm.showExportPicker = true
                        }
                    }
                } else {
                    Task {
                        await vm.showPaywall()
                    }
                }
            }) {
                HStack {
                    if vm.isExportingData {
                        ProgressView()
                            .controlSize(.small)
                        Text("Exporting...")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Export", systemImage: "square.and.arrow.up")
                        Spacer()
                        if !vm.isPremiumUser {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(vm.isExportingData || vm.isImportingData)

            // Import My Data Button (Premium Feature)
            Button(action: {
                if vm.isPremiumUser {
                    vm.showImportPicker = true
                } else {
                    Task {
                        await vm.showPaywall()
                    }
                }
            }) {
                HStack {
                    if vm.isImportingData {
                        ProgressView()
                            .controlSize(.small)
                        Text("Importing...")
                            .foregroundStyle(.secondary)
                    } else {
                        Label("Import", systemImage: "square.and.arrow.down")
                        Spacer()
                        if !vm.isPremiumUser {
                            Text("PRO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(vm.isImportingData || vm.isExportingData)

            // Delete All Data Button
            Button(role: .destructive) {
                showingDeleteConfirmation = true
            } label: {
                HStack {
                    if vm.isDeletingCloudData {
                        ProgressView()
                            .controlSize(.small)
                        Text("Deleting...")
                            .foregroundStyle(.secondary)
                    } else {
                        Label(Strings.DataManagement.deleteAllData, systemImage: "trash")
                            .foregroundStyle(.red)
                    }
                }
            }
            .disabled(vm.isDeletingCloudData || vm.isExportingData || vm.isImportingData)
            .opacity(vm.isDeletingCloudData ? 0.5 : 1.0)

        } header: {
            Text("Data Management")
        } footer: {
            Text(footerText)
        }
        .alert(
            Strings.DataManagement.deleteTitle,
            isPresented: $showingDeleteConfirmation
        ) {
            Button(Strings.Button.delete, role: .destructive) {
                Task {
                    let result = await vm.deleteAllData()
                    await MainActor.run {
                        onDeleteResult(result)
                    }
                }
            }
            Button(Strings.Button.cancel, role: .cancel) {}
        } message: {
            Text(deleteConfirmationMessage)
        }
        .sheet(isPresented: $vm.showExportPicker) {
            if let jsonString = vm.exportedDataJSON {
                DocumentPickerForExport(jsonString: jsonString) {
                    // Clear exported data after picker dismisses
                    vm.exportedDataJSON = nil
                }
            }
        }
        .sheet(isPresented: $vm.showImportPicker) {
            DocumentPickerForImport { url in
                Task {
                    await handleImportFile(url: url)
                }
            }
        }
    }

    private func handleImportFile(url: URL) async {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            // If we can't access the file, just return
            // The file picker already handles user feedback
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Read the file and pass to view model
        // View model will handle errors and update UI state
        if let jsonString = try? String(contentsOf: url, encoding: .utf8) {
            await vm.importData(jsonString: jsonString)
        }
    }
}

// MARK: - Document Picker for Export

struct DocumentPickerForExport: UIViewControllerRepresentable {
    let jsonString: String
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        // Create temporary file with JSON data
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "Ritualist_Export_\(ISO8601DateFormatter().string(from: Date())).json"
        let fileURL = tempDir.appendingPathComponent(fileName)

        do {
            try jsonString.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            // If writing fails, return a picker with empty file list
            // The error will be visible to the user when they see no file
            return UIDocumentPickerViewController(forExporting: [])
        }

        // Create document picker in export mode
        let picker = UIDocumentPickerViewController(forExporting: [fileURL])
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDismiss: () -> Void

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            // File was successfully saved
            onDismiss()
        }

        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // User cancelled
            onDismiss()
        }
    }
}

// MARK: - Document Picker for Import

struct DocumentPickerForImport: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json])
        picker.allowsMultipleSelection = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPick: onPick)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void

        init(onPick: @escaping (URL) -> Void) {
            self.onPick = onPick
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
