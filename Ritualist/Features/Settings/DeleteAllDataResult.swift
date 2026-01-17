//
//  DeleteAllDataResult.swift
//  Ritualist
//
//  Result type for delete all data operation
//

import Foundation

/// Result of delete all data operation
public enum DeleteAllDataResult {
    case success
    case successButCloudSyncMayBeDelayed
    case failed(Error)
}
