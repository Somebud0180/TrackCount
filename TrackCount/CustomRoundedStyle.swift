//
//  CustomRoundedStyle.swift
//  TrackCount
//
//  The custom rounded style used across the interface
//  Features a thin material for its background and a rounded corner, padded to fit its content in a compact space
//


import SwiftUI

/// A rounded style with a thin material background and padding
struct CustomRoundedStyle: ViewModifier {
    var padding: CGFloat = 12
    var cornerRadius: CGFloat = 8
    
    func body(content: Content) -> some View {
        content
            .padding(padding)           // Apply padding
            .background(.thinMaterial)  // Apply thinMaterial background
            .cornerRadius(cornerRadius) // Set corner radius
    }
}

// Extend View for easier usage
extension View {
    /// A rounded style with a thin material background and padding
    func customRoundedStyle(padding: CGFloat = 12, cornerRadius: CGFloat = 8) -> some View {
        self.modifier(CustomRoundedStyle(padding: padding, cornerRadius: cornerRadius))
    }
}
