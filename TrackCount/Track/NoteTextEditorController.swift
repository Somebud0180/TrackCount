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

/// Connects the SwiftUI formatting palette to the UITextView currently being edited.
final class NoteTextEditorController: ObservableObject {
    @Published private(set) var isEditing = false
    @Published private(set) var activeTraits: Set<NoteTextTrait> = []
    @Published var editingCardUUID: UUID? = nil
    
    private weak var activeTextView: UITextView?
    private var onTextChanged: ((UITextView) -> Void)?
    private var traitUpdateIsScheduled = false
    private var pendingInsertionTraits: Set<NoteTextTrait>?
    private var pendingInsertionLocation: Int?
    private var pendingTextLength: Int?

    func beginEditing(_ textView: UITextView, cardUUID: UUID, onTextChanged: @escaping (UITextView) -> Void) {
        self.editingCardUUID = cardUUID
        activate(textView, onTextChanged: onTextChanged)
        publishEditingState(true)
    }

    func endEditing(_ textView: UITextView) {
        guard activeTextView === textView else { return }
        self.editingCardUUID = nil
        clearPendingInsertionTraits()
        publishEditingState(false)
    }

    func selectionDidChange(in textView: UITextView) {
        guard activeTextView === textView else { return }
        updateActiveTraits()
    }

    func toggleBold() {
        toggleFontTrait(.traitBold, noteTrait: .bold)
    }

    func toggleItalic() {
        toggleFontTrait(.traitItalic, noteTrait: .italic)
    }

    func toggleUnderline() {
        guard let textView = activeTextView else { return }
        let range = textView.selectedRange
        let isUnderlined = traitsAtSelection().contains(.underline)

        if range.length == 0 {
            setTypingAttribute(
                .underlineStyle,
                value: isUnderlined ? 0 : NSUnderlineStyle.single.rawValue,
                toggling: .underline,
                in: textView
            )
        } else {
            textView.textStorage.beginEditing()
            textView.textStorage.addAttribute(
                .underlineStyle,
                value: isUnderlined ? 0 : NSUnderlineStyle.single.rawValue,
                range: range
            )
            textView.textStorage.endEditing()
            notifyTextChanged(textView)
        }
    }

    func dismissKeyboard() {
        activeTextView?.resignFirstResponder()
    }

