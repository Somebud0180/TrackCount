//
//  CustomRoundedStyle.swift
//  TrackCount
//
//  The custom rounded style used across the interface
//  Features a thin material for its background and a rounded corner, padded to fit its content in a compact space
//


import SwiftUI

/// A rounded style with a thin material background and padding.
struct CustomRoundedStyle: ViewModifier {
    var isInteractive: Bool = false
    var tint: Color = .gray
    var padding: CGFloat = 12
    var cornerRadius: CGFloat = 8
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if isInteractive {
                content
                    .padding(padding)                                               // Apply padding
                    .glassEffect(.regular.interactive().tint(tint), in: Capsule())  // Apply a glass background
            } else {
                content
                    .padding(padding)                                   // Apply padding
                    .glassEffect(.regular.tint(tint), in: Capsule())    // Apply a glass background
            }
        } else {
            content
                .padding(padding)           // Apply padding
                .background(.thickMaterial) // Apply a material background
                .cornerRadius(cornerRadius) // Set corner radius
        }
    }
}

// Extend View for easier usage
extension View {
    /// A rounded style with a thin material background and padding.
    func customRoundedStyle(interactive: Bool = false, tint: Color = .gray, padding: CGFloat = 12, cornerRadius: CGFloat = 8) -> some View {
        self.modifier(CustomRoundedStyle(isInteractive: interactive, tint: tint, padding: padding, cornerRadius: cornerRadius))
    }
}
