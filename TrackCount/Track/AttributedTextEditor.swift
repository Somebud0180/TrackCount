//
//  AttributedTextEditor.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 8/10/26.
//

import SwiftUI
import UIKit

struct AttributedTextEditor: UIViewRepresentable {
    @Binding var attributedText: AttributedString
    let controller: NoteTextEditorController
    var textColor: UIColor = .label

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.isOpaque = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        controller.attach(textView) { [weak coordinator = context.coordinator] textView in
            coordinator?.syncAttributedText(from: textView)
        }
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Convert Swift AttributedString to NSAttributedString for UITextView
        let newText: NSAttributedString
        if let nsAttr = try? NSAttributedString(attributedText, including: \.uiKit) {
            newText = nsAttr
        } else {
            newText = NSAttributedString(attributedText)
        }

        // Avoid resetting the insertion point and selection while the user types.
        if !uiView.attributedText.isEqual(to: newText) {
            uiView.attributedText = newText
        }
        uiView.textColor = textColor
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AttributedTextEditor

        init(_ parent: AttributedTextEditor) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.controller.isEditing = true
            parent.controller.updateActiveTraits()
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.controller.isEditing = false
        }

        func textViewDidChange(_ textView: UITextView) {
            syncAttributedText(from: textView)
            parent.controller.updateActiveTraits()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            parent.controller.updateActiveTraits()
        }

        func syncAttributedText(from textView: UITextView) {
            // Sync user edits back to the SwiftUI AttributedString binding
            if let updated = try? AttributedString(textView.attributedText, including: \.uiKit) {
                parent.attributedText = updated
            } else {
                parent.attributedText = AttributedString(textView.text)
            }
        }
    }
}