    /// Schedules a toolbar state refresh after UIKit has finished its selection work.
    func updateActiveTraits() {
        guard !traitUpdateIsScheduled else { return }
        traitUpdateIsScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.traitUpdateIsScheduled = false
            let traits = self.traitsAtSelection()
            if self.activeTraits != traits {
                self.activeTraits = traits
            }
        }
    }

    private func activate(_ textView: UITextView, onTextChanged: @escaping (UITextView) -> Void) {
        activeTextView = textView
        self.onTextChanged = onTextChanged
        clearPendingInsertionTraits()
        updateActiveTraits()
    }

    private func publishEditingState(_ value: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self, self.isEditing != value else { return }
            self.isEditing = value
        }
    }

    private func toggleFontTrait(_ fontTrait: UIFontDescriptor.SymbolicTraits, noteTrait: NoteTextTrait) {
        guard let textView = activeTextView else { return }
        let range = textView.selectedRange

        if range.length == 0 {
            let currentFont = currentTypingFont(in: textView)
            let updatedFont = font(from: currentFont, toggling: fontTrait)
            setTypingAttribute(.font, value: updatedFont, toggling: noteTrait, in: textView)
        } else {
            let sourceText = textView.attributedText ?? NSAttributedString()
            var fontUpdates: [(NSRange, UIFont)] = []
            sourceText.enumerateAttribute(.font, in: range) { value, subrange, _ in
                let existingFont = (value as? UIFont) ?? self.currentTypingFont(in: textView)
                fontUpdates.append((subrange, self.font(from: existingFont, toggling: fontTrait)))
            }

            textView.textStorage.beginEditing()
            for (subrange, font) in fontUpdates {
                textView.textStorage.addAttribute(.font, value: font, range: subrange)
            }
            textView.textStorage.endEditing()
            notifyTextChanged(textView)
        }
    }

    private func setTypingAttribute(
        _ key: NSAttributedString.Key,
        value: Any,
        toggling trait: NoteTextTrait,
        in textView: UITextView
    ) {
        var attributes = textView.typingAttributes
        attributes[key] = value
        textView.typingAttributes = attributes

        var traits = traitsAtSelection()
        if traits.contains(trait) {
            traits.remove(trait)
        } else {
            traits.insert(trait)
        }
        pendingInsertionTraits = traits
        pendingInsertionLocation = textView.selectedRange.location
        pendingTextLength = (textView.attributedText ?? NSAttributedString()).length
        updateActiveTraits()
    }

    private func currentTypingFont(in textView: UITextView) -> UIFont {
        (textView.typingAttributes[.font] as? UIFont)
            ?? textView.font
            ?? .preferredFont(forTextStyle: .body)
    }

    private func notifyTextChanged(_ textView: UITextView) {
        onTextChanged?(textView)
        clearPendingInsertionTraits()
        updateActiveTraits()
    }

    private func traitsAtSelection() -> Set<NoteTextTrait> {
        guard let textView = activeTextView else { return [] }
        let text = textView.attributedText ?? NSAttributedString()
        let range = textView.selectedRange

        if let pendingTraits = pendingInsertionTraits,
           range.length == 0,
           range.location == pendingInsertionLocation,
           text.length == pendingTextLength {
            return pendingTraits
        }

        clearPendingInsertionTraits()

        if text.length == 0 {
            return traits(from: textView.typingAttributes, defaultFont: textView.font)
        }

        if range.length == 0 {
            let location = min(max(0, range.location - 1), text.length - 1)
            return traits(
                from: text.attributes(at: location, effectiveRange: nil),
                defaultFont: textView.font
            )
        }

        return traitsSharedByAllRuns(in: range, text: text, defaultFont: textView.font)
    }

    private func traitsSharedByAllRuns(
        in range: NSRange,
        text: NSAttributedString,
        defaultFont: UIFont?
    ) -> Set<NoteTextTrait> {
        var shared: Set<NoteTextTrait> = [.bold, .italic, .underline]
        text.enumerateAttributes(in: range) { attributes, _, stop in
            shared.formIntersection(traits(from: attributes, defaultFont: defaultFont))
            if shared.isEmpty { stop.pointee = true }
        }
        return shared
    }

    private func traits(
        from attributes: [NSAttributedString.Key: Any],
        defaultFont: UIFont?
    ) -> Set<NoteTextTrait> {
        let font = (attributes[.font] as? UIFont) ?? defaultFont ?? .preferredFont(forTextStyle: .body)
        let fontTraits = font.fontDescriptor.symbolicTraits
        var traits: Set<NoteTextTrait> = []

        if fontTraits.contains(.traitBold) { traits.insert(.bold) }
        if fontTraits.contains(.traitItalic) { traits.insert(.italic) }
        if underlineStyleValue(in: attributes) != 0 { traits.insert(.underline) }
        return traits
    }

    private func underlineStyleValue(in attributes: [NSAttributedString.Key: Any]) -> Int {
        if let value = attributes[.underlineStyle] as? NSNumber { return value.intValue }
        if let value = attributes[.underlineStyle] as? Int { return value }
        return 0
    }

    private func font(from font: UIFont, toggling trait: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let existingTraits = font.fontDescriptor.symbolicTraits
        let updatedTraits = existingTraits.contains(trait)
            ? existingTraits.subtracting(trait)
            : existingTraits.union(trait)
        let descriptor = font.fontDescriptor.withSymbolicTraits(updatedTraits) ?? font.fontDescriptor
        return UIFont(descriptor: descriptor, size: font.pointSize)
    }

    private func clearPendingInsertionTraits() {
        pendingInsertionTraits = nil
        pendingInsertionLocation = nil
        pendingTextLength = nil
    }
}
