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
/// - Returns: A HStack containing an error symbol and message.
func errorMessageView(_ conditionValue: String, with condition: [String], message: String) -> some View {
    Group {
        if condition.contains(conditionValue) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                Text(message)
            }
            .font(.footnote)
            .foregroundColor(.red)
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
    /// - Returns: A red outline to the shape of CustomRoundedStyle.
    func errorOverlay(_ conditionValue: String, with condition: [String], isRectangle: Bool = false) -> some View {
        self.overlay(
            Group {
                if condition.contains(conditionValue) {
                    if !isRectangle, #available(iOS 26.0, *) {
                        Capsule()
                            .stroke(Color.red, lineWidth: 0.5)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 0.5)
                    }
                }
            }
        )
    }
}
