//
//  AttributedTextEditor.swift
//  TrackCount
//

import SwiftUI
import UIKit

/// A transparent UIKit editor that keeps RTF data as its source of truth.
///
/// Keeping the exact RTF bytes avoids rebuilding a UITextView's attributed text
/// during unrelated SwiftUI renders, which would otherwise cancel a selection.
struct AttributedTextEditor: UIViewRepresentable {
    @Binding var noteData: Data?
    let controller: NoteTextEditorController
    var textColor: UIColor = .label
    var locked: Bool
    var cardUUID: UUID

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.allowsEditingTextAttributes = true
        textView.backgroundColor = .clear
        textView.isOpaque = false
        textView.font = .preferredFont(forTextStyle: .body)
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isEditable = !locked
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        textView.textColor = textColor
        textView.isEditable = !locked

        // Changes made by UITextView have already been applied locally. Do not
        // assign attributedText again for those changes: it resets its selection.
        guard context.coordinator.shouldApplyModelData(noteData) else { return }

        textView.attributedText = attributedText(from: noteData)
        context.coordinator.didApplyModelData(noteData)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func attributedText(from data: Data?) -> NSAttributedString {
        guard let data,
              let text = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.rtf],
                documentAttributes: nil
              ) else {
            return NSAttributedString()
        }
        return text
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: AttributedTextEditor
        private var hasAppliedModelData = false
        private var lastAppliedModelData: Data?

        init(_ parent: AttributedTextEditor) {
            self.parent = parent
        }

        func shouldApplyModelData(_ data: Data?) -> Bool {
            !hasAppliedModelData || data != lastAppliedModelData
        }

        func didApplyModelData(_ data: Data?) {
            hasAppliedModelData = true
            lastAppliedModelData = data
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.controller.beginEditing(textView, cardUUID: parent.cardUUID) { [weak self] textView in
                self?.syncRTFData(from: textView)
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            parent.controller.endEditing(textView)
        }

        func textViewDidChange(_ textView: UITextView) {
            syncRTFData(from: textView)
            parent.controller.updateActiveTraits()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            // This can fire for inactive editors while SwiftUI lays out the grid.
            // Only the active editor is allowed to drive the floating toolbar.
            parent.controller.selectionDidChange(in: textView)
        }

        func syncRTFData(from textView: UITextView) {
            let text = textView.attributedText ?? NSAttributedString()
            guard let data = try? text.data(
                from: NSRange(location: 0, length: text.length),
                documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
            ) else {
                return
            }

            // Set the snapshot before changing SwiftUI state. The following update
            // will then recognize this as the editor's own change and preserve its
            // current caret/selection.
            didApplyModelData(data)
            parent.noteData = data
        }
    }
}
