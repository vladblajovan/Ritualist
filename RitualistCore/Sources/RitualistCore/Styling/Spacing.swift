import SwiftUI

public enum Spacing {
    public static let none: CGFloat = 0
    public static let xxsmall: CGFloat = 4
    public static let xsmall: CGFloat = 6
    public static let small: CGFloat = 8
    public static let screenMargin: CGFloat = 10  // Consistent horizontal screen margins
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let extraLarge: CGFloat = 20  // Common 20px spacing
    public static let xlarge: CGFloat = 24
    public static let xxlarge: CGFloat = 32
    public static let xxxlarge: CGFloat = 40
    public static let xxxxlarge: CGFloat = 48
}

public enum CornerRadius {
    public static let none: CGFloat = 0
    public static let xsmall: CGFloat = 2.5
    public static let small: CGFloat = 4
    public static let medium: CGFloat = 8
    public static let large: CGFloat = 10
    public static let xlarge: CGFloat = {
        if #available(iOS 26.0, *) {
            return 18 // iOS 26 style - larger radius
        } else {
            return 12 // Classic radius
        }
    }()
    public static let xxlarge: CGFloat = {
        if #available(iOS 26.0, *) {
            return 25 // iOS 26 style - matches CardDesign.cornerRadius
        } else {
            return 16 // Classic radius
        }
    }()
    public static let xxxlarge: CGFloat = {
        if #available(iOS 26.0, *) {
            return 30 // iOS 26 style - extra large radius
        } else {
            return 20 // Classic radius
        }
    }()
}