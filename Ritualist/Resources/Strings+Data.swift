import Foundation

// MARK: - Data & iCloud Strings

extension Strings {
    // MARK: - iCloud Sync
    public enum ICloudSync {
        public static let syncedFromCloud = String(localized: "icloud.synced_from_cloud")
        public static let stillSyncing = String(localized: "icloud.still_syncing")
        public static let syncingData = String(localized: "icloud.syncing_data")
        public static let setupTitle = String(localized: "icloud.setup_title")
        public static let setupDescription = String(localized: "icloud.setup_description")
        public static let syncDelayed = String(localized: "icloud.sync_delayed")
        public static let sectionSync = String(localized: "icloud.sectionSync")
        public static let iCloud = String(localized: "icloud.iCloud")
        public static let syncingAcrossDevices = String(localized: "icloud.syncingAcrossDevices")
        public static let tapToEnableSync = String(localized: "icloud.tapToEnableSync")
        public static let title = String(localized: "icloud.title")
        public static let description = String(localized: "icloud.description")
        public static let syncStatus = String(localized: "icloud.syncStatus")
        public static let syncStatusFooter = String(localized: "icloud.syncStatusFooter")
        public static let whatSyncs = String(localized: "icloud.whatSyncs")
        public static let whatSyncsFooter = String(localized: "icloud.whatSyncsFooter")
        public static let troubleshooting = String(localized: "icloud.troubleshooting")
    }

    // MARK: - Data Management
    public enum DataManagement {
        public static let deleteAllData = String(localized: "data_management.delete_all_data")
        public static let deleteTitle = String(localized: "data_management.delete_title")
        public static let deleteMessageWithICloud = String(localized: "data_management.delete_message_with_icloud")
        public static let deleteMessageLocalOnly = String(localized: "data_management.delete_message_local_only")
        public static let footerWithICloud = String(localized: "data_management.footer_with_icloud")
        public static let footerLocalOnly = String(localized: "data_management.footer_local_only")
        public static let deleteSuccessMessage = String(localized: "data_management.delete_success_message")
        public static let deleteSyncDelayedMessage = String(localized: "data_management.delete_sync_delayed_message")
        public static let deleteFailedMessage = String(localized: "data_management.delete_failed_message")
        public static let sectionDataManagement = String(localized: "data_management.section")
        public static let exporting = String(localized: "data_management.exporting")
        public static let export = String(localized: "data_management.export")
        public static let importing = String(localized: "data_management.importing")
        public static let importData = String(localized: "data_management.import")
        public static let deleting = String(localized: "data_management.deleting")
        public static let exportSuccess = String(localized: "data_management.export_success")
        public static func exportFailed(_ error: String) -> String { String(format: String(localized: "data_management.export_failed"), error) }
        public static func importFailed(_ error: String) -> String { String(format: String(localized: "data_management.import_failed"), error) }
        public static let unableToAccessFile = String(localized: "data_management.unable_to_access_file")
        public static let invalidFile = String(localized: "data_management.invalid_file")
    }
}
