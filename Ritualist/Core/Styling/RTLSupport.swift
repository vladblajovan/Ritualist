import SwiftUI

// MARK: - RTL Support
public enum RTLSupport {
    /// Returns the appropriate system image name for RTL-aware icons
    public static func chevronLeading(_ isRTL: Bool = false) -> String {
        isRTL ? "chevron.right" : "chevron.left"
    }
    
    public static func chevronTrailing(_ isRTL: Bool = false) -> String {
        isRTL ? "chevron.left" : "chevron.right"
    }
}

// MARK: - SwiftUI Extensions for RTL
extension View {
    /// Automatically flips layout for RTL languages
    public func rtlAware() -> some View {
        self.environment(\.layoutDirection, Locale.current.language.characterDirection == .rightToLeft ? .rightToLeft : .leftToRight)
    }
    
    /// Provides RTL-aware leading alignment
    public func leadingAlignment(_ isRTL: Bool = Locale.current.language.characterDirection == .rightToLeft) -> some View {
        self.multilineTextAlignment(isRTL ? .trailing : .leading)
    }
}