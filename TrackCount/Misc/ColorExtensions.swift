//
//  ColorExtensions.swift
//  TrackCount
//
//  Extensions for Color readability and manipulation
//

import SwiftUI

extension Color {
    /// Returns the relative luminance of this color, from 0 (black) to 1 (white).
    func luminance() -> Double {
        // Convert the color to UIColor/NSColor and extract components
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#else
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif
        
        // Calculate luminance (perceptual brightness)
        func channel(_ c: CGFloat) -> Double {
            let c = Double(c)
            return (c <= 0.03928) ? (c/12.92) : pow((c+0.055)/1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
    
    /// Determines if the color is considered "white" based on its luminance.
    /// - Parameters:
    /// - colorScheme: The current color scheme (light or dark).
    /// - sensitivity: A value from 0 to 1 indicating how sensitive the readability check is. Default is 0.6.
    func isColorUnreadable(_ colorScheme: ColorScheme, sensitivity: CGFloat = 0.60) -> Bool {
        if colorScheme == .dark {
            return self.luminance() <= (1 - sensitivity)
        } else {
            return self.luminance() >= sensitivity
        }
    }
    
    /// Returns a color that is guaranteed to be readable for the given color scheme.
    /// If the color is unreadable, returns a contrasting color (black for light mode, white for dark mode). Otherwise returns self.
    /// - Parameters:
    ///  - colorScheme: The current color scheme (light or dark).
    ///  - sensitivity: A value from 0 to 1 indicating how sensitive the readability check is. Default is 0.6.
    func readable(in colorScheme: ColorScheme, sensitivity: CGFloat = 0.6) -> Color {
        if isColorUnreadable(colorScheme, sensitivity: sensitivity) {
            return colorScheme == .light ? self.darkened() : self.lightened()
        } else {
            return self
        }
    }
    
    /// Returns a version of the color that is readable against a background color, using luminance contrast.
    /// If the contrast is insufficient, returns a darkened or lightened variant for readability.
    /// - Parameters:
    ///   - background: The background color to check against.
    ///   - sensitivity: How strict the contrast check is (0 to 1). Default is 0.9.
    func readableOn(_ background: Color, sensitivity: CGFloat = 0.75) -> Color {
        // Calculate luminance of the background
        let bgLuminance = background.luminance()
        // Thresholds can be tweaked for your design preference.
        return bgLuminance > sensitivity ? self.darkened(by: 0.6) : self.lightened(by: 0.6)
    }
    
    /// Returns a darkened version of the color by blending it towards black.
    /// - Parameter amount: A value from 0 (no change) to 1 (black). Default is 0.5.
    func darkened(by amount: CGFloat = 0.5) -> Color {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#else
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif
        return Color(red: Double(r * (1 - amount)), green: Double(g * (1 - amount)), blue: Double(b * (1 - amount)), opacity: Double(a))
    }
    
    /// Returns a lightened version of the color by blending it towards white.
    /// - Parameter amount: A value from 0 (no change) to 1 (white). Default is 0.5.
    func lightened(by amount: CGFloat = 0.5) -> Color {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#else
        let nsColor = NSColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getRed(&r, green: &g, blue: &b, alpha: &a)
#endif
        return Color(red: Double(r + (1 - r) * amount), green: Double(g + (1 - g) * amount), blue: Double(b + (1 - b) * amount), opacity: Double(a))
    }
}
