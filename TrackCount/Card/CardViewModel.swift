//
//  CardViewModel.swift
//  TrackCount
//
//  Contains most of the logic related to cards
//

import Foundation
import SwiftData
import SwiftUI
import Combine

class CardViewModel: ObservableObject {
    // Set variable defaults
    @Published var selectedGroup: DMCardGroup
    @Published var selectedCard: DMStoredCard?
    @Published var newCardIndex: Int = 0
    @Published var newCardType: DMStoredCard.Types = .counter
    @Published var newCardTitle: String = ""
    @Published var newCardCount: Int = 1
    @Published var newCardModifier: [Int] = [1, 0, 0]
    @Published var newCardModifierItems: [ModifierItem] = [
        ModifierItem(text: "1"),
        ModifierItem(text: "0"),
        ModifierItem(text: "0")
    ]
    @Published var newButtonText: [String] = Array(repeating: "", count: 1)
    @Published var newCardState: [Bool] = Array(repeating: true, count: 1)
    @Published var newTimerValues: [Int : [Int]] = [0 : [0, 0 ,0]]
    @Published var newCardTimer: [Int] = [0]
    @Published var newCardRingtone: String = ""
    @Published var newCardSymbol: String = ""
    @Published var newCardPrimary: Color = .blue
    @Published var newCardSecondary: Color = .white
    @Published var validationError: [String] = []
    @Published var warnError: [String] = []
    
    struct ModifierItem: Identifiable, Equatable {
        let id = UUID()
        var text: String
    }
    
    enum ResetFor {
        case viewModel
        case dismiss
    }
    
    enum InitFor {
        case switchType
        case validation
    }
    
    // Counter limit
    let minModifierLimit = 0
    let maxModifierLimit = 100000
    
    // Button limit
    let buttonTextLimit = 20
    let minButtonLimit = 1
    let maxButtonLimit = 4096
    
    // Timer limit
    let minTimerAmount = 1
    let maxTimerAmount = 4
    let minTimerLimit = 1
    let maxTimerLimit = 86399
    
    /// Initializes the `selectedGroup` and `selectedCard` variable for editing.
    /// - Parameters:
    ///   - selectedGroup: accepts `DMCardGroup` entities, reference for which group to store the card.
    ///   - selectedCard: (optional) accepts `DMStoredCard` entities, edits the entity that is passed over.
    init(selectedGroup: DMCardGroup, selectedCard: DMStoredCard? = nil) {
        self.selectedGroup = selectedGroup
        self.selectedCard = selectedCard
    }
    
    /// A function that grabs the saved data from a selected card.
    /// Used to populate the temporary variables within `CardViewModel` with the variables from the selected card.
    func fetchCard() {
        guard let card = selectedCard else { return }
        
        self.newCardType = card.type ?? .counter
        self.newCardTitle = card.title
        self.newCardCount = card.count
        
        self.newCardState = card.state?.isEmpty == false
        ? card.state!.map { $0.state }
        : Array(repeating: true, count: 1)
        
        self.newCardModifier = card.modifier?.isEmpty == false
        ? card.modifier!.map { $0.modifier }
        : [1, 0, 0]
        
        self.newCardModifierItems = card.modifier?.isEmpty == false
        ? card.modifier!.map { ModifierItem(text: String($0.modifier)) }
        : [ModifierItem(text: "1"), ModifierItem(text: "0"), ModifierItem(text: "0")]
        
        self.newButtonText = card.buttonText?.isEmpty == false
        ? card.buttonText!.map { $0.buttonText }
        : Array(repeating: "", count: 1)
        
        self.newCardSymbol = card.symbol ?? ""
        self.newCardTimer = card.timer?.isEmpty == false
        ? card.timer!.map { $0.timerValue }
        : Array(repeating: 0, count: 1)
        
        self.newCardRingtone = card.timerRingtone ?? ""
        self.newCardPrimary = card.primaryColor?.color ?? .blue
        self.newCardSecondary = card.secondaryColor?.color ?? .white
        
        if card.type == .timer || card.type == .timer_custom {
            for i in 0..<(card.timer?.count ?? 0) {
                if let seconds = card.timer?[i].timerValue {
                    let h = seconds / 3600
                    let m = (seconds % 3600) / 60
                    let s = seconds % 60
                    newTimerValues[i] = [h, m, s]
                }
            }
        }
    }
    
    /// A function that calls the corresponding initializers dynamically based on the type
    func initTypes(for behaviour: InitFor) {
        // When switching cards, reset errors and shared values
        validationError.removeAll()
        
        if behaviour == .switchType {
            newCardCount = 1
        }
        
        switch newCardType {
        case .counter:
            initCounter()
        case .toggle:
            initButton()
        case .timer, .timer_custom:
            initTimer()
        default:
            break
        }
    }
    
    func initCounter() {
        newCardModifier = newCardModifierItems.map { item in
            let value = Int(item.text) ?? 0
            return max(value, 0)
        }
    }
    
