//
//  CardViewModel.swift
//  TrackCount
//
//  Contains most of the logic related to cards
//


import Foundation
import SwiftData
import SwiftUI

class CardViewModel: ObservableObject {
    // Set variable defaults
    @Published var selectedGroup: DMCardGroup
    @Published var selectedCard: DMStoredCard?
    @Published var newCardIndex: Int = 0
    @Published var newCardType: DMStoredCard.Types = .counter
    @Published var newCardTitle: String = ""
    @Published var newCardCount: Int = 1
    @Published var newCardModifier1: Int = 1
    @Published var newCardModifier2: Int = 0
    @Published var newCardModifier3: Int = 0
    @Published var newCardModifier: [Int] = [1]
    @Published var newButtonText: [String] = Array(repeating: "", count: 1)
    @Published var newCardState: [Bool] = Array(repeating: true, count: 1)
    @Published var newCardTimer1: [Int] = [0, 0, 0]
    @Published var newCardTimer2: [Int] = [0, 0, 0]
    @Published var newCardTimer3: [Int] = [0, 0, 0]
    @Published var newCardTimer4: [Int] = [0, 0, 0]
    @Published var newCardTimer: [Int] = [0]
    @Published var newCardRingtone: String = ""
    @Published var newCardSymbol: String = ""
    @Published var newCardPrimary: Color = .blue
    @Published var newCardSecondary: Color = .white
    @Published var validationError: [String] = []
    
    enum resetFor {
        case viewModel
        case dismiss
    }
    
