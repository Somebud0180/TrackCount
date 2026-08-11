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
        textView.inputAccessoryView = context.coordinator.makeFormattingToolbar()
        context.coordinator.textView = textView
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
        weak var textView: UITextView?

        init(_ parent: AttributedTextEditor) {
            self.parent = parent
        }

        func makeFormattingToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            toolbar.items = [
                formattingButton(title: "B", action: #selector(toggleBold), accessibilityLabel: "Bold"),
                formattingButton(title: "I", action: #selector(toggleItalic), accessibilityLabel: "Italic"),
                formattingButton(title: "U", action: #selector(toggleUnderline), accessibilityLabel: "Underline"),
                UIBarButtonItem.flexibleSpace(),
                UIBarButtonItem(
                    image: UIImage(systemName: "keyboard.chevron.compact.down"),
                    style: .plain,
                    target: self,
                    action: #selector(dismissKeyboard)
                )
            ]
            toolbar.items?.last?.accessibilityLabel = "Dismiss keyboard"
            return toolbar
        }

        private func formattingButton(title: String, action: Selector, accessibilityLabel: String) -> UIBarButtonItem {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            button.accessibilityLabel = accessibilityLabel
            button.addTarget(self, action: action, for: .touchUpInside)
            return UIBarButtonItem(customView: button)
        }

        @objc private func toggleBold() {
            toggleFontTrait(.traitBold)
        }

        @objc private func toggleItalic() {
            toggleFontTrait(.traitItalic)
        }

        @objc private func toggleUnderline() {
            guard let textView else { return }
            let range = textView.selectedRange
            let active = (textView.typingAttributes[.underlineStyle] as? NSNumber)?.intValue != 0
            let value: NSNumber = (active ? 0 : NSUnderlineStyle.single.rawValue) as NSNumber

            if range.length == 0 {
                textView.typingAttributes[.underlineStyle] = value
            } else {
                let text = NSMutableAttributedString(attributedString: textView.attributedText)
                text.addAttribute(.underlineStyle, value: value, range: range)
                textView.attributedText = text
                textView.selectedRange = range
                textViewDidChange(textView)
            }
        }

        private func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
            guard let textView else { return }
            let range = textView.selectedRange
            let currentFont = (textView.typingAttributes[.font] as? UIFont) ?? textView.font ?? .preferredFont(forTextStyle: .body)
            let traits = currentFont.fontDescriptor.symbolicTraits
            let newTraits = traits.contains(trait) ? traits.subtracting(trait) : traits.union(trait)
            let newFont = UIFont(descriptor: currentFont.fontDescriptor.withSymbolicTraits(newTraits) ?? currentFont.fontDescriptor, size: currentFont.pointSize)

            if range.length == 0 {
                textView.typingAttributes[.font] = newFont
            } else {
                let text = NSMutableAttributedString(attributedString: textView.attributedText)
                text.enumerateAttribute(.font, in: range) { value, subrange, _ in
                    let font = (value as? UIFont) ?? currentFont
                    let fontTraits = font.fontDescriptor.symbolicTraits
                    let updatedTraits = fontTraits.contains(trait) ? fontTraits.subtracting(trait) : fontTraits.union(trait)
                    let updatedFont = UIFont(descriptor: font.fontDescriptor.withSymbolicTraits(updatedTraits) ?? font.fontDescriptor, size: font.pointSize)
                    text.addAttribute(.font, value: updatedFont, range: subrange)
                }
                textView.attributedText = text
                textView.selectedRange = range
                textViewDidChange(textView)
            }
        }

        @objc private func dismissKeyboard() {
            textView?.resignFirstResponder()
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