    /// A function that adjusts variables related to buttons.
    /// Used to adjust the arrays `newButtonText` and `newCardState` to match the `newCardCount`.
    /// Also clamps `newCardCount` to stay within limits.
    func initButton() {
        // Validate newCardCount
        guard newCardCount >= minButtonLimit && newCardCount <= maxButtonLimit else {
            validateForm()
            return
        }
        
        // Clamp newCardCount within valid limits
        newCardCount = min(max(newCardCount, minButtonLimit), maxButtonLimit)
        
        // Adjust `newButtonText` array size
        if newButtonText.count < newCardCount {
            newButtonText.append(contentsOf: Array(repeating: "", count: newCardCount - newButtonText.count))
        } else if newButtonText.count > newCardCount {
            newButtonText.removeLast(newButtonText.count - newCardCount)
        }
        
        // Adjust `newCardState` array size
        newCardState = Array(repeating: true, count: newCardCount)
    }
    
    /// Used to adjust the array `newCardTimer` to match the `newCardCount` and prep `newCardState`.
    /// Also clamps `newCardCount` to stay within limits
    func initTimer() {
        // Validate newCardCount
        guard newCardCount >= minTimerAmount && newCardCount <= maxTimerAmount else {
            validateForm()
            return
        }
        
        // Clamp newCardCount within valid limits
        newCardCount = min(max(newCardCount, minTimerAmount), maxTimerAmount)
        
        // Convert time arrays to total seconds
        let timerTotals = Array(0..<4).map { index in
            convertToTotalSeconds(newTimerValues[index] ?? [0, 0, 0])
        }
        
        // Adjust newCardTimer array size and populate with total seconds
        newCardTimer = Array(timerTotals.prefix(newCardCount))
        
        // Set newCardState for timer
        newCardState = Array(repeating: false, count: 1)
        
        // Validate timer values
        if newCardTimer.isEmpty {
            newCardTimer = Array(repeating: 0, count: newCardCount)
        }
    }
    
    /// A function that handles the movement of modifiers in the list.
    func moveModifier(from source: IndexSet, to destination: Int) {
        newCardModifierItems.move(fromOffsets: source, toOffset: destination)
        newCardModifier.move(fromOffsets: source, toOffset: destination)
        validateForm()
    }
    
    /// A function that converts the timer values [hour, minute, second] into total seconds.
    private func convertToTotalSeconds(_ timeArray: [Int]) -> Int {
        guard timeArray.count >= 3 else { return 0 }
        return timeArray[0] * 3600 + timeArray[1] * 60 + timeArray[2]
    }
    
    /// A function that updates the timer values based on the index.
    func updateTimerValue(index: Int, hours: Int, minutes: Int, seconds: Int) {
        // Input validation
        let validatedHours = max(0, min(hours, 23))
        let validatedMinutes = max(0, min(minutes, 59))
        let validatedSeconds = max(0, min(seconds, 59))
        
        newTimerValues[index] = [validatedHours, validatedMinutes, validatedSeconds]
        initTimer() // Recalculate timer values
    }
    
    // MARK: - Saving Logic
    /// Stores the temporary variables to a card and saves it to the data model entity.
    func saveCard(with context: ModelContext) {
        initTypes(for: .validation)
        
        validateForm()
        guard validationError.isEmpty else { return }
        
        // Determine the next index based on existing cards
        newCardIndex = selectedGroup.cards?.count ?? 0
        
        do {
            if let existingCard = selectedCard {
                update(existingCard)
            } else {
                createNewCard(in: context)
            }
            
            try context.save()
            resetFields(.viewModel)
        } catch {
            warnError = ["Failed to save the card: \(error.localizedDescription)"]
        }
    }
    
    /// Helper function to handle updating an existing card
    private func update(_ card: DMStoredCard) {
        if card.type == .timer || card.type == .timer_custom {
            NotificationCenter.default.post(
                name: NSNotification.Name("TimerCardEdited"),
                object: nil,
                userInfo: ["cardUUID": card.uuid]
            )
        }
        
        card.title = newCardTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        card.type = newCardType
        card.count = (newCardType == .counter && card.type != .counter) ? 0 : newCardCount
        card.primaryColor = CodableColor(color: newCardPrimary)
        card.secondaryColor = CodableColor(color: newCardSecondary)
        card.group = selectedGroup
        
        // Wipe type-specific fields before reapplying
        card.state = nil
        card.modifier = nil
        card.buttonText = nil
        card.symbol = nil
        card.timer = nil
        card.timerRingtone = nil
        
        // Apply type-specific fields dynamically
        switch newCardType {
        case .counter:
            card.modifier = newCardModifier.map { CounterModifier(modifier: $0) }
            
        case .toggle:
            card.state = newCardState.prefix(newCardCount).map { CardState(state: $0) }
            card.buttonText = newButtonText.prefix(newCardCount).map { ButtonText(buttonText: $0) }
            card.symbol = newCardSymbol
            
        case .timer, .timer_custom:
            card.state = [CardState(state: false)]
            card.timer = newCardTimer.map { TimerValue(timerValue: $0) }
            card.timerRingtone = newCardRingtone
            
        case .note:
            card.state = [CardState(state: false)]
        }
    }
    
