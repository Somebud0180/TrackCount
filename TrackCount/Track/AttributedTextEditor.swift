//
//  AttributedTextEditor.swift
//  TrackCount
//
//  Created by Ethan John Lagera on 8/10/26.
//  Made with Gemini
//

import SwiftUI
import UIKit

struct AttributedTextEditor: UIViewRepresentable {
    @Binding var attributedText: AttributedString
    var textColor: UIColor = .label

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.font = .preferredFont(forTextStyle: .body)
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Convert Swift AttributedString to NSAttributedString for UITextView
        if let nsAttr = try? NSAttributedString(attributedText, including: \.uiKit) {
            uiView.attributedText = nsAttr
        } else {
            uiView.attributedText = NSAttributedString(attributedText)
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

        func textViewDidChange(_ textView: UITextView) {
            // Sync user edits back to the SwiftUI AttributedString binding
            if let updated = try? AttributedString(textView.attributedText, including: \.uiKit) {
                parent.attributedText = updated
            } else {
                parent.attributedText = AttributedString(textView.text)
            }
        }
    }
}
