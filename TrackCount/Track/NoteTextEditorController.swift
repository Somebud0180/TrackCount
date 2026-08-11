//
//  NoteTextEditorController.swift
//  TrackCount
//

import Combine
import UIKit

enum NoteTextTrait: Hashable {
    case bold
    case italic
    case underline
}

/// Connects SwiftUI formatting controls to the active rich-text editor.
final class NoteTextEditorController: ObservableObject {
    @Published var isEditing = false
    @Published private(set) var activeTraits: Set<NoteTextTrait> = []

    private weak var textView: UITextView?
    private var onTextChanged: ((UITextView) -> Void)?

    func attach(_ textView: UITextView, onTextChanged: @escaping (UITextView) -> Void) {
        self.textView = textView
        self.onTextChanged = onTextChanged
        updateActiveTraits()
    }

    func toggleBold() {
        toggleFontTrait(.traitBold)
    }

    func toggleItalic() {
        toggleFontTrait(.traitItalic)
    }

    func toggleUnderline() {
        guard let textView else { return }
        let range = textView.selectedRange
        let isUnderlined = (textView.typingAttributes[.underlineStyle] as? NSNumber)?.intValue != 0
        let value: NSNumber = (isUnderlined ? 0 : NSUnderlineStyle.single.rawValue) as NSNumber

        if range.length == 0 {
            textView.typingAttributes[.underlineStyle] = value
            updateActiveTraits()
        } else {
            let text = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
            text.addAttribute(.underlineStyle, value: value, range: range)
            apply(text, preserving: range, to: textView)
        }
    }

    func dismissKeyboard() {
        textView?.resignFirstResponder()
    }

    /// Publishes the actual rich-text traits at the selection.
    ///
    /// UIKit's `typingAttributes` can temporarily include underline metadata from
    /// autocorrection, so a non-empty note reads its stored attributed text instead.
    func updateActiveTraits() {
        let traits = traitsAtSelection()

        // UITextView calls this from its selection callback, which may occur during
        // a SwiftUI render pass. Publishing on the next main-loop turn preserves the
        // native double-tap selection gesture and avoids nested view updates.
        DispatchQueue.main.async { [weak self] in
            guard let self, self.activeTraits != traits else { return }
            self.activeTraits = traits
        }
    }

    private func traitsAtSelection() -> Set<NoteTextTrait> {
        guard let textView else { return [] }

        let text = textView.attributedText ?? NSAttributedString()
        let attributes: [NSAttributedString.Key: Any]
        if text.length == 0 {
            attributes = textView.typingAttributes
        } else {
            let range = textView.selectedRange
            // For an insertion point, inspect the character immediately before it.
            // This reflects what is visibly formatted, without autocorrect's transient
            // typing attributes. At the start, inspect the first character instead.
            let location = range.length > 0
                ? range.location
                : max(0, range.location - 1)
            let safeLocation = min(location, text.length - 1)
            attributes = text.attributes(at: safeLocation, effectiveRange: nil)
        }

        let font = (attributes[.font] as? UIFont) ?? textView.font ?? .preferredFont(forTextStyle: .body)
        let fontTraits = font.fontDescriptor.symbolicTraits
        var traits: Set<NoteTextTrait> = []

        if fontTraits.contains(.traitBold) { traits.insert(.bold) }
        if fontTraits.contains(.traitItalic) { traits.insert(.italic) }
        if underlineStyleValue(in: attributes) != 0 { traits.insert(.underline) }

        return traits
    }

    private func underlineStyleValue(in attributes: [NSAttributedString.Key: Any]) -> Int {
        if let value = attributes[.underlineStyle] as? NSNumber {
            return value.intValue
        }
        if let value = attributes[.underlineStyle] as? Int {
            return value
        }
        return 0
    }

    private func toggleFontTrait(_ trait: UIFontDescriptor.SymbolicTraits) {
        guard let textView else { return }
        let range = textView.selectedRange
        let currentFont = (textView.typingAttributes[.font] as? UIFont) ?? textView.font ?? .preferredFont(forTextStyle: .body)

        if range.length == 0 {
            textView.typingAttributes[.font] = font(from: currentFont, toggling: trait)
            updateActiveTraits()
        } else {
            let text = NSMutableAttributedString(attributedString: textView.attributedText ?? NSAttributedString())
            text.enumerateAttribute(.font, in: range) { value, subrange, _ in
                let existingFont = (value as? UIFont) ?? currentFont
                text.addAttribute(.font, value: font(from: existingFont, toggling: trait), range: subrange)
            }
            apply(text, preserving: range, to: textView)
        }
    }

    private func font(from font: UIFont, toggling trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let existingTraits = font.fontDescriptor.symbolicTraits
        let updatedTraits = existingTraits.contains(trait) ? existingTraits.subtracting(trait) : existingTraits.union(trait)
        let descriptor = font.fontDescriptor.withSymbolicTraits(updatedTraits) ?? font.fontDescriptor
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    private func apply(_ text: NSAttributedString, preserving range: NSRange, to textView: UITextView) {
        textView.attributedText = text
        textView.selectedRange = range
        onTextChanged?(textView)
        updateActiveTraits()
    }
}