    /// Helper function to build and insert a brand new card
    private func createNewCard(in context: ModelContext) {
        var rawState: [Bool]? = nil
        var rawModifier: [Int]? = nil
        var rawButtonText: [String]? = nil
        var rawSymbol: String? = nil
        var rawTimer: [Int]? = nil
        var rawRingtone: String? = nil
        
        let resolvedCount = (newCardType == .counter) ? 0 : newCardCount
        
        switch newCardType {
        case .counter:
            rawModifier = newCardModifier
            
        case .toggle:
            rawState = Array(newCardState.prefix(resolvedCount))
            rawButtonText = Array(newButtonText.prefix(resolvedCount))
            rawSymbol = newCardSymbol
            
        case .timer, .timer_custom:
            rawState = [false]
            rawTimer = newCardTimer
            rawRingtone = newCardRingtone
            
        case .note:
            rawState = [false]
        }
        
        let newCard = DMStoredCard(
            index: newCardIndex,
            type: newCardType,
            title: newCardTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            count: resolvedCount,
            state: rawState,
            modifier: rawModifier,
            buttonText: rawButtonText,
            symbol: rawSymbol,
            timer: rawTimer,
            timerRingtone: rawRingtone,
            primaryColor: newCardPrimary,
            secondaryColor: newCardSecondary,
            group: selectedGroup
        )
        
        if selectedGroup.cards == nil {
            selectedGroup.cards = []
        }
        selectedGroup.cards?.append(newCard)
        context.insert(newCard)
    }
    
    // MARK: - Card Removal & Validation
    /// A function that removes the card from the data model entity.
    func removeCard(_ card: DMStoredCard, with context: ModelContext) {
        do {
            context.delete(card)
            selectedGroup.cards?.removeAll { $0.uuid == card.uuid }
            
            // Update indices of remaining cards safely
            if let cards = selectedGroup.cards {
                let sortedCards = cards.sorted(by: { ($0.index ?? 0) < ($1.index ?? 0) })
                for (index, remainingCard) in sortedCards.enumerated() {
                    remainingCard.index = index
                }
            }
            
            try context.save()
        } catch {
            warnError = ["Failed to remove card: \(error.localizedDescription)"]
        }
    }
    
    /// Checks the card's contents for any issues and appends errors to `validationError`.
    func validateForm() {
        withAnimation(.easeInOut(duration: 1.0)) {
            validationError.removeAll()
            
            if newCardTitle.trimmingCharacters(in: .whitespaces).isEmpty {
                validationError.append("CardTitleEmpty")
            }
            
            switch newCardType {
            case .counter:
                for (index, modifierValue) in newCardModifier.enumerated() {
                    if modifierValue < 0 {
                        validationError.append("Modifier\(index)Negative")
                    } else if modifierValue > maxModifierLimit {
                        validationError.append("Modifier\(index)MoreThanMax")
                    }
                }
                if !newCardModifier.contains(where: { $0 > 0 }) {
                    validationError.append("ModifierLessThanOne")
                }
                
            case .toggle:
                if newCardSymbol.trimmingCharacters(in: .whitespaces).isEmpty {
                    validationError.append("SymbolEmpty")
                }
                if newCardCount < minButtonLimit {
                    validationError.append("ButtonLessThanMin")
                } else if newCardCount > maxButtonLimit {
                    validationError.append("ButtonMoreThanMax")
                }
                
            case .timer, .timer_custom: // Consolidated timer cases
                if newCardCount < minTimerAmount || newCardCount > maxTimerAmount {
                    validationError.append("TimerExceedsLimits")
                }
                for (index, timerValue) in newCardTimer.enumerated() {
                    if timerValue < minTimerLimit {
                        validationError.append("Timer\(index)LessThanMin")
                    } else if timerValue > maxTimerLimit {
                        validationError.append("Timer\(index)MoreThanMax")
                    }
                }
                
            default:
                break
            }
        }
    }
    
    /// Sets the temporary fields to defaults.
    func resetFields(_ behaviour: ResetFor? = .dismiss) {
        if behaviour == .dismiss {
            selectedCard = nil
        }
        
        newCardType = .counter
        newCardTitle = ""
        newCardCount = 1
        newCardModifier = [1, 0, 0]
        newCardModifierItems = [ModifierItem(text: "1"), ModifierItem(text: "0"), ModifierItem(text: "0")]
        newButtonText = Array(repeating: "", count: 1)
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
        newTimerValues = [0 : [0, 0 ,0]]
        newCardTimer = Array(repeating: 0, count: 1)
        newCardRingtone = ""
        newCardPrimary = .blue
        newCardSecondary = .white
    }
}
