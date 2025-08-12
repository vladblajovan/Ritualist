import Foundation

// MARK: - RTL Support
public enum RTLSupport {
    /// Check if current locale uses right-to-left writing direction
    public static var isRTL: Bool {
        return Locale.characterDirection(forLanguage: Locale.current.languageCode ?? "en") == .rightToLeft
    }
    
    /// Returns the appropriate system image name for RTL-aware icons
    public static func chevronLeading(_ isRTL: Bool? = nil) -> String {
        let rtl = isRTL ?? self.isRTL
        return rtl ? "chevron.right" : "chevron.left"
    }
    
    public static func chevronTrailing(_ isRTL: Bool? = nil) -> String {
        let rtl = isRTL ?? self.isRTL
        return rtl ? "chevron.left" : "chevron.right"
    }
    
    /// Returns RTL-appropriate SF Symbol names
    public static func arrowLeading(_ isRTL: Bool? = nil) -> String {
        let rtl = isRTL ?? self.isRTL
        return rtl ? "arrow.right" : "arrow.left"
    }
    
    public static func arrowTrailing(_ isRTL: Bool? = nil) -> String {
        let rtl = isRTL ?? self.isRTL
        return rtl ? "arrow.left" : "arrow.right"
    }
    
    /// Text alignment helpers (for programmatic use)
    public enum TextAlignment {
        case leading
        case trailing
        case center
        
        /// Get the actual alignment based on RTL context
        public func resolved(isRTL: Bool? = nil) -> TextAlignment {
            let rtl = isRTL ?? RTLSupport.isRTL
            switch self {
            case .leading:
                return rtl ? .trailing : .leading
            case .trailing:
                return rtl ? .leading : .trailing
            case .center:
                return .center
            }
        }
    }
    
    /// Layout direction enumeration
    public enum LayoutDirection {
        case leftToRight
        case rightToLeft
        
        public static var current: LayoutDirection {
            return RTLSupport.isRTL ? .rightToLeft : .leftToRight
        }
    }
    
    /// Helper for RTL-aware edge insets
    public static func leadingInset(_ value: CGFloat, isRTL: Bool? = nil) -> (leading: CGFloat, trailing: CGFloat) {
        let rtl = isRTL ?? self.isRTL
        return rtl ? (leading: 0, trailing: value) : (leading: value, trailing: 0)
    }
    
    public static func trailingInset(_ value: CGFloat, isRTL: Bool? = nil) -> (leading: CGFloat, trailing: CGFloat) {
        let rtl = isRTL ?? self.isRTL
        return rtl ? (leading: value, trailing: 0) : (leading: 0, trailing: value)
    }
}