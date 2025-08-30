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
    let isInteractive: Bool
    let tint: Color
    let padding: CGFloat
    let cornerRadius: CGFloat
    let externalPressed: Bool
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var pressedSize: CGFloat {
        if #available(iOS 26.0, *) {
            return 1.1
        } else {
            return 0.95
        }
    }
    
    // Calculate the final scale based on all states
    private var finalScale: CGFloat {
        if externalPressed || isPressed {
            return pressedSize
        } else if isHovering {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            if isInteractive {
                content
                    .padding(padding)
                    .glassEffect(.regular.interactive().tint(tint), in: Capsule())
            } else {
                content
                    .padding(padding)
                    .glassEffect(.regular.tint(tint), in: Capsule())
            }
        } else {
            content
                .padding(padding)
                .adaptiveBackgroundMaterial(tint)
                .cornerRadius(cornerRadius)
                .scaleEffect(isInteractive ? finalScale : 1.0)
                .animation(.easeInOut(duration: 0.15), value: finalScale)
                .onHover { hovering in
                    isHovering = hovering
                }
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
                    isPressed = isPressing
                } perform: {
                    // Empty perform block - we only want the pressing state, not to intercept the tap
                }
        }
    }
}

// Simplified Conditional Button Modifier with unified scaling
struct CustomConditionalButtonModifier<S: Shape>: ViewModifier {
    let condition: Bool
    let tint: Color
    let shape: S
    let externalPressed: Bool
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var pressedSize: CGFloat {
        if #available(iOS 26.0, *) {
            return 1.1
        } else {
            return 0.95
        }
    }
    
    // Calculate the final scale based on all states
    private var finalScale: CGFloat {
        if externalPressed || isPressed {
            return pressedSize
        } else if isHovering {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    func body(content: Content) -> some View {
        content
            .background(condition ? tint.opacity(0.9) : .secondary, in: shape)
            .scaleEffect(finalScale)
            .animation(.easeInOut(duration: 0.15), value: finalScale)
            .onHover { hovering in
                isHovering = hovering
            }
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
                isPressed = isPressing
            } perform: {
                // Empty perform block - we only want the pressing state, not to intercept the tap
            }
    }
}

/// Liquid Glass / Tinted Button Background
struct AdaptiveGlassButtonModifier<S: Shape>: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let isInteractive: Bool
    let tintStrength: CGFloat
    let tint: Color
    let shape: S
    let externalPressed: Bool
    
    @State private var isHovering = false
    @State private var isPressed = false
    
    var pressedSize: CGFloat {
        if #available(iOS 26.0, *) {
            return 1.1
        } else {
            return 0.95
        }
    }
    
    // Calculate the final scale based on all states
    private var finalScale: CGFloat {
        if externalPressed || isPressed {
            return pressedSize
        } else if isHovering {
            return 1.05
        } else {
            return 1.0
        }
    }
    
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            let tintColor = colorScheme == .dark ? tint.opacity(0.2) : tint.opacity(tintStrength)
            if isInteractive {
                content.glassEffect(
                    .regular
                    .tint(tintStrength == 0.0 ? nil : tintColor)
                    .interactive()
                    , in: shape
                )
            } else {
                content.glassEffect(
                    .regular
                    .tint(tintColor)
                    , in: shape
                )
            }
        } else {
            let tintColor = colorScheme == .dark ? tint.opacity(0.2) : tint.opacity(tintStrength)
            content
                .background(tintColor, in: shape)
                .scaleEffect(isInteractive ? finalScale : 1.0)
                .animation(.easeInOut(duration: 0.15), value: finalScale)
                .onHover { hovering in
                    isHovering = hovering
                }
                .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity) { isPressing in
                    isPressed = isPressing
                } perform: {
                    // Empty perform block - we only want the pressing state, not to intercept the tap
                }
        }
    }
}

/// Group Card Interactive Modifier with press and hover effects
struct GroupCardModifier: ViewModifier {
    @State private var isHovering = false
    @State private var isPressed = false
    
    var pressedSize: CGFloat {
        if #available(iOS 26.0, *) {
            return 1.04
        } else {
            return 0.98
        }
    }
    
    // Calculate the final scale based on all states
    private var finalScale: CGFloat {
        if isPressed {
            return pressedSize
        } else if isHovering {
            return 1.02
        } else {
            return 1.0
        }
    }
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(finalScale)
            .animation(.easeInOut(duration: 0.15), value: finalScale)
            .onHover { hovering in
                isHovering = hovering
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                    isPressed = false
                }
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

struct AdaptiveBackgroundMaterial: ViewModifier {
    let tint: Color
    
    func body(content: Content) -> some View {
        if (tint == .gray || tint == .white) {
            content.background(.thickMaterial)
        } else {
            content.background(tint)
        }
    }
}


// MARK: - View Extensions
// Extend View for easier usage
extension View {
    /// A rounded style with a thin material background and padding.
    func customRoundedStyle(interactive: Bool = false, tint: Color = .gray, padding: CGFloat = 12, cornerRadius: CGFloat = 8, externalPressed: Bool = false) -> some View {
        self.modifier(CustomRoundedStyle(isInteractive: interactive, tint: tint, padding: padding, cornerRadius: cornerRadius, externalPressed: externalPressed))
    }
    
    /// A button style with a liquid glass / tinted background that changes based on a condition.
    func customConditionalButtonModifier<S: Shape>(condition: Bool, tint: Color, shape: S = defaultShape(), externalPressed: Bool = false) -> some View {
        self.modifier(CustomConditionalButtonModifier(condition: condition, tint: tint, shape: shape, externalPressed: externalPressed))
    }
    
    /// A button style with a liquid glass / tinted background.
    func adaptiveGlassButton<S: Shape>(interactive: Bool = true, tintStrength: CGFloat = 0.8, tintColor: Color = Color.white, shape: S = defaultShape(), externalPressed: Bool = false) -> some View {
        self.modifier(AdaptiveGlassButtonModifier(isInteractive: interactive, tintStrength: tintStrength, tint: tintColor, shape: shape, externalPressed: externalPressed))
    }
    
    /// A modifier that adds interactive effects for group cards, with subtle scaling on press and hover.
    func groupCardModifier() -> some View {
        self.modifier(GroupCardModifier())
    }
    
    /// A foreground style that ensures readability for iOS versions below 26.
    func legacyDarkTint() -> some View {
        self.modifier(LegacyDarkTint())
    }
    
    func adaptiveBackgroundMaterial(_ tint: Color) -> some View {
        self.modifier(AdaptiveBackgroundMaterial(tint: tint))
    }
}
