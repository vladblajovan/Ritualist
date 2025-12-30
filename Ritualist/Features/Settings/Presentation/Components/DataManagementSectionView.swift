import SwiftUI
import RitualistCore
import UniformTypeIdentifiers

// MARK: - Export Document

/// A simple document type for exporting JSON data
struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    let jsonString: String

    init(jsonString: String) {
        self.jsonString = jsonString
    }

    init(configuration: ReadConfiguration) throws {
        // Not used for export, but required by protocol
        if let data = configuration.file.regularFileContents,
           let string = String(data: data, encoding: .utf8) {
            self.jsonString = string
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = jsonString.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

struct DataManagementSectionView: View {
    @Bindable var vm: SettingsViewModel
    let onDeleteResult: (DeleteAllDataResult) -> Void
    @State private var showingDeleteConfirmation = false
    @State private var showingExporter = false
    @State private var showingImporter = false
    @State private var exportDocument: ExportDocument?

    /// Date formatter for export filename
    private static let exportDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        return formatter
    }()

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
            Button {
                if vm.isPremiumUser {
                    Task {
                        await vm.exportData()
                        // Only show exporter if export succeeded
                        if let jsonString = vm.exportedDataJSON {
                            exportDocument = ExportDocument(jsonString: jsonString)
                            showingExporter = true
                        }
                    }
                } else {
                    Task {
                        await vm.showPaywall()
                    }
                }
            } label: {
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
                            CrownProBadge()
                        }
                    }
                }
            }
            .disabled(vm.isExportingData || vm.isImportingData)

            // Import My Data Button (Premium Feature)
            Button {
                if vm.isPremiumUser {
                    showingImporter = true
                } else {
                    Task {
                        await vm.showPaywall()
                    }
                }
            } label: {
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
                            CrownProBadge()
                        }
                    }
                }
            }
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
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: "Ritualist_Export_\(Self.exportDateFormatter.string(from: Date())).json"
        ) { result in
            // Clear state after export completes
            exportDocument = nil
            vm.exportedDataJSON = nil

            switch result {
            case .success:
                vm.toastService.success("Data exported successfully")
            case .failure(let error):
                vm.toastService.error("Export failed: \(error.localizedDescription)")
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.json],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task {
                    await handleImportFile(url: url)
                }
            case .failure(let error):
                vm.toastService.error("Import failed: \(error.localizedDescription)")
            }
        }
    }

    private func handleImportFile(url: URL) async {
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            vm.toastService.error("Unable to access the selected file. Please try again.")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        // Read the file and pass to view model
        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            await vm.importData(jsonString: jsonString)
        } catch {
            vm.toastService.error("Could not read the file. Make sure it's a valid JSON file.")
        }
    }
}

