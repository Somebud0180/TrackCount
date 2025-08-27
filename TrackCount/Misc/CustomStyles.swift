//
//  CustomStyles.swift
//  TrackCount
//
//  The custom styles used across the interface
//


import SwiftUI

func defaultShape() -> some Shape {
    if #available(iOS 26.0, *) {
        return Capsule()
    } else {
        return RoundedRectangle(cornerRadius: 8, style: .continuous)
    }
}

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
            if (tint == .gray || tint == .white) {
                content
                    .padding(padding)           // Apply padding
                    .background(.thickMaterial) // Apply a tinted background
                    .cornerRadius(cornerRadius) // Set corner radius
            } else {
                content
                    .padding(padding)           // Apply padding
                    .background(tint)           // Apply a tinted background
                    .cornerRadius(cornerRadius) // Set corner radius
            }
        }
    }
}

// Liquid Glass / Tinted (Conditional) Button Modifier
struct AdaptiveGlassConditionalButtonModifier<S: Shape>: ViewModifier {
    let condition: Bool
    let tint: Color
    let shape: S
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .glassEffect(
                    .regular
                    .tint(condition ? tint.opacity(0.9) : .secondary)
                    .interactive()
                    ,in: shape
                )
        } else {
            content
                .background(condition ? tint.opacity(0.9) : .secondary, in: shape)
        }
    }
}

/// Liquid Glass / Tinted Button Background
struct AdaptiveGlassButtonModifier<S: Shape>: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let tintStrength: CGFloat
    let tint: Color
    let shape: S
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            let tintColor = colorScheme == .dark ? tint.opacity(0.2) : tint.opacity(tintStrength)
            if tintStrength == 0.0 {
                content
                    .glassEffect(
                        .regular
                        .interactive()
                        ,in: shape
                    )
            } else {
                content
                    .glassEffect(
                        .regular
                        .tint(tintColor)
                        .interactive()
                        ,in: shape
                    )
            }
        } else {
            let tintColor = colorScheme == .dark ? tint.opacity(0.2) : tint.opacity(tintStrength)
            content
                .background(tintColor, in: shape)
        }
    }
}

/// Legacy Dark Foreground Modifier for iOS versions below 26
struct LegacyDarkTint: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
        } else {
            content
                .tint(colorScheme == .dark ? .white : .primary)
        }
    }
}

// Extend View for easier usage
extension View {
    /// A rounded style with a thin material background and padding.
    func customRoundedStyle(interactive: Bool = false, tint: Color = .gray, padding: CGFloat = 12, cornerRadius: CGFloat = 8) -> some View {
        self.modifier(CustomRoundedStyle(isInteractive: interactive, tint: tint, padding: padding, cornerRadius: cornerRadius))
    }
    
    /// A button style with a liquid glass / tinted background that changes based on a condition.
    func adaptiveGlassConditionalButton<S: Shape>(condition: Bool, tint: Color, shape: S = defaultShape()) -> some View {
        self.modifier(AdaptiveGlassConditionalButtonModifier(condition: condition, tint: tint, shape: shape))
    }
    
    /// A button style with a liquid glass / tinted background.
    func adaptiveGlassButton<S: Shape>(tintStrength: CGFloat = 0.8, tintColor: Color = Color.white, shape: S = defaultShape()) -> some View {
        self.modifier(AdaptiveGlassButtonModifier(tintStrength: tintStrength, tint: tintColor, shape: shape))
    }
    
    /// A foreground style that ensures readability for iOS versions below 26.
    func legacyDarkTint() -> some View {
        self.modifier(LegacyDarkTint())
    }
}

