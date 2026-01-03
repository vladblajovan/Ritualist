//
//  Bundle+AppIcon.swift
//  Ritualist
//
//  Created by Vlad Blajovan on 27.11.2025.
//

import UIKit

extension Bundle {
    /// Returns the app's primary icon from the bundle
    var appIcon: UIImage? {
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconName = iconFiles.last else {
            return nil
        }
        return UIImage(named: iconName)
    }
}