    enum initFor {
        case switchType
        case validation
    }
    
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
        self.newCardType = card.type
        self.newCardTitle = card.title
        self.newCardCount = card.count
        self.newCardState = card.state?.isEmpty == false ? card.state!.map { $0.state } : Array(repeating: true, count: 1)
        self.newCardModifier = card.modifier?.isEmpty == false ? card.modifier!.map { $0.modifier } : [1]
        self.newButtonText = card.buttonText?.isEmpty == false ? card.buttonText!.map { $0.buttonText } : Array(repeating: "", count: 1)
        self.newCardSymbol = card.symbol ?? ""
        self.newCardTimer = card.timer?.isEmpty == false ? card.timer!.map { $0.timerValue } : Array(repeating: 0, count: 1)
        self.newCardRingtone = card.timerRingtone ?? ""
        self.newCardPrimary = card.primaryColor.color
        self.newCardSecondary = card.secondaryColor.color
    }
    
    /// A function that calls the corresponding initializers dynamically based on the type
    func initTypes(for behaviour: initFor) {
        // When switching cards, reset shared values
        if behaviour == .switchType {
            newCardCount = 1
        }
        
        if newCardType == .counter {
            initModifier()
        } else if newCardType == .toggle {
            initButton()
        } else if newCardType == .timer || newCardType == .timer_custom {
            initTimer()
        }
    }
    
    /// A function that consolidates the modifiers into one
    func initModifier() {
        var modifiers = [Int]()
        if newCardModifier1 != 0 { modifiers.append(newCardModifier1) }
        if newCardModifier2 != 0 { modifiers.append(newCardModifier2) }
        if newCardModifier3 != 0 { modifiers.append(newCardModifier3) }
        newCardModifier = modifiers
    }
    
    /// A function that adjusts variables related to buttons.
    /// Used to adjust the arrays `newButtonText` and `newCardState` to match the `newCardCount`.
    /// Also clamps `newCardCount` to stay within limits.
    func initButton() {
        // Validate newCardCount
        guard newCardCount >= minButtonLimit && newCardCount <= maxButtonLimit else {
            validationError.append("newCardCount must be between \(minButtonLimit) and \(maxButtonLimit)")
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
    
    /// A function that converts the timer values [hour, minute, second] into total seconds.
    /// - Parameter timeArray: Timer array to turn into total seconds
    /// - Returns: Returns an integer containing the total seconds
    private func convertToTotalSeconds(_ timeArray: [Int]) -> Int {
        guard timeArray.count >= 3 else { return 0 }
        return timeArray[0] * 3600 + timeArray[1] * 60 + timeArray[2]
    }
    
    /// Used to adjust the array `newCardTimer` to match the `newCardCount` and prep `newCardState`.
    /// Also clamps `newCardCount` to stay within limits
    func initTimer() {
        // Validate newCardCount
        guard newCardCount >= minTimerAmount && newCardCount <= maxTimerAmount else {
            validationError.append("newCardCount must be between \(minTimerAmount) and \(maxTimerAmount)")
            return
        }
        // Clamp newCardCount within valid limits
        newCardCount = min(max(newCardCount, minTimerAmount), maxTimerAmount)
        
        // Convert time arrays to total seconds
        let timerTotals = [
            convertToTotalSeconds(newCardTimer1),
            convertToTotalSeconds(newCardTimer2),
            convertToTotalSeconds(newCardTimer3),
            convertToTotalSeconds(newCardTimer4)
        ]
        
        // Adjust newCardTimer array size and populate with total seconds
        newCardTimer = Array(timerTotals.prefix(newCardCount))
        
        // Set newCardState for timer
        newCardState = Array(repeating: false, count: 1)
        
        // Validate timer values
        if newCardTimer.isEmpty {
            newCardTimer = Array(repeating: 0, count: newCardCount)
        }
    }
    
    /// A function that updates the timer values based on the index.
    func updateTimerValue(index: Int, hours: Int, minutes: Int, seconds: Int) {
        // Input validation
        let validatedHours = max(0, min(hours, 23))
        let validatedMinutes = max(0, min(minutes, 59))
        let validatedSeconds = max(0, min(seconds, 59))
        
        switch index {
        case 0:
            newCardTimer1 = [validatedHours, validatedMinutes, validatedSeconds]
        case 1:
            newCardTimer2 = [validatedHours, validatedMinutes, validatedSeconds]
        case 2:
            newCardTimer3 = [validatedHours, validatedMinutes, validatedSeconds]
        case 3:
            newCardTimer4 = [validatedHours, validatedMinutes, validatedSeconds]
        default:
            break
        }
        initTimer() // Recalculate timer values
    }
    
    /// A function that removes the card from the data model entity.
    /// Used to delete the card gracefully, adjusting existing card's indexes to take over a free index if applicable.
    func removeCard(_ card: DMStoredCard, with context: ModelContext) {
        do {
            // Remove the card from the context
            context.delete(card)
            
            // Remove the card from the group`s cards array
            selectedGroup.cards.removeAll { $0.uuid == card.uuid }
            
            // Update indices of remaining cards
            let sortedCards = selectedGroup.cards.sorted(by: { $0.index < $1.index })
            for (index, card) in sortedCards.enumerated() {
                card.index = index
            }
            
            // Save the context
            try context.save()
        } catch {
            validationError.append("Failed to remove card: \(error.localizedDescription)")
        }
    }
    
    /// A function that stores the temporary variables to a card and saves it to the data model entity.
    /// Used to save the set variables into the cards within the selected group.
    /// Also checks the card contents and throws errors, if any, to `validationError`.
    /// Also provides the card's index and uuid on save.
    func saveCard(with context: ModelContext) {
        // Validate types and update them before saving
        initTypes(for: .validation)
        
        // Validate the form before saving
        validateForm()
        guard validationError.isEmpty else {
            return
        }
        
        // Check if there are any existing cards
        if selectedGroup.cards.count == 0 {
            newCardIndex = 0 // Set new index to 0 if there are no cards
        } else {
            newCardIndex = selectedGroup.cards.count // Set new index to the next highest number
        }
        
        do {
            if let card = selectedCard {
                // Update existing card
                card.title = newCardTitle
                card.type = newCardType
                card.count = newCardType == .counter ? 0 : newCardCount
                card.state = newCardType == .toggle ? newCardState.prefix(newCardCount).map { CardState(state: $0) } : (newCardType == .timer || newCardType == .timer_custom) ? [CardState(state: false)] : nil
                card.modifier = newCardType == .counter ? newCardModifier.map { CounterModifier(modifier: $0) } : nil
                card.buttonText = newCardType == .toggle ? newButtonText.prefix(newCardCount).map { ButtonText(buttonText: $0) } : nil
                card.symbol = newCardType == .toggle ? newCardSymbol : nil
                card.timer = (newCardType == .timer || newCardType == .timer_custom) ? newCardTimer.map { TimerValue(timerValue: $0) } : nil
                card.timerRingtone = (newCardType == .timer || newCardType == .timer_custom) ? newCardRingtone : nil
                card.primaryColor = CodableColor(color: newCardPrimary)
                card.secondaryColor = CodableColor(color: newCardSecondary)
            } else {
                // Create new card with guaranteed unique UUID
                let newCard = DMStoredCard(
                    uuid: UUID(),
                    index: newCardIndex,
                    type: newCardType,
                    title: newCardTitle,
                    count: newCardType == .counter ? 0 : newCardCount,
                    state: newCardType == .toggle ? newCardState.prefix(newCardCount).map { $0 } :
                        (newCardType == .timer || newCardType == .timer_custom) ? [false] : nil,
                    modifier: newCardType == .counter ? newCardModifier : nil,
                    buttonText: newCardType == .toggle ? newButtonText.prefix(newCardCount).map { $0 } : nil,
                    symbol: newCardType == .toggle ? newCardSymbol : nil,
                    timer: (newCardType == .timer || newCardType == .timer_custom) ? newCardTimer : nil,
                    timerRingtone: (newCardType == .timer || newCardType == .timer_custom) ? newCardRingtone : nil,
                    primaryColor: newCardPrimary,
                    secondaryColor: newCardSecondary
                )
                selectedGroup.cards.append(newCard)
            }
            
            // Save the context
            try context.save()
            resetFields(.viewModel)
        } catch {
            validationError.append("Failed to save the card: \(error.localizedDescription)")
        }
    }
    
    /// A function that sets the temporary fields to defaults.
    /// Used to reset the contents after saving a card to free the fields for a new card.
    func resetFields(_ behaviour: resetFor? = .dismiss) {
        if behaviour == .dismiss {
            selectedCard = nil
        }
        newCardType = .counter
        newCardTitle = ""
        newCardCount = 1
        newCardModifier1 = 1
        newCardModifier2 = 0
        newCardModifier3 = 0
        newCardModifier = [1]
        newButtonText = Array(repeating: "", count: 1)
        newCardState = Array(repeating: true, count: 1)
        newCardSymbol = ""
        newCardTimer = Array(repeating: 0, count: 1)
        newCardRingtone = ""
        newCardPrimary = .blue
        newCardSecondary = .white
    }
    
    /// A function that checks the card's contents for any issues.
    /// Prevents empty titles for all card types and empty symbols for toggle cards.
    /// Appends errors to `validationError`.
    private func validateForm() {
        validationError.removeAll()
        
        if newCardTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            validationError.append("Card title cannot be empty")
        }
        
        if newCardType == .counter {
            if newCardModifier.contains(where: { $0 < 0 }) {
                validationError.append("Modifiers cannot be negative")
            }
            
            if newCardModifier.isEmpty {
                validationError.append("There can't be less than one modifier")
            }
        } else if newCardType == .toggle {
            if newCardSymbol.trimmingCharacters(in: .whitespaces).isEmpty {
                validationError.append("Symbol cannot be empty for toggle type")
            }
        } else if newCardType == .timer {
            for (index, timerValue) in newCardTimer.enumerated() {
                if timerValue <= 0 {
                    validationError.append("Timer \(index + 1) cannot be less than one")
                } else if timerValue >= 86400 {
                    validationError.append("Timer \(index + 1) cannot exceed limits")
                }
            }
        }
    }
}
