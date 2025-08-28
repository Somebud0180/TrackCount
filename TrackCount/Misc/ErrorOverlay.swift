//
//  ErrorOverlay.swift
//  TrackCount
//
//  Handles form error view modifiers
//

import SwiftUI

/// Error message with animation.
/// - Parameters:
///   - conditionValue: The value to check in condition.
///   - condition: The variable to check for condition.
///   - message: The message to display when the error appears.
///   - warn: If true, the message will be yellow instead of red.
/// - Returns: A HStack containing an error symbol and message.
func errorMessageView(_ conditionValue: String, with condition: [String], message: String, warn: Bool = false) -> some View {
    var leadingPadding: CGFloat {
        if #available(iOS 26.0, *) {
            return 4
        } else {
            return 0
        }
    }
    
    return Group {
        if condition.contains(conditionValue) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Text(message)
            }
            .font(.footnote)
            .padding(.leading, leadingPadding)
            .foregroundColor(warn ? .yellow : .red)
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    .animation(.easeInOut(duration: 0.3), value: condition)
}

extension View {
    /// Checks with conditions to pass a red outline used for errors.
    /// - Parameters:
    ///   - condition: The variable which the function will be conditioned with.
    ///   - conditionValue: The variable which contains the condition value.
    ///   - warn: If true, the outline will be yellow instead of red.
    ///   - isRectangle: If true, the outline will be a rounded rectangle instead of a capsule.
    /// - Returns: A red outline to the shape of CustomRoundedStyle.
    func errorOverlay(_ conditionValue: String, with condition: [String], warn: Bool = false, isRectangle: Bool = false) -> some View {
        self
            .padding(0.5) // Padding to avoid clipping the border
            .overlay(
                Group {
                    if condition.contains(conditionValue) {
                        if !isRectangle, #available(iOS 26.0, *) {
                            Capsule()
                                .stroke(warn ? Color.yellow : Color.red, lineWidth: 1.0)
                        } else {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(warn ? Color.yellow : Color.red, lineWidth: 0.5)
                        }
                    }
                }
            )
    }
}
