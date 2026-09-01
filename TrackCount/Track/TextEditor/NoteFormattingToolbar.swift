//
//  NoteFormattingToolbar.swift
//  TrackCount
//

import SwiftUI

/// A floating SwiftUI toolbar displayed above the keyboard while editing a note.
struct NoteFormattingToolbar: View {
    @ObservedObject var editor: NoteTextEditorController

    var body: some View {
        let isBold = editor.activeTraits.contains(.bold)
        let isItalic = editor.activeTraits.contains(.italic)
        let isUnderlined = editor.activeTraits.contains(.underline)
        
        HStack(spacing: 16) {
            Button(action: editor.toggleBold) {
                Image(systemName: "bold")
            }
            .foregroundStyle(isBold ? Color.accentColor : .primary)
            .accessibilityLabel("Bold")

            Button(action: editor.toggleItalic) {
                Image(systemName: "italic")
            }
            .foregroundStyle(isItalic ? Color.accentColor : .primary)
            .accessibilityLabel("Italic")

            Button(action: editor.toggleUnderline) {
                Image(systemName: "underline")
            }
            .foregroundStyle(isUnderlined ? Color.accentColor : .primary)
            .accessibilityLabel("Underline")

            Divider()
                .frame(height: 20)

            Button(action: editor.dismissKeyboard) {
                Image(systemName: "keyboard.chevron.compact.down")
            }
            .accessibilityLabel("Dismiss keyboard")
        }
        .font(.body.weight(.semibold))
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .customRoundedGlass()
        .padding(.bottom, 2)
        .accessibilityElement(children: .contain)
    }
}
